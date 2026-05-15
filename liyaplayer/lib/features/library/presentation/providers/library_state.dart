import 'package:liyaplayer/features/library/data/models/models.dart';
import 'package:liyaplayer/features/library/domain/repositories/library_repository.dart';

enum LibraryTab { songs, artists, albums }

class LibraryState {
  final List<SongModel> songs;
  final List<AlbumModel> albums;
  final List<ArtistModel> artists;
  final List<ScanDirectoryModel> directories;
  final bool isLoading;
  final bool isScanning;
  final ScanProgress? scanProgress;
  final String? errorMessage;
  final LibraryTab currentTab;
  final String searchQuery;

  const LibraryState({
    required this.songs,
    required this.albums,
    required this.artists,
    required this.directories,
    required this.isLoading,
    this.isScanning = false,
    this.scanProgress,
    this.errorMessage,
    required this.currentTab,
    required this.searchQuery,
  });

  factory LibraryState.initial() {
    return const LibraryState(
      songs: [],
      albums: [],
      artists: [],
      directories: [],
      isLoading: false,
      isScanning: false,
      currentTab: LibraryTab.songs,
      searchQuery: '',
    );
  }

  LibraryState copyWith({
    List<SongModel>? songs,
    List<AlbumModel>? albums,
    List<ArtistModel>? artists,
    List<ScanDirectoryModel>? directories,
    bool? isLoading,
    bool? isScanning,
    ScanProgress? scanProgress,
    String? errorMessage,
    LibraryTab? currentTab,
    String? searchQuery,
  }) {
    return LibraryState(
      songs: songs ?? this.songs,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      directories: directories ?? this.directories,
      isLoading: isLoading ?? this.isLoading,
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress,
      errorMessage: errorMessage,
      currentTab: currentTab ?? this.currentTab,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<SongModel> getSongsByArtist(String artistId) {
    return songs.where((s) => s.artistId == artistId).toList();
  }

  List<AlbumModel> getAlbumsByArtist(String artistId) {
    return albums.where((a) => a.artistId == artistId).toList();
  }

  List<SongModel> getSongsByAlbum(String albumId) {
    return songs.where((s) => s.albumId == albumId).toList();
  }
}
