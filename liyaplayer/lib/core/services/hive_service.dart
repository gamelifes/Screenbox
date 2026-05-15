import 'package:hive_flutter/hive_flutter.dart';
import 'package:liyaplayer/features/library/data/models/models.dart';

/// Hive 数据库服务
///
/// 负责：
/// - 初始化 Hive
/// - 打开和管理 Boxes
/// - 提供同步/异步存取接口
class HiveService {
  static const String songBoxName = 'songs';
  static const String albumBoxName = 'albums';
  static const String artistBoxName = 'artists';
  static const String directoryBoxName = 'directories';
  static const String settingsBoxName = 'settings';

  static HiveService? _instance;
  static HiveService get instance => _instance ??= HiveService._();

  HiveService._();

  late Box<SongModel> _songBox;
  late Box<AlbumModel> _albumBox;
  late Box<ArtistModel> _artistBox;
  late Box<ScanDirectoryModel> _dirBox;
  late Box<dynamic> _settingsBox;

  Box<SongModel> get songBox => _songBox;
  Box<AlbumModel> get albumBox => _albumBox;
  Box<ArtistModel> get artistBox => _artistBox;
  Box<ScanDirectoryModel> get dirBox => _dirBox;
  Box<dynamic> get settingsBox => _settingsBox;

  /// 初始化 Hive
  Future<void> initialize() async {
    await Hive.initFlutter();

    // 注册 Adapters
    Hive.registerAdapter(SongModelAdapter());
    Hive.registerAdapter(AlbumModelAdapter());
    Hive.registerAdapter(ArtistModelAdapter());
    Hive.registerAdapter(ScanDirectoryModelAdapter());

    // 打开 Boxes
    _songBox = await Hive.openBox<SongModel>(songBoxName);
    _albumBox = await Hive.openBox<AlbumModel>(albumBoxName);
    _artistBox = await Hive.openBox<ArtistModel>(artistBoxName);
    _dirBox = await Hive.openBox<ScanDirectoryModel>(directoryBoxName);
    _settingsBox = await Hive.openBox<dynamic>(settingsBoxName);
  }

  /// 关闭所有 Boxes
  Future<void> close() async {
    await _songBox.close();
    await _albumBox.close();
    await _artistBox.close();
    await _dirBox.close();
    await _settingsBox.close();
  }

  // ============ Songs ============

  List<SongModel> getAllSongs() => _songBox.values.toList();

  Future<void> saveSong(SongModel song) async {
    await _songBox.put(song.id, song);
  }

  Future<void> saveSongs(List<SongModel> songs) async {
    final map = {for (var s in songs) s.id: s};
    await _songBox.putAll(map);
  }

  Future<void> deleteSong(String id) async {
    await _songBox.delete(id);
  }

  Future<void> clearSongs() async {
    await _songBox.clear();
  }

  // ============ Albums ============

  List<AlbumModel> getAllAlbums() => _albumBox.values.toList();

  Future<void> saveAlbum(AlbumModel album) async {
    await _albumBox.put(album.id, album);
  }

  Future<void> saveAlbums(List<AlbumModel> albums) async {
    final map = {for (var a in albums) a.id: a};
    await _albumBox.putAll(map);
  }

  Future<void> clearAlbums() async {
    await _albumBox.clear();
  }

  // ============ Artists ============

  List<ArtistModel> getAllArtists() => _artistBox.values.toList();

  Future<void> saveArtist(ArtistModel artist) async {
    await _artistBox.put(artist.id, artist);
  }

  Future<void> saveArtists(List<ArtistModel> artists) async {
    final map = {for (var a in artists) a.id: a};
    await _artistBox.putAll(map);
  }

  Future<void> clearArtists() async {
    await _artistBox.clear();
  }

  // ============ Directories ============

  List<ScanDirectoryModel> getAllDirectories() => _dirBox.values.toList();

  Future<void> saveDirectory(ScanDirectoryModel dir) async {
    await _dirBox.put(dir.path, dir);
  }

  Future<void> deleteDirectory(String path) async {
    await _dirBox.delete(path);
  }

  // ============ Settings ============

  T? getSetting<T>(String key) => _settingsBox.get(key) as T?;

  Future<void> saveSetting<T>(String key, T value) async {
    await _settingsBox.put(key, value);
  }

  // ============ Window State ============

  /// 窗口状态
  static const String windowStateKey = 'windowState';

  Map<String, dynamic>? getWindowState() {
    final data = _settingsBox.get(windowStateKey);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> saveWindowState({
    required double x,
    required double y,
    required double width,
    required double height,
    required bool isMaximized,
  }) async {
    await _settingsBox.put(windowStateKey, {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'isMaximized': isMaximized,
    });
  }

  Future<void> clearWindowState() async {
    await _settingsBox.delete(windowStateKey);
  }
}
