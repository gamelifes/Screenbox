import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class VideoDirectory {
  final String path;
  final DateTime addedAt;

  VideoDirectory({required this.path, required this.addedAt});
}

class VideoDirectoriesState {
  final List<VideoDirectory> directories;
  final bool isLoading;

  const VideoDirectoriesState({
    this.directories = const [],
    this.isLoading = false,
  });

  VideoDirectoriesState copyWith({
    List<VideoDirectory>? directories,
    bool? isLoading,
  }) {
    return VideoDirectoriesState(
      directories: directories ?? this.directories,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class VideoDirectoriesNotifier extends StateNotifier<VideoDirectoriesState> {
  static const _boxName = 'video_directories';
  Box<String>? _box;
  bool _isInitialized = false;

  VideoDirectoriesNotifier() : super(const VideoDirectoriesState()) {
    _loadDirectories();
  }

  Future<void> _loadDirectories() async {
    state = state.copyWith(isLoading: true);
    try {
      _box = await Hive.openBox<String>(_boxName);
      _isInitialized = true;
      final dirs = _box!.values
          .map((path) => VideoDirectory(path: path, addedAt: DateTime.now()))
          .toList();
      state = state.copyWith(directories: dirs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addDirectory(String path) async {
    if (!_isInitialized || _box == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_box == null) return;
    }
    if (state.directories.any((d) => d.path == path)) return;
    await _box!.put(path, path);
    state = state.copyWith(
      directories: [
        ...state.directories,
        VideoDirectory(path: path, addedAt: DateTime.now()),
      ],
    );
  }

  Future<void> removeDirectory(String path) async {
    if (_box == null) return;
    await _box!.delete(path);
    state = state.copyWith(
      directories: state.directories.where((d) => d.path != path).toList(),
    );
  }
}

final videoDirectoriesProvider =
    StateNotifierProvider<VideoDirectoriesNotifier, VideoDirectoriesState>(
        (ref) {
  return VideoDirectoriesNotifier();
});