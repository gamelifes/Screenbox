import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liyaplayer/features/player/presentation/widgets/player_controls.dart';

void main() {
  // These tests require native media_kit libraries (libmpv-2.dll) and
  // MediaKit.ensureInitialized() to be called before creating providers.
  // They are integration tests that need special environment setup.

  group('PlayerControls - UI组件测试', skip: true, () {
    testWidgets('PlayerControls应该显示播放按钮', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PlayerControls(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('PlayerControls应该显示上一曲和下一曲按钮', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PlayerControls(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.skip_previous), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
    });

    testWidgets('PlayerControls应该显示停止按钮', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PlayerControls(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    testWidgets('PlayerControls应该是一个Row布局', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PlayerControls(),
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('PlayerControls应该包含多个IconButton', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PlayerControls(),
            ),
          ),
        ),
      );

      // skip_previous, play_arrow, skip_next, stop = 4 buttons
      expect(find.byType(IconButton), findsNWidgets(4));
    });
  });
}
