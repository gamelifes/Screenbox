import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'core/errors/error_handler.dart';
import 'core/services/hive_service.dart';
import 'core/windows/window_state_manager.dart';
import 'multi_window_app.dart';

// 全局 ProviderContainer，用于所有窗口共享状态
final providerContainer = ProviderContainer();

/// LihaPlayer 应用入口点
void main() async {
  // 初始化 Flutter Binding (必须在其他服务前) - 完全匹配官方示例
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 window_manager
  await windowManager.ensureInitialized();

  // 配置窗口选项
  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: Size(800, 640),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'LihaPlayer',
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  // 初始化 Hive
  await HiveService.instance.initialize();

  // 初始化 MediaKit
  MediaKit.ensureInitialized();

  // 初始化全局状态管理器
  WindowStateManager.instance.registerWindow(0, WindowType.main);

  // 使用共享的 ProviderContainer 运行多窗口应用
  runWidget(const MultiWindowApp());
}
