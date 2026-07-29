import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:usly/core/theme/usly_theme.dart';
import 'package:usly/core/widgets/usly_brand.dart';
import 'package:usly/features/couple/data/couple_repository.dart';
import 'package:usly/features/weekly/presentation/online_weekly_page.dart';

class CoupleGate extends StatefulWidget {
  const CoupleGate({
    required this.client,
    required this.onToggleTheme,
    this.isTemporaryGuest = false,
    super.key,
  });

  final SupabaseClient client;
  final VoidCallback onToggleTheme;
  final bool isTemporaryGuest;

  @override
  State<CoupleGate> createState() => _CoupleGateState();
}

class _CoupleGateState extends State<CoupleGate> {
  late final CoupleRepository _repository;
  CoupleState? _state;
  PairingInvite? _invite;
  Object? _error;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _repository = CoupleRepository(widget.client);
    _load();
    _poller = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_state?.isPending == true) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _state = null;
        _error = null;
      });
    }
    try {
      final state = await _repository.loadState();
      if (!mounted) return;
      setState(() {
        _state = state;
        _error = null;
      });
    } on Object catch (error) {
      if (!mounted || silent) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ConnectionError(onRetry: _load);
    }
    if (_state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_state!.isActive) {
      return OnlineWeeklyPage(
        client: widget.client,
        coupleId: _state!.coupleId!,
        isTemporaryGuest: widget.isTemporaryGuest,
        onToggleTheme: widget.onToggleTheme,
      );
    }
    return _PairingPage(
      client: widget.client,
      repository: _repository,
      state: _state!,
      invite: _invite,
      isTemporaryGuest: widget.isTemporaryGuest,
      onInviteChanged: (invite) => setState(() => _invite = invite),
      onStateChanged: _load,
      onToggleTheme: widget.onToggleTheme,
    );
  }
}

class _PairingPage extends StatefulWidget {
  const _PairingPage({
    required this.client,
    required this.repository,
    required this.state,
    required this.invite,
    required this.onInviteChanged,
    required this.onStateChanged,
    required this.onToggleTheme,
    required this.isTemporaryGuest,
  });

  final SupabaseClient client;
  final CoupleRepository repository;
  final CoupleState state;
  final PairingInvite? invite;
  final ValueChanged<PairingInvite?> onInviteChanged;
  final VoidCallback onStateChanged;
  final VoidCallback onToggleTheme;
  final bool isTemporaryGuest;

  @override
  State<_PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends State<_PairingPage> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _isCreator =>
      widget.state.createdBy == widget.client.auth.currentUser?.id;

