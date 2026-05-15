// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui' show FlutterView;
import 'dart:io' show Platform, Process, File, Directory, exit;

import 'core/windows/window_models.dart';
import 'core/windows/window_state_manager.dart';
import 'core/windows/system_tray_service.dart';
import 'core/windows/window_manager.dart';
import 'features/player/presentation/providers/player_provider.dart';
import 'features/player/presentation/pages/player_page.dart';
import 'features/player/presentation/pages/music_player_page.dart';
import 'features/player/presentation/widgets/mini_player.dart';
import 'features/player/presentation/widgets/mini_player_view.dart';
import 'features/library/presentation/pages/library_page.dart';
import 'features/library/presentation/pages/video_library_page.dart';
import 'main.dart' show providerContainer;

/// 全局暴露 onShowMiniPlayer 回调的 Provider
final onShowMiniPlayerProvider = StateProvider<VoidCallback?>((ref) => null);

/// 多窗口应用
class MultiWindowApp extends StatefulWidget {
  const MultiWindowApp({super.key});

  @override
  State<MultiWindowApp> createState() => _MultiWindowAppState();
}

class _MultiWindowAppState extends State<MultiWindowApp> {
  // 窗口设置
  final WindowSettings windowSettings = WindowSettings();

  // 窗口管理器
  late final LihaWindowManager windowManager;

  // 主窗口是否可见（内容是否显示）
  // 计算属性：没有迷你窗口时显示主窗口，有迷你窗口时根据 miniPlayerVisible 决定
  bool get _mainWindowVisible => !windowManager.hasMiniPlayer || !windowManager.miniPlayerVisible;

  @override
  void initState() {
    super.initState();
    // 初始化窗口管理器
    windowManager = LihaWindowManager(
      initialWindows: <KeyedWindow>[],
    );

    // 注册主窗口
    WindowStateManager.instance.registerWindow(0, WindowType.main);

    // 监听窗口管理器变化，触发 UI 重建
    windowManager.addListener(_onWindowManagerChanged);
  }

  @override
  void dispose() {
    windowManager.removeListener(_onWindowManagerChanged);
    super.dispose();
  }

