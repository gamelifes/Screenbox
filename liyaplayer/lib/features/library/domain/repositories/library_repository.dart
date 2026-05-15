import 'package:liyaplayer/features/library/data/models/models.dart';

/// Scan progress information
class ScanProgress {
  final int foundCount;
  final int totalCount;
  final String currentFile;
  final double progress; // 0.0 - 1.0

  ScanProgress({
    required this.foundCount,
    required this.totalCount,
    required this.currentFile,
    required this.progress,
  });
}

abstract class LibraryRepository {
  // Songs
  Future<List<SongModel>> getAllSongs();
  Future<List<SongModel>> getSongsByArtist(String artistId);
  Future<List<SongModel>> getSongsByAlbum(String albumId);

  // Albums
  Future<List<AlbumModel>> getAllAlbums();
  Future<AlbumModel?> getAlbumById(String albumId);

  // Artists
  Future<List<ArtistModel>> getAllArtists();
  Future<ArtistModel?> getArtistById(String artistId);

  // Directories
  Future<List<ScanDirectoryModel>> getScanDirectories();
  Future<void> addScanDirectory(String path, List<String> extensions);
  Future<void> removeScanDirectory(String path);

  // Search
  Future<List<SongModel>> searchSongs(String query);
  Future<List<ArtistModel>> searchArtists(String query);
  Future<List<AlbumModel>> searchAlbums(String query);

  // Scan
  Stream<ScanProgress> scanDirectory(String path);

  // Initialize
  Future<void> initialize();
}
