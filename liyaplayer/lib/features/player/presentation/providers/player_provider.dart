import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liyaplayer/features/player/domain/repositories/player_repository.dart';
import 'package:liyaplayer/features/player/data/repositories/player_repository_impl.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Player 状态枚举
///
/// 状态转换图：
/// ```
///  idle ──loadAudio()──> loading ──完成──> stopped
///                                       │
///                         play() <──────┘
///                           │
///                           ▼
///                       playing ◄──────┐
///                           │          │
///                      pause()      play()
///                           │          │
///                           ▼          │
///                        paused ───────┘
///                           │
///                      stop() ◄────┐
///                           │      │
///                           ▼      │
///                        stopped ──┘
/// ```
///
/// 状态说明：
/// - **idle**: 初始状态，无媒体加载
/// - **loading**: 正在加载媒体文件
/// - **stopped**: 媒体已加载，等待播放
/// - **playing**: 正在播放
/// - **paused**: 暂停
/// - **error**: 错误状态
enum PlayerStatus {
  /// 初始状态，无媒体加载
  idle,

  /// 正在加载媒体文件
  loading,

  /// 媒体已加载，等待播放
  stopped,

  /// 正在播放
  playing,

  /// 暂停
  paused,

  /// 错误状态
  error,
}

/// 循环模式枚举
enum LoopMode {
  off,
  all,
  one,
}

/// Player 状态数据类
class PlayerState {
  final PlayerStatus status;
  final Duration position;
  final Duration? duration;
  final String? errorMessage;
  final String? currentSongTitle;
  final String? currentSongArtist;
  final String? currentSongAlbum;
  final String? currentSongPath;
  final String? albumArtPath; // 专辑封面路径
  final List<PlaylistItem> queue;
  final int queueIndex;
  final LoopMode loopMode; // 循环模式
  final bool isShuffleOn; // 随机播放
  final double volume; // 音量 0.0-1.0
  final double speed; // 播放速率 0.5-2.0
  final bool isVideoMode; // 是否为视频播放模式
  final String? currentVideoPath; // 当前视频路径

  const PlayerState({
    required this.status,
    required this.position,
    this.duration,
    this.errorMessage,
    this.currentSongTitle,
    this.currentSongArtist,
    this.currentSongAlbum,
    this.currentSongPath,
    this.albumArtPath,
    this.queue = const [],
    this.queueIndex = -1,
    this.loopMode = LoopMode.off,
    this.isShuffleOn = false,
    this.volume = 1.0,
    this.speed = 1.0,
    this.isVideoMode = false,
    this.currentVideoPath,
  });

  /// 是否可以播放（stopped 或 paused 状态）
  bool get canPlay =>
      status == PlayerStatus.stopped || status == PlayerStatus.paused;

  /// 是否有媒体加载
  bool get hasMedia => currentSongPath != null;

  /// 是否正在播放
  bool get isPlaying => status == PlayerStatus.playing;

  /// 是否有错误
  bool get hasError => status == PlayerStatus.error;

  PlayerState copyWith({
    PlayerStatus? status,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    String? currentSongTitle,
    String? currentSongArtist,
    String? currentSongAlbum,
    String? currentSongPath,
    String? albumArtPath,
    List<PlaylistItem>? queue,
    int? queueIndex,
    LoopMode? loopMode,
    bool? isShuffleOn,
    double? volume,
    double? speed,
    bool? isVideoMode,
    String? currentVideoPath,
  }) {
    return PlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
      currentSongTitle: currentSongTitle ?? this.currentSongTitle,
      currentSongArtist: currentSongArtist ?? this.currentSongArtist,
      currentSongAlbum: currentSongAlbum ?? this.currentSongAlbum,
      currentSongPath: currentSongPath ?? this.currentSongPath,
      albumArtPath: albumArtPath ?? this.albumArtPath,
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
      loopMode: loopMode ?? this.loopMode,
      isShuffleOn: isShuffleOn ?? this.isShuffleOn,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      isVideoMode: isVideoMode ?? this.isVideoMode,
      currentVideoPath: currentVideoPath ?? this.currentVideoPath,
    );
  }

  static const initial = PlayerState(
    status: PlayerStatus.idle,
    position: Duration.zero,
    duration: null,
    errorMessage: null,
    currentSongTitle: null,
    currentSongArtist: null,
    currentSongAlbum: null,
    currentSongPath: null,
    albumArtPath: null,
    queue: const [],
    queueIndex: -1,
    loopMode: LoopMode.off,
    isShuffleOn: false,
    volume: 1.0,
    isVideoMode: false,
    currentVideoPath: null,
  );
}

