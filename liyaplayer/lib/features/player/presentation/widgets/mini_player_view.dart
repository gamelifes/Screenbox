import 'dart:ffi' hide Size;
import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:ffi/ffi.dart' as ffi_alloc;
import 'package:win32/win32.dart';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' show AnimatedBuilder;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:liyaplayer/features/player/presentation/providers/player_provider.dart';
import 'package:liyaplayer/core/windows/window_styler.dart';

/// 浮动迷你播放器视图
///
/// 用于独立窗口中显示的播放器。
/// 状态直接通过 Riverpod 共享（单引擎架构）。
///
/// 布局 (512x512):
/// ```
/// ┌────────────────────────────────────┐
/// │ Song Title - Artist      [↗ Close] │
/// ├────────────────────────────────────┤
/// │ 0:00 ═══════════●══════════ 3:45   │
/// ├────────────────────────────────────┤
///                                    │
///         ┌──────────┐               │
///         │  Cover   │               │
///         └──────────╯               │
///                                    │
/// ├────────────────────────────────────┤
/// │  ◀◀  ▶/❚❚  ▶▶    🔁 🔀 ☰        │
/// └────────────────────────────────────┘
/// ```
class MiniPlayerView extends ConsumerStatefulWidget {
  const MiniPlayerView({
    super.key,
    this.onClose,
    this.onCloseRequested,
  });

  final VoidCallback? onClose;
  /// 在窗口关闭前调用，用于通知主窗口显示
  final VoidCallback? onCloseRequested;

  @override
  ConsumerState<MiniPlayerView> createState() => _MiniPlayerViewState();
}

class _MiniPlayerViewState extends ConsumerState<MiniPlayerView> with TickerProviderStateMixin {
  bool _borderlessApplied = false;
  final WindowStyler _windowStyler = WindowStyler();

  // 拖动相关变量
  int? _dragStartX;
  int? _dragStartY;
  int? _windowStartX;
  int? _windowStartY;
  int? _windowHandle; // 缓存窗口句柄，避免重复查找

  // 上一次是否是视频模式，用于检测模式切换
  bool _wasVideoMode = false;

  // UI 自动隐藏相关
  bool _uiVisible = true;
  Timer? _hideTimer;
  static const _hideDelay = Duration(seconds: 5);

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (!_uiVisible) {
      setState(() => _uiVisible = true);
    }
    _hideTimer = Timer(_hideDelay, () {
      if (mounted) {
        setState(() => _uiVisible = false);
      }
    });
  }

  void _pauseHideTimer() {
    _hideTimer?.cancel();
  }

  void _resumeHideTimer() {
    if (_uiVisible && mounted) {
      _hideTimer = Timer(_hideDelay, () {
        if (mounted) {
          setState(() => _uiVisible = false);
        }
      });
    }
  }

  void _toggleUi() {
    setState(() => _uiVisible = !_uiVisible);
    if (_uiVisible) {
      _resetHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }


   @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final isPlaying = playerState.status == PlayerStatus.playing;
    final hasMedia = playerState.currentSongPath != null;
    final isVideoMode = playerState.isVideoMode;

    // 检测模式切换：进入视频模式时启动隐藏计时器
    if (isVideoMode && !_wasVideoMode) {
      _wasVideoMode = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resetHideTimer();
      });
    } else if (!isVideoMode) {
      _wasVideoMode = false;
    }

