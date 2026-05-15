import 'package:flutter_test/flutter_test.dart';
import 'package:liyaplayer/features/library/data/models/scan_directory_model.dart';

void main() {
  group('ScanDirectoryModel', () {
    test('should have correct fields', () {
      final dir = ScanDirectoryModel()
        ..path = '/music'
        ..extensions = ['.mp3', '.flac', '.wav']
        ..addedAt = DateTime.now()
        ..lastScanAt = DateTime.now();

      expect(dir.path, '/music');
      expect(dir.extensions, ['.mp3', '.flac', '.wav']);
    });
  });
}
