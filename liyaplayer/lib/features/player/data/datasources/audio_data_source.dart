import 'package:media_kit/media_kit.dart';

/// 音频数据源
/// 封装Player并提供基础播放控制
class AudioDataSource {
  final Player _player = Player();

  AudioDataSource();

  Future<Media> loadAudioSource(String path) async {
    try {
      final media = Media(path);
      await _player.open(media);
      return media;
    } catch (e) {
      throw Exception('Failed to load audio source: $e');
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// 释放资源
  Future<void> dispose() async {
    await _player.dispose();
  }
}
