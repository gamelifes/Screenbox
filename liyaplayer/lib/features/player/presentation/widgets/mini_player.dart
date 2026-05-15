import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:liyaplayer/features/player/presentation/providers/player_provider.dart';
import 'package:liyaplayer/features/player/presentation/widgets/mini_player_controls.dart';

/// 底部迷你播放栏组件
///
/// 布局结构 (高度 90px):
/// ┌────────────────────────────────────────────────────────────┐
/// │ ◀━━━━━━━━━●━━━━━━━━━━━━━━━━━━━━━━━━ 1:23 / 3:45          │
/// ├────────────────────────────────────────────────────────────┤
/// │ [封面] 歌曲标题 - 艺术家    ◀◀  ▶  ▶▶   🔁 🔀 🔊  ≡    │
/// └────────────────────────────────────────────────────────────┘
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({
    super.key,
    this.onOpenMiniWindow,
    this.onVideoThumbnailTap,
    this.onMusicThumbnailTap,
  });

  /// 打开迷你窗口的回调
  final VoidCallback? onOpenMiniWindow;

  /// 视频封面点击回调（跳转到大屏播放页）
  final VoidCallback? onVideoThumbnailTap;

  /// 音乐封面点击回调（跳转到大屏音乐播放页）
  final VoidCallback? onMusicThumbnailTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final isPlaying = playerState.status == PlayerStatus.playing;
    final hasMedia = playerState.currentSongPath != null;

    // 未加载媒体时不显示
    if (!hasMedia) {
      return const SizedBox.shrink();
    }

    // 计算进度百分比
    double progress = 0.0;
    if (playerState.duration != null &&
        playerState.duration!.inMilliseconds > 0) {
      progress =
          playerState.position.inMilliseconds /
          playerState.duration!.inMilliseconds;
      progress = progress.clamp(0.0, 1.0);
    }

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // 可拖拽进度条
          _buildProgressBar(context, ref, playerState, progress),
          // 控制栏
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: Row(
                children: [
                  // 专辑封面
                  _buildAlbumCover(context, playerState),
                  // 歌曲信息
                  Expanded(child: _buildSongInfo(context, playerState)),
                  // 播放控制按钮
                  MiniPlayerControls(onOpenMiniWindow: onOpenMiniWindow),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建可拖拽进度条
  Widget _buildProgressBar(
    BuildContext context,
    WidgetRef ref,
    PlayerState playerState,
    double progress,
  ) {
    final position = playerState.position;
    final duration = playerState.duration ?? Duration.zero;

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // 当前时间
          SizedBox(
            width: 45,
            child: Text(
              _formatDuration(position),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // 进度条
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;
                final thumbPosition = progress.clamp(0.0, 1.0) * trackWidth;

                return GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (playerState.duration == null) return;
                    final ratio = (details.localPosition.dx / trackWidth).clamp(
                      0.0,
                      1.0,
                    );
                    final newPosition = Duration(
                      milliseconds:
                          (playerState.duration!.inMilliseconds * ratio)
                              .round(),
                    );
                    ref.read(playerProvider.notifier).seek(newPosition);
                  },
                  onTapDown: (details) {
                    if (playerState.duration == null) return;
                    final ratio = (details.localPosition.dx / trackWidth).clamp(
                      0.0,
                      1.0,
                    );
                    final newPosition = Duration(
                      milliseconds:
                          (playerState.duration!.inMilliseconds * ratio)
                              .round(),
                    );
                    ref.read(playerProvider.notifier).seek(newPosition);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 背景 - 灰色
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 10,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // 进度 - 主题色（使用 Container 替代 FractionallySizedBox）
                      Positioned(
                        left: 0,
                        top: 10,
                        child: Container(
                          width: thumbPosition,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // 滑块 - 白色圆形
                      Positioned(
                        left: thumbPosition - 7,
                        top: 5,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x4D000000),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // 总时长
          SizedBox(
            width: 45,
            child: Text(
              _formatDuration(duration),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建专辑封面
  Widget _buildAlbumCover(BuildContext context, PlayerState playerState) {
    // 视频模式：显示小窗口视频
    if (playerState.isVideoMode) {
      return Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.only(left: 8, right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _MiniVideoThumbnail(onTap: onVideoThumbnailTap),
      );
    }

    // 音频模式：显示专辑封面
    Widget coverContent;
    if (playerState.albumArtPath != null &&
        File(playerState.albumArtPath!).existsSync()) {
      coverContent = Image.file(
        File(playerState.albumArtPath!),
        fit: BoxFit.cover,
      );
    } else {
      coverContent = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Icon(
          Icons.music_note,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
      );
    }

    return GestureDetector(
      onTap: onMusicThumbnailTap,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.only(left: 8, right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: coverContent,
      ),
    );
  }

  /// 构建歌曲信息（带跑马灯效果）
  Widget _buildSongInfo(BuildContext context, PlayerState playerState) {
    final title = playerState.currentSongTitle ?? '未知歌曲';
    final artist = playerState.currentSongArtist ?? '未知艺术家';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 歌曲标题（跑马灯）
          _MarqueeText(
            text: title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          // 艺术家名（跑马灯）
          _MarqueeText(
            text: artist,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建播放控制按钮
  Widget _buildPlaybackControls(
    BuildContext context,
    WidgetRef ref,
    bool isPlaying,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 24,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: () {
            ref.read(playerProvider.notifier).previous();
          },
        ),
        IconButton(
          icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
          iconSize: 32,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: () {
            if (isPlaying) {
              ref.read(playerProvider.notifier).pause();
            } else {
              ref.read(playerProvider.notifier).play();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 24,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: () {
            ref.read(playerProvider.notifier).next();
          },
        ),
      ],
    );
  }

  /// 构建功能按钮 (循环/随机/音量/更多)
  Widget _buildFeatureButtons(
    BuildContext context,
    WidgetRef ref,
    PlayerState playerState,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 循环模式
        _FeatureButton(
          icon: _getLoopIcon(playerState.loopMode),
          isActive: playerState.loopMode != LoopMode.off,
          onPressed: () {
            ref.read(playerProvider.notifier).toggleLoop();
          },
          tooltip: _getLoopTooltip(playerState.loopMode),
        ),
        // 随机播放
        _FeatureButton(
          icon: Icons.shuffle,
          isActive: playerState.isShuffleOn,
          onPressed: () {
            ref.read(playerProvider.notifier).toggleShuffle();
          },
          tooltip: '随机播放',
        ),
        // 音量
        const _VolumeButton(),
        // 打开迷你窗口
        Tooltip(
          message: '迷你播放窗口',
          child: IconButton(
            icon: Icon(
              Icons.picture_in_picture_alt,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            onPressed: onOpenMiniWindow,
          ),
        ),
        // 更多
        _FeatureButton(
          icon: Icons.more_vert,
          isActive: false,
          onPressed: () {
            // TODO: 显示更多菜单
          },
          tooltip: '更多',
        ),
      ],
    );
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// 功能按钮组件
class _FeatureButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;
  final String tooltip;

  const _FeatureButton({
    required this.icon,
    required this.isActive,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        iconSize: 18,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        onPressed: onPressed,
      ),
    );
  }
}

/// 音量按钮组件
class _VolumeButton extends ConsumerStatefulWidget {
  const _VolumeButton();

  @override
  ConsumerState<_VolumeButton> createState() => _VolumeButtonState();
}

class _VolumeButtonState extends ConsumerState<_VolumeButton> {
  OverlayEntry? _overlayEntry;

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showVolumeSlider() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    final playerState = ref.read(playerProvider);
    final volume = playerState.volume;

    _overlayEntry = OverlayEntry(
      builder: (context) => _VolumeSliderPopup(
        initialVolume: volume,
        onVolumeChanged: (value) {
          ref.read(playerProvider.notifier).setVolume(value);
        },
        onDismiss: _removeOverlay,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final volume = playerState.volume;

    final icon = volume == 0
        ? Icons.volume_off
        : volume < 0.5
        ? Icons.volume_down
        : Icons.volume_up;

    return Tooltip(
      message: '音量',
      child: IconButton(
        icon: Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        onPressed: _showVolumeSlider,
      ),
    );
  }
}

/// 音量滑块悬浮面板（垂直布局）
class _VolumeSliderPopup extends StatefulWidget {
  final double initialVolume;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onDismiss;

  const _VolumeSliderPopup({
    required this.initialVolume,
    required this.onVolumeChanged,
    required this.onDismiss,
  });

  @override
  State<_VolumeSliderPopup> createState() => _VolumeSliderPopupState();
}

class _VolumeSliderPopupState extends State<_VolumeSliderPopup> {
  late double _currentVolume;

  @override
  void initState() {
    super.initState();
    _currentVolume = widget.initialVolume;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 点击外部关闭
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // 音量滑块面板
        Positioned(
          right: 50,
          bottom: 80,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 音量图标
                  Icon(
                    _currentVolume == 0
                        ? Icons.volume_off
                        : _currentVolume < 0.5
                        ? Icons.volume_down
                        : Icons.volume_up,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(height: 8),
                  // 自定义垂直滑块
                  _VerticalSlider(
                    value: _currentVolume,
                    onChanged: (value) {
                      setState(() {
                        _currentVolume = value;
                      });
                      widget.onVolumeChanged(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  // 百分比文字
                  Text(
                    '${(_currentVolume * 100).round()}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 自定义垂直滑块
class _VerticalSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _VerticalSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const double trackHeight = 120;
    const double thumbSize = 14;
    const double padding = 7; // 上下边距，确保滑块不被裁剪

    return SizedBox(
      width: 30,
      height: trackHeight + padding * 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final trackLeft = (trackWidth - 4) / 2; // 居中

          // 计算滑块位置（从下往上）
          // value=1.0 时滑块在顶部，value=0.0 时滑块在底部
          const effectiveTrackHeight = trackHeight;
          final thumbY =
              padding +
              effectiveTrackHeight -
              (value * effectiveTrackHeight) -
              (thumbSize / 2);

          return GestureDetector(
            onVerticalDragUpdate: (details) {
              // 计算新的值（从下往上）
              final localY = details.localPosition.dy - padding;
              final ratio = 1.0 - (localY / effectiveTrackHeight);
              onChanged(ratio.clamp(0.0, 1.0));
            },
            onTapDown: (details) {
              final localY = details.localPosition.dy - padding;
              final ratio = 1.0 - (localY / effectiveTrackHeight);
              onChanged(ratio.clamp(0.0, 1.0));
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 轨道背景
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
                // 进度
                Positioned(
                  left: trackLeft,
                  bottom: padding,
                  child: Container(
                    width: 4,
                    height: value * effectiveTrackHeight,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // 滑块
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
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4D000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
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

/// 跑马灯文本组件
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int scrollDurationMs;
  final int pauseDurationMs;
  final int initialDelayMs;

  const _MarqueeText({
    required this.text,
    required this.style,
    this.scrollDurationMs = 3000,
    this.pauseDurationMs = 1000,
    this.initialDelayMs = 500,
  });

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.scrollDurationMs),
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // 滚动完成，等待一段时间后重置
        if (!_isHovered) {
          Future.delayed(Duration(milliseconds: widget.pauseDurationMs), () {
            if (mounted &&
                !_isHovered &&
                _controller.status != AnimationStatus.dismissed) {
              _controller.reset();
              _controller.forward();
            }
          });
        }
      }
    });

    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 先尝试静态显示
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // 测量文本宽度
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();

        final measuredWidth = textPainter.width;

        // 如果文本不需要滚动，直接显示
        if (measuredWidth <= availableWidth ||
            availableWidth == double.infinity) {
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        // 需要跑马灯效果
        final scrollDistance = measuredWidth - availableWidth + 16;
        final currentOffset = _animation.value * scrollDistance;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: ClipRect(
            child: Transform.translate(
              offset: Offset(-currentOffset, 0),
              child: Text(widget.text, style: widget.style, maxLines: 1),
            ),
          ),
        );
      },
    );
  }
}

/// MouseDetector 组件（简化版 hover 检测）
class MouseDetector extends StatelessWidget {
  final void Function(bool enter)? onEnter;
  final void Function(bool enter)? onExit;
  final Widget child;

  const MouseDetector({
    super.key,
    this.onEnter,
    this.onExit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onEnter?.call(true),
      onExit: (_) => onExit?.call(false),
      child: child,
    );
  }
}

class _MiniVideoThumbnail extends ConsumerWidget {
  const _MiniVideoThumbnail({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(playerProvider.notifier);
    final videoController = notifier.videoController;

    if (videoController == null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.grey[800],
          child: const Icon(Icons.videocam, color: Colors.white54, size: 24),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Video(
          controller: videoController,
          controls: NoVideoControls,
        ),
      ),
    );
  }
}
