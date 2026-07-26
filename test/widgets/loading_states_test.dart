import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/theme/app_theme.dart';
import 'package:rozgar/widgets/loading_states.dart';

void main() {
  group('LoadingOverlay', () {
    testWidgets('renders spinner without message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Stack(
              children: const [LoadingOverlay()],
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders spinner with message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Stack(
              children: const [LoadingOverlay(message: 'Loading...')],
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });
  });

  group('ShimmerLoading', () {
    testWidgets('renders animated container', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: const ShimmerLoading(width: 100, height: 20),
          ),
        ),
      );

      // Should be present and rendering
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });
  });

  group('ShimmerCard', () {
    testWidgets('renders card placeholders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: const ShimmerCard(),
          ),
        ),
      );

      expect(find.byType(ShimmerCard), findsOneWidget);
    });
  });

  group('ShimmerJobList', () {
    testWidgets('renders specified number of items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: const ShimmerJobList(itemCount: 3),
          ),
        ),
      );

      expect(find.byType(ShimmerCard), findsNWidgets(3));
    });
  });

  group('ShimmerProfileCard', () {
    testWidgets('renders profile card placeholder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: const ShimmerProfileCard(),
          ),
        ),
      );

      expect(find.byType(ShimmerProfileCard), findsOneWidget);
    });
  });
}