/// 播放列表项
class PlaylistItem {
  final String path;
  final String title;
  final String? artist;
  final String? album;
  final bool isVideo; // 是否为视频文件

  const PlaylistItem({
    required this.path,
    required this.title,
    this.artist,
    this.album,
    this.isVideo = false,
  });
}

/// Player 业务逻辑 Notifier
///
/// 职责：
/// - 管理 PlayerState 单一状态源
/// - 处理所有状态转换（通过方法调用）
/// - 订阅 stream 事件，但只在安全时更新状态
///
/// 状态转换规则：
/// 1. `loading` 和 `stopped` 状态下，stream listener 不更新播放状态
/// 2. 所有播放控制通过显式方法（play/pause/stop）进行
/// 3. stream 事件只更新 position，不改变播放状态
/// 4. 播放完毕时根据循环模式处理
class PlayerNotifier extends StateNotifier<PlayerState> {
  final IPlayerRepository _repository;
  StreamSubscription<PlayingState>? _playingStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<bool>? _completedSubscription;

  /// 外部注册的监听器回调列表
  final List<void Function(PlayerState previous, PlayerState next)>
      _externalListeners = [];

  PlayerNotifier(this._repository) : super(PlayerState.initial) {
    _initStreamListeners();
  }

  /// 获取 VideoController，用于视频渲染
  VideoController? get videoController {
    if (_repository is PlayerRepositoryImpl) {
      return (_repository as PlayerRepositoryImpl).videoController;
    }
    return null;
  }

  /// 添加外部监听器
  void addExternalListener(
      void Function(PlayerState previous, PlayerState next) listener) {
    _externalListeners.add(listener);
    debugPrint(
        '[PlayerNotifier] addExternalListener, total listeners: ${_externalListeners.length}');
  }

  /// 移除外部监听器
  void removeExternalListener(
      void Function(PlayerState previous, PlayerState next) listener) {
    _externalListeners.remove(listener);
  }

  @override
  set state(PlayerState newState) {
    final oldState = state;
    // debugPrint(
    //     '[PlayerNotifier] state setter called: ${oldState.status} -> ${newState.status}');
    super.state = newState;
    // 通知外部监听器
    for (final listener in _externalListeners) {
      try {
        listener(oldState, newState);
      } catch (e) {
        debugPrint('[PlayerNotifier] external listener exception: $e');
      }
    }
  }

  void _initStreamListeners() {
    // 监听播放状态流
    _playingStateSubscription = _repository.playingState.listen((playingState) {
      // 规则 1: loading 和 stopped 状态下不响应播放状态变化
      if (state.status == PlayerStatus.loading ||
          state.status == PlayerStatus.stopped) {
        return;
      }
      // 只更新 position，status 由显式方法控制
      state = state.copyWith(position: playingState.position);
    });

    // 监听位置更新流
    if (_repository is PlayerRepositoryImpl) {
      final repo = _repository as PlayerRepositoryImpl;

      _positionSubscription = repo.positionStream.listen((position) {
        state = state.copyWith(position: position);
      });

      _durationSubscription = repo.durationStream.listen((duration) {
        // 只在从未获取过有效 duration 时更新
        if (state.duration == null &&
            duration != null &&
            duration.inMilliseconds > 0) {
          state = state.copyWith(duration: duration);
        }
      });

      // 监听播放完成流
      _completedSubscription = repo.completed.listen((completed) {
        if (completed) {
          _onTrackCompleted();
        }
      });
    }
  }

