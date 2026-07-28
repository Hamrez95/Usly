import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usly/main.dart';

void main() {
  testWidgets('shows the initial private weekly sync', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const UslyApp());
    await tester.pumpAndSettle();

    expect(find.text('Usly'), findsOneWidget);
    expect(find.text('حال این هفته'), findsOneWidget);
    expect(find.text('پاسخ خصوصی نفر اول'), findsOneWidget);
    expect(find.text('ثبت و قفل پاسخ خصوصی'), findsOneWidget);
  });
}
