import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usly/features/auth/domain/auth_service.dart';
import 'package:usly/features/auth/presentation/auth_gate.dart';

void main() {
  testWidgets('shows a dedicated confirmation state after email sign-up', (
    tester,
  ) async {
    final auth = _FakeAuthService(
      signUpResult: AuthSubmission.confirmationRequired,
    );

    await tester.pumpWidget(_testApp(auth));
    await _tapVisible(tester, find.text('ساخت حساب'));
    await tester.enterText(
      find.byType(TextField).at(0),
      'hamidreza@example.com',
    );
    await tester.enterText(find.byType(TextField).at(1), 'secure-pass-123');
    await _tapVisible(tester, find.text('حسابم را بساز'));

    expect(auth.signUpCalls, 1);
    expect(find.text('فقط تأیید ایمیل مانده'), findsOneWidget);
    expect(find.textContaining('hamidreza@example.com'), findsOneWidget);
    expect(find.textContaining('ارسال دوباره تا'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('invalid input stays local and explains the problem', (
    tester,
  ) async {
    final auth = _FakeAuthService();

    await tester.pumpWidget(_testApp(auth));
    await tester.enterText(find.byType(TextField).at(0), 'not-an-email');
    await tester.enterText(find.byType(TextField).at(1), 'short');
    await _tapVisible(tester, find.text('وارد فضای دونفره شو'));

    expect(auth.signInCalls, 0);
    expect(find.text('یک ایمیل معتبر وارد کن.'), findsOneWidget);
  });

  testWidgets('guest mode warns before creating a temporary account', (
    tester,
  ) async {
    final auth = _FakeAuthService();

    await tester.pumpWidget(_testApp(auth));
    await _tapVisible(tester, find.text('ورود موقت مهمان برای تست'));
    await tester.pumpAndSettle();

    expect(find.text('ورود مهمان فقط برای تست است'), findsOneWidget);
    expect(auth.anonymousCalls, 0);

    await tester.tap(find.text('متوجه‌ام؛ موقت وارد شو'));
    await tester.pumpAndSettle();
    expect(auth.anonymousCalls, 1);
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

Widget _testApp(AuthService auth) {
  return MaterialApp(
    home: AuthPage(
      authService: auth,
      onOfflineDemo: () {},
      onToggleTheme: () {},
    ),
  );
}

class _FakeAuthService implements AuthService {
  _FakeAuthService({this.signUpResult = AuthSubmission.signedIn});

  final AuthSubmission signUpResult;
  int signUpCalls = 0;
  int signInCalls = 0;
  int anonymousCalls = 0;
  int resendCalls = 0;

  @override
  Future<AuthSubmission> signUp({
    required String email,
    required String password,
  }) async {
    signUpCalls += 1;
    return signUpResult;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls += 1;
  }

  @override
  Future<void> signInAnonymously() async {
    anonymousCalls += 1;
  }

  @override
  Future<void> resendSignupConfirmation({required String email}) async {
    resendCalls += 1;
  }
}
