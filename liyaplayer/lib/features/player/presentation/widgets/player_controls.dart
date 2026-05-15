import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liyaplayer/features/player/presentation/providers/player_provider.dart';

/// 播放器控制按钮组件
class PlayerControls extends ConsumerWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final isPlaying = playerState.status == PlayerStatus.playing;
    final isLoading = playerState.status == PlayerStatus.loading;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 上一曲
        IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 32,
          onPressed: () {
            ref.read(playerProvider.notifier).previous();
          },
        ),
        const SizedBox(width: 16),

        // 播放/暂停按钮
        isLoading
            ? const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                iconSize: 48,
                onPressed: () {
                  if (isPlaying) {
                    ref.read(playerProvider.notifier).pause();
                  } else {
                    ref.read(playerProvider.notifier).play();
                  }
                },
              ),
        const SizedBox(width: 16),

        // 下一曲
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 32,
          onPressed: () {
            ref.read(playerProvider.notifier).next();
          },
        ),

        const SizedBox(width: 32),

        // 停止按钮
        IconButton(
          icon: const Icon(Icons.stop),
          iconSize: 32,
          onPressed: () {
            ref.read(playerProvider.notifier).stop();
          },
        ),
      ],
    );
  }
}
