import 'dart:convert';
import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:liyaplayer/features/library/data/models/models.dart';

class MetadataExtractor {
  /// Extract metadata from an audio file
  Future<SongModel> extractMetadata(String filePath) async {
    final file = File(filePath);
    final stat = await file.stat();

    // Generate ID from file path hash
    final id = md5.convert(utf8.encode(filePath)).toString();

    // Parse filename as fallback title
    final fileName = p.basenameWithoutExtension(filePath);

    // Try to read metadata with audio_metadata_reader
    String title = fileName;
    String artist = 'Unknown';
    String album = 'Unknown';
    int durationMs = 0;
    int? trackNumber;
    int? year;

    try {
      final metadata = readMetadata(file, getImage: false);
      title = metadata.title?.isNotEmpty == true ? metadata.title! : fileName;
      artist =
          metadata.artist?.isNotEmpty == true ? metadata.artist! : 'Unknown';
      album = metadata.album?.isNotEmpty == true ? metadata.album! : 'Unknown';
      // Duration is Duration object, convert to milliseconds
      if (metadata.duration != null) {
        durationMs = metadata.duration!.inMilliseconds;
      }
      trackNumber = metadata.trackNumber;
      // Year - handle both DateTime and int types
      if (metadata.year != null) {
        if (metadata.year is int) {
          year = metadata.year as int;
        } else if (metadata.year is DateTime) {
          year = (metadata.year as DateTime).year;
        }
      }
    } catch (e) {
      // Fallback to filename parsing on error
    }

    // Generate artistId and albumId from names
    final artistId = md5.convert(utf8.encode(artist)).toString();
    final albumId = md5.convert(utf8.encode(album)).toString();

    return SongModel()
      ..id = id
      ..filePath = filePath
      ..title = title
      ..artist = artist
      ..album = album
      ..durationMs = durationMs
      ..trackNumber = trackNumber
      ..year = year
      ..artistId = artistId
      ..albumId = albumId
      ..addedAt = DateTime.now()
      ..modifiedAt = stat.modified;
  }

  /// Extract album artwork from file using readAllMetadata for full metadata
  Future<List<int>?> extractArtwork(String filePath) async {
    try {
      final metadata = readAllMetadata(File(filePath), getImage: true);

      // Handle different metadata types - pictures stored differently
      if (metadata is Mp3Metadata) {
        // MP3 (ID3v2) stores artwork in pictures list
        final pictures = metadata.pictures;
        if (pictures != null && pictures.isNotEmpty) {
          return pictures.first.bytes.toList();
        }
      } else if (metadata is VorbisMetadata) {
        // FLAC/OGG uses Vorbis comments
        final pictures = metadata.pictures;
        if (pictures != null && pictures.isNotEmpty) {
          return pictures.first.bytes.toList();
        }
      }
      // Mp4Metadata may have different structure, skip for now
    } catch (e) {
      // Ignore errors - artwork is optional
    }
    return null;
  }
}
