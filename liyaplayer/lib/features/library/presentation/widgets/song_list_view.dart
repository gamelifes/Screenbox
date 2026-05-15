import 'package:flutter/material.dart';
import 'package:liyaplayer/features/library/data/models/models.dart';
import 'package:liyaplayer/features/library/presentation/widgets/song_list_item.dart';

class SongListView extends StatelessWidget {
  final List<SongModel> songs;
  final String? currentlyPlayingId;
  final void Function(SongModel song) onSongTap;
  final void Function(SongModel song)? onPlayTap;

  const SongListView({
    super.key,
    required this.songs,
    this.currentlyPlayingId,
    required this.onSongTap,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const Center(
        child: Text('暂无歌曲'),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return SongListItem(
          song: song,
          isPlaying: song.id == currentlyPlayingId,
          onTap: () => onSongTap(song),
          onPlay: onPlayTap != null ? () => onPlayTap!(song) : null,
        );
      },
    );
  }
}
