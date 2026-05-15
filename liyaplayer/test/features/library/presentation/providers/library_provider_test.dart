import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liyaplayer/features/library/presentation/providers/library_provider.dart';

void main() {
  group('LibraryProvider', () {
    test('should provide initial state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(libraryProvider);
      expect(state.isLoading, false);
    });
  });
}
