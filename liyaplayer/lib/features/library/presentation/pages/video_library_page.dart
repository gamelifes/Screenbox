import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:liyaplayer/features/library/data/models/models.dart';
import 'package:liyaplayer/features/library/presentation/providers/video_library_provider.dart';
import 'package:liyaplayer/features/library/presentation/providers/video_directories_provider.dart';
import 'package:liyaplayer/features/player/presentation/providers/player_provider.dart';
import 'package:liyaplayer/features/player/presentation/pages/player_page.dart';
import 'package:liyaplayer/multi_window_app.dart';

class VideoLibraryPage extends ConsumerStatefulWidget {
  const VideoLibraryPage({super.key, this.onOpenMiniWindow});

  final VoidCallback? onOpenMiniWindow;

  @override
  ConsumerState<VideoLibraryPage> createState() => _VideoLibraryPageState();
}

class _VideoLibraryPageState extends ConsumerState<VideoLibraryPage> {
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadVideos() async {
    final dirs = ref.read(videoDirectoriesProvider).directories;
    for (final dir in dirs) {
      await ref.read(videoLibraryProvider.notifier).scanDirectory(dir.path);
    }
  }

  void _showAddDirectoryDialog() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      await ref.read(videoDirectoriesProvider.notifier).addDirectory(result);
      await _loadVideos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dirs = ref.watch(videoDirectoriesProvider);
    final playerState = ref.watch(playerProvider);

    if (!_initialLoadDone && !dirs.isLoading && dirs.directories.isNotEmpty) {
      _initialLoadDone = true;
      Future.microtask(() => _loadVideos());
    }

    final state = ref.watch(videoLibraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('视频库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加目录',
            onPressed: _showAddDirectoryDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _loadVideos,
          ),
        ],
      ),
      body: _buildBody(state, dirs, playerState),
    );
  }

  Widget _buildBody(VideoLibraryState state, VideoDirectoriesState dirs, PlayerState playerState) {
    if (dirs.directories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              '暂无视频目录',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '点击上方"+"添加视频目录',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (dirs.isLoading || state.isScanning) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('错误: ${state.errorMessage}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVideos,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              '目录中未找到视频文件',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 16 / 9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: state.videos.length,
      itemBuilder: (context, index) {
        final video = state.videos[index];
        final isPlaying = playerState.isVideoMode &&
            playerState.currentVideoPath == video.filePath;
        return _VideoGridItem(
          video: video,
          isPlaying: isPlaying,
          onTap: () => _playVideo(video),
        );
      },
    );
  }

  void _playVideo(VideoModel video) {
    ref.read(videoLibraryProvider.notifier).playVideo(video);
    if (mounted) {
      // 优先用构造参数（来自 router extra），fallback 到全局 provider
      final onOpenMiniWindow =
          widget.onOpenMiniWindow ?? ref.read(onShowMiniPlayerProvider);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerPage(onOpenMiniWindow: onOpenMiniWindow),
        ),
      );
    }
  }
}

class _VideoGridItem extends StatelessWidget {
  final VideoModel video;
  final bool isPlaying;
  final VoidCallback onTap;

  const _VideoGridItem({
    required this.video,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: isPlaying ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                color: Colors.grey[800],
                width: double.infinity,
                height: double.infinity,
                child: const Icon(Icons.video_file,
                    size: 48, color: Colors.white54),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                video.title ?? video.fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (isPlaying)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '正在播放',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0x4D000000),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}