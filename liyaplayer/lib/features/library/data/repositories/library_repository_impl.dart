import 'package:hive/hive.dart';
import 'package:liyaplayer/features/library/data/models/models.dart';
import 'package:liyaplayer/features/library/data/datasources/file_watcher_service.dart';
import 'package:liyaplayer/features/library/domain/repositories/library_repository.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final Box<SongModel> _songBox;
  final Box<AlbumModel> _albumBox;
  final Box<ArtistModel> _artistBox;
  final Box<ScanDirectoryModel> _dirBox;
  final FileWatcherService _watcher;

  LibraryRepositoryImpl({
    required Box<SongModel> songBox,
    required Box<AlbumModel> albumBox,
    required Box<ArtistModel> artistBox,
    required Box<ScanDirectoryModel> dirBox,
    FileWatcherService? watcher,
  })  : _songBox = songBox,
        _albumBox = albumBox,
        _artistBox = artistBox,
        _dirBox = dirBox,
        _watcher = watcher ?? FileWatcherService();

  @override
  Future<List<SongModel>> getAllSongs() async {
    return _songBox.values.toList();
  }

  @override
  Future<List<AlbumModel>> getAllAlbums() async {
    return _albumBox.values.toList();
  }

  @override
  Future<List<ArtistModel>> getAllArtists() async {
    return _artistBox.values.toList();
  }

  @override
  Future<List<SongModel>> getSongsByArtist(String artistId) async {
    return _songBox.values.where((song) => song.artistId == artistId).toList();
  }

  @override
  Future<List<SongModel>> getSongsByAlbum(String albumId) async {
    return _songBox.values.where((song) => song.albumId == albumId).toList();
  }

  @override
  Future<List<SongModel>> searchSongs(String query) async {
    final lowerQuery = query.toLowerCase();
    return _songBox.values
        .where((song) =>
            song.title?.toLowerCase().contains(lowerQuery) == true ||
            song.artist?.toLowerCase().contains(lowerQuery) == true ||
            song.album?.toLowerCase().contains(lowerQuery) == true)
        .toList();
  }

  @override
  Future<List<ArtistModel>> searchArtists(String query) async {
    final lowerQuery = query.toLowerCase();
    return _artistBox.values
        .where(
            (artist) => artist.name?.toLowerCase().contains(lowerQuery) == true)
        .toList();
  }

  @override
  Future<List<AlbumModel>> searchAlbums(String query) async {
    final lowerQuery = query.toLowerCase();
    return _albumBox.values
        .where((album) =>
            album.name?.toLowerCase().contains(lowerQuery) == true ||
            album.artist?.toLowerCase().contains(lowerQuery) == true)
        .toList();
  }

  @override
  Future<AlbumModel?> getAlbumById(String albumId) async {
    return _albumBox.get(albumId);
  }

  @override
  Future<ArtistModel?> getArtistById(String artistId) async {
    return _artistBox.get(artistId);
  }

  @override
  Future<List<ScanDirectoryModel>> getScanDirectories() async {
    return _dirBox.values.toList();
  }

  @override
  Future<void> addScanDirectory(String path, List<String> extensions) async {
    final dir = ScanDirectoryModel()
      ..path = path
      ..extensions = extensions
      ..addedAt = DateTime.now()
      ..lastScanAt = DateTime.now();
    await _dirBox.put(path, dir);
  }

  @override
  Future<void> removeScanDirectory(String path) async {
    await _dirBox.delete(path);
  }

  @override
  Stream<ScanProgress> scanDirectory(String path) async* {
    // Implementation in Task 2.3.2
  }

  @override
  Future<void> initialize() async {
    // Ensure boxes are open
  }

  Future<void> startWatching() async {
    final dirs = await getScanDirectories();
    for (final dir in dirs) {
      _watcher.watch(dir.path, (event, path) {
        _handleFileEvent(event, path);
      });
    }
  }

  Future<void> _handleFileEvent(String event, String path) async {
    // Add/remove song based on event type
  }
}
