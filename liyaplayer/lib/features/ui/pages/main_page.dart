import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liyaplayer/core/windows/global_shortcuts.dart';
import 'package:liyaplayer/core/windows/system_tray.dart';
import 'package:liyaplayer/core/windows/window_state_manager.dart';
import 'package:liyaplayer/features/player/presentation/providers/player_provider.dart';
import 'package:liyaplayer/features/player/presentation/pages/music_player_page.dart';
import 'package:liyaplayer/features/player/presentation/widgets/mini_player.dart';
import 'package:window_manager/window_manager.dart';

/// Main page with sidebar navigation and bottom mini player
///
/// 使用 WindowStateManager 进行跨窗口状态同步。
class MainPage extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onShowMiniPlayer;

  const MainPage({super.key, required this.child, this.onShowMiniPlayer});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  final FocusNode _focusNode = FocusNode();
  final _stateManager = WindowStateManager.instance;

  @override
  void initState() {
    super.initState();
    // 注册主窗口到全局状态管理器
    _stateManager.registerWindow(0, WindowType.main);

    // 设置状态变化监听器
    _stateManager.setStateChangeListener(_onGlobalStateChanged);

    _initSystemTray();
    _initGlobalHotkeys();
  }

  /// 全局状态变化回调（由 WindowStateManager 调用）
  void _onGlobalStateChanged(PlayerState previous, PlayerState next) {
    debugPrint(
      '[main_page] ★★★ Global state changed! ${previous.status} -> ${next.status}',
    );
  }

  Future<void> _initSystemTray() async {
    final playerNotifier = ref.read(playerProvider.notifier);

    await SystemTrayService.instance.initialize(
      onShowWindow: () async {
        debugPrint('[main_page] onShowWindow called');
        await windowManager.show();
        await windowManager.focus();
      },
      onPlayPause: () => _togglePlayPause(),
      onNext: () => playerNotifier.next(),
      onPrevious: () => playerNotifier.previous(),
      onQuit: () async {
        await SystemTrayService.instance.dispose();
        exit(0);
      },
    );
  }

  void _initGlobalHotkeys() {
    globalHotkeyService.onPlayPause = () => _togglePlayPause();
    globalHotkeyService.onNext = () => ref.read(playerProvider.notifier).next();
    globalHotkeyService.onPrevious = () =>
        ref.read(playerProvider.notifier).previous();
    globalHotkeyService.onVolumeUp = _volumeUp;
    globalHotkeyService.onVolumeDown = _volumeDown;
  }

  Future<void> _togglePlayPause() async {
    debugPrint('[main_page] _togglePlayPause called');
    final playerNotifier = ref.read(playerProvider.notifier);
    final state = ref.read(playerProvider);

    debugPrint(
      '[main_page] current status: ${state.status}, isPlaying: ${state.isPlaying}, hasMedia: ${state.hasMedia}',
    );

    // 如果没有媒体，先加载
    if (!state.hasMedia && state.queue.isNotEmpty) {
      debugPrint('[main_page] No media, loading first song');
      await playerNotifier.setQueue(
        state.queue,
        state.queueIndex >= 0 ? state.queueIndex : 0,
      );
      return;
    }

    if (state.isPlaying) {
      debugPrint('[main_page] Pausing');
      await playerNotifier.pause();
    } else {
      debugPrint('[main_page] Playing');
      await playerNotifier.play();
    }
  }

  void _volumeUp() {
    // TODO: 实现音量控制
  }

  void _volumeDown() {
    // TODO: 实现音量控制
  }

  @override
  void dispose() {
    _focusNode.dispose();
    globalHotkeyService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 监听本地 PlayerProvider 变化，同步到全局状态管理器
    // 新架构下，迷你窗口直接通过 Riverpod 共享状态，无需额外同步
    ref.listen(playerProvider, (previous, next) {
      debugPrint(
        '[main_page] ★★★ Player listener: ${previous?.status} -> ${next.status}',
      );
      // 同步到全局状态管理器（用于日志和调试）
      _stateManager.updateState(next);
    });

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (globalHotkeyService.handleKeyEvent(event)) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        body: Row(
          children: [
            // Sidebar
            NavigationRail(
              selectedIndex: _getSelectedIndex(context),
              onDestinationSelected: (index) =>
                  _onDestinationSelected(context, index),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    if (widget.onShowMiniPlayer != null)
                      IconButton(
                        icon: const Icon(
                          Icons.picture_in_picture_alt,
                          size: 20,
                        ),
                        onPressed: widget.onShowMiniPlayer,
                        tooltip: '打开迷你窗口',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music),
                  label: Text('音乐库'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.podcasts_outlined),
                  selectedIcon: Icon(Icons.podcasts),
                  label: Text('流媒体'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.video_library_outlined),
                  selectedIcon: Icon(Icons.video_library),
                  label: Text('视频库'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.queue_music_outlined),
                  selectedIcon: Icon(Icons.queue_music),
                  label: Text('播放列表'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('设置'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // Main content with bottom mini player
            Expanded(
              child: Column(
                children: [
                  Expanded(child: widget.child),
                  MiniPlayer(
                    onVideoThumbnailTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerPage(
                          onOpenMiniWindow: widget.onShowMiniPlayer,
                        ),
                      ),
                    ),
                    onMusicThumbnailTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MusicPlayerPage(
                          onOpenMiniWindow: widget.onShowMiniPlayer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getSelectedIndex(BuildContext context) {
    try {
      final location = GoRouterState.of(context).uri.path;
      if (location.startsWith('/library')) return 0;
      if (location.startsWith('/streaming')) return 1;
      if (location.startsWith('/video')) return 2;
      if (location.startsWith('/playlist')) return 3;
      if (location.startsWith('/settings')) return 4;
    } catch (e) {
      // 在多窗口架构中可能没有路由上下文，使用默认值
      debugPrint('[main_page] GoRouterState not available, using default: $e');
    }
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/library');
        break;
      case 1:
        context.go('/streaming');
        break;
      case 2:
        context.go('/video');
        break;
      case 3:
        context.go('/playlists');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }
}
