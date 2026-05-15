import 'package:flutter/material.dart';
import 'package:liyaplayer/features/library/data/models/models.dart';
import 'package:liyaplayer/features/library/presentation/widgets/artist_list_tile.dart';

class ArtistListView extends StatelessWidget {
  final List<ArtistModel> artists;
  final void Function(ArtistModel artist) onArtistTap;

  const ArtistListView({
    super.key,
    required this.artists,
    required this.onArtistTap,
  });

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return const Center(
        child: Text('暂无艺术家'),
      );
    }

    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ArtistListTile(
          artist: artist,
          onTap: () => onArtistTap(artist),
        );
      },
    );
  }
}