  void _onWindowManagerChanged() {
    // 当窗口管理器通知变化时，重新构建 UI
    // _mainWindowVisible 的值由 windowManager 状态计算得出
    debugPrint('[MultiWindowApp] _onWindowManagerChanged, _isHidden=${windowManager.isHidden}, hasMiniPlayer=${windowManager.hasMiniPlayer}, miniPlayerVisible=${windowManager.miniPlayerVisible}, _mainWindowVisible=$_mainWindowVisible');
    if (mounted) {
      setState(() {});
    }
  }

/// 创建新的迷你播放器窗口
  void createMiniPlayerWindow(BuildContext context) {
    debugPrint('[MultiWindowApp] createMiniPlayerWindow called, _isHidden=${windowManager.isHidden}, hasMiniPlayer=${windowManager.hasMiniPlayer}');

    final UniqueKey key = UniqueKey();

    // 创建迷你窗口控制器 - 这会创建一个新的原生窗口
    final controller = RegularWindowController(
      preferredSize: windowSettings.miniPlayerSize,
      title: '迷你播放器',
      delegate: _MiniPlayerDelegate(
        onDestroyed: () {
          debugPrint('[MultiWindowApp] delegate onDestroyed called');
        },
      ),
    );

    // 设置父窗口为主窗口（第一个 view）
    final parentView = PlatformDispatcher.instance.views.first;

    // 先标记迷你窗口为可见，再添加到列表（确保状态同步）
    windowManager.miniPlayerVisible = true;

    windowManager.add(
      KeyedWindow(
        key: key,
        controller: controller,
        parent: parentView,
        onClose: () {
          debugPrint('[MultiWindowApp] keyedWindow.onClose called');
          // 销毁 controller
          controller.destroy();
          // 从管理器移除窗口
          windowManager.remove(key);
          // 显示主窗口
          windowManager.showMainWindow();
        },
      ),
    );

    debugPrint('[MultiWindowApp] window added, total windows: ${windowManager.windows.length}');

    // 隐藏主窗口
    _hideMainWindow();
    debugPrint('[MultiWindowApp] after hideMainWindow, _isHidden=${windowManager.isHidden}, hasMiniPlayer=${windowManager.hasMiniPlayer}');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[MultiWindowApp] build called, hasMiniPlayer=${windowManager.hasMiniPlayer}, miniPlayerVisible=${windowManager.miniPlayerVisible}, _mainWindowVisible=$_mainWindowVisible');
    // 构建视图列表
    final List<Widget> views = [];

    // 主窗口直接使用默认FlutterView，不需要RegularWindow包装
    // 通过window_manager的hide/show控制原生窗口显隐
    if (_mainWindowVisible) {
      views.add(
        UncontrolledProviderScope(
          container: providerContainer,
          child: View(
            view: PlatformDispatcher.instance.views.first,
            child: _MainWindowContent(
              onShowMiniPlayer: () => createMiniPlayerWindow(context),
              windowManager: windowManager,
            ),
          ),
        ),
      );
    } else {
      // 主窗口隐藏时 - 内容为空，通过 window_manager.hide() 隐藏原生窗口
      views.add(
        UncontrolledProviderScope(
          container: providerContainer,
          child: View(
            view: PlatformDispatcher.instance.views.first,
            child: const SizedBox.shrink(),
          ),
        ),
      );
    }

    // 添加子窗口
    for (final keyedWindow in windowManager.windows) {
      if (keyedWindow.parent != null) {
        // 这是子窗口，创建新的 RegularWindow
        // 用 MaterialApp 包裹，提供 Directionality 和 Material 主题
        views.add(
          UncontrolledProviderScope(
            container: providerContainer,
            child: RegularWindow(
              key: keyedWindow.key,
              controller: keyedWindow.controller as RegularWindowController,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData.dark(),
home: Scaffold(
        body: MiniPlayerView(
          onCloseRequested: () {
            // 先显示主窗口
            windowManager.showMainWindow();
            // _mainWindowVisible 是计算属性，会在 windowManager 通知后自动重新计算
            // 不需要手动 setState
          },
          // onClose 使用 keyedWindow.onClose 回调
          onClose: keyedWindow.onClose,
        ),
      ),
              ),
            ),
          ),
        );
      }
    }

    debugPrint('[MultiWindowApp] total views: ${views.length}');

    return LihaWindowManagerAccessor(
      windowManager: windowManager,
      child: WindowSettingsAccessor(
        windowSettings: windowSettings,
        child: ViewCollection(views: views),
      ),
    );
  }

  /// 隐藏主窗口（使用 window_manager）
  void _hideMainWindow() {
    debugPrint('[MultiWindowApp] hiding main window via window_manager');
    windowManager.hideMainWindow();
}
}

/// 迷你播放器窗口委托
class _MiniPlayerDelegate extends RegularWindowControllerDelegate {
  _MiniPlayerDelegate({required this.onDestroyed});

  final VoidCallback onDestroyed;

  @override
  void onWindowCloseRequested(RegularWindowController controller) {
    onDestroyed();
    // 使用帧回调延迟执行，避免打断鼠标跟踪器状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.destroy();
    });
  }
}

/// 主窗口内容
class _MainWindowContent extends StatelessWidget {
  const _MainWindowContent({
    required this.onShowMiniPlayer,
    required this.windowManager,
  });

  final VoidCallback onShowMiniPlayer;
  final LihaWindowManager windowManager;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: _MainPageWithMiniPlayer(
        onShowMiniPlayer: onShowMiniPlayer,
        windowManager: windowManager,
      ),
    );
  }
}

/// 主页面：侧边栏 + 底部迷你播放器 + 页面内容
class _MainPageWithMiniPlayer extends ConsumerStatefulWidget {
  const _MainPageWithMiniPlayer({
    required this.onShowMiniPlayer,
    required this.windowManager,
  });