  Future<void> _createOrRefresh() async {
    if (!widget.state.hasCouple && _nameController.text.trim().isEmpty) {
      setState(() => _message = 'اسمی که همراهت می‌شناسد وارد کن.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final invite = widget.state.hasCouple
          ? await widget.repository.refreshPairingCode()
          : await widget.repository.startPairing(_nameController.text);
      widget.onInviteChanged(invite);
      widget.onStateChanged();
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _message = _pairingError(error.message));
    } on Object {
      if (mounted) {
        setState(
          () => _message =
              'ساخت کد انجام نشد. اتصال اینترنت را بررسی کن و دوباره بزن.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    if (_nameController.text.trim().isEmpty ||
        _codeController.text.trim().length < 6) {
      setState(() => _message = 'نام و کد اتصال را کامل وارد کن.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.repository.acceptPairing(
        code: _codeController.text,
        displayName: _nameController.text,
      );
      widget.onStateChanged();
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _message = _pairingError(error.message));
    } on Object {
      if (mounted) {
        setState(
          () => _message =
              'اتصال انجام نشد. اینترنت را بررسی کن و دوباره تلاش کن.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _pairingError(String message) {
    if (message.contains('invalid_or_expired')) {
      return 'این کد منقضی یا قبلاً استفاده شده است.';
    }
    if (message.contains('already_paired')) {
      return 'این حساب همین حالا به یک همراه وصل است.';
    }
    if (message.contains('cannot_pair_with_self')) {
      return 'کد را باید همراهت روی گوشی خودش وارد کند.';
    }
    return 'اتصال امن کامل نشد. دوباره تلاش کن.';
  }

  @override
  Widget build(BuildContext context) {
    final invite = widget.invite;
    return Scaffold(
      appBar: AppBar(
        title: const UslyBrandMark(size: 36),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            tooltip: 'تغییر روشنایی',
            icon: const Icon(Icons.contrast_rounded),
          ),
          IconButton(
            onPressed: _busy ? null : () => widget.client.auth.signOut(),
            tooltip: 'خروج از حساب',
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsetsDirectional.fromSTEB(
              UslySpacing.pagePadding(context),
              16,
              UslySpacing.pagePadding(context),
              40,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  if (widget.isTemporaryGuest) ...[
                    const UslyGuestNotice(),
                    const SizedBox(height: 14),
                  ],
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: widget.state.isPending && _isCreator
                        ? _PendingPairingCard(
                            key: const ValueKey('pending'),
                            invite: invite,
                            busy: _busy,
                            onRefresh: _createOrRefresh,
                          )
                        : _NewPairingCard(
                            key: const ValueKey('new'),
                            nameController: _nameController,
                            codeController: _codeController,
                            busy: _busy,
                            message: _message,
                            onCreate: _createOrRefresh,
                            onJoin: _join,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingPairingCard extends StatelessWidget {
  const _PendingPairingCard({
    required this.invite,
    required this.busy,
    required this.onRefresh,
    super.key,
  });

  final PairingInvite? invite;
  final bool busy;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const UslyCompanionScene(
              height: 132,
              caption: 'یک کد کوتاه، فقط برای اتصال امن شما دو نفر',
            ),
            const SizedBox(height: 12),
            Text(
              'همراهت را دعوت کن',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'کد فقط ۲۰ دقیقه معتبر است و بعد از یک‌بار استفاده باطل می‌شود.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (invite == null)
              FilledButton.icon(
                onPressed: busy ? null : onRefresh,
                icon: const Icon(Icons.key_rounded),
                label: const Text('تولید کد اتصال'),
              )
            else ...[
              Semantics(
                label: 'کد اتصال ${invite!.code}',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: SelectableText(
                    invite!.code,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.displaySmall?.copyWith(letterSpacing: 4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        await Clipboard.setData(
                          ClipboardData(text: invite!.code),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('کد کپی شد.')),
                        );
                      },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('کپی کد'),
              ),
              TextButton(
                onPressed: busy ? null : onRefresh,
                child: const Text('ساخت کد تازه'),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sync_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'وقتی همراهت کد را وارد کند، این صفحه خودکار باز می‌شود.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewPairingCard extends StatelessWidget {
  const _NewPairingCard({
    required this.nameController,
    required this.codeController,
    required this.busy,
    required this.message,
    required this.onCreate,
    required this.onJoin,
    super.key,
  });

  final TextEditingController nameController;
  final TextEditingController codeController;
  final bool busy;
  final String? message;
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: UslyCompanionScene(height: 124)),
            const SizedBox(height: 12),
            Text(
              'دو گوشی، یک قرار',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'یکی از شما کد می‌سازد و نفر دوم همان کد را وارد می‌کند.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),
            TextField(
              controller: nameController,
              enabled: !busy,
              maxLength: 40,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'اسمی که همراهت می‌شناسد',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: busy ? null : onCreate,
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('من کد اتصال می‌سازم'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('یا'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            TextField(
              controller: codeController,
              enabled: !busy,
              textCapitalization: TextCapitalization.characters,
              textDirection: TextDirection.ltr,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'کد همراهت',
                prefixIcon: Icon(Icons.key_rounded),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : onJoin,
              icon: const Icon(Icons.favorite_rounded),
              label: const Text('به همراه من وصل شو'),
            ),
            if (message != null) ...[
              const SizedBox(height: 14),
              Text(
                message!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConnectionError extends StatelessWidget {
  const _ConnectionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 44),
              const SizedBox(height: 16),
              Text(
                'ارتباط با فضای دونفره قطع شد',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'اطلاعات خصوصی پاک نشده؛ فقط دوباره اتصال را امتحان کن.',
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تلاش دوباره'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
