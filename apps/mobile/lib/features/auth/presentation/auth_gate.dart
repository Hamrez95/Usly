import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:usly/core/theme/usly_theme.dart';
import 'package:usly/core/widgets/usly_brand.dart';
import 'package:usly/features/auth/data/supabase_auth_service.dart';
import 'package:usly/features/auth/domain/auth_service.dart';
import 'package:usly/features/couple/presentation/couple_gate.dart';
import 'package:usly/features/weekly/data/local_weekly_store.dart';
import 'package:usly/features/weekly/presentation/weekly_ritual_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    required this.client,
    required this.preferences,
    required this.onToggleTheme,
    super.key,
  });

  final SupabaseClient client;
  final SharedPreferences preferences;
  final VoidCallback onToggleTheme;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _subscription;
  Session? _session;
  bool _offlineDemo = false;

  @override
  void initState() {
    super.initState();
    _session = widget.client.auth.currentSession;
    _subscription = widget.client.auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      setState(() {
        _session = event.session;
        if (_session != null) _offlineDemo = false;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_offlineDemo) {
      return WeeklyRitualPage(
        store: LocalWeeklyStore(widget.preferences),
        onToggleTheme: widget.onToggleTheme,
      );
    }

    if (_session == null) {
      return AuthPage(
        authService: SupabaseAuthService(widget.client),
        onOfflineDemo: () => setState(() => _offlineDemo = true),
        onToggleTheme: widget.onToggleTheme,
      );
    }

    return CoupleGate(
      client: widget.client,
      isTemporaryGuest: _session?.user.isAnonymous == true,
      onToggleTheme: widget.onToggleTheme,
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({
    required this.authService,
    required this.onOfflineDemo,
    required this.onToggleTheme,
    super.key,
  });

  final AuthService authService;
  final VoidCallback onOfflineDemo;
  final VoidCallback onToggleTheme;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

enum _AuthMode { signIn, signUp }

enum _NoticeTone { success, warning, error }

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _message;
  _NoticeTone _messageTone = _NoticeTone.error;
  bool _confirmationRequired = false;
  Timer? _resendTimer;
  int _resendSeconds = 0;

  bool get _signUp => _mode == _AuthMode.signUp;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (!email.contains('@')) {
      _showMessage('یک ایمیل معتبر وارد کن.', _NoticeTone.error);
      return;
    }
    if (password.length < 8) {
      _showMessage('رمز عبور باید حداقل ۸ کاراکتر باشد.', _NoticeTone.error);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      switch (_mode) {
        case _AuthMode.signUp:
          final result = await widget.authService.signUp(
            email: email,
            password: password,
          );
          if (result == AuthSubmission.confirmationRequired && mounted) {
            setState(() {
              _confirmationRequired = true;
              _message = null;
            });
            _startResendCooldown();
          }
          break;
        case _AuthMode.signIn:
          await widget.authService.signIn(email: email, password: password);
          break;
      }
    } on AuthException catch (error) {
      _showMessage(
        _friendlyAuthError(error.message, code: error.code),
        _NoticeTone.error,
      );
    } on TimeoutException {
      _showMessage(
        'پاسخی از سرور نرسید. اینترنت را بررسی کن و دوباره امتحان کن.',
        _NoticeTone.error,
      );
    } on Object {
      _showMessage(
        'ارتباط با Usly برقرار نشد. اینترنت را بررسی کن و دوباره بزن.',
        _NoticeTone.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendConfirmation() async {
    if (_resendSeconds > 0 || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.authService.resendSignupConfirmation(
        email: _emailController.text.trim(),
      );
      _showMessage(
        'ایمیل تأیید دوباره فرستاده شد. پوشه Spam را هم ببین.',
        _NoticeTone.success,
      );
      _startResendCooldown();
    } on AuthException catch (error) {
      _showMessage(
        _friendlyAuthError(error.message, code: error.code),
        _NoticeTone.error,
      );
    } on TimeoutException {
      _showMessage(
        'ارسال ایمیل طول کشید. کمی بعد دوباره امتحان کن.',
        _NoticeTone.error,
      );
    } on Object {
      _showMessage(
        'ارسال دوباره انجام نشد. کمی بعد دوباره امتحان کن.',
        _NoticeTone.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    if (!mounted) return;
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  void _selectMode(_AuthMode mode) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _mode = mode;
      _confirmationRequired = false;
      _message = null;
    });
  }

  void _showMessage(String message, _NoticeTone tone) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _messageTone = tone;
    });
  }

  Future<void> _anonymousSignIn() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.authService.signInAnonymously();
    } on AuthException catch (error) {
      _showMessage(
        _friendlyAuthError(error.message, code: error.code),
        _NoticeTone.error,
      );
    } on TimeoutException {
      _showMessage(
        'ورود مهمان طول کشید. اینترنت را بررسی کن.',
        _NoticeTone.error,
      );
    } on Object {
      _showMessage(
        'ورود مهمان در دسترس نیست؛ با ایمیل وارد شو.',
        _NoticeTone.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmGuestSignIn() async {
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ورود مهمان فقط برای تست است',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'اگر از حساب مهمان خارج شوی یا برنامه پاک شود، ممکن است نتوانی به فضای دونفره‌ات برگردی. برای استفاده واقعی، حساب ایمیلی بساز.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('متوجه‌ام؛ موقت وارد شو'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('برگشت به ساخت حساب'),
              ),
            ],
          ),
        ),
      ),
    );
    if (accepted == true) await _anonymousSignIn();
  }

  String _friendlyAuthError(String message, {String? code}) {
    final normalized = message.toLowerCase();
    final normalizedCode = code?.toLowerCase();
    if (normalizedCode == 'email_rate_limit_exceeded' ||
        normalized.contains('rate limit')) {
      return 'تعداد ایمیل‌های درخواستی زیاد شده؛ چند دقیقه دیگر دوباره امتحان کن.';
    }
    if (normalizedCode == 'weak_password' ||
        normalized.contains('password should be')) {
      return 'این رمز عبور امن نیست؛ از حداقل ۸ کاراکتر و ترکیب حروف و عدد استفاده کن.';
    }
    if (normalizedCode == 'email_address_invalid') {
      return 'این نشانی ایمیل معتبر نیست.';
    }
    if (normalizedCode == 'signup_disabled') {
      return 'ساخت حساب موقتاً غیرفعال است؛ کمی بعد دوباره امتحان کن.';
    }
    if (normalized.contains('invalid login')) {
      return 'ایمیل یا رمز درست نیست.';
    }
    if (normalized.contains('anonymous') && normalized.contains('disabled')) {
      return 'ورود سریع در پروژه فعال نیست؛ با ایمیل وارد شو.';
    }
    if (normalized.contains('already registered')) {
      return 'این ایمیل قبلاً ثبت شده؛ حالت ورود را انتخاب کن.';
    }
    return 'ورود انجام نشد. چند لحظه بعد دوباره تلاش کن.';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pagePadding = UslySpacing.pagePadding(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            tooltip: 'تغییر روشنایی',
            icon: const Icon(Icons.contrast_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          PositionedDirectional(
            top: -90,
            end: -70,
            child: _Glow(color: colors.secondary),
          ),
          PositionedDirectional(
            bottom: -120,
            start: -80,
            child: _Glow(color: colors.primary),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  pagePadding,
                  8,
                  pagePadding,
                  32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const UslyBrandMark(),
                      const SizedBox(height: 24),
                      Text(
                        'کمتر در اپ؛\nبیشتر باهم.',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'یک آیین کوتاه و خصوصی برای پیدا کردن قرار مشترک همین هفته.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 10),
                      const Center(child: UslyCompanionScene(height: 128)),
                      const SizedBox(height: 14),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _confirmationRequired
                                ? _confirmationPanel()
                                : _authForm(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: widget.onOfflineDemo,
                        icon: const Icon(Icons.phonelink_lock_rounded),
                        label: const Text('دموی آفلاین یک‌گوشی'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'پاسخ خام تو برای همراهت نمایش داده نمی‌شود؛ فقط زمینه مشترک و پیشنهادهای امن همگام می‌شوند.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _authForm() {
    return Column(
      key: ValueKey(_mode),
      children: [
        SegmentedButton<_AuthMode>(
          segments: const [
            ButtonSegment(
              value: _AuthMode.signIn,
              label: Text('ورود'),
              icon: Icon(Icons.login_rounded),
            ),
            ButtonSegment(
              value: _AuthMode.signUp,
              label: Text('ساخت حساب'),
              icon: Icon(Icons.person_add_alt_1_rounded),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: _busy
              ? null
              : (value) => _selectMode(value.first),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _emailController,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'ایمیل',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordController,
          enabled: !_busy,
          obscureText: _obscurePassword,
          textDirection: TextDirection.ltr,
          autofillHints: [
            _signUp ? AutofillHints.newPassword : AutofillHints.password,
          ],
          decoration: InputDecoration(
            labelText: 'رمز عبور',
            helperText: _signUp ? 'حداقل ۸ کاراکتر' : null,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              tooltip: 'نمایش یا پنهان کردن رمز',
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: 14),
          _InlineMessage(text: _message!, tone: _messageTone),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _signUp
                      ? Icons.arrow_back_rounded
                      : Icons.favorite_outline_rounded,
                ),
          label: Text(_signUp ? 'حسابم را بساز' : 'وارد فضای دونفره شو'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _confirmGuestSignIn,
          icon: const Icon(Icons.science_outlined),
          label: const Text('ورود موقت مهمان برای تست'),
        ),
      ],
    );
  }

  Widget _confirmationPanel() {
    return Column(
      key: const ValueKey('confirmation-required'),
      children: [
        _AuthHeroIcon(
          icon: Icons.mark_email_unread_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 18),
        Text(
          'فقط تأیید ایمیل مانده',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'حساب ساخته شد. لینک فرستاده‌شده به ${_emailController.text.trim()} را باز کن و بعد وارد شو.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'اگر پیدایش نکردی، پوشه Spam یا Promotions را هم بررسی کن.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (_message != null) ...[
          const SizedBox(height: 14),
          _InlineMessage(text: _message!, tone: _messageTone),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _busy || _resendSeconds > 0 ? null : _resendConfirmation,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(
            _resendSeconds > 0
                ? 'ارسال دوباره تا $_resendSeconds ثانیه'
                : 'ارسال دوباره ایمیل',
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : () => _selectMode(_AuthMode.signIn),
          child: const Text('ایمیل را تأیید کردم؛ برو به ورود'),
        ),
        TextButton(
          onPressed: _busy ? null : () => _selectMode(_AuthMode.signUp),
          child: const Text('ایمیل را اشتباه وارد کردم'),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: .2), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.text, required this.tone});

  final String text;
  final _NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (tone) {
      _NoticeTone.success => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        Icons.check_circle_outline_rounded,
      ),
      _NoticeTone.warning => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
        Icons.info_outline_rounded,
      ),
      _NoticeTone.error => (
        colors.errorContainer,
        colors.onErrorContainer,
        Icons.error_outline_rounded,
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }
}

class _AuthHeroIcon extends StatelessWidget {
  const _AuthHeroIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 34),
    );
  }
}
