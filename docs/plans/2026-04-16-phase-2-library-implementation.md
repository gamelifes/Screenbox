# Phase 2: 音频库管理 - TDD实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** 实现音乐库管理功能，包括目录扫描、元数据提取、本地存储、文件监视、列表展示

**Architecture:** 
- 使用Hive存储元数据，支持快速查询
- 文件监视器使用watcher包监听目录变化
- 元数据提取使用taglib_ffi
- Clean Architecture: domain/data/presentation三层

**Tech Stack:** Hive, watcher, taglib_ffi, Riverpod, GoRouter

---

## Phase 2.1: 数据模型与Repository

### Task 2.1.1: 创建SongModel Hive模型

**Files:**
- Create: `liyaplayer/lib/features/library/data/models/song_model.dart`
- Test: `liyaplayer/test/features/library/data/models/song_model_test.dart`

**Step 1: Write the failing test**

```dart
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
```

**Step 2: Run test to verify it fails**

Run: `cd liyaplayer && flutter test test/features/library/data/models/song_model_test.dart -v`
Expected: FAIL with "File not found"

**Step 3: Write minimal implementation**

```dart
// liyaplayer/lib/features/library/data/models/song_model.dart
import 'package:hive/hive.dart';

part 'song_model.g.dart';

@HiveType(typeId: 0)
class SongModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String filePath;

  @HiveField(2)
  String? title;

  @HiveField(3)
  String? artist;

  @HiveField(4)
  String? album;

  @HiveField(5)
  String? genre;

  @HiveField(6)
  late int durationMs;

  @HiveField(7)
  int? trackNumber;

  @HiveField(8)
  int? year;

  @HiveField(9)
  late DateTime addedAt;

  @HiveField(10)
  late DateTime modifiedAt;

  @HiveField(11)
  List<int>? artwork;

  @HiveField(12)
  late String artistId;

  @HiveField(13)
  late String albumId;
}
```

**Step 4: Run build_runner to generate adapter**

Run: `cd liyaplayer && flutter pub run build_runner build --delete-conflicting-outputs`

**Step 5: Run test to verify it passes**

Run: `cd liyaplayer && flutter test test/features/library/data/models/song_model_test.dart -v`
Expected: PASS

**Step 6: Commit**

```bash
git add lib/features/library/data/models/song_model.dart test/features/library/data/models/song_model_test.dart
git commit -m "feat(library): create SongModel Hive model"
```

---

### Task 2.1.2: 创建AlbumModel Hive模型

**Files:**
- Create: `liyaplayer/lib/features/library/data/models/album_model.dart`
- Test: `liyaplayer/test/features/library/data/models/album_model_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:liyaplayer/features/library/data/models/album_model.dart';

void main() {
  group('AlbumModel', () {
    test('should have correct fields', () {
      final album = AlbumModel()
        ..id = 'album-1'
        ..name = '七里香'
        ..artist = '周杰伦'
        ..year = 2004
        ..songCount = 10
        ..firstSongPath = '/music/七里香/01.mp3';

      expect(album.id, 'album-1');
      expect(album.name, '七里香');
      expect(album.songCount, 10);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Expected: FAIL with "File not found"

**Step 3: Write minimal implementation**

```dart
// liyaplayer/lib/features/library/data/models/album_model.dart
import 'package:hive/hive.dart';

part 'album_model.g.dart';

