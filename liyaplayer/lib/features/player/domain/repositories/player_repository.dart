/// Player播放状态
class PlayingState {
  final bool isPlaying;
  final Duration position;
  final Duration? duration;

  const PlayingState({
    required this.isPlaying,
    required this.position,
    this.duration,
  });
}

/// Player仓库抽象接口
/// 定义音频播放器核心操作的抽象
abstract class IPlayerRepository {
  /// 加载音频文件
  Future<void> loadAudio(String path);

  /// 开始播放
  Future<void> play();

  /// 暂停播放
  Future<void> pause();

  /// 停止播放
  Future<void> stop();

  /// 跳转播放位置
  Future<void> seek(Duration position);

  /// 获取当前播放位置
  Future<Duration> getPosition();

  /// 获取音频总时长
  Future<Duration?> getDuration();

  /// 设置音量 (0.0 - 1.0)
  Future<void> setVolume(double volume);

  /// 设置播放速率 (0.5 - 2.0)
  Future<void> setSpeed(double speed);

  /// 播放状态流
  Stream<PlayingState> get playingState;

  /// 位置更新流
  Stream<Duration> get positionStream;

  /// 时长更新流
  Stream<Duration?> get durationStream;

  /// 播放完成流 (当一首歌曲播放完毕时触发)
  Stream<bool> get completed;
}
