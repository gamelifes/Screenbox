import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_enums.dart' as enums;
import 'media_item.dart';

/// 播放器状态实体
class PlaybackStatus extends Equatable {
  final enums.PlayerState playbackState; // 当前播放状态
  final MediaItem? currentMedia; // 当前播放的媒体
  final Duration? position; // 当前位置
  final Duration? bufferedPosition; // 缓冲位置
  final Duration? duration; // 总时长
  final double volume; // 音量 0.0 - 1.0
  final double playbackSpeed; // 播放速度
  final enums.PlaybackMode playbackMode; // 播放模式
  final bool isShuffleOn; // 随机播放开关
  final List<MediaItem> queue; // 播放队列
  final int queueIndex; // 当前播放索引

  const PlaybackStatus({
    required this.playbackState,
    this.currentMedia,
    this.position,
    this.bufferedPosition,
    this.duration,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.playbackMode = enums.PlaybackMode.sequential,
    this.isShuffleOn = false,
    this.queue = const [],
    this.queueIndex = -1,
  });

  @override
  List<Object?> get props => [
        playbackState,
        currentMedia,
        position,
        bufferedPosition,
        duration,
        volume,
        playbackSpeed,
        playbackMode,
        isShuffleOn,
        queue,
        queueIndex,
      ];

  bool get isPlaying => playbackState == enums.PlayerState.playing;
  bool get isPaused => playbackState == enums.PlayerState.paused;
  bool get isStopped => playbackState == enums.PlayerState.stopped;
  bool get hasMedia => currentMedia != null;

  double? get progress {
    if (duration == null || duration!.inMilliseconds == 0) return null;
    return position!.inMilliseconds / duration!.inMilliseconds;
  }

  double? get bufferedProgress {
    if (duration == null || duration!.inMilliseconds == 0) return null;
    return bufferedPosition!.inMilliseconds / duration!.inMilliseconds;
  }

  PlaybackStatus copyWith({
    enums.PlayerState? playbackState,
    MediaItem? currentMedia,
    Duration? position,
    Duration? bufferedPosition,
    Duration? duration,
    double? volume,
    double? playbackSpeed,
    enums.PlaybackMode? playbackMode,
    bool? isShuffleOn,
    List<MediaItem>? queue,
    int? queueIndex,
  }) {
    return PlaybackStatus(
      playbackState: playbackState ?? this.playbackState,
      currentMedia: currentMedia ?? this.currentMedia,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      playbackMode: playbackMode ?? this.playbackMode,
      isShuffleOn: isShuffleOn ?? this.isShuffleOn,
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
    );
  }
}

/// 向后兼容别名
typedef PlayerState = PlaybackStatus;
