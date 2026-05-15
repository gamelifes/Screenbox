import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liyaplayer/features/player/presentation/providers/player_provider.dart';
import 'package:liyaplayer/features/player/domain/repositories/player_repository.dart';

void main() {
  group('PlayerProvider - 状态管理测试', () {
    test('playerProvider应该是一个StateNotifierProvider', () {
      expect(playerProvider,
          isA<StateNotifierProvider<PlayerNotifier, PlayerState>>());
    });

    test('playerRepositoryProvider应该是一个Provider', () {
      expect(playerRepositoryProvider, isA<Provider<IPlayerRepository>>());
    });

    test('PlayerState应该有正确的初始状态', () {
      final state = PlayerState.initial;

      expect(state.status, equals(PlayerStatus.idle));
      expect(state.position, equals(Duration.zero));
      expect(state.duration, isNull);
      expect(state.errorMessage, isNull);
    });

    test('PlayerState.copyWith应该正确更新状态', () {
      final state = PlayerState.initial;
      final newState = state.copyWith(
        status: PlayerStatus.playing,
        position: const Duration(seconds: 30),
        duration: const Duration(minutes: 3),
      );

      expect(newState.status, equals(PlayerStatus.playing));
      expect(newState.position, equals(const Duration(seconds: 30)));
      expect(newState.duration, equals(const Duration(minutes: 3)));
    });

    test('PlayerStatus枚举应该有所有状态', () {
      expect(PlayerStatus.values, contains(PlayerStatus.idle));
      expect(PlayerStatus.values, contains(PlayerStatus.loading));
      expect(PlayerStatus.values, contains(PlayerStatus.playing));
      expect(PlayerStatus.values, contains(PlayerStatus.paused));
      expect(PlayerStatus.values, contains(PlayerStatus.stopped));
      expect(PlayerStatus.values, contains(PlayerStatus.error));
    });
  });
}
