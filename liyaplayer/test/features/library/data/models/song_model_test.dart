import 'package:flutter_test/flutter_test.dart';
import 'package:liyaplayer/features/library/data/models/song_model.dart';
import 'package:hive/hive.dart';

void main() {
  group('SongModel', () {
    test('should have correct fields', () {
      final song = SongModel()
        ..id = 'test-id'
        ..filePath = '/path/to/song.mp3'
        ..title = '晴天'
        ..artist = '周杰伦'
        ..album = '叶惠美'
        ..durationMs = 269000
        ..artistId = 'artist-1'
        ..albumId = 'album-1'
        ..addedAt = DateTime.now()
        ..modifiedAt = DateTime.now();

      expect(song.id, 'test-id');
      expect(song.title, '晴天');
      expect(song.durationMs, 269000);
    });
  });
}
