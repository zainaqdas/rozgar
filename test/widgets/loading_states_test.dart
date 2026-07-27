import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/widgets/loading_states.dart';
import 'package:rozgar/theme/app_theme.dart';

void main() {
  testWidgets('ShimmerLoading renders with default size', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: ShimmerLoading()),
      ),
    );
    expect(find.byType(ShimmerLoading), findsOneWidget);
  });

  testWidgets('ShimmerCard renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: ShimmerCard()),
      ),
    );
    expect(find.byType(ShimmerCard), findsOneWidget);
  });

  testWidgets('LoadingOverlay renders with message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: LoadingOverlay(message: 'Loading...')),
      ),
    );
    expect(find.text('Loading...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('LoadingOverlay renders without message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: LoadingOverlay()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ShimmerJobList renders correct number of items', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: ShimmerJobList(itemCount: 2)),
      ),
    );
    expect(find.byType(ShimmerCard), findsNWidgets(2));
  });

  testWidgets('ShimmerProfileCard renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: ShimmerProfileCard()),
      ),
    );
    expect(find.byType(ShimmerProfileCard), findsOneWidget);
  });
}
