import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liyaplayer/features/player/presentation/widgets/player_controls.dart';
import 'package:liyaplayer/features/player/presentation/widgets/hidden_controls_video_widget.dart';
import 'package:liyaplayer/features/player/presentation/widgets/mini_player_controls.dart';
import 'package:liyaplayer/features/player/presentation/providers/player_provider.dart';

class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key, this.onOpenMiniWindow});

  final VoidCallback? onOpenMiniWindow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final isVideoMode = playerState.isVideoMode;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isVideoMode
              ? (playerState.currentSongTitle ?? '视频播放')
              : '音频播放',
        ),
        centerTitle: true,
        actions: [
          if (isVideoMode)
            IconButton(
              icon: const Icon(Icons.audiotrack),
              onPressed: () {
                ref.read(playerProvider.notifier).switchToAudioMode();
              },
              tooltip: '切换到音频模式',
            ),
        ],
      ),
      body: isVideoMode ? _VideoPlayerView(onOpenMiniWindow: onOpenMiniWindow) : const _AudioPlayerView(),
    );
  }
}

class _VideoPlayerView extends ConsumerWidget {
  const _VideoPlayerView({this.onOpenMiniWindow});

  final VoidCallback? onOpenMiniWindow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);

    double progress = 0.0;
    if (playerState.duration != null &&
        playerState.duration!.inMilliseconds > 0) {
      progress = playerState.position.inMilliseconds /
          playerState.duration!.inMilliseconds;
      progress = progress.clamp(0.0, 1.0);
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: const HiddenControlsVideoWidget(),
              ),
            ),
          ),
        ),
        _buildProgressBar(context, ref, playerState, progress),
        MiniPlayerControls(onOpenMiniWindow: onOpenMiniWindow),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    WidgetRef ref,
    PlayerState playerState,
    double progress,
  ) {
    final position = playerState.position;
    final duration = playerState.duration ?? Duration.zero;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              _formatDuration(position),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: progress,
                onChanged: (value) {
                  if (playerState.duration != null) {
                    final newPosition = Duration(
                      milliseconds:
                          (playerState.duration!.inMilliseconds * value).round(),
                    );
                    ref.read(playerProvider.notifier).seek(newPosition);
                  }
                },
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              _formatDuration(duration),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _AudioPlayerView extends ConsumerWidget {
  const _AudioPlayerView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatusDisplay(playerState),
          const SizedBox(height: 32),
          const PlayerControls(),
          const SizedBox(height: 24),
          _buildProgressInfo(playerState),
        ],
      ),
    );
  }

  Widget _buildStatusDisplay(PlayerState state) {
    String statusText;
    Color statusColor;

    switch (state.status) {
      case PlayerStatus.idle:
        statusText = '就绪';
        statusColor = Colors.grey;
      case PlayerStatus.loading:
        statusText = '加载中...';
        statusColor = Colors.orange;
      case PlayerStatus.playing:
        statusText = '播放中';
        statusColor = Colors.green;
      case PlayerStatus.paused:
        statusText = '已暂停';
        statusColor = Colors.blue;
      case PlayerStatus.stopped:
        statusText = '已停止';
        statusColor = Colors.grey;
      case PlayerStatus.error:
        statusText = '错误: ${state.errorMessage ?? "未知错误"}';
        statusColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildProgressInfo(PlayerState state) {
    final position = _formatDuration(state.position);
    final duration =
        state.duration != null ? _formatDuration(state.duration!) : '--:--';

    return Text(
      '$position / $duration',
      style: const TextStyle(fontSize: 16, color: Colors.grey),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}