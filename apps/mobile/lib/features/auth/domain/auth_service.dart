enum AuthSubmission { signedIn, confirmationRequired }

abstract interface class AuthService {
  Future<AuthSubmission> signUp({
    required String email,
    required String password,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> signInAnonymously();

  Future<void> resendSignupConfirmation({required String email});
}
