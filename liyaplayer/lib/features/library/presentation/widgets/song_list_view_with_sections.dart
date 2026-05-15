import 'package:flutter/material.dart';
import 'package:liyaplayer/features/library/data/models/models.dart';
import 'package:liyaplayer/features/library/presentation/widgets/song_list_item.dart';

/// 歌曲列表组件（按首字母分组）
class SongListViewWithSections extends StatelessWidget {
  final List<SongModel> songs;
  final String? currentlyPlayingId;
  final void Function(SongModel song) onSongTap;
  final void Function(SongModel song)? onPlayTap;

  const SongListViewWithSections({
    super.key,
    required this.songs,
    this.currentlyPlayingId,
    required this.onSongTap,
    this.onPlayTap,
  });

  /// 按首字母分组歌曲
  Map<String, List<SongModel>> _groupSongsByFirstLetter(List<SongModel> songs) {
    final Map<String, List<SongModel>> grouped = {};

    for (final song in songs) {
      final title = song.title ?? '未知';
      // 获取首字母，处理中文和其他语言
      final firstChar = _getFirstLetter(title);
      grouped.putIfAbsent(firstChar, () => []).add(song);
    }

    // 按字母排序
    final sortedKeys = grouped.keys.toList()..sort();

    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  /// 获取首字母
  /// - 英文返回大写字母
  /// - 中文返回拼音首字母（这里简化为 '#'）
  /// - 其他返回 '#'
  String _getFirstLetter(String title) {
    if (title.isEmpty) return '#';

    final firstChar = title[0].toUpperCase();
    final code = firstChar.codeUnitAt(0);

    // A-Z 范围内的直接返回
    if (code >= 65 && code <= 90) {
      return firstChar;
    }

    // 数字
    if (code >= 48 && code <= 57) {
      return '#';
    }

    // 其他字符（包括中文）归类到 #
    return '#';
  }

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const Center(child: Text('暂无歌曲'));
    }

    final groupedSongs = _groupSongsByFirstLetter(songs);
    final sections = groupedSongs.entries.toList();

    return CustomScrollView(
      slivers: [
        for (final section in sections)
          _buildSection(context, section.key, section.value),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String letter,
    List<SongModel> sectionSongs,
  ) {
    return SliverMainAxisGroup(
      slivers: [
        // 字母 header
        SliverPersistentHeader(
          pinned: true,
          delegate: _SectionHeaderDelegate(letter: letter),
        ),
        // 该字母下的歌曲列表
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final song = sectionSongs[index];
              return SongListItem(
                song: song,
                isPlaying: song.id == currentlyPlayingId,
                onTap: () => onSongTap(song),
                onPlay: onPlayTap != null ? () => onPlayTap!(song) : null,
              );
            },
            childCount: sectionSongs.length,
          ),
        ),
      ],
    );
  }
}

/// Section Header 代理
class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String letter;

  _SectionHeaderDelegate({required this.letter});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: 32,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  double get maxExtent => 32;

  @override
  double get minExtent => 32;

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) {
    return letter != oldDelegate.letter;
  }
}
