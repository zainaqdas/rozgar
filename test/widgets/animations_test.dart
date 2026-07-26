import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/theme/app_theme.dart';
import 'package:rozgar/widgets/animations.dart';

void main() {
  group('ScalePress', () {
    testWidgets('triggers onTap when pressed', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ScalePress(
              onTap: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();
      expect(tapped, true);
    });

    testWidgets('does not crash without onTap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: const ScalePress(child: Text('No-op')),
          ),
        ),
      );

      await tester.tap(find.text('No-op'));
      await tester.pump();
      // Should not throw
    });
  });

  group('FadeInSlide', () {
    testWidgets('renders child after animation delay', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: FadeInSlide(
                index: 0,
                child: const Text('Animated'),
              ),
            ),
          ),
        ),
      );

      // Pump past the animation delay
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Animated'), findsOneWidget);
    });
  });

  group('StaggeredList', () {
    testWidgets('renders all children after animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StaggeredList(
                children: const [
                  Text('Item 1'),
                  Text('Item 2'),
                  Text('Item 3'),
                ],
              ),
            ),
          ),
        ),
      );

      // Pump past the animation delays
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });
  });

  group('AnimatedCard', () {
    testWidgets('renders child and responds to tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AnimatedCard(
              onTap: () => tapped = true,
              child: const Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      await tester.tap(find.text('Card Content'));
      await tester.pump();
      expect(tapped, true);
    });
  });
}
