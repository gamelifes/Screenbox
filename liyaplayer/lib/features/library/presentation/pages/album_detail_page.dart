import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:liyaplayer/features/library/data/models/models.dart';
import 'package:liyaplayer/features/library/presentation/widgets/song_list_view.dart';

/// Album detail page showing album info and songs
class AlbumDetailPage extends StatelessWidget {
  final AlbumModel album;
  final List<SongModel> songs;
  final String? currentlyPlayingId;
  final void Function(SongModel song) onSongTap;
  final void Function(SongModel song)? onPlayTap;

  const AlbumDetailPage({
    super.key,
    required this.album,
    required this.songs,
    this.currentlyPlayingId,
    required this.onSongTap,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate total duration
    Duration totalDuration = Duration.zero;
    for (final song in songs) {
      if (song.durationMs != null && song.durationMs! > 0) {
        totalDuration += Duration(milliseconds: song.durationMs!);
      }
    }

    String formatDuration(Duration d) {
      final hours = d.inHours;
      final minutes = d.inMinutes.remainder(60);
      if (hours > 0) {
        return '$hours 小時 $minutes 分鐘';
      }
      return '$minutes 分鐘';
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with album art
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                album.name ?? '未知專輯',
                style: const TextStyle(
                  shadows: [Shadow(blurRadius: 4)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
                child: album.artwork != null && album.artwork!.isNotEmpty
                    ? Image.memory(
                        Uint8List.fromList(album.artwork!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
                      )
                    : _buildPlaceholder(theme),
              ),
            ),
          ),
          // Album info header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name ?? '未知專輯',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${album.artist ?? '未知藝術家'} • ${album.year ?? ""}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${songs.length} 首歌 • ${formatDuration(totalDuration)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Play all button
                  FilledButton.icon(
                    onPressed: songs.isNotEmpty
                        ? () {
                            if (songs.isNotEmpty) {
                              onPlayTap?.call(songs.first);
                            }
                          }
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('播放全部'),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          // Songs list
          SliverFillRemaining(
            child: songs.isEmpty
                ? const Center(child: Text('暫無歌曲'))
                : SongListView(
                    songs: songs,
                    currentlyPlayingId: currentlyPlayingId,
                    onSongTap: onSongTap,
                    onPlayTap: onPlayTap,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.album,
        size: 120,
        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
      ),
    );
  }
}
