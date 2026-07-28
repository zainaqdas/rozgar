import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rozgar/widgets/header.dart';
import 'package:rozgar/providers/providers.dart';
import 'package:rozgar/theme/app_theme.dart';
import 'package:rozgar/utils/translations.dart';

Widget buildHeader() {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: RozgarHeader(
          onOpenNotifications: () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders app name', (tester) async {
    await tester.pumpWidget(buildHeader());
    expect(find.text(AppTranslations.t('appName', LanguageOption.en)),
        findsOneWidget);
  });

  testWidgets('shows notification bell', (tester) async {
    await tester.pumpWidget(buildHeader());
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
  });

  testWidgets('shows language toggle button', (tester) async {
    await tester.pumpWidget(buildHeader());
    expect(find.text('اردو'), findsOneWidget);
  });

  testWidgets('language toggle switches language', (tester) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return RozgarHeader(onOpenNotifications: () {});
            },
          ),
        ),
      ),
    ));

    expect(capturedRef.read(settingsProvider).language, LanguageOption.en);
    await tester.tap(find.text('اردو'));
    await tester.pumpAndSettle();
    expect(capturedRef.read(settingsProvider).language, LanguageOption.ur);
  });

  testWidgets('calls onOpenNotifications when bell tapped', (tester) async {
    bool opened = false;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: RozgarHeader(
            onOpenNotifications: () => opened = true,
          ),
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    expect(opened, true);
  });

  testWidgets('no unread badge when no notifications', (tester) async {
    await tester.pumpWidget(buildHeader());
    expect(find.text('0'), findsNothing);
  });
}
