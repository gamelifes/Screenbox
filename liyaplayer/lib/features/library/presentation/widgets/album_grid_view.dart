import 'package:flutter/material.dart';
import 'package:liyaplayer/features/library/data/models/models.dart';
import 'package:liyaplayer/features/library/presentation/widgets/album_grid_tile.dart';

class AlbumGridView extends StatelessWidget {
  final List<AlbumModel> albums;
  final void Function(AlbumModel album) onAlbumTap;

  const AlbumGridView({
    super.key,
    required this.albums,
    required this.onAlbumTap,
  });

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const Center(
        child: Text('暂无专辑'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return AlbumGridTile(
          album: album,
          onTap: () => onAlbumTap(album),
        );
      },
    );
  }
}
