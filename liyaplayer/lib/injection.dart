// LihaPlayer Riverpod Provider 容器
// 负责所有 Providers 的注册和全局访问

export 'package:riverpod/riverpod.dart';

// ============================================
// 全局 Providers 将在各 Feature 模块中定义
// ============================================

/// 播放器相关 Providers
// TODO: Phase 1 - 在 features/player/presentation/providers/ 中定义
// - playerProvider (StateNotifierProvider)
// - currentMediaProvider (Provider)
// - playlistProvider (Provider)

/// 媒体库相关 Providers
// TODO: Phase 2 - 在 features/library/presentation/providers/ 中定义
// - libraryProvider (StateNotifierProvider)
// - songsProvider (FutureProvider)
// - albumsProvider (FutureProvider)
// - artistsProvider (FutureProvider)

/// 播放列表相关 Providers
// TODO: Phase 3 - 在 features/playlist/presentation/providers/ 中定义
// - playlistsProvider (FutureProvider)
// - currentPlaylistProvider (StateNotifierProvider)

/// 设置相关 Providers
// TODO: Phase 6 - 在 features/settings/presentation/providers/ 中定义
// - themeModeProvider (StateProvider)
// - scanDirectoriesProvider (StateNotifierProvider)

/// 核心服务 Providers
// TODO: Phase 0.4 / Phase 5
// - windowManagerProvider ( Provider/Singleton)
// - systemTrayProvider ( Provider/Singleton)
// - globalShortcutsProvider ( Provider/Singleton)

// ============================================
// Providers 容器说明
// ============================================
// 本文件仅作为 Provider 注册的约定入口
// 实际每个 Feature 的 Provider 应在其 presentation/providers/ 目录下
// 通过 part 'xxx.providers.dart'; 和 part 'xxx.dart'; 组织代码
//
// 推荐结构:
// features/player/presentation/providers/player_provider.dart
//   => 导出所有 player 相关的 providers
//
// 最终在 main.dart 中使用:
//   ProviderContainer container = ProviderContainer();
//   final playerProvider = container.read(playerProvider.notifier);
// ============================================