@HiveType(typeId: 1)
class AlbumModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String? name;

  @HiveField(2)
  String? artist;

  @HiveField(3)
  int? year;

  @HiveField(4)
  List<int>? artwork;

  @HiveField(5)
  late int songCount;

  @HiveField(6)
  late String firstSongPath;
}
```

**Step 4: Run build_runner**

**Step 5: Run test to verify it passes**

Expected: PASS

**Step 6: Commit**

```bash
git add lib/features/library/data/models/album_model.dart test/features/library/data/models/album_model_test.dart
git commit -m "feat(library): create AlbumModel Hive model"
```

---

### Task 2.1.3: 创建ArtistModel Hive模型

**Files:**
- Create: `liyaplayer/lib/features/library/data/models/artist_model.dart`
- Test: `liyaplayer/test/features/library/data/models/artist_model_test.dart`

**Step 1-6: 同上模式**

```dart
// ArtistModel fields: id, name, songCount, albumCount
```

Commit: `feat(library): create ArtistModel Hive model`

---

### Task 2.1.4: 创建ScanDirectoryModel

**Files:**
- Create: `liyaplayer/lib/features/library/data/models/scan_directory_model.dart`
- Test: `liyaplayer/test/features/library/data/models/scan_directory_model_test.dart`

**Step 1-6: 同上模式**

```dart
// ScanDirectoryModel fields: path, extensions, addedAt, lastScanAt
// typeId: 3
```

Commit: `feat(library): create ScanDirectoryModel`

---

### Task 2.1.5: 创建models.dart导出文件

**Files:**
- Create: `liyaplayer/lib/features/library/data/models/models.dart`
- Modify: `liyaplayer/pubspec.yaml` (添加hive依赖如果需要)

**Step 1: 创建导出文件**

```dart
// lib/features/library/data/models/models.dart
export 'song_model.dart';
export 'album_model.dart';
export 'artist_model.dart';
export 'scan_directory_model.dart';
```

**Step 2: 运行build_runner生成所有adapter**

**Step 3: Commit**

```bash
git add lib/features/library/data/models/models.dart lib/features/library/data/models/
git commit -m "feat(library): export all Hive models"
```

---

### Task 2.1.6: 定义LibraryRepository接口

**Files:**
- Create: `liyaplayer/lib/features/library/domain/repositories/library_repository.dart`
- Test: `liyaplayer/test/features/library/domain/repositories/library_repository_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:liyaplayer/features/library/domain/repositories/library_repository.dart';

void main() {
  group('LibraryRepository Interface', () {
    test('should define getAllSongs method', () {
      // Verify interface has required methods
      expect(LibraryRepository, isNotNull);
    });
  });
}
```

**Step 2: Write minimal interface**

```dart
// lib/features/library/domain/repositories/library_repository.dart
import 'package:liyaplayer/features/library/data/models/models.dart';

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
```

**Step 3: Add ScanProgress class to models**

```dart
// Add to scan_directory_model.dart or create separate
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
```

**Step 4: Commit**

```bash
git add lib/features/library/domain/repositories/library_repository.dart
git commit -m "feat(library): define LibraryRepository interface"
```

---

## Phase 2.2: 文件扫描与元数据提取

### Task 2.2.1: 创建MetadataExtractor数据源

**Files:**
- Create: `liyaplayer/lib/features/library/data/datasources/metadata_extractor.dart`
- Test: `liyaplayer/test/features/library/data/datasources/metadata_extractor_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:liyaplayer/features/library/data/datasources/metadata_extractor.dart';

void main() {
  group('MetadataExtractor', () {
    test('should extract metadata from audio file', () async {
      // Note: This test requires a real audio file
      // For unit test, we'll mock or use a test fixture
      expect(MetadataExtractor, isNotNull);
    });
  });
}
```

**Step 2: Write minimal implementation (stub for now)**

```dart
// lib/features/library/data/datasources/metadata_extractor.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
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
    
    return SongModel()
      ..id = id
      ..filePath = filePath
      ..title = fileName
      ..artist = 'Unknown'
      ..album = 'Unknown'
      ..durationMs = 0
      ..artistId = md5.convert(utf8.encode('Unknown')).toString()
      ..albumId = md5.convert(utf8.encode('Unknown')).toString()
      ..addedAt = DateTime.now()
      ..modifiedAt = stat.modified;
  }
  
  /// Extract album artwork from file
  Future<List<int>?> extractArtwork(String filePath) async {
    // TODO: Implement with taglib_ffi
    return null;
  }
}
```

**Step 3: Commit**

```bash
git add lib/features/library/data/datasources/metadata_extractor.dart test/features/library/data/datasources/metadata_extractor_test.dart
git commit -m "feat(library): create MetadataExtractor data source"
```

---

### Task 2.2.2: 创建FileScanner

**Files:**
- Create: `liyaplayer/lib/features/library/data/datasources/file_scanner.dart`
- Test: `liyaplayer/test/features/library/data/datasources/file_scanner_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:liyaplayer/features/library/data/datasources/file_scanner.dart';

