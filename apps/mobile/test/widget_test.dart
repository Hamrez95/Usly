import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usly/app/usly_app.dart';

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

  testWidgets('reset asks for confirmation and keeps state when cancelled', (tester) async {
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
}
