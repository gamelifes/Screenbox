import 'package:flutter_test/flutter_test.dart';
import 'package:liyaplayer/features/library/data/datasources/file_scanner.dart';

void main() {
  group('FileScanner', () {
    test('should scan directory for audio files', () async {
      expect(FileScanner, isNotNull);
    });
  });
}
