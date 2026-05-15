import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liyaplayer/features/player/presentation/providers/player_provider.dart';

class MiniPlayerControls extends ConsumerWidget {
  const MiniPlayerControls({
    super.key,
    this.onOpenMiniWindow,
    this.isMiniWindow = false,
  });

  final VoidCallback? onOpenMiniWindow;
  final bool isMiniWindow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 512;

    final loopMode = ref.watch(playerProvider).loopMode;
    final isShuffleOn = ref.watch(playerProvider).isShuffleOn;

    // Buttons in control bar:
    // Always: loop, more
    // Non-mini window: prev/play/next
    // Large non-mini: shuffle, volume, pip
    // Small non-mini: shuffle

    final showPrevNext = !isMiniWindow;
    final showShuffle = !isMiniWindow;
    final showVolume = isLargeScreen && !isMiniWindow;
    final showPip = isLargeScreen && !isMiniWindow && onOpenMiniWindow != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (showPrevNext) ...[
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 24,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () => ref.read(playerProvider.notifier).previous(),
          ),
          Consumer(builder: (context, ref, _) {
            final isPlaying = ref.watch(playerProvider).status == PlayerStatus.playing;
            return IconButton(
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
            );
          }),
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 24,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () => ref.read(playerProvider.notifier).next(),
          ),
          const SizedBox(width: 8),
        ],
        _FeatureButton(
          icon: _getLoopIcon(loopMode),
          isActive: loopMode != LoopMode.off,
          onPressed: () => ref.read(playerProvider.notifier).toggleLoop(),
          tooltip: _getLoopTooltip(loopMode),
        ),
        if (showShuffle) ...[
          _FeatureButton(
            icon: isShuffleOn ? Icons.shuffle_on : Icons.shuffle,
            isActive: isShuffleOn,
            onPressed: () => ref.read(playerProvider.notifier).toggleShuffle(),
            tooltip: '随机播放',
          ),
        ],
        if (showVolume) ...[
          const _VolumeButton(),
        ],
        if (showPip) ...[
          _MiniWindowButton(onPressed: onOpenMiniWindow),
        ],
        _MoreButton(
          onOpenMiniWindow: onOpenMiniWindow,
          isMiniWindow: isMiniWindow,
          isLargeScreen: isLargeScreen,
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
}

class _MoreButton extends ConsumerStatefulWidget {
  const _MoreButton({
    this.onOpenMiniWindow,
    required this.isMiniWindow,
    required this.isLargeScreen,
  });

  final VoidCallback? onOpenMiniWindow;
  final bool isMiniWindow;
  final bool isLargeScreen;

  @override
  ConsumerState<_MoreButton> createState() => _MoreButtonState();
}

class _MoreButtonState extends ConsumerState<_MoreButton> {
  OverlayEntry? _overlayEntry;

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showMorePopup() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => _MorePopup(
        onDismiss: _removeOverlay,
        onOpenMiniWindow: widget.onOpenMiniWindow,
        isMiniWindow: widget.isMiniWindow,
        isLargeScreen: widget.isLargeScreen,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.more_vert),
      iconSize: 18,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      onPressed: _showMorePopup,
      tooltip: '更多',
    );
  }
}

class _MorePopup extends ConsumerWidget {
  const _MorePopup({
    required this.onDismiss,
    this.onOpenMiniWindow,
    required this.isMiniWindow,
    required this.isLargeScreen,
  });

  final VoidCallback onDismiss;
  final VoidCallback? onOpenMiniWindow;
  final bool isMiniWindow;
  final bool isLargeScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final isShuffle = state.isShuffleOn;
    final volume = state.volume;

    // Buttons in control bar (should NOT be in more panel):
    // Always: loop, more
    // Non-mini: prev/play/next
    // Large non-mini: shuffle, volume, pip
    // Small non-mini: shuffle

    // So what's left for more panel:
    // Mini window: prev/play/next, shuffle, volume, pip, properties, speed
    // Small screen: volume, pip, properties, speed
    // Large screen: properties, speed

