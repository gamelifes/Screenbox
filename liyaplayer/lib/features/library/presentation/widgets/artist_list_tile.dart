import 'package:flutter/material.dart';
import 'package:liyaplayer/features/library/data/models/models.dart';

class ArtistListTile extends StatelessWidget {
  final ArtistModel artist;
  final VoidCallback onTap;

  const ArtistListTile({
    super.key,
    required this.artist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          (artist.name ?? '未知')[0].toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(artist.name ?? '未知艺术家'),
      subtitle:
          Text('${artist.songCount ?? 0} 首歌曲 • ${artist.albumCount ?? 0} 张专辑'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
