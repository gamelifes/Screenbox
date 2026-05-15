import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:liyaplayer/features/library/data/models/models.dart';
import 'package:liyaplayer/features/library/data/datasources/metadata_extractor.dart';

class FileScanner {
  final MetadataExtractor _extractor;

  FileScanner({MetadataExtractor? extractor})
      : _extractor = extractor ?? MetadataExtractor();

  /// Scan directory and emit progress
  Stream<SongModel> scanDirectory(
    String directoryPath, {
    List<String> extensions = const ['.mp3', '.flac', '.wav', '.m4a', '.ogg'],
  }) async* {
    final dir = Directory(directoryPath);

    if (!await dir.exists()) {
      throw Exception('Directory not found: $directoryPath');
    }

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase();
        if (extensions.contains(ext)) {
          try {
            final song = await _extractor.extractMetadata(entity.path);
            yield song;
          } catch (e) {
            // Skip files that can't be read
          }
        }
      }
    }
  }
}
