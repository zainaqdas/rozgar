import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/app.dart';
import 'package:rozgar/providers/app_state.dart';
import 'package:rozgar/theme/app_theme.dart';

void main() {
  testWidgets('Rozgar app smoke test', (WidgetTester tester) async {
    final appState = AppState();
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: RozgarShell(appState: appState),
      ),
    );

    // App shell should be in the widget tree
    expect(find.byType(RozgarShell), findsOneWidget);
    appState.dispose();
  });
}
