import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      return _AuthPage(
        client: widget.client,
        onOfflineDemo: () => setState(() => _offlineDemo = true),
        onToggleTheme: widget.onToggleTheme,
      );
    }

    return CoupleGate(
      client: widget.client,
      onToggleTheme: widget.onToggleTheme,
    );
  }
}

class _AuthPage extends StatefulWidget {
  const _AuthPage({
    required this.client,
    required this.onOfflineDemo,
    required this.onToggleTheme,
  });

  final SupabaseClient client;
  final VoidCallback onOfflineDemo;
  final VoidCallback onToggleTheme;

  @override
  State<_AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<_AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (!email.contains('@') || password.length < 8) {
      setState(() => _message = 'ایمیل معتبر و رمز حداقل ۸ کاراکتری وارد کن.');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      if (_signUp) {
        final response = await widget.client.auth.signUp(
          email: email,
          password: password,
        );
        if (response.session == null && mounted) {
          setState(() {
            _message =
                'لینک تأیید برایت ایمیل شد. بعد از تأیید، از همین صفحه وارد شو.';
          });
        }
      } else {
        await widget.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = _friendlyAuthError(error.message));
    } on Object {
      if (mounted) {
        setState(() => _message =
            'ارتباط با Usly برقرار نشد. اینترنت را بررسی کن و دوباره بزن.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _anonymousSignIn() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.client.auth.signInAnonymously();
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = _friendlyAuthError(error.message));
    } on Object {
      if (mounted) {
        setState(() => _message = 'ورود سریع در دسترس نیست؛ با ایمیل وارد شو.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyAuthError(String message) {
    final normalized = message.toLowerCase();
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
                padding:
                    const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _brandMark(context),
                      const SizedBox(height: 28),
                      Text(
                        'کمتر در اپ؛\nبیشتر باهم.',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'یک آیین کوتاه و خصوصی برای پیدا کردن قرار مشترک همین هفته.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 28),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            children: [
                              SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment(
                                    value: false,
                                    label: Text('ورود'),
                                    icon: Icon(Icons.login_rounded),
                                  ),
                                  ButtonSegment(
                                    value: true,
                                    label: Text('ساخت حساب'),
                                    icon: Icon(Icons.person_add_alt_1_rounded),
                                  ),
                                ],
                                selected: {_signUp},
                                onSelectionChanged: _busy
                                    ? null
                                    : (value) =>
                                        setState(() => _signUp = value.first),
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
                                  _signUp
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'رمز عبور',
                                  prefixIcon:
                                      const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                    tooltip: 'نمایش یا پنهان کردن رمز',
                                    icon: Icon(_obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined),
                                  ),
                                ),
                              ),
                              if (_message != null) ...[
                                const SizedBox(height: 14),
                                _InlineMessage(text: _message!),
                              ],
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: _busy ? null : _submit,
                                icon: _busy
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(_signUp
                                        ? Icons.arrow_back_rounded
                                        : Icons.favorite_outline_rounded),
                                label: Text(_signUp
                                    ? 'حسابم را بساز'
                                    : 'وارد فضای دونفره شو'),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed:
                                    _busy ? null : _anonymousSignIn,
                                icon: const Icon(Icons.bolt_rounded),
                                label:
                                    const Text('ورود سریع برای تست روی این گوشی'),
                              ),
                            ],
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

  Widget _brandMark(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.secondary],
            ),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(
            Icons.all_inclusive_rounded,
            color: colors.onPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Text('Usly', style: Theme.of(context).textTheme.titleLarge),
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
            colors: [
              color.withValues(alpha: .2),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(color: colors.onErrorContainer),
      ),
    );
  }
}