  final VoidCallback onShowMiniPlayer;
  final LihaWindowManager windowManager;

  @override
  ConsumerState<_MainPageWithMiniPlayer> createState() => _MainPageWithMiniPlayerState();
}

class _MainPageWithMiniPlayerState extends ConsumerState<_MainPageWithMiniPlayer> {
  final _stateManager = WindowStateManager.instance;
  int _selectedIndex = 0;

  void _navigateToPlayerPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerPage(onOpenMiniWindow: widget.onShowMiniPlayer)),
    );
  }

void _navigateToMusicPlayerPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MusicPlayerPage(onOpenMiniWindow: widget.onShowMiniPlayer),
      ),
    );
  }

@override
  void initState() {
    super.initState();
    _selectedIndex = _stateManager.selectedIndex;
    _stateManager.registerWindow(0, WindowType.main);
    // 延迟设置全局 Provider，等 build 阶段完成后再修改
    Future.microtask(() {
      ref.read(onShowMiniPlayerProvider.notifier).state = widget.onShowMiniPlayer;
    });
    _initSystemTray();
  }

Future<void> _initSystemTray() async {
    final playerNotifier = ref.read(playerProvider.notifier);
    await SystemTrayService.instance.initialize(
      // 点击托盘图标：toggle 窗口显示状态
      onToggleWindow: () {
        debugPrint('[SystemTray] onToggleWindow');
        if (widget.windowManager.hasMiniPlayer) {
          // 迷你窗口存在，toggle 迷你窗口
          widget.windowManager.toggleWindow();
        } else {
          // 没有迷你窗口，toggle 主窗口
          widget.windowManager.toggleMainWindow();
        }
      },
      // 右键菜单"显示/隐藏"：切换窗口显示状态
      onShowWindow: () {
        debugPrint('[SystemTray] onShowWindow');
        if (widget.windowManager.hasMiniPlayer) {
          // 有迷你窗口，根据当前状态切换显示/隐藏
          if (widget.windowManager.miniPlayerVisible) {
            widget.windowManager.hideMiniPlayerWindow();
          } else {
            widget.windowManager.showMiniPlayerWindow();
          }
        } else {
          // 没有迷你窗口，toggle 主窗口
          widget.windowManager.toggleMainWindow();
        }
      },
      onPlayPause: () {
        final state = ref.read(playerProvider);
        if (state.isPlaying) {
          playerNotifier.pause();
        } else {
          playerNotifier.play();
        }
      },
      onNext: () => playerNotifier.next(),
      onPrevious: () => playerNotifier.previous(),
      onQuit: () async {
        await SystemTrayService.instance.dispose();
        _exitApp();
      },
    );
  }

  void _exitApp() {
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 监听 PlayerProvider 变化
    ref.listen(playerProvider, (previous, next) {
      _stateManager.updateState(next);
    });

    return Scaffold(
      body: Row(
        children: [
          // 侧边栏
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
                _stateManager.setSelectedIndex(index);
              });
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Icon(
                Icons.music_note,
                size: 32,
                color: theme.colorScheme.primary,
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
          // 主内容区域 + 底部迷你播放器
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildContent()),
                // 使用 MiniPlayer 作为底部播放控制栏，不是 MiniPlayerView
                MiniPlayer(
                  onOpenMiniWindow: widget.onShowMiniPlayer,
                  onVideoThumbnailTap: _navigateToPlayerPage,
                  onMusicThumbnailTap: _navigateToMusicPlayerPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const LibraryPage();
      case 1:
        return const Center(child: Text('流媒体功能开发中...'));
      case 2:
        return const VideoLibraryPage();
      case 3:
        return const Center(child: Text('播放列表功能开发中...'));
      case 4:
        return const Center(child: Text('设置功能开发中...'));
      default:
        return const LibraryPage();
    }
  }
}
