import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'router.dart';

/// 应用主入口配置
///
/// 负责:
/// - MaterialApp 配置
/// - 主题切换
/// - 路由管理
/// - 国际化 (future)
class LihaPlayerApp extends StatelessWidget {
  const LihaPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LihaPlayer',
      debugShowCheckedModeBanner: false,

      // 主题配置
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // 路由配置
      routerConfig: router,
    );
  }
}
