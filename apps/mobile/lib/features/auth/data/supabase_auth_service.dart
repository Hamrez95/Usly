import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:usly/features/auth/domain/auth_service.dart';

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(
    this._client, {
    Duration timeout = const Duration(seconds: 20),
  }) : _timeout = timeout;

  final SupabaseClient _client;
  final Duration _timeout;

  @override
  Future<AuthSubmission> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth
        .signUp(email: email, password: password)
        .timeout(_timeout);
    return response.session == null
        ? AuthSubmission.confirmationRequired
        : AuthSubmission.signedIn;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth
        .signInWithPassword(email: email, password: password)
        .timeout(_timeout);
  }

  @override
  Future<void> signInAnonymously() async {
    await _client.auth.signInAnonymously().timeout(_timeout);
  }

  @override
  Future<void> resendSignupConfirmation({required String email}) async {
    await _client.auth
        .resend(type: OtpType.signup, email: email)
        .timeout(_timeout);
  }
}
