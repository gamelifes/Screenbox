import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

/// 窗口管理器
/// 封装 window_manager 包，提供统一的窗口操作接口
class WindowManager {
  WindowManager._internal();

  static final WindowManager _instance = WindowManager._internal();

  factory WindowManager() => _instance;

  /// 初始化窗口管理器
  Future<void> initialize() async {
    await windowManager.ensureInitialized();
  }

  /// 最小化窗口
  Future<void> minimize() async {
    await windowManager.minimize();
  }

  /// 最大化窗口
  Future<void> maximize() async {
    await windowManager.maximize();
  }

  /// 关闭窗口
  Future<void> close() async {
    await windowManager.close();
  }

  /// 检查窗口是否最大化
  Future<bool> isMaximized() async {
    return await windowManager.isMaximized();
  }

  /// 隐藏窗口（不显示在任务栏）
  Future<void> hide() async {
    await windowManager.hide();
  }

  /// 显示窗口
  Future<void> show() async {
    await windowManager.show();
    await windowManager.focus();
  }

  /// 设置窗口位置
  Future<void> setPosition(Offset offset) async {
    await windowManager.setPosition(offset);
  }

  /// 获取窗口位置
  Future<Offset> getPosition() async {
    final point = await windowManager.getPosition();
    return Offset(point.dx, point.dy);
  }

  /// 设置窗口大小
  Future<void> setSize(Size size) async {
    await windowManager.setSize(size);
  }

  /// 获取窗口大小
  Future<Size> getSize() async {
    return await windowManager.getSize();
  }

  /// 设置窗口为最小化状态
  Future<void> setMinimized(bool minimized) async {
    if (minimized) {
      await windowManager.minimize();
    } else {
      await windowManager.restore();
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await windowManager.destroy();
  }
}