import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liyaplayer/core/services/hive_service.dart';
import 'package:liyaplayer/features/library/data/datasources/file_scanner.dart';
import 'package:liyaplayer/features/library/data/models/models.dart';
import 'package:liyaplayer/features/library/domain/repositories/library_repository.dart';
import 'package:liyaplayer/features/library/presentation/providers/library_state.dart';

/// Library Provider
final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier();
});

/// 扫描取消标记
final _scanCancelToken = CancelToken();

class CancelToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;
  void cancel() => _isCancelled = true;
  void reset() => _isCancelled = false;
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final FileScanner _scanner;
  final HiveService _hive;

  LibraryNotifier({FileScanner? scanner, HiveService? hive})
      : _scanner = scanner ?? FileScanner(),
        _hive = hive ?? HiveService.instance,
        super(LibraryState.initial());

  /// 切换 Tab
  void setTab(LibraryTab tab) {
    state = state.copyWith(currentTab: tab);
  }

  /// 设置搜索关键字
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// 加载媒体库（从 Hive 持久化存储）
  Future<void> loadLibrary() async {
    state = state.copyWith(isLoading: true);
    try {
      // 从 Hive 加载数据
      final songs = _hive.getAllSongs();
      final albums = _hive.getAllAlbums();
      final artists = _hive.getAllArtists();
      final dirs = _hive.getAllDirectories();

      state = state.copyWith(
        isLoading: false,
        songs: songs,
        albums: albums,
        artists: artists,
        directories: dirs,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '加载媒体库失败: $e',
      );
    }
  }

  /// 添加扫描目录
  Future<void> addDirectory(String path) async {
    if (state.isScanning) return;

    _scanCancelToken.reset();
    state = state.copyWith(isScanning: true, scanProgress: null);

    try {
      final songs = <SongModel>[];
      var foundCount = 0;

      await for (final song in _scanner.scanDirectory(path)) {
        if (_scanCancelToken.isCancelled) break;

        // 生成 artistId 和 albumId
        final artistId = _generateArtistId(song.artist ?? 'Unknown');
        final albumId = _generateAlbumId(song.album ?? 'Unknown', song.artist);
        song.artistId = artistId;
        song.albumId = albumId;

        songs.add(song);
        foundCount++;

        // 实时更新进度
        state = state.copyWith(
          scanProgress: ScanProgress(
            foundCount: foundCount,
            totalCount: -1,
            currentFile: song.filePath,
            progress: 0.0,
          ),
        );
      }

      if (_scanCancelToken.isCancelled) {
        state = state.copyWith(isScanning: false, scanProgress: null);
        return;
      }

      // 获取已存在的歌曲路径集合（用于去重）
      final existingPaths = state.songs.map((s) => s.filePath).toSet();

      // 过滤掉已存在的歌曲
      final newSongs =
          songs.where((s) => !existingPaths.contains(s.filePath)).toList();

      // 生成目录信息
      final newDir = ScanDirectoryModel()
        ..path = path
        ..extensions = ['.mp3', '.flac', '.wav', '.m4a', '.ogg']
        ..addedAt = DateTime.now();

      // 生成专辑和艺术家（只从新歌曲生成，避免ID冲突）
      final albums = _generateAlbums(newSongs);
      final artists = _generateArtists(newSongs);

      // 持久化到 Hive
      await _hive.saveSongs(newSongs);
      await _hive.saveAlbums([...state.albums, ...albums]);
      await _hive.saveArtists([...state.artists, ...artists]);
      await _hive.saveDirectory(newDir);

      // 更新状态（去重后追加）
      state = state.copyWith(
        songs: [...state.songs, ...newSongs],
        albums: [...state.albums, ...albums],
        artists: [...state.artists, ...artists],
        directories: [...state.directories, newDir],
        isScanning: false,
        scanProgress: null,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        scanProgress: null,
        errorMessage: '扫描失败: $e',
      );
    }
  }

  /// 取消扫描
  void cancelScan() {
    _scanCancelToken.cancel();
    state = state.copyWith(
      isScanning: false,
      scanProgress: null,
    );
  }

  /// 移除扫描目录
  Future<void> removeDirectory(String path) async {
    // 获取该目录的歌曲 ID
    final songsToRemove =
        state.songs.where((s) => s.filePath.startsWith(path)).toList();

    // 从 Hive 删除
    await _hive.deleteDirectory(path);
    for (final song in songsToRemove) {
      await _hive.deleteSong(song.id);
    }

    // 过滤掉该目录的歌曲
    final remainingSongs =
        state.songs.where((s) => !s.filePath.startsWith(path)).toList();

    // 重新生成 albums 和 artists
    final albums = _generateAlbums(remainingSongs);
    final artists = _generateArtists(remainingSongs);

    // 更新 Hive
    await _hive.saveAlbums(albums);
    await _hive.saveArtists(artists);

    state = state.copyWith(
      songs: remainingSongs,
      albums: albums,
      artists: artists,
      directories: state.directories.where((d) => d.path != path).toList(),
    );
  }

  /// 生成 Artist ID
  String _generateArtistId(String artistName) {
    return artistName.toLowerCase().hashCode.toRadixString(16);
  }

  /// 生成 Album ID
  String _generateAlbumId(String albumName, String? artist) {
    final key = '${albumName}_${artist ?? ""}';
    return key.toLowerCase().hashCode.toRadixString(16);
  }

  /// 从歌曲列表生成专辑列表
  List<AlbumModel> _generateAlbums(List<SongModel> songs) {
    final albumMap = <String, AlbumModel>{};

    for (final song in songs) {
      if (albumMap.containsKey(song.albumId)) continue;

      final albumSongs = songs.where((s) => s.albumId == song.albumId).toList();
      final album = AlbumModel()
        ..id = song.albumId
        ..name = song.album ?? 'Unknown Album'
        ..artist = song.artist
        ..artistId = song.artistId
        ..songCount = albumSongs.length
        ..firstSongPath = albumSongs.first.filePath;

      albumMap[song.albumId] = album;
    }

    return albumMap.values.toList();
  }

  /// 从歌曲列表生成艺术家列表
  List<ArtistModel> _generateArtists(List<SongModel> songs) {
    final artistMap = <String, ArtistModel>{};

    for (final song in songs) {
      if (artistMap.containsKey(song.artistId)) continue;

      final artistSongs = songs.where((s) => s.artistId == song.artistId);
      final artistAlbums = artistSongs.map((s) => s.albumId).toSet();

      final artist = ArtistModel()
        ..id = song.artistId
        ..name = song.artist ?? 'Unknown Artist'
        ..songCount = artistSongs.length
        ..albumCount = artistAlbums.length;

      artistMap[song.artistId] = artist;
    }

    return artistMap.values.toList();
  }
}
