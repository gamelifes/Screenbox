import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liyaplayer/features/player/presentation/providers/player_provider.dart';
import 'package:liyaplayer/features/player/presentation/widgets/blurred_cover_background.dart';
import 'package:liyaplayer/features/player/presentation/widgets/mini_player_controls.dart';

class MusicPlayerPage extends ConsumerWidget {
  const MusicPlayerPage({super.key, this.onOpenMiniWindow});

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

    return Scaffold(
      body: BlurredCoverBackground(
        albumArtPath: playerState.albumArtPath,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, playerState),
              Expanded(child: _buildCoverArea(context, playerState)),
              _buildProgressBar(context, ref, playerState, progress),
              MiniPlayerControls(onOpenMiniWindow: onOpenMiniWindow),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, PlayerState playerState) {
    final title = playerState.currentSongTitle ?? '未知歌曲';
    final artist = playerState.currentSongArtist ?? '未知艺术家';

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  artist,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
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
              style: const TextStyle(color: Colors.white70, fontSize: 12),
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
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverArea(BuildContext context, PlayerState playerState) {
    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: playerState.albumArtPath != null &&
                File(playerState.albumArtPath!).existsSync()
            ? Image.file(
                File(playerState.albumArtPath!),
                fit: BoxFit.cover,
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.music_note,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}