  /// 处理曲目播放完毕
  void _onTrackCompleted() {
    if (state.queue.isEmpty) {
      // 无队列：停止
      stop();
      return;
    }

    switch (state.loopMode) {
      case LoopMode.one:
        // 单曲循环：重新播放当前
        _repository.seek(Duration.zero).then((_) => _repository.play());
        break;
      case LoopMode.all:
        // 列表循环：播放下一首（会自动循环到开头）
        next();
        break;
      case LoopMode.off:
        // 不循环：检查是否是最后一首
        if (state.queueIndex >= state.queue.length - 1) {
          // 最后一首：停止并重置
          stop();
        } else {
          // 不是最后一首：自动播放下一首
          next();
        }
        break;
    }
  }

  /// 加载音频文件
  ///
  /// 设置状态为 loading → stopped，等待外部调用 play() 开始播放
  Future<void> loadAudio(String path,
      {String? title, String? artist, String? album, bool? isVideo}) async {
    final videoExtensions = ['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm'];
    final ext = path.toLowerCase();
    final detectedIsVideo = isVideo ?? videoExtensions.any((e) => ext.endsWith(e));

    state = state.copyWith(
      status: PlayerStatus.loading,
      duration: null,
      position: Duration.zero,
      isVideoMode: detectedIsVideo,
      currentVideoPath: detectedIsVideo ? path : null,
    );
    try {
      await _repository.loadAudio(path);
      state = state.copyWith(
        status: PlayerStatus.stopped,
        currentSongTitle: title,
        currentSongArtist: artist,
        currentSongAlbum: album,
        currentSongPath: path,
      );
    } catch (e) {
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 播放或继续播放
  ///
  /// - stopped 状态：重新加载并播放
  /// - paused 状态：继续播放
  Future<void> play() async {
    if (!state.hasMedia) return;

    try {
      if (state.status == PlayerStatus.stopped) {
        // stopped 需要重新加载媒体
        state = state.copyWith(status: PlayerStatus.loading);
        await _repository.loadAudio(state.currentSongPath!);
        await _repository.play();
        // 更新位置和时长
        final position = await _repository.getPosition();
        final duration = await _repository.getDuration();
        state = state.copyWith(
          status: PlayerStatus.playing,
          position: position,
          duration: duration,
        );
      } else if (state.status == PlayerStatus.paused) {
        // paused 直接继续
        await _repository.play();
        state = state.copyWith(status: PlayerStatus.playing);
      }
    } catch (e) {
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    debugPrint(
        '[PlayerNotifier] pause() START, current status: ${state.status}, isPlaying: ${state.isPlaying}, hasMedia: ${state.hasMedia}');
    final oldStatus = state.status;
    if (state.status != PlayerStatus.playing) {
      debugPrint(
          '[PlayerNotifier] pause() EARLY RETURN - status is ${state.status}, not playing');
      return;
    }
    try {
      debugPrint('[PlayerNotifier] pause() calling _repository.pause()');
      await _repository.pause();
      debugPrint('[PlayerNotifier] pause() _repository.pause() COMPLETED');
      debugPrint(
          '[PlayerNotifier] pause() calling state.copyWith(status: PlayerStatus.paused)');
      state = state.copyWith(status: PlayerStatus.paused);
      debugPrint(
          '[PlayerNotifier] pause() state updated, new status: ${state.status}, new isPlaying: ${state.isPlaying}');
      debugPrint('[PlayerNotifier] pause() completed');
    } catch (e, st) {
      debugPrint('[PlayerNotifier] pause() EXCEPTION: $e\n$st');
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 停止播放
  Future<void> stop() async {
    if (state.status == PlayerStatus.idle || state.status == PlayerStatus.error)
      return;
    try {
      await _repository.stop();
      state = state.copyWith(
        status: PlayerStatus.stopped,
        position: Duration.zero,
      );
    } catch (e) {
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 跳转播放位置
  Future<void> seek(Duration position) async {
    try {
      await _repository.seek(position);
      state = state.copyWith(position: position);
    } catch (e) {
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 设置播放队列并播放指定索引的歌曲
  Future<void> setQueue(List<PlaylistItem> items, int startIndex) async {
    if (items.isEmpty || startIndex < 0 || startIndex >= items.length) return;
    final item = items[startIndex];
    state = state.copyWith(queue: items, queueIndex: startIndex);
    await loadAudio(
      item.path,
      title: item.title,
      artist: item.artist,
      album: item.album,
    );
    await play();
  }

  /// 上一曲
  Future<void> previous() async {
    if (state.queue.isEmpty) return;

    int newIndex;
    if (state.isShuffleOn) {
      // 随机模式：随机选择一首不同的歌曲
      newIndex = _getRandomIndex(exclude: state.queueIndex);
    } else if (state.loopMode == LoopMode.all && state.queueIndex <= 0) {
      // 列表循环且在第一首：跳到最后一首
      newIndex = state.queue.length - 1;
    } else {
      newIndex = state.queueIndex - 1;
      if (newIndex < 0) {
        // 非循环模式：重新播放当前
        await seek(Duration.zero);
        await play();
        return;
      }
    }

    final item = state.queue[newIndex];
    state = state.copyWith(queueIndex: newIndex);
    await loadAudio(item.path,
        title: item.title, artist: item.artist, album: item.album);
    await play();
  }

  /// 下一曲
  Future<void> next() async {
    if (state.queue.isEmpty) return;

    int newIndex;
    if (state.isShuffleOn) {
      // 随机模式：随机选择一首不同的歌曲
      newIndex = _getRandomIndex(exclude: state.queueIndex);
    } else if (state.loopMode == LoopMode.all &&
        state.queueIndex >= state.queue.length - 1) {
      // 列表循环且在最后一首：跳到第一首
      newIndex = 0;
    } else {
      newIndex = state.queueIndex + 1;
      if (newIndex >= state.queue.length) {
        // 非循环模式：停止
        await stop();
        return;
      }
    }

    final item = state.queue[newIndex];
    state = state.copyWith(queueIndex: newIndex);
    await loadAudio(item.path,
        title: item.title, artist: item.artist, album: item.album);
    await play();
  }

  /// 获取随机索引（排除指定项）
  int _getRandomIndex({required int exclude}) {
    if (state.queue.length <= 1) return exclude;
    int index;
    do {
      index = DateTime.now().millisecondsSinceEpoch % state.queue.length;
    } while (index == exclude && state.queue.length > 1);
    return index;
  }

  /// 切换循环模式: off -> all -> one -> off
  void toggleLoop() {
    final nextMode = switch (state.loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    state = state.copyWith(loopMode: nextMode);
  }

  /// 切换随机播放
  void toggleShuffle() {
    state = state.copyWith(isShuffleOn: !state.isShuffleOn);
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    state = state.copyWith(volume: clampedVolume);
    await _repository.setVolume(clampedVolume);
  }

  /// 设置播放速率
  Future<void> setSpeed(double speed) async {
    final clampedSpeed = speed.clamp(0.5, 2.0);
    state = state.copyWith(speed: clampedSpeed);
    await _repository.setSpeed(clampedSpeed);
  }

  /// 设置专辑封面路径
  void setAlbumArt(String? path) {
    state = state.copyWith(albumArtPath: path);
  }

  /// 加载视频文件
  ///
  /// 设置状态为 loading → stopped，等待外部调用 play() 开始播放
  Future<void> loadVideo(String path,
      {String? title, String? artist, String? album}) async {
    state = state.copyWith(
      status: PlayerStatus.loading,
      duration: null,
      position: Duration.zero,
      isVideoMode: true,
      currentVideoPath: path,
    );
    try {
      await _repository.loadAudio(path);
      state = state.copyWith(
        status: PlayerStatus.stopped,
        currentSongTitle: title,
        currentSongArtist: artist,
        currentSongAlbum: album,
        currentSongPath: path,
      );
    } catch (e) {
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 切换到音频模式
  void switchToAudioMode() {
    state = state.copyWith(isVideoMode: false);
  }

  @override
  void dispose() {
    _playingStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completedSubscription?.cancel();
    super.dispose();
  }
}

/// IPlayerRepository Provider
final playerRepositoryProvider = Provider<IPlayerRepository>((ref) {
  return PlayerRepositoryImpl();
});

/// Player StateNotifierProvider
final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  final repository = ref.watch(playerRepositoryProvider);
  return PlayerNotifier(repository);
});
