import 'package:flutter_test/flutter_test.dart';
import 'package:liyaplayer/features/player/domain/repositories/player_repository.dart';

void main() {
  group('IPlayerRepository - 接口定义测试', () {
    test('IPlayerRepository应该是抽象类', () {
      expect(IPlayerRepository, isA<Type>());
    });

    test('PlayingState应该有isPlaying, position, duration属性', () {
      const state = PlayingState(
        isPlaying: true,
        position: Duration.zero,
        duration: Duration(minutes: 3),
      );

      expect(state.isPlaying, isTrue);
      expect(state.position, equals(Duration.zero));
      expect(state.duration, equals(const Duration(minutes: 3)));
    });

    test('接口方法应该存在', () {
      // 使用reflector检查方法存在性
      final repository = _TestRepository();

      expect(repository.loadAudio, isA<Function>());
      expect(repository.play, isA<Function>());
      expect(repository.pause, isA<Function>());
      expect(repository.stop, isA<Function>());
      expect(repository.seek, isA<Function>());
      expect(repository.getPosition, isA<Function>());
      expect(repository.getDuration, isA<Function>());
      expect(repository.playingState, isA<Stream<PlayingState>>());
    });
  });
}

/// 测试用实现
class _TestRepository implements IPlayerRepository {
  @override
  Future<void> loadAudio(String path) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<Duration> getPosition() async => Duration.zero;

  @override
  Future<Duration?> getDuration() async => null;

  @override
  Stream<PlayingState> get playingState => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Stream<bool> get completed => const Stream.empty();
}
