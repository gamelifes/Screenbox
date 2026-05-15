import 'package:flutter_test/flutter_test.dart';
import 'package:liyaplayer/features/library/data/models/album_model.dart';

void main() {
  group('AlbumModel', () {
    test('should have correct fields', () {
      final album = AlbumModel()
        ..id = 'album-1'
        ..name = '七里香'
        ..artist = '周杰伦'
        ..year = 2004
        ..songCount = 10
        ..firstSongPath = '/music/七里香/01.mp3';

      expect(album.id, 'album-1');
      expect(album.name, '七里香');
      expect(album.songCount, 10);
    });
  });
}