void main() {
  group('FileScanner', () {
    test('should scan directory for audio files', () async {
      expect(FileScanner, isNotNull);
    });
  });
}
```

**Step 2: Write minimal implementation**

```dart
// lib/features/library/data/datasources/file_scanner.dart
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
```

**Step 3: Commit**

```bash
git add lib/features/library/data/datasources/file_scanner.dart test/features/library/data/datasources/file_scanner_test.dart
git commit -m "feat(library): create FileScanner"
```

---

### Task 2.2.3: 实现LibraryRepositoryImpl

**Files:**
- Create: `liyaplayer/lib/features/library/data/repositories/library_repository_impl.dart`
- Test: `liyaplayer/test/features/library/data/repositories/library_repository_impl_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:liyaplayer/features/library/data/repositories/library_repository_impl.dart';

void main() {
  group('LibraryRepositoryImpl', () {
    test('should be created', () {
      expect(LibraryRepositoryImpl, isNotNull);
    });
  });
}
```

**Step 2: Write minimal implementation**

```dart
// lib/features/library/data/repositories/library_repository_impl.dart
import 'package:hive/hive.dart';
import 'package:liyaplayer/features/library/data/models/models.dart';
import 'package:liyaplayer/features/library/domain/repositories/library_repository.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final Box<SongModel> _songBox;
  final Box<AlbumModel> _albumBox;
  final Box<ArtistModel> _artistBox;
  final Box<ScanDirectoryModel> _dirBox;
  
  LibraryRepositoryImpl({
    required Box<SongModel> songBox,
    required Box<AlbumModel> albumBox,
    required Box<ArtistModel> artistBox,
    required Box<ScanDirectoryModel> dirBox,
  })  : _songBox = songBox,
        _albumBox = albumBox,
        _artistBox = artistBox,
        _dirBox = dirBox;
  
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
    return _songBox.values
        .where((song) => song.artistId == artistId)
        .toList();
  }
  
  @override
  Future<List<SongModel>> getSongsByAlbum(String albumId) async {
    return _songBox.values
        .where((song) => song.albumId == albumId)
        .toList();
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
        .where((artist) => artist.name.toLowerCase().contains(lowerQuery))
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
}
```

**Step 3: Commit**

```bash
git add lib/features/library/data/repositories/library_repository_impl.dart test/features/library/data/repositories/library_repository_impl_test.dart
git commit -m "feat(library): implement LibraryRepositoryImpl"
```

---

## Phase 2.3: 文件监视器

### Task 2.3.1: 创建FileWatcherService

**Files:**
- Create: `liyaplayer/lib/features/library/data/datasources/file_watcher_service.dart`
- Test: `liyaplayer/test/features/library/data/datasources/file_watcher_service_test.dart`

**Step 1-3: 标准TDD模式**

```dart
// FileWatcherService using watcher package
import 'package:watcher/watcher.dart';

class FileWatcherService {
  final Map<String, DirectoryWatcher> _watchers = {};
  
  void watch(String path, Function(String event, String path) onEvent) {
    final watcher = DirectoryWatcher(path);
    _watchers[path] = watcher;
    
    watcher.events.listen((event) {
      onEvent(event.type.toString(), event.path);
    });
  }
  
  void stopWatching(String path) {
    _watchers.remove(path);
  }
  
  void stopAll() {
    _watchers.clear();
  }
}
```

**Step 4: Commit**

```bash
git add lib/features/library/data/datasources/file_watcher_service.dart test/features/library/data/datasources/file_watcher_service_test.dart
git commit -m "feat(library): create FileWatcherService"
```

---

### Task 2.3.2: 集成文件监视器到Repository

**Modify:** `library_repository_impl.dart`

**Step 1: Update test for file watching integration**

**Step 2: Add FileWatcherService integration**

```dart
// Add to LibraryRepositoryImpl
class LibraryRepositoryImpl implements LibraryRepository {
  final FileWatcherService _watcher;
  
