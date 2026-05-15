import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:liyaplayer/features/player/presentation/providers/player_provider.dart';

class HiddenControlsVideoWidget extends ConsumerWidget {
  const HiddenControlsVideoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);

    if (!playerState.isVideoMode || playerState.currentVideoPath == null) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(playerProvider.notifier);
    final videoController = notifier.videoController;

    if (videoController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return _VideoWithHiddenControls(controller: videoController);
  }
}

class _VideoWithHiddenControls extends StatelessWidget {
  final VideoController controller;

  const _VideoWithHiddenControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Video(
          controller: controller,
          controls: NoVideoControls,
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
          ),
        ),
      ],
    );
  }
}