import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/theme/app_theme.dart';
import 'package:rozgar/widgets/error_states.dart';

void main() {
  group('ErrorState', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ErrorState(
              title: 'Oops!',
              message: 'Something went wrong.',
            ),
          ),
        ),
      );

      expect(find.text('Oops!'), findsOneWidget);
      expect(find.text('Something went wrong.'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry is provided', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ErrorState(
              title: 'Error',
              message: 'Test',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Try Again'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      expect(retried, true);
    });

    testWidgets('does not show retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: const ErrorState(),
          ),
        ),
      );

      expect(find.text('Try Again'), findsNothing);
    });
  });

  group('EmptyState', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: const EmptyState(
              title: 'Nothing Here',
              message: 'Check back later.',
            ),
          ),
        ),
      );

      expect(find.text('Nothing Here'), findsOneWidget);
      expect(find.text('Check back later.'), findsOneWidget);
    });

    testWidgets('shows action button when provided', (tester) async {
      bool actioned = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: EmptyState(
              title: 'Empty',
              message: 'Nothing yet.',
              actionLabel: 'Create One',
              onAction: () => actioned = true,
            ),
          ),
        ),
      );

      expect(find.text('Create One'), findsOneWidget);
      await tester.tap(find.text('Create One'));
      expect(actioned, true);
    });
  });

  group('OfflineBanner', () {
    testWidgets('renders offline message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OfflineBanner()),
        ),
      );

      expect(find.textContaining('offline'), findsOneWidget);
    });
  });

  group('InlineRetry', () {
    testWidgets('renders label and retry button', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: InlineRetry(
              label: 'Failed to load',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Failed to load'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, true);
    });
  });
}
