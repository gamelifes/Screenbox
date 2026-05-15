import 'package:flutter/material.dart';
import 'package:liyaplayer/features/library/data/models/models.dart';

class SongListItem extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;
  final VoidCallback? onPlay;
  final bool isPlaying;

  const SongListItem({
    super.key,
    required this.song,
    required this.onTap,
    this.onPlay,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: isPlaying
          ? const Icon(Icons.play_arrow, color: Colors.green)
          : const Icon(Icons.music_note),
      title: Text(song.title ?? '未知标题'),
      subtitle: Text('${song.artist ?? '未知艺术家'} • ${song.album ?? '未知专辑'}'),
      trailing: Text(_formatDuration(song.durationMs)),
      onTap: onTap,
    );
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
