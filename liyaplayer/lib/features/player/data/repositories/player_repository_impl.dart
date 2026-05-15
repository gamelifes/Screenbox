import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:liyaplayer/features/player/domain/repositories/player_repository.dart';

/// Player仓库实现
class PlayerRepositoryImpl implements IPlayerRepository {
  final Player _player;
  late final VideoController _videoController;

  PlayerRepositoryImpl() : _player = Player() {
    _videoController = VideoController(_player);
  }

  Player get player => _player;
  VideoController get videoController => _videoController;

  @override
  Future<void> loadAudio(String path) async {
    await _player.open(Media(path));
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<Duration> getPosition() async {
    return _player.state.position;
  }

  @override
  Future<Duration?> getDuration() async {
    var duration = _player.state.duration;
    if (duration == null || duration.inMilliseconds == 0) {
      int waited = 0;
      const maxWait = 500;
      const checkInterval = 50;
      while ((duration == null || duration.inMilliseconds == 0) &&
          waited < maxWait) {
        await Future.delayed(const Duration(milliseconds: checkInterval));
        waited += checkInterval;
        duration = _player.state.duration;
      }
    }
    return duration;
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume * 100);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setRate(speed);
  }

  @override
  Stream<PlayingState> get playingState {
    return _player.stream.playing.map((isPlaying) {
      return PlayingState(
        isPlaying: isPlaying,
        position: _player.state.position,
        duration: _player.state.duration,
      );
    }).asBroadcastStream();
  }

  @override
  Stream<Duration> get positionStream {
    return _player.stream.position;
  }

  @override
  Stream<Duration?> get durationStream {
    return _player.stream.duration;
  }

  @override
  Stream<bool> get completed {
    return _player.stream.completed;
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}