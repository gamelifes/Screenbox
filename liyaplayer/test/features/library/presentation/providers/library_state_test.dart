import 'package:flutter_test/flutter_test.dart';
import 'package:liyaplayer/features/library/presentation/providers/library_state.dart';

void main() {
  group('LibraryState', () {
    test('should have correct initial state', () {
      final state = LibraryState.initial();
      expect(state.songs, isEmpty);
      expect(state.isLoading, false);
    });
  });
}
