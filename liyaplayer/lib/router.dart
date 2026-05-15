// LihaPlayer GoRouter 路由配置
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/library/presentation/pages/library_page.dart';
import 'features/library/presentation/pages/video_library_page.dart';
import 'features/player/presentation/pages/player_page.dart';
import 'features/ui/pages/main_page.dart';

/// 路由名称常量
class AppRoutes {
  AppRoutes._();
  
  static const String library = '/library';
  static const String videoLibrary = '/video';
  static const String player = '/player';
  static const String playlists = '/playlists';
  static const String settings = '/settings';
  static const String titleBarTest = '/title-bar-test';
}

/// Shell route with sidebar navigation
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// 路由配置
final GoRouter router = GoRouter(
  initialLocation: AppRoutes.library,
  debugLogDiagnostics: true,
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64),
          const SizedBox(height: 16),
          Text('页面不存在: ${state.uri.path}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.library),
            child: const Text('返回音乐库'),
          ),
        ],
      ),
    ),
  ),
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainPage(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.library,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LibraryPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.videoLibrary,
          pageBuilder: (context, state) {
            final onOpenMiniWindow = state.extra as VoidCallback?;
            return NoTransitionPage(
              child: VideoLibraryPage(onOpenMiniWindow: onOpenMiniWindow),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.player,
          pageBuilder: (context, state) {
            final onOpenMiniWindow = state.extra as VoidCallback?;
            return NoTransitionPage(
              child: PlayerPage(onOpenMiniWindow: onOpenMiniWindow),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.playlists,
          pageBuilder: (context, state) => NoTransitionPage(
            child: Scaffold(
              appBar: AppBar(title: const Text('播放列表')),
              body: const Center(child: Text('播放列表功能开发中...')),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => NoTransitionPage(
            child: Scaffold(
              appBar: AppBar(title: const Text('设置')),
              body: const Center(child: Text('设置功能开发中...')),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.titleBarTest,
          pageBuilder: (context, state) => NoTransitionPage(
            child: TitleBarTestPage(),
          ),
        ),
      ],
    ),
  ],
);
