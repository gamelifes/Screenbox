// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/widgets.dart';
import 'package:flutter/src/widgets/_window.dart' show BaseWindowController, RegularWindowController, RegularWindowControllerDelegate;
import 'dart:ui' show FlutterView;
import 'package:window_manager/window_manager.dart';

/// 窗口信息
class KeyedWindow {
  KeyedWindow({
    this.isMainWindow = false,
    required this.key,
    required this.controller,
    this.parent,
    this.onClose,
  });

  final bool isMainWindow;
  final UniqueKey key;
  final BaseWindowController controller;
  final FlutterView? parent; // 父窗口视图（用于子窗口判断）
  final VoidCallback? onClose; // 关闭回调
}

/// 提供应用程序创建的所有窗口的访问权限。
class LihaWindowManager extends ChangeNotifier {
  LihaWindowManager({required List<KeyedWindow> initialWindows})
    : _windows = initialWindows;

  final List<KeyedWindow> _windows;
  List<KeyedWindow> get windows => _windows;
  
  // 原生窗口是否隐藏
  bool _isHidden = false;
  bool get isHidden => _isHidden;

  UniqueKey? _mainWindowKey;
  UniqueKey? get mainWindowKey => _mainWindowKey;

  /// 添加窗口
  void add(KeyedWindow window) {
    if (window.isMainWindow) {
      _mainWindowKey = window.key;
    }
    _windows.add(window);
    notifyListeners();
  }

  /// 移除窗口
  void remove(UniqueKey key) {
    debugPrint('[LihaWindowManager] remove called, key=$key, current _windows.length=${_windows.length}');
    _windows.removeWhere((KeyedWindow window) => window.key == key);
    debugPrint('[LihaWindowManager] after remove, _windows.length=${_windows.length}');
    // 使用 setter 重置状态，会自动调用 notifyListeners()
    miniPlayerVisible = false;
  }

  /// 获取顶级窗口（无父窗口的窗口）
  Iterable<KeyedWindow> getRootWindows() {
    return _windows.where((KeyedWindow window) => window.parent == null);
  }

  /// 获取指定父窗口的子窗口
  Iterable<KeyedWindow> getChildWindows(FlutterView parent) {
    return _windows.where((KeyedWindow window) => window.parent == parent);
  }

  /// 获取指定父窗口的所有子窗口（官方 API 兼容）
  Iterable<KeyedWindow> getWindows({required FlutterView? parent}) {
    return _windows.where((KeyedWindow window) => window.parent == parent);
  }

  /// 检查是否有迷你窗口
  bool get hasMiniPlayer {
    return _windows.any(
      (w) => !w.isMainWindow && w.controller is RegularWindowController,
    );
  }

  /// 关闭迷你窗口
  void closeMiniPlayer() {
    final miniWindow = _windows.where((w) => !w.isMainWindow).firstOrNull;
    if (miniWindow != null) {
      miniWindow.controller.destroy();
    }
  }

  /// 检查主窗口是否可见
  bool get isVisible => !_isHidden;

  /// 隐藏主窗口（不显示在任务栏）
  Future<void> hideMainWindow() async {
    debugPrint('[LihaWindowManager] hideMainWindow called');
    // 使用 window_manager 包的 hide 方法
    await windowManager.hide();
    _isHidden = true;
    notifyListeners();
  }

  /// 显示主窗口
  Future<void> showMainWindow() async {
    debugPrint('[LihaWindowManager] showMainWindow called');
    // 使用 window_manager 包的 show 方法
    await windowManager.show();
    await windowManager.focus();
    _isHidden = false;
    notifyListeners();
  }

  /// 显示窗口（自动判断：优先显示迷你窗口）
  ///
  /// 如果有迷你窗口打开 → 显示迷你窗口
  /// 否则 → 显示主窗口
  Future<void> showWindow() async {
    if (hasMiniPlayer) {
      await showMiniPlayerWindow();
    } else {
      await showMainWindow();
    }
  }

  /// 隐藏窗口（自动判断：优先隐藏迷你窗口）
  ///
  /// 如果有迷你窗口打开 → 隐藏迷你窗口
  /// 否则 → 隐藏主窗口
  Future<void> hideWindow() async {
    if (hasMiniPlayer) {
      await hideMiniPlayerWindow();
    } else {
      await hideMainWindow();
    }
  }

  /// 切换窗口显示状态
  ///
  /// 如果有窗口可见 → 隐藏所有窗口
  /// 否则 → 显示对应窗口
  Future<void> toggleWindow() async {
    debugPrint('[LihaWindowManager] toggleWindow called, isAnyWindowVisible=$isAnyWindowVisible');
    if (isAnyWindowVisible) {
      await hideWindow();
    } else {
      await showWindow();
    }
  }

  /// 切换主窗口显示状态
  ///
  /// 如果主窗口可见 → 隐藏主窗口
  /// 否则 → 显示主窗口
  Future<void> toggleMainWindow() async {
    debugPrint('[LihaWindowManager] toggleMainWindow called, _isHidden=$_isHidden');
    if (_isHidden) {
      await showMainWindow();
    } else {
      await hideMainWindow();
    }
  }

