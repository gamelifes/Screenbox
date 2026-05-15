import 'package:flutter_test/flutter_test.dart';
import 'package:liyaplayer/features/player/data/repositories/player_repository_impl.dart';
import 'package:liyaplayer/features/player/domain/repositories/player_repository.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Must initialize MediaKit before using any media_kit API
  MediaKit.ensureInitialized();

  group('PlayerRepositoryImpl - 仓库实现测试', () {
    late PlayerRepositoryImpl repository;

    setUp(() {
      repository = PlayerRepositoryImpl();
    });

    test('PlayerRepositoryImpl应该实现IPlayerRepository', () {
      expect(repository, isA<IPlayerRepository>());
    });

    test('所有方法应该存在且可调用', () {
      expect(repository.loadAudio, isA<Function>());
      expect(repository.play, isA<Function>());
      expect(repository.pause, isA<Function>());
      expect(repository.stop, isA<Function>());
      expect(repository.seek, isA<Function>());
      expect(repository.getPosition, isA<Function>());
      expect(repository.getDuration, isA<Function>());
      expect(repository.playingState, isA<Stream<PlayingState>>());
    });

    test('getPosition应该返回Future<Duration>', () async {
      final result = repository.getPosition();
      expect(result, isA<Future<Duration>>());
    });

    test('getDuration应该返回Future<Duration?>', () async {
      final result = repository.getDuration();
      expect(result, isA<Future<Duration?>>());
    });
  });
}
