import 'package:flutter_test/flutter_test.dart';
import 'package:liyaplayer/features/library/data/models/artist_model.dart';

void main() {
  group('ArtistModel', () {
    test('should have correct fields', () {
      final artist = ArtistModel()
        ..id = 'artist-1'
        ..name = '周杰伦'
        ..songCount = 50
        ..albumCount = 10;

      expect(artist.id, 'artist-1');
      expect(artist.name, '周杰伦');
      expect(artist.songCount, 50);
      expect(artist.albumCount, 10);
    });
  });
}