// 在窗口首次显示后，将原生窗口改为无边框样式
  // 使用延迟执行避免在 draw frame 阶段调用 Win32 API
  if (!_borderlessApplied) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_borderlessApplied) return;
      _borderlessApplied = true;
      // 延迟执行，等待 Flutter 调度器进入 idle 状态
      Future.delayed(const Duration(milliseconds: 100), () {
        WindowStyler().setWindowBorderless('迷你播放器');
      });
    });
  }

    // 未加载媒体时显示占位
    if (!hasMedia) {
      return Container(
        color: const Color(0xFF1E1E1E),
        child: const Center(
          child: Text(
            '未播放任何内容',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    // 视频模式：全屏视频 + 自动隐藏 UI
    if (isVideoMode) {
      return _buildVideoMode(playerState);
    }

    // 音频模式：原有逻辑
    return _buildAudioMode(playerState, isPlaying);
  }

  Widget _buildVideoMode(PlayerState playerState) {
    final notifier = ref.read(playerProvider.notifier);
    final videoController = notifier.videoController;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 视频渲染 - 点击空白区域切换 UI
          GestureDetector(
            onTap: _toggleUi,
            behavior: HitTestBehavior.translucent,
            child: videoController != null
                ? Video(
                    controller: videoController,
                    controls: NoVideoControls,
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),
          // UI 层 - translucent 不消耗事件，让子 widget 可以响应
          if (_uiVisible)
            Positioned.fill(
              child: Column(
                children: [
                  _buildTopBar(context, playerState),
                  const Spacer(),
                  // 进度条（靠近控制栏）
                  _buildVideoProgressBar(playerState),
                  _buildVideoControlBar(playerState),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoProgressBar(PlayerState playerState) {
    double progress = 0.0;
    if (playerState.duration != null &&
        playerState.duration!.inMilliseconds > 0) {
      progress = playerState.position.inMilliseconds /
          playerState.duration!.inMilliseconds;
      progress = progress.clamp(0.0, 1.0);
    }
    final position = playerState.position;
    final duration = playerState.duration ?? Duration.zero;

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              _formatDuration(position),
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: const SliderThemeData(
                trackHeight: 4,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Colors.blue,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: progress,
                onChanged: (value) {
                  if (playerState.duration != null) {
                    final newPosition = Duration(
                      milliseconds:
                          (playerState.duration!.inMilliseconds * value)
                              .round(),
                    );
                    ref.read(playerProvider.notifier).seek(newPosition);
                  }
                },
              ),
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              _formatDuration(duration),
              style: const TextStyle(fontSize: 10, color: Colors.white70),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControlBar(PlayerState playerState) {
    final isPlaying = playerState.status == PlayerStatus.playing;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 32),
            onPressed: () => ref.read(playerProvider.notifier).previous(),
          ),
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: Colors.white,
              size: 48,
            ),
            onPressed: () {
              if (isPlaying) {
                ref.read(playerProvider.notifier).pause();
              } else {
                ref.read(playerProvider.notifier).play();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 32),
            onPressed: () => ref.read(playerProvider.notifier).next(),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioMode(PlayerState playerState, bool isPlaying) {
    // 计算进度
    double progress = 0.0;
    if (playerState.duration != null &&
        playerState.duration!.inMilliseconds > 0) {
      progress = playerState.position.inMilliseconds /
          playerState.duration!.inMilliseconds;
      progress = progress.clamp(0.0, 1.0);
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1E1E1E),
      child: Stack(
      // 不设置 fit: StackFit.expand，由子元素自行约束
      children: [
        // 1. 模糊背景
        if (playerState.albumArtPath != null &&
            File(playerState.albumArtPath!).existsSync())
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Image.file(
              File(playerState.albumArtPath!),
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
            ),
          ),
// 2. 玻璃态叠加层
Container(color: Colors.black.withValues(alpha: 0.4)),
// 3. 内容 - 用Positioned.fill约束高度
      Positioned.fill(
        child: Column(
          children: [
            _buildTopBar(context, playerState),
            _buildProgressBar(context, ref, playerState, progress),
            Expanded(child: _buildCoverArea(context, playerState)),
            _buildControlBar(context, ref, playerState, isPlaying),
          ],
        ),
            ),
          ],
        ),
      );
    }

/// 顶部栏（支持拖动、最小化、返回主窗口）
/// 布局设计：
/// ┌─────────────────────────────────────────────────┐
/// │ [12px padding] 歌曲标题 - 歌手     [─] [↗]     │
/// │                 （可拖动区域覆盖整行）           │
/// └─────────────────────────────────────────────────┐
/// 按钮区域固定在右侧，文本区域在按钮左侧自动截断
Widget _buildTopBar(BuildContext context, PlayerState playerState) {
    final titleText =
        '${playerState.currentSongTitle ?? ''} - ${playerState.currentSongArtist ?? ''}';
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    );

    return SizedBox(
      height: 50,
      child: Stack(
        children: [
          // 左侧：可拖动的标题文本区域
          Positioned(
            left: 12,
            right: 100, // 为右侧按钮留出空间
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onPanStart: (details) async {
                _pauseHideTimer();
                final titlePtr = '迷你播放器'.toNativeUtf16(allocator: ffi_alloc.calloc);
                final hwnd = FindWindow(nullptr, titlePtr);
                ffi_alloc.calloc.free(titlePtr);

                if (hwnd != 0) {
                  _windowHandle = hwnd;
                  final point = ffi_alloc.calloc<POINT>();
                  GetCursorPos(point);
                  _dragStartX = point.ref.x;
                  _dragStartY = point.ref.y;
                  ffi_alloc.calloc.free(point);

                  final rect = ffi_alloc.calloc<RECT>();
                  GetWindowRect(_windowHandle!, rect);
                  _windowStartX = rect.ref.left;
                  _windowStartY = rect.ref.top;
                  ffi_alloc.calloc.free(rect);
                }
              },
              onPanUpdate: (details) {
                if (_dragStartX != null && _dragStartY != null && _windowHandle != null && _windowHandle != 0) {
                  final point = ffi_alloc.calloc<POINT>();
                  GetCursorPos(point);
                  final dx = point.ref.x - _dragStartX!;
                  final dy = point.ref.y - _dragStartY!;
                  final newX = _windowStartX! + dx;
                  final newY = _windowStartY! + dy;
                  SetWindowPos(_windowHandle!, 0, newX, newY, 0, 0, SWP_NOSIZE | SWP_NOZORDER);
                  ffi_alloc.calloc.free(point);
                }
              },
              onPanEnd: (_) {
                _dragStartX = null;
                _dragStartY = null;
                _windowStartX = null;
                _windowStartY = null;
                _resumeHideTimer();
              },
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final textPainter = TextPainter(
                      text: TextSpan(text: titleText, style: textStyle),
                      textDirection: TextDirection.ltr,
                    );
                    textPainter.layout();
                    final textWidth = textPainter.width;

                    // 仅在需要时显示Tooltip
                    if (textWidth > availableWidth) {
                      return Tooltip(
                        message: titleText,
                        child: SizedBox(
                          width: availableWidth,
                          child: Text(
                            titleText,
                            style: textStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    } else {
                      return SizedBox(
                        width: availableWidth,
                        child: Text(
                          titleText,
                          style: textStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          // 右侧：窗口控制按钮
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 最小化按钮
                  IconButton(
                    icon: const Icon(Icons.minimize, color: Colors.white),
                    onPressed: () {
                      final hwnd = FindWindow(nullptr, '迷你播放器'.toNativeUtf16(allocator: ffi_alloc.calloc));
                      if (hwnd != 0) {
                        ShowWindow(hwnd, SW_MINIMIZE);
                      }
                    },
                  ),
                  // 返回主窗口按钮
                  IconButton(
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                    onPressed: () {
                      widget.onCloseRequested?.call();
                      widget.onClose?.call();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 进度条
  Widget _buildProgressBar(
      BuildContext context, WidgetRef ref, PlayerState playerState, double progress) {
    final position = playerState.position;
    final duration = playerState.duration ?? Duration.zero;

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              _formatDuration(position),
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: const SliderThemeData(
                trackHeight: 4,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Colors.blue,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: progress,
                onChanged: (value) {
                  if (playerState.duration != null) {
                    final newPosition = Duration(
                      milliseconds:
                          (playerState.duration!.inMilliseconds * value)
                              .round(),
                    );
                    ref.read(playerProvider.notifier).seek(newPosition);
                  }
                },
              ),
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              _formatDuration(duration),
              style: const TextStyle(fontSize: 10, color: Colors.white70),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// 封面区域
  Widget _buildCoverArea(BuildContext context, PlayerState playerState) {
    return Center(
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: playerState.albumArtPath != null &&
                  File(playerState.albumArtPath!).existsSync()
              ? Image.file(
                  File(playerState.albumArtPath!),
                  fit: BoxFit.cover,
                )
              : Container(
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.music_note,
                    size: 80,
                    color: Colors.white54,
                  ),
                ),
        ),
      ),
    );
  }

  /// 控制栏
  Widget _buildControlBar(BuildContext context, WidgetRef ref, PlayerState playerState, bool isPlaying) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 播放控制
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                onPressed: () => ref.read(playerProvider.notifier).previous(),
              ),
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle : Icons.play_circle,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: () {
                  if (isPlaying) {
                    ref.read(playerProvider.notifier).pause();
                  } else {
                    ref.read(playerProvider.notifier).play();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: () => ref.read(playerProvider.notifier).next(),
              ),
            ],
          ),
          // 功能按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  playerState.loopMode == LoopMode.one
                      ? Icons.repeat_one
                      : Icons.repeat,
                  color: playerState.loopMode != LoopMode.off
                      ? Colors.blue
                      : Colors.white,
                ),
                onPressed: () => ref.read(playerProvider.notifier).toggleLoop(),
              ),
              IconButton(
                icon: Icon(
                  Icons.shuffle,
                  color: playerState.isShuffleOn ? Colors.blue : Colors.white,
                ),
                onPressed: () =>
                    ref.read(playerProvider.notifier).toggleShuffle(),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () => _showMorePanel(context, ref, playerState),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMorePanel(BuildContext context, WidgetRef ref, PlayerState playerState) {
    final isShuffle = playerState.isShuffleOn;
    final currentLoopMode = playerState.loopMode;
    final volume = playerState.volume;

    OverlayEntry? overlayEntry;

    void dismiss() {
      overlayEntry?.remove();
      overlayEntry = null;
    }

    overlayEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: dismiss,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            right: 50,
            bottom: 80,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MiniMoreButton(
                      icon: Icons.shuffle,
                      label: '随机播放',
                      isActive: isShuffle,
                      onPressed: () {
                        dismiss();
                        ref.read(playerProvider.notifier).toggleShuffle();
                      },
                    ),
                    const SizedBox(height: 8),
                    _MiniMoreButton(
                      icon: _getLoopIcon(currentLoopMode),
                      label: _getLoopTooltip(currentLoopMode),
                      isActive: currentLoopMode != LoopMode.off,
                      onPressed: () {
                        dismiss();
                        ref.read(playerProvider.notifier).toggleLoop();
                      },
                    ),
                    const SizedBox(height: 8),
                    _MiniMoreButton(
                      icon: Icons.volume_up,
                      label: '音量',
                      onPressed: () {
                        dismiss();
                        _showVolumePopup(ctx, ref, volume);
                      },
                    ),
                    const SizedBox(height: 8),
                    _MiniMoreButton(
                      icon: Icons.info_outline,
                      label: '属性',
                      onPressed: () {
                        dismiss();
                        _showInfoPopup(ctx, ref);
                      },
                    ),
                    const SizedBox(height: 8),
                    _MiniMoreButton(
                      icon: Icons.speed,
                      label: '播放速率',
                      onPressed: () {
                        dismiss();
                        _showSpeedPopup(ctx, ref);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(overlayEntry!);
  }

  IconData _getLoopIcon(LoopMode mode) {
    return switch (mode) {
      LoopMode.off => Icons.repeat,
      LoopMode.all => Icons.repeat,
      LoopMode.one => Icons.repeat_one,
    };
  }

  String _getLoopTooltip(LoopMode mode) {
    return switch (mode) {
      LoopMode.off => '关闭循环',
      LoopMode.all => '列表循环',
      LoopMode.one => '单曲循环',
    };
  }

  void _showVolumePopup(BuildContext context, WidgetRef ref, double currentVolume) {
    final volumeNotifier = ValueNotifier<double>(currentVolume);
    OverlayEntry? volumeOverlay;

    volumeOverlay = OverlayEntry(
      builder: (ctx) => ValueListenableBuilder<double>(
        valueListenable: volumeNotifier,
        builder: (ctx, volume, _) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  volumeOverlay?.remove();
                  volumeOverlay = null;
                },
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              right: 50,
              bottom: 80,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  child: Container(
                    width: 50,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          volume == 0
                              ? Icons.volume_off
                              : volume < 0.5
                                  ? Icons.volume_down
                                  : Icons.volume_up,
                          size: 18,
                          color: Theme.of(ctx).colorScheme.onSurface,
                        ),
                        const SizedBox(height: 8),
                        _MiniVolumeSlider(
                          value: volume,
                          onChanged: (value) {
                            volumeNotifier.value = value;
                            ref.read(playerProvider.notifier).setVolume(value);
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(volume * 100).round()}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    volumeNotifier.addListener(() {
      volumeOverlay?.markNeedsBuild();
    });

    Overlay.of(context).insert(volumeOverlay!);
  }

  void _showInfoPopup(BuildContext context, WidgetRef ref) {
    final playerState = ref.read(playerProvider);

    final path = playerState.currentSongPath ?? '未知';
    final name = playerState.currentSongTitle ?? '未知歌曲';

    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                overlayEntry?.remove();
                overlayEntry = null;
              },
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            right: 100,
            bottom: 80,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: '文件名称', value: name),
                    const SizedBox(height: 8),
                    _InfoRow(label: '文件地址', value: path),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(overlayEntry!);
  }

  void _showSpeedPopup(BuildContext context, WidgetRef ref) {
    final playerState = ref.read(playerProvider);
    final currentSpeed = playerState.speed;

    final speedNotifier = ValueNotifier<double>(currentSpeed);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (ctx) => ValueListenableBuilder<double>(
        valueListenable: speedNotifier,
        builder: (ctx, speed, _) {
          final sliderValue = (speed - 0.5) / 1.5;
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    overlayEntry?.remove();
                    overlayEntry = null;
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
              ),
              Positioned(
                right: 100,
                bottom: 80,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    child: Container(
                      width: 50,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.speed, size: 18, color: Theme.of(ctx).colorScheme.onSurface),
                          const SizedBox(height: 8),
                          _MiniSpeedSlider(
                            value: sliderValue.clamp(0.0, 1.0),
                            onChanged: (value) {
                              final newSpeed = value * 1.5 + 0.5;
                              speedNotifier.value = newSpeed;
                              ref.read(playerProvider.notifier).setSpeed(newSpeed);
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${speed.toStringAsFixed(1)}x',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    speedNotifier.addListener(() {
      overlayEntry?.markNeedsBuild();
    });

    Overlay.of(context).insert(overlayEntry!);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _MiniMoreButton extends StatelessWidget {
  const _MiniMoreButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniVolumeSlider extends StatelessWidget {
  const _MiniVolumeSlider({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    const double trackHeight = 120;
    const double thumbSize = 14;
    const double padding = 7;

    return SizedBox(
      width: 30,
      height: trackHeight + padding * 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final trackLeft = (trackWidth - 4) / 2;
          final thumbY = padding + trackHeight - (value * trackHeight) - (thumbSize / 2);

          return GestureDetector(
            onVerticalDragUpdate: (details) {
              final localY = details.localPosition.dy - padding;
              final ratio = 1.0 - (localY / trackHeight);
              onChanged(ratio.clamp(0.0, 1.0));
            },
            onTapDown: (details) {
              final localY = details.localPosition.dy - padding;
              final ratio = 1.0 - (localY / trackHeight);
              onChanged(ratio.clamp(0.0, 1.0));
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: trackLeft,
                  top: padding,
                  bottom: padding,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  left: trackLeft,
                  bottom: padding,
                  child: Container(
                    width: 4,
                    height: value * trackHeight,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  left: trackLeft - (thumbSize - 4) / 2,
                  top: thumbY,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MiniSpeedSlider extends StatelessWidget {
  const _MiniSpeedSlider({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    const double trackHeight = 120;
    const double thumbSize = 14;
    const double padding = 7;

    return SizedBox(
      width: 30,
      height: trackHeight + padding * 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final trackLeft = (trackWidth - 4) / 2;
          final thumbY = padding + trackHeight - (value * trackHeight) - (thumbSize / 2);

          return GestureDetector(
            onVerticalDragUpdate: (details) {
              final localY = details.localPosition.dy - padding;
              final ratio = 1.0 - (localY / trackHeight);
              onChanged(ratio.clamp(0.0, 1.0));
            },
            onTapDown: (details) {
              final localY = details.localPosition.dy - padding;
              final ratio = 1.0 - (localY / trackHeight);
              onChanged(ratio.clamp(0.0, 1.0));
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: trackLeft,
                  top: padding,
                  bottom: padding,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  left: trackLeft,
                  bottom: padding,
                  child: Container(
                    width: 4,
                    height: value * trackHeight,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  left: trackLeft - (thumbSize - 4) / 2,
                  top: thumbY,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