  /// 是否有任何窗口可见
  bool get isAnyWindowVisible {
    if (hasMiniPlayer) {
      return _miniPlayerVisible;
    }
    return !_isHidden;
  }

  bool _miniPlayerVisible = false;
  bool get miniPlayerVisible => _miniPlayerVisible;

  set miniPlayerVisible(bool value) {
    if (_miniPlayerVisible != value) {
      _miniPlayerVisible = value;
      debugPrint('[LihaWindowManager] miniPlayerVisible changed to $value, notifying');
      notifyListeners();
    }
  }

  /// 显示迷你窗口
  ///
  /// 如果迷你窗口是最小化状态，恢复窗口
  /// 如果迷你窗口已销毁，此方法无效
  Future<void> showMiniPlayerWindow() async {
    debugPrint('[LihaWindowManager] showMiniPlayerWindow called, hasMiniPlayer=$hasMiniPlayer, miniPlayerVisible=$miniPlayerVisible');
    final miniWindow = _windows.where((w) => !w.isMainWindow).firstOrNull;
    debugPrint('[LihaWindowManager] miniWindow found: ${miniWindow != null}');
    if (miniWindow != null && miniWindow.controller is RegularWindowController) {
      // 使用 dynamic 调用 internal 方法 setMinimized
      final controller = miniWindow.controller as dynamic;
      debugPrint('[LihaWindowManager] isMinimized: ${controller.isMinimized}');
      // 始终尝试恢复窗口（无论是否最小化）
      debugPrint('[LihaWindowManager] restoring mini window via setMinimized(false)');
      controller.setMinimized(false);
      // 隐藏主窗口
      debugPrint('[LihaWindowManager] hiding main window via window_manager');
      await windowManager.hide();
      _isHidden = true;
      // 使用 setter 会自动调用 notifyListeners()
      miniPlayerVisible = true;
    }
  }

/// 隐藏迷你窗口（最小化，不销毁）
  ///
  /// 注意：此方法只是最小化窗口，不会销毁，主窗口保持隐藏
  Future<void> hideMiniPlayerWindow() async {
    debugPrint('[LihaWindowManager] hideMiniPlayerWindow called');
    // 只有在迷你窗口真正可见时才最小化
    if (!miniPlayerVisible) {
      debugPrint('[LihaWindowManager] miniPlayerVisible is false, skipping minimize');
      return;
    }
    final miniWindow = _windows.where((w) => !w.isMainWindow).firstOrNull;
    if (miniWindow != null && miniWindow.controller is RegularWindowController) {
      debugPrint('[LihaWindowManager] minimizing mini window');
      // 最小化迷你窗口（使用 internal 方法 setMinimized）
      final controller = miniWindow.controller as dynamic;
      controller.setMinimized(true);
      // 标记主窗口可见（因为迷你窗口已隐藏）
      _isHidden = false;
      // 使用 setter 会自动调用 notifyListeners()
      miniPlayerVisible = false;
    }
  }
}

/// 从 Widget 树中获取 [LihaWindowManager]。
class LihaWindowManagerAccessor extends InheritedNotifier<LihaWindowManager> {
  const LihaWindowManagerAccessor({
    super.key,
    required super.child,
    required LihaWindowManager windowManager,
  }) : super(notifier: windowManager);

  static LihaWindowManager of(BuildContext context) {
    final LihaWindowManagerAccessor? result = context
        .dependOnInheritedWidgetOfExactType<LihaWindowManagerAccessor>();
    assert(result != null, 'No LihaWindowManager found in context');
    return result!.notifier!;
  }
}

/// 控制新创建窗口行为的设置。
class WindowSettings {
  WindowSettings({
    this.miniPlayerSize = const Size(320, 320),
    this.miniPlayerPosition = const Offset(100, 100),
  });

  Size miniPlayerSize;
  Offset miniPlayerPosition;
}

/// 从 Widget 树中获取 [WindowSettings]。
class WindowSettingsAccessor extends InheritedWidget {
  const WindowSettingsAccessor({
    super.key,
    required super.child,
    required this.windowSettings,
  });

  final WindowSettings windowSettings;

  static WindowSettings of(BuildContext context) {
    final WindowSettingsAccessor? result = context
        .dependOnInheritedWidgetOfExactType<WindowSettingsAccessor>();
    assert(result != null, 'No WindowSettings found in context');
    return result!.windowSettings;
  }

  @override
  bool updateShouldNotify(WindowSettingsAccessor oldWidget) {
    return windowSettings != oldWidget.windowSettings;
  }
}

/// 迷你窗口控制器委托
mixin MiniPlayerWindowDelegate on RegularWindowControllerDelegate {
  void onMiniPlayerDestroyed();
}

/// 窗口命令
class WindowCommand {
  final String method;
  final dynamic args;
  final DateTime timestamp;

  WindowCommand({required this.method, this.args, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}
