import 'package:flutter/services.dart';

/// 全局热键服务
///
/// 提供播放控制快捷键：
/// - Space: 播放/暂停
/// - Ctrl+Right: 下一曲
/// - Ctrl+Left: 上一曲
/// - Ctrl+Up: 音量+
/// - Ctrl+Down: 音量-
///
/// 注：当前为本地快捷键实现，全局热键需要额外配置
class GlobalHotkeyService {
  static final GlobalHotkeyService _instance = GlobalHotkeyService._internal();
  factory GlobalHotkeyService() => _instance;
  GlobalHotkeyService._internal();

  bool _isInitialized = false;

  /// 快捷键回调类型
  void Function()? onPlayPause;
  void Function()? onNext;
  void Function()? onPrevious;
  void Function()? onVolumeUp;
  void Function()? onVolumeDown;

  /// 初始化热键服务
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// 处理快捷键事件
  ///
  /// 在 Widget 的 KeyEventHandler 中调用此方法
  bool handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isControlPressed = HardwareKeyboard.instance.isControlPressed;

    // Space: 播放/暂停
    if (event.logicalKey == LogicalKeyboardKey.space && !isControlPressed) {
      onPlayPause?.call();
      return true;
    }

    // Ctrl+Right: 下一曲
    if (event.logicalKey == LogicalKeyboardKey.arrowRight && isControlPressed) {
      onNext?.call();
      return true;
    }

    // Ctrl+Left: 上一曲
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft && isControlPressed) {
      onPrevious?.call();
      return true;
    }

    // Ctrl+Up: 音量+
    if (event.logicalKey == LogicalKeyboardKey.arrowUp && isControlPressed) {
      onVolumeUp?.call();
      return true;
    }

    // Ctrl+Down: 音量-
    if (event.logicalKey == LogicalKeyboardKey.arrowDown && isControlPressed) {
      onVolumeDown?.call();
      return true;
    }

    return false;
  }

  /// 释放资源
  Future<void> dispose() async {
    onPlayPause = null;
    onNext = null;
    onPrevious = null;
    onVolumeUp = null;
    onVolumeDown = null;
    _isInitialized = false;
  }
}

/// 全局热键服务单例
final globalHotkeyService = GlobalHotkeyService();
