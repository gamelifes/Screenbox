import 'dart:io';
import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import 'package:liyaplayer/core/services/hive_service.dart';

/// 系统托盘服务
///
/// 负责：
/// - 托盘图标和菜单
/// - 托盘事件处理
/// - 与 WindowManager 交互
class SystemTrayService {
  static final SystemTrayService _instance = SystemTrayService._internal();
  static SystemTrayService get instance => _instance;

  final SystemTray _systemTray = SystemTray();
  bool _isInitialized = false;

  // 回调函数
  VoidCallback? onPlayPause;
  VoidCallback? onNext;
  VoidCallback? onPrevious;
  VoidCallback? onShowWindow;   // 显示窗口（迷你 > 主）
  VoidCallback? onToggleWindow;  // 切换窗口显示状态
  VoidCallback? onQuit;

  SystemTrayService._internal();

  /// 初始化托盘
  Future<void> initialize({
    VoidCallback? onPlayPause,
    VoidCallback? onNext,
    VoidCallback? onPrevious,
    VoidCallback? onShowWindow,
    VoidCallback? onToggleWindow,
    VoidCallback? onQuit,
  }) async {
    if (_isInitialized) return;

    this.onPlayPause = onPlayPause;
    this.onNext = onNext;
    this.onPrevious = onPrevious;
    this.onShowWindow = onShowWindow;
    this.onToggleWindow = onToggleWindow;
    this.onQuit = onQuit;

    // 获取托盘图标路径
    String iconPath = _getIconPath();

    // 初始化托盘
    await _systemTray.initSystemTray(
      title: 'LihaPlayer',
      iconPath: iconPath,
      toolTip: 'LihaPlayer - 音乐播放器',
    );

    // 设置上下文菜单
    await _updateMenu(isPlaying: false);

    // 注册事件处理
    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        // 点击托盘图标：显示右键菜单
        _systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        _systemTray.popUpContextMenu();
      } else if (eventName == 'doubleClick') {
        // 双击托盘图标：显示窗口
        onShowWindow?.call();
      }
    });

    _isInitialized = true;
  }

  String _getIconPath() {
    if (Platform.isWindows) {
      final exePath = Platform.resolvedExecutable;
      final exeDir = File(exePath).parent.path;
      final iconPath =
          '$exeDir\\data\\flutter_assets\\assets\\icons\\app_icon.ico';
      if (File(iconPath).existsSync()) {
        return iconPath;
      }
    }
    return '';
  }

  Future<void> updatePlayState(bool isPlaying) async {
    if (!_isInitialized) return;
    await _updateMenu(isPlaying: isPlaying);
  }

  Future<void> _updateMenu({required bool isPlaying}) async {
    final menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: '显示/隐藏',
        onClicked: (menuItem) => onShowWindow?.call(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: isPlaying ? '暂停' : '播放',
        onClicked: (menuItem) => _handlePlayPause(),
      ),
      MenuItemLabel(
        label: '上一曲',
        onClicked: (menuItem) => _handlePrevious(),
      ),
      MenuItemLabel(
        label: '下一曲',
        onClicked: (menuItem) => _handleNext(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: '退出',
        onClicked: (menuItem) => _handleQuit(),
      ),
    ]);
    await _systemTray.setContextMenu(menu);
  }

  void _handlePlayPause() => onPlayPause?.call();
  void _handlePrevious() => onPrevious?.call();
  void _handleNext() => onNext?.call();
  void _handleQuit() => onQuit?.call();

  Future<void> showNotification(String title, String body) async {
    // 保留接口，system_tray 不支持通知
  }

  Future<void> setToolTip(String tooltip) async {
    if (!_isInitialized) return;
    await _systemTray.setToolTip(tooltip);
  }

  Future<void> dispose() async {
    if (!_isInitialized) return;
    await _systemTray.destroy();
    _isInitialized = false;
  }
}

/// WindowManager 服务
///
/// 负责：
/// - 窗口初始化
/// - 最小化/最大化/关闭
/// - 最小化到托盘
/// - 焦点管理
class WindowManagerService {
  static final WindowManagerService _instance =
      WindowManagerService._internal();
  static WindowManagerService get instance => _instance;

  bool _isInitialized = false;
  bool _minimizeToTray = false;
  VoidCallback? _onClose;

  WindowManagerService._internal();

  Future<void> initialize({
    bool minimizeToTray = false,
    VoidCallback? onClose,
  }) async {
    if (_isInitialized) return;

    _minimizeToTray = minimizeToTray;
    _onClose = onClose;

    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'LihaPlayer',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await _restoreWindowState();
      await windowManager.show();
      await windowManager.focus();
    });

    _isInitialized = true;
  }

  Future<void> _restoreWindowState() async {
    try {
      final state = HiveService.instance.getWindowState();
      if (state != null) {
        await windowManager.setPosition(Offset(state['x'], state['y']));
        await windowManager.setSize(Size(state['width'], state['height']));
        if (state['isMaximized'] == true) {
          await windowManager.maximize();
        }
      }
    } catch (e) {
      // 忽略恢复失败，使用默认值
    }
  }

  Future<void> _saveWindowState() async {
    try {
      final position = await windowManager.getPosition();
      final size = await windowManager.getSize();
      final isMaximized = await windowManager.isMaximized();

      await HiveService.instance.saveWindowState(
        x: position.dx,
        y: position.dy,
        width: size.width,
        height: size.height,
        isMaximized: isMaximized,
      );
    } catch (e) {
      // 忽略保存失败
    }
  }

  Future<void> minimize() async => await windowManager.minimize();

  Future<void> maximize() async => await windowManager.maximize();

  Future<void> close() async {
    await _saveWindowState();
    await windowManager.close();
  }

  Future<bool> isMaximized() async => await windowManager.isMaximized();

  Future<void> minimizeToTray() async => await windowManager.hide();

  Future<void> show() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> hide() async => await windowManager.hide();

  Future<void> focus() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> toggleMaximize() async {
    final isMax = await windowManager.isMaximized();
    if (isMax) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  Future<void> dispose() async {
    await _saveWindowState();
    await windowManager.destroy();
    _isInitialized = false;
  }
}
