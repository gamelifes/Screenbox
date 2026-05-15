import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:liyaplayer/features/library/data/models/models.dart';
import 'package:liyaplayer/features/library/presentation/providers/library_provider.dart';
import 'package:liyaplayer/features/library/presentation/providers/library_state.dart';
import 'package:liyaplayer/features/library/presentation/widgets/album_grid_view.dart';
import 'package:liyaplayer/features/library/presentation/widgets/artist_list_view.dart';
import 'package:liyaplayer/features/library/presentation/widgets/empty_library_view.dart';
import 'package:liyaplayer/features/library/presentation/widgets/scan_progress_view.dart';
import 'package:liyaplayer/features/library/presentation/widgets/song_list_view_with_sections.dart';
import 'package:liyaplayer/features/library/presentation/pages/artist_detail_page.dart';
import 'package:liyaplayer/features/library/presentation/pages/album_detail_page.dart';
import 'package:liyaplayer/features/player/presentation/providers/player_provider.dart';

/// Main library page with tabs
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Load initial data
    Future.microtask(() => ref.read(libraryProvider.notifier).loadLibrary());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = LibraryTab.values[_tabController.index];
    ref.read(libraryProvider.notifier).setTab(tab);
  }

  void _showAddDirectoryDialog() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      await ref.read(libraryProvider.notifier).addDirectory(result);
    }
  }

  void _navigateToArtist(ArtistModel artist) {
    final songs = ref.read(libraryProvider).getSongsByArtist(artist.id);
    final albums = ref.read(libraryProvider).getAlbumsByArtist(artist.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtistDetailPage(
          artist: artist,
          songs: songs,
          albums: albums,
          currentlyPlayingId: null, // TODO: get from player
          onSongTap: (song) => _playSong(song),
          onPlayTap: (song) => _playSong(song),
          onAlbumTap: (album) => _navigateToAlbum(album),
        ),
      ),
    );
  }

  void _navigateToAlbum(AlbumModel album) {
    final songs = ref.read(libraryProvider).getSongsByAlbum(album.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlbumDetailPage(
          album: album,
          songs: songs,
          currentlyPlayingId: null, // TODO: get from player
          onSongTap: (song) => _playSong(song),
          onPlayTap: (song) => _playSong(song),
        ),
      ),
    );
  }

  void _playSong(SongModel song) async {
    try {
      final playerNotifier = ref.read(playerProvider.notifier);
      final libraryState = ref.read(libraryProvider);

      // 创建播放队列
      final items = libraryState.songs
          .map((s) => PlaylistItem(
                path: s.filePath,
                title: s.title ?? '未知标题',
                artist: s.artist,
                album: s.album,
              ))
          .toList();

      // 找到当前歌曲的索引
      final index = libraryState.songs.indexWhere((s) => s.id == song.id);

      await playerNotifier.setQueue(items, index >= 0 ? index : 0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('播放失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryProvider);

    // Show scan progress if scanning
    if (state.isScanning && state.scanProgress != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('音乐库')),
        body: ScanProgressView(
          progress: state.scanProgress!,
          onCancel: () => ref.read(libraryProvider.notifier).cancelScan(),
        ),
      );
    }

    // Show empty state if no directories
    if (state.directories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('音乐库')),
        body: EmptyLibraryView(
          onAddDirectory: _showAddDirectoryDialog,
        ),
      );
    }

    // Show loading
    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('音乐库')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Main UI with tabs
    return Scaffold(
      appBar: AppBar(
        title: const Text('音乐库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加目录',
            onPressed: _showAddDirectoryDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '歌曲'),
            Tab(text: '艺术家'),
            Tab(text: '专辑'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
// Songs tab
          SongListViewWithSections(
            songs: state.songs,
            currentlyPlayingId: null, // TODO: get from player
            onSongTap: _playSong,
            onPlayTap: _playSong,
          ),
          // Artists tab
          state.artists.isEmpty
              ? const Center(child: Text('暂无艺术家'))
              : ArtistListView(
                  artists: state.artists,
                  onArtistTap: _navigateToArtist,
                ),
          // Albums tab
          state.albums.isEmpty
              ? const Center(child: Text('暂无专辑'))
              : AlbumGridView(
                  albums: state.albums,
                  onAlbumTap: _navigateToAlbum,
                ),
        ],
      ),
    );
  }
}
