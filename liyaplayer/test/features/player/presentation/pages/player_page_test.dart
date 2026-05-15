import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liyaplayer/features/player/presentation/pages/player_page.dart';
import 'package:liyaplayer/features/player/presentation/widgets/player_controls.dart';

void main() {
  // These tests require native media_kit libraries (libmpv-2.dll) and
  // MediaKit.ensureInitialized() to be called before creating providers.
  // They are integration tests that need special environment setup.

  group('PlayerPage - 集成测试', skip: true, () {
    testWidgets('PlayerPage应该显示标题', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlayerPage(),
          ),
        ),
      );

      expect(find.text('音频播放器'), findsOneWidget);
    });

    testWidgets('PlayerPage应该包含PlayerControls', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlayerPage(),
          ),
        ),
      );

      expect(find.byType(PlayerControls), findsOneWidget);
    });

    testWidgets('PlayerPage应该显示就绪状态', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlayerPage(),
          ),
        ),
      );

      expect(find.text('就绪'), findsOneWidget);
    });

    testWidgets('PlayerPage应该有播放控制按钮', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlayerPage(),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.skip_previous), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    testWidgets('PlayerPage应该使用Column布局', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlayerPage(),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('PlayerPage应该使用Scaffold', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlayerPage(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
