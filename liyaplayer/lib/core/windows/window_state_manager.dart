import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:liyaplayer/features/player/presentation/providers/player_provider.dart';

/// 窗口类型枚举
enum WindowType { main, mini }

/// 窗口信息
class WindowInfo {
  final int windowId;
  final WindowType type;
  final StreamController<PlayerState>? stateController;

  WindowInfo({
    required this.windowId,
    required this.type,
    this.stateController,
  });
}

/// 跨窗口状态管理器
///
/// 使用单例模式管理全局播放状态，所有窗口共享同一状态源。
/// 状态变化通过 Stream 广播给所有订阅窗口。
///
/// 架构：
/// ```
/// ┌─────────────────────────────────────────────────────┐
/// │            WindowStateManager (Singleton)            │
/// │  - 全局状态存储 (currentState)                       │
/// │  - 已注册窗口列表 (windows)                          │
/// │  - 状态变化广播 (broadcastState)                     │
/// └─────────────────────────────────────────────────────┘
///          ↑ publish                    ↓ subscribe
///          │                            │
/// ┌───────────────┐           ┌───────────────┐
/// │   主窗口       │           │   迷你窗口     │
/// │  发布状态变化   │           │  订阅状态变化   │
/// └───────────────┘           └───────────────┘
/// ```
class WindowStateManager {
  // 单例
  static final WindowStateManager _instance = WindowStateManager._internal();
  static WindowStateManager get instance => _instance;
  WindowStateManager._internal() {
    debugPrint('[WindowStateManager] Created singleton instance');
  }

  // 全局播放状态
  PlayerState _currentState = PlayerState.initial;
  PlayerState get currentState => _currentState;

  // 导航状态（当前选中的导航索引）
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    if (index < 0 || index > 4) return;
    _selectedIndex = index;
    debugPrint('[WindowStateManager] selectedIndex set to $index');
  }

  // 已注册窗口列表
  final Map<int, WindowInfo> _windows = {};

  // 命令流（所有窗口发送的命令都汇聚到这里）
  final StreamController<WindowCommand> _commandController =
      StreamController<WindowCommand>.broadcast();

  // 外部监听器（用于 Riverpod ref.listen）
  void Function(PlayerState previous, PlayerState next)? _onStateChanged;

  /// 注册状态变化监听器
  void setStateChangeListener(
    void Function(PlayerState previous, PlayerState next)? listener,
  ) {
    _onStateChanged = listener;
    debugPrint('[WindowStateManager] State change listener set');
  }

  /// 注册窗口
  void registerWindow(int windowId, WindowType type) {
    if (_windows.containsKey(windowId)) {
      debugPrint('[WindowStateManager] Window $windowId already registered');
      return;
    }

    _windows[windowId] = WindowInfo(windowId: windowId, type: type);
    debugPrint(
      '[WindowStateManager] Registered window $windowId as ${type.name}, total: ${_windows.length}',
    );

    // 新窗口注册时，发送当前状态给它
    if (type == WindowType.mini) {
      _sendStateToWindow(windowId);
    }
  }

  /// 注销窗口
  void unregisterWindow(int windowId) {
    final window = _windows.remove(windowId);
    if (window != null) {
      debugPrint(
        '[WindowStateManager] Unregistered window $windowId, remaining: ${_windows.length}',
      );
    }
  }

  /// 更新全局状态（由主窗口调用）
  void updateState(PlayerState newState) {
    final previousState = _currentState;
    _currentState = newState;
    // debugPrint('[WindowStateManager] State updated: ${previousState.status} -> ${newState.status}');

    // 调用外部监听器
    if (_onStateChanged != null) {
      try {
        _onStateChanged!(previousState, newState);
      } catch (e) {
        debugPrint('[WindowStateManager] _onStateChanged exception: $e');
      }
    }

    // 广播状态给所有迷你窗口
    _broadcastState(newState);
  }

  /// 广播状态给所有窗口
  void _broadcastState(PlayerState state) {
    for (final entry in _windows.entries) {
      if (entry.value.type == WindowType.mini) {
        _sendStateToWindow(entry.key, state);
      }
    }
  }

  /// 发送状态到指定窗口
  void _sendStateToWindow(int windowId, [PlayerState? state]) {
    // 这个方法会被 MiniWindowManager 的跨窗口通信调用
    // 实际发送由 DesktopMultiWindow.invokeMethod 完成
    debugPrint('[WindowStateManager] Preparing state for window $windowId');
  }

  /// 发送命令到主窗口处理
  void sendCommandToMain(String method, [dynamic args]) {
    debugPrint('[WindowStateManager] Command to main: $method, args: $args');
    _commandController.add(
      WindowCommand(
        method: method,
        args: args,
        sourceWindowType: WindowType.mini,
      ),
    );
  }

  /// 订阅命令流
  Stream<WindowCommand> get commandStream => _commandController.stream;

  /// 获取主窗口 ID
  int? get mainWindowId {
    for (final entry in _windows.entries) {
      if (entry.value.type == WindowType.main) {
        return entry.key;
      }
    }
    return null;
  }

  /// 检查是否有指定窗口
  bool hasWindow(int windowId) => _windows.containsKey(windowId);

  /// 获取窗口数量
  int get windowCount => _windows.length;

  /// 打印所有窗口状态
  void debugPrintWindows() {
    debugPrint('[WindowStateManager] Registered windows:');
    for (final entry in _windows.entries) {
      debugPrint('  - Window ${entry.key}: ${entry.value.type.name}');
    }
  }

  /// 清理资源
  void dispose() {
    _windows.clear();
    _commandController.close();
    debugPrint('[WindowStateManager] Disposed');
  }
}

/// 窗口命令
class WindowCommand {
  final String method;
  final dynamic args;
  final WindowType sourceWindowType;
  final DateTime timestamp;

  WindowCommand({
    required this.method,
    this.args,
    required this.sourceWindowType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