    final showPrevNextInMore = isMiniWindow;
    final showShuffleInMore = isMiniWindow; // shuffle NOT in control bar for mini window
    final showVolumeInMore = !isLargeScreen || isMiniWindow; // volume NOT in control bar for small/mini
    final showPipInMore = !isLargeScreen || isMiniWindow; // pip NOT in control bar for small/mini

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          right: 50,
          bottom: 80,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showPrevNextInMore) ...[
                    _PanelButton(
                      icon: Icons.skip_previous,
                      label: '上一曲',
                      onPressed: () {
                        onDismiss();
                        ref.read(playerProvider.notifier).previous();
                      },
                    ),
                    const SizedBox(height: 8),
                    _PanelButton(
                      icon: Icons.skip_next,
                      label: '下一曲',
                      onPressed: () {
                        onDismiss();
                        ref.read(playerProvider.notifier).next();
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (showShuffleInMore) ...[
                    _PanelButton(
                      icon: isShuffle ? Icons.shuffle_on : Icons.shuffle,
                      label: '随机播放',
                      isActive: isShuffle,
                      onPressed: () {
                        onDismiss();
                        ref.read(playerProvider.notifier).toggleShuffle();
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (showVolumeInMore) ...[
                    _VolumePanelButton(
                      currentVolume: volume,
                      onDismiss: onDismiss,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (showPipInMore) ...[
                    _PanelButton(
                      icon: Icons.picture_in_picture_alt,
                      label: '画中画',
                      onPressed: () {
                        onDismiss();
                        onOpenMiniWindow?.call();
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  _PanelButton(
                    icon: Icons.info_outline,
                    label: '属性',
                    onPressed: () {
                      onDismiss();
                      _showInfoPopup(context, ref);
                    },
                  ),
                  const SizedBox(height: 8),
                  _PanelButton(
                    icon: Icons.speed,
                    label: '播放速率',
                    onPressed: () {
                      onDismiss();
                      _showSpeedPopup(context, ref);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
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
            right: 50,
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
    final notifier = ref.read(playerProvider.notifier);

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
                          Icon(Icons.speed, size: 18, color: Theme.of(ctx).colorScheme.onSurface),
                          const SizedBox(height: 8),
                          _MiniSpeedSlider(
                            value: sliderValue.clamp(0.0, 1.0),
                            onChanged: (value) {
                              final newSpeed = value * 1.5 + 0.5;
                              speedNotifier.value = newSpeed;
                              notifier.setSpeed(newSpeed);
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
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({
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

class _VolumePanelButton extends ConsumerWidget {
  const _VolumePanelButton({
    required this.currentVolume,
    required this.onDismiss,
  });

  final double currentVolume;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PanelButton(
      icon: Icons.volume_up,
      label: '音量',
      onPressed: () {
        onDismiss();
        _showVolumePopup(context, ref, currentVolume);
      },
    );
  }

  void _showVolumePopup(BuildContext context, WidgetRef ref, double volume) {
    OverlayEntry? volumeOverlay;

    volumeOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                volumeOverlay?.remove();
                volumeOverlay = null;
              },
              behavior: HitTestBehavior.opaque,
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
                    _VerticalSlider(
                      value: volume,
                      onChanged: (value) {
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
        ],
      ),
    );

    Overlay.of(context).insert(volumeOverlay!);
  }
}

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
    final volume = ref.watch(playerProvider).volume;

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
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
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
                  _VerticalSlider(
                    value: _currentVolume,
                    onChanged: (value) {
                      setState(() => _currentVolume = value);
                      widget.onVolumeChanged(value);
                    },
                  ),
                  const SizedBox(height: 8),
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

class _VerticalSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _VerticalSlider({required this.value, required this.onChanged});

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

class _MiniWindowButton extends StatelessWidget {
  const _MiniWindowButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '迷你播放窗口',
      child: IconButton(
        icon: const Icon(Icons.picture_in_picture_alt, size: 18),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        onPressed: onPressed,
      ),
    );
  }
}

class _FeatureButton extends StatelessWidget {
  const _FeatureButton({
    required this.icon,
    required this.isActive,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;
  final String tooltip;

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