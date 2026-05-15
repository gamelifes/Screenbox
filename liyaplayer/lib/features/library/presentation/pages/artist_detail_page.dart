import 'package:flutter/material.dart';
import 'package:liyaplayer/features/library/data/models/models.dart';
import 'package:liyaplayer/features/library/presentation/widgets/album_grid_view.dart';
import 'package:liyaplayer/features/library/presentation/widgets/song_list_view.dart';

/// Artist detail page showing songs and albums
class ArtistDetailPage extends StatelessWidget {
  final ArtistModel artist;
  final List<SongModel> songs;
  final List<AlbumModel> albums;
  final String? currentlyPlayingId;
  final void Function(SongModel song) onSongTap;
  final void Function(SongModel song)? onPlayTap;
  final void Function(AlbumModel album) onAlbumTap;

  const ArtistDetailPage({
    super.key,
    required this.artist,
    required this.songs,
    required this.albums,
    this.currentlyPlayingId,
    required this.onSongTap,
    this.onPlayTap,
    required this.onAlbumTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(artist.name ?? '未知艺术家'),
          bottom: TabBar(
            tabs: [
              Tab(text: '歌曲 (${songs.length})'),
              Tab(text: '专辑 (${albums.length})'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Artist header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      (artist.name?.isNotEmpty == true)
                          ? artist.name![0].toUpperCase()
                          : '?',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artist.name ?? '未知艺术家',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${songs.length} 首歌 • ${albums.length} 张专辑',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Tab views
            Expanded(
              child: TabBarView(
                children: [
                  // Songs tab
                  SongListView(
                    songs: songs,
                    currentlyPlayingId: currentlyPlayingId,
                    onSongTap: onSongTap,
                    onPlayTap: onPlayTap,
                  ),
                  // Albums tab
                  albums.isEmpty
                      ? const Center(child: Text('暂无专辑'))
                      : AlbumGridView(
                          albums: albums,
                          onAlbumTap: onAlbumTap,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
