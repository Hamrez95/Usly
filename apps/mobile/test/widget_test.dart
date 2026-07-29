import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usly/app/usly_app.dart';
import 'package:usly/core/theme/usly_theme.dart';
import 'package:usly/features/weekly/data/local_weekly_store.dart';
import 'package:usly/features/weekly/presentation/weekly_ritual_page.dart';

void main() {
  testWidgets('starts the staged private weekly ritual', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(UslyApp(preferences: preferences));
    await tester.pumpAndSettle();

    expect(find.text('Usly'), findsOneWidget);
    expect(find.text('انرژی این هفته‌ات چطور است؟'), findsOneWidget);
    expect(find.text('پاسخ خصوصی تو'), findsOneWidget);
    expect(find.text('بعدی'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);
  });

  testWidgets('reset asks for confirmation and keeps state when cancelled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(UslyApp(preferences: preferences));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('شروع دوباره این هفته'));
    await tester.pumpAndSettle();

    expect(find.text('این هفته از نو شروع شود؟'), findsOneWidget);
    await tester.tap(find.text('نه، نگهش دار'));
    await tester.pumpAndSettle();
    expect(find.text('انرژی این هفته‌ات چطور است؟'), findsOneWidget);
  });

  testWidgets('weekly flow fits a narrow phone at 200 percent text scale', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MaterialApp(
        theme: UslyTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(2),
          ),
          child: WeeklyRitualPage(
            store: LocalWeeklyStore(preferences),
            onToggleTheme: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('انرژی این هفته‌ات چطور است؟'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly flow renders in dark mode', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MaterialApp(
        theme: UslyTheme.dark(),
        home: WeeklyRitualPage(
          store: LocalWeeklyStore(preferences),
          onToggleTheme: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('کمتر در اپ؛ بیشتر باهم.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
