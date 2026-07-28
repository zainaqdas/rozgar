import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rozgar/widgets/bottom_nav.dart';
import 'package:rozgar/app.dart';
import 'package:rozgar/theme/app_theme.dart';

void main() {
  testWidgets('renders all provided tabs', (tester) async {
    final tabs = [AppView.home, AppView.chat, AppView.profile];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RozgarBottomNav(
              activeTab: AppView.home,
              tabs: tabs,
              onTabChange: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(RozgarBottomNav), findsOneWidget);
  });

  testWidgets('calls onTabChange when tab is tapped', (tester) async {
    final tabs = [AppView.home, AppView.chat, AppView.profile];
    AppView? tapped;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RozgarBottomNav(
              activeTab: AppView.home,
              tabs: tabs,
              onTabChange: (v) => tapped = v,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Chat'));
    expect(tapped, AppView.chat);
  });
}