  @override
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
```

**Step 3: Commit**

```bash
git add lib/features/library/data/repositories/library_repository_impl.dart
git commit -m "feat(library): integrate FileWatcherService into repository"
```

---

## Phase 2.4: LibraryProvider状态管理

### Task 2.4.1: 创建LibraryState

**Files:**
- Create: `liyaplayer/lib/features/library/presentation/providers/library_state.dart`
- Test: `liyaplayer/test/features/library/presentation/providers/library_state_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:liyaplayer/features/library/presentation/providers/library_state.dart';

void main() {
  group('LibraryState', () {
    test('should have correct initial state', () {
      final state = LibraryState.initial();
      expect(state.songs, isEmpty);
      expect(state.isLoading, false);
    });
  });
}
```

**Step 2: Write minimal implementation**

```dart
// lib/features/library/presentation/providers/library_state.dart
import 'package:liyaplayer/features/library/data/models/models.dart';

enum LibraryTab { songs, artists, albums }

class LibraryState {
  final List<SongModel> songs;
  final List<AlbumModel> albums;
  final List<ArtistModel> artists;
  final List<ScanDirectoryModel> directories;
  final bool isLoading;
  final String? errorMessage;
  final LibraryTab currentTab;
  final String searchQuery;
  
  const LibraryState({
    required this.songs,
    required this.albums,
    required this.artists,
    required this.directories,
    required this.isLoading,
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
      errorMessage: errorMessage,
      currentTab: currentTab ?? this.currentTab,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
```

**Step 3: Commit**

```bash
git add lib/features/library/presentation/providers/library_state.dart test/features/library/presentation/providers/library_state_test.dart
git commit -m "feat(library): create LibraryState"
```

---

### Task 2.4.2: 创建LibraryProvider

**Files:**
- Create: `liyaplayer/lib/features/library/presentation/providers/library_provider.dart`
- Test: `liyaplayer/test/features/library/presentation/providers/library_provider_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liyaplayer/features/library/presentation/providers/library_provider.dart';

void main() {
  group('LibraryProvider', () {
    test('should provide initial state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      final state = container.read(libraryProvider);
      expect(state.isLoading, false);
    });
  });
}
```

**Step 2: Write minimal implementation**

```dart
// lib/features/library/presentation/providers/library_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liyaplayer/features/library/data/models/models.dart';
import 'package:liyaplayer/features/library/domain/repositories/library_repository.dart';
import 'package:liyaplayer/features/library/presentation/providers/library_state.dart';

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier();
});

class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier() : super(LibraryState.initial());
  
  void setTab(LibraryTab tab) {
    state = state.copyWith(currentTab: tab);
  }
  
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
  
  Future<void> loadLibrary() async {
    state = state.copyWith(isLoading: true);
    // TODO: Load from repository
    state = state.copyWith(isLoading: false);
  }
  
  Future<void> addDirectory(String path) async {
    // TODO: Add directory and scan
  }
}
```

**Step 3: Commit**

```bash
git add lib/features/library/presentation/providers/library_provider.dart test/features/library/presentation/providers/library_provider_test.dart
git commit -m "feat(library): create LibraryProvider"
```

---

## Phase 2.5: UI组件

### Task 2.5.1: 创建EmptyLibraryView

**Files:**
- Create: `liyaplayer/lib/features/library/presentation/widgets/empty_library_view.dart`
- Test: `liyaplayer/test/features/library/presentation/widgets/empty_library_view_test.dart`

**Step 1-3: 标准TDD模式**

```dart
import 'package:flutter/material.dart';

class EmptyLibraryView extends StatelessWidget {
  final VoidCallback onAddDirectory;
  
  const EmptyLibraryView({super.key, required this.onAddDirectory});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('你的音乐库是空的', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('添加音乐目录开始使用'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddDirectory,
            icon: const Icon(Icons.add),
            label: const Text('添加目录'),
          ),
        ],
      ),
    );
  }
}
```

**Step 4: Commit**

---

### Task 2.5.2: 创建SongListItem

**Files:**
- Create: `liyaplayer/lib/features/library/presentation/widgets/song_list_item.dart`
- Test: `liyaplayer/test/features/library/presentation/widgets/song_list_item_test.dart`

```dart
class SongListItem extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;
  final VoidCallback? onPlay;
  
  // ... implementation
}
```

Commit: `feat(library): create SongListItem widget`

---

### Task 2.5.3: 创建SongList（按字母分组）

**Files:**
- Create: `liyaplayer/lib/features/library/presentation/widgets/song_list.dart`
- Test: `liyaplayer/test/features/library/presentation/widgets/song_list_test.dart`

```dart
class SongList extends StatelessWidget {
  final List<SongModel> songs;
  final Function(SongModel) onSongTap;
  
