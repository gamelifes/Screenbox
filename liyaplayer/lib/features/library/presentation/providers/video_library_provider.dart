import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liyaplayer/features/library/data/models/models.dart';
import 'package:liyaplayer/features/player/presentation/providers/player_provider.dart';

class VideoLibraryState {
  final List<VideoModel> videos;
  final bool isLoading;
  final bool isScanning;
  final String? errorMessage;

  const VideoLibraryState({
    this.videos = const [],
    this.isLoading = false,
    this.isScanning = false,
    this.errorMessage,
  });

  VideoLibraryState copyWith({
    List<VideoModel>? videos,
    bool? isLoading,
    bool? isScanning,
    String? errorMessage,
  }) {
    return VideoLibraryState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      isScanning: isScanning ?? this.isScanning,
      errorMessage: errorMessage,
    );
  }
}

class VideoLibraryNotifier extends StateNotifier<VideoLibraryState> {
  final Ref _ref;
  static const _videoExtensions = ['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v'];

  VideoLibraryNotifier(this._ref) : super(const VideoLibraryState());

  Future<void> scanDirectory(String path) async {
    if (state.isScanning) return;

    state = state.copyWith(isScanning: true, errorMessage: null);

    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        state = state.copyWith(isScanning: false, errorMessage: '目录不存在');
        return;
      }

      final newVideos = <VideoModel>[];
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final ext = entity.path.toLowerCase();
          if (_videoExtensions.any((e) => ext.endsWith(e))) {
            final stat = await entity.stat();
            newVideos.add(VideoModel(
              id: entity.path.hashCode.toString(),
              filePath: entity.path,
              title: _extractTitle(entity.path),
              durationMs: 0,
              addedAt: DateTime.now(),
              modifiedAt: stat.modified,
            ));
          }
        }
      }

      final existingPaths = state.videos.map((v) => v.filePath).toSet();
      final uniqueNewVideos = newVideos.where((v) => !existingPaths.contains(v.filePath));
      state = state.copyWith(
        videos: [...state.videos, ...uniqueNewVideos],
        isScanning: false,
      );
    } catch (e) {
      state = state.copyWith(isScanning: false, errorMessage: e.toString());
    }
  }

  String _extractTitle(String path) {
    final fileName = path.split('\\').last.split('/').last;
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0) {
      return fileName.substring(0, lastDot);
    }
    return fileName;
  }

  void playVideo(VideoModel video) async {
    final playerNotifier = _ref.read(playerProvider.notifier);
    await playerNotifier.loadVideo(
      video.filePath,
      title: video.title ?? video.fileName,
    );
    await playerNotifier.play();
  }

  void playAll() async {
    if (state.videos.isEmpty) return;
    playVideo(state.videos.first);
  }
}

final videoLibraryProvider =
    StateNotifierProvider<VideoLibraryNotifier, VideoLibraryState>((ref) {
  return VideoLibraryNotifier(ref);
});