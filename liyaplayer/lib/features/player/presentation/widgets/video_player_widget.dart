import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:liyaplayer/features/player/presentation/providers/player_provider.dart';

class VideoPlayerWidget extends ConsumerWidget {
  const VideoPlayerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);

    if (!playerState.isVideoMode || playerState.currentVideoPath == null) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(playerProvider.notifier);
    final videoController = notifier.videoController;

    if (videoController == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Video(
        controller: videoController,
        fill: Colors.black,
      ),
    );
  }
}