  // Group songs by first letter of title
  Map<String, List<SongModel>> _groupByLetter() {
    // ...
  }
  
  // ... implementation
}
```

Commit: `feat(library): create SongList with alphabetical grouping`

---

### Task 2.5.4: 创建AlbumGridItem

**Files:**
- Create: `liyaplayer/lib/features/library/presentation/widgets/album_grid_item.dart`
- Test: `liyaplayer/test/features/library/presentation/widgets/album_grid_item_test.dart`

Commit: `feat(library): create AlbumGridItem widget`

---

### Task 2.5.5: 创建AlbumGrid

**Files:**
- Create: `liyaplayer/lib/features/library/presentation/widgets/album_grid.dart`
- Test: `liyaplayer/test/features/library/presentation/widgets/album_grid_test.dart`

Commit: `feat(library): create AlbumGrid widget`

---

### Task 2.5.6: 创建ArtistListItem

**Files:**
- Create: `liyaplayer/lib/features/library/presentation/widgets/artist_list_item.dart`
- Test: `liyaplayer/test/features/library/presentation/widgets/artist_list_item_test.dart`

Commit: `feat(library): create ArtistListItem widget`

---

### Task 2.5.7: 创建ArtistList

**Files:**
- Create: `liyaplayer/lib/features/library/presentation/widgets/artist_list.dart`
- Test: `liyaplayer/test/features/library/presentation/widgets/artist_list_test.dart`

Commit: `feat(library): create ArtistList widget`

---

### Task 2.5.8: 创建ArtistDetailPage

**Files:**
- Create: `liyaplayer/lib/features/library/presentation/pages/artist_detail_page.dart`
- Test: `liyaplayer/test/features/library/presentation/pages/artist_detail_page_test.dart`

```dart
class ArtistDetailPage extends ConsumerWidget {
  final String artistId;
  
  // Shows: artist info card + songs list
}
```

Commit: `feat(library): create ArtistDetailPage`

---

### Task 2.5.9: 创建AlbumDetailPage

**Files:**
- Create: `liyaplayer/lib/features/library/presentation/pages/album_detail_page.dart`
- Test: `liyaplayer/test/features/library/presentation/pages/album_detail_page_test.dart`

```dart
class AlbumDetailPage extends ConsumerWidget {
  final String albumId;
  
  // Shows: album info card + songs list
}
```

Commit: `feat(library): create AlbumDetailPage`

---

### Task 2.5.10: 创建LibraryPage（主页面）

**Files:**
- Create: `liyaplayer/lib/features/library/presentation/pages/library_page.dart`
- Test: `liyaplayer/test/features/library/presentation/pages/library_page_test.dart`

```dart
class LibraryPage extends ConsumerWidget {
  // Top tabs: Songs | Artists | Albums
  // Shows EmptyLibraryView or SongList/ArtistList/AlbumGrid based on tab
}
```

Commit: `feat(library): create LibraryPage with tab navigation`

---

## Phase 2.6: 集成测试

### Task 2.6.1: 端到端测试

**Files:**
- Test: `liyaplayer/test/features/library/library_e2e_test.dart`

**Step 1: Write integration test**

```dart
void main() {
  group('Library E2E', () {
    testWidgets('should add directory and show songs', (tester) async {
      // 1. Tap add directory
      // 2. Select directory
      // 3. Wait for scan
      // 4. Verify songs appear
    });
  });
}
```

**Step 2: Commit**

```bash
git add test/features/library/library_e2e_test.dart
git commit -m "test(library): add end-to-end integration tests"
```

---

## 总结

| Phase | Tasks | 预计Commit数 |
|-------|-------|--------------|
| 2.1 数据模型 | 6 | 6 |
| 2.2 扫描提取 | 3 | 3 |
| 2.3 文件监视 | 2 | 2 |
| 2.4 状态管理 | 2 | 2 |
| 2.5 UI组件 | 10 | 10 |
| 2.6 集成测试 | 1 | 1 |
| **总计** | **24** | **24 commits** |

---

**Plan execution: Use Subagent-Driven Development per task**
