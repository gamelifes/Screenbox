import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liyaplayer/features/library/presentation/widgets/empty_library_view.dart';

void main() {
  group('EmptyLibraryView', () {
    testWidgets('should display empty state message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyLibraryView(
              onAddDirectory: () {},
            ),
          ),
        ),
      );

      expect(find.text('你的音乐库是空的'), findsOneWidget);
      expect(find.text('添加目录'), findsOneWidget);
    });

    testWidgets('should call onAddDirectory when button pressed',
        (tester) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyLibraryView(
              onAddDirectory: () => called = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('添加目录'));
      expect(called, true);
    });
  });
}
