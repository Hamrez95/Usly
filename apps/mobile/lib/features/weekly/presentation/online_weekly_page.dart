import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:usly/core/theme/usly_theme.dart';
import 'package:usly/features/weekly/data/online_weekly_repository.dart';
import 'package:usly/features/weekly/domain/weekly_models.dart';

class OnlineWeeklyPage extends StatefulWidget {
  const OnlineWeeklyPage({
    required this.client,
    required this.coupleId,
    required this.onToggleTheme,
    super.key,
  });

  final SupabaseClient client;
  final String coupleId;
  final VoidCallback onToggleTheme;

  @override
  State<OnlineWeeklyPage> createState() => _OnlineWeeklyPageState();
}

class _OnlineWeeklyPageState extends State<OnlineWeeklyPage> {
  late final OnlineWeeklyRepository _repository;
  OnlineWeeklyState? _state;
  WeeklyDraft _draft = const WeeklyDraft();
  int _questionIndex = 0;
  bool _busy = false;
  String? _error;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _repository = OnlineWeeklyRepository(widget.client);
    _load();
    _poller = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _load({
    bool silent = false,
    bool force = false,
  }) async {
    if (_busy && !force) return;
    try {
      final state = await _repository.load(widget.coupleId);
      if (!mounted) return;
      setState(() {
        _state = state;
        _error = null;
      });
    } on Object {
      if (!mounted || silent) return;
      setState(() => _error =
          'همگام‌سازی انجام نشد. پاسخ‌ها پاک نشده‌اند؛ دوباره تلاش کن.');
    }
  }

  Future<void> _next() async {
    HapticFeedback.selectionClick();
    if (_questionIndex < 4) {
      setState(() => _questionIndex += 1);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repository.submit(_draft);
      await _load(force: true);
      HapticFeedback.mediumImpact();
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error.message));
    } on Object {
      if (mounted) {
        setState(() =>
            _error = 'ثبت امن انجام نشد. اینترنت را بررسی کن و دوباره بزن.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _vote(String optionId) async {
    final syncId = _state?.syncId;
    if (syncId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repository.vote(syncId: syncId, optionId: optionId);
      await _load(force: true);
      HapticFeedback.mediumImpact();
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error.message));
    } on Object {
      if (mounted) {
        setState(() =>
            _error = 'رأی ثبت نشد. اینترنت را بررسی کن و دوباره بزن.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(String message) {
    if (message.contains('active_couple_required')) {
      return 'اتصال زوج کامل نیست. یک‌بار از حساب خارج و دوباره وارد شو.';
    }
    if (message.contains('not_accessible')) {
      return 'این چرخه دیگر در دسترس نیست؛ صفحه را تازه کن.';
    }
    return 'عملیات امن کامل نشد. دوباره تلاش کن.';
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return Scaffold(
      appBar: AppBar(
        title: const _OnlineWordmark(),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            tooltip: 'تغییر روشنایی',
            icon: const Icon(Icons.contrast_rounded),
          ),
          IconButton(
            onPressed: _busy ? null : () => _load(),
            tooltip: 'همگام‌سازی',
            icon: const Icon(Icons.sync_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') widget.client.auth.signOut();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout_rounded),
                  title: Text('خروج از حساب'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _OnlineAmbientBackground()),
          SafeArea(
            top: false,
            child: RefreshIndicator(
              onRefresh: () => _load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 40),
                children: [
                  _OnlineHeader(state: state),
                  const SizedBox(height: 22),
                  if (_error != null) ...[
                    _ErrorBanner(
                      message: _error!,
                      onRetry: () => _load(),
                    ),
                    const SizedBox(height: 14),
                  ],
                  AnimatedSwitcher(
                    duration: UslyMotion.standard(context),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0, .035),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: _content(state),
                  ),
                  const SizedBox(height: 24),
                  const _OnlinePrivacySeal(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(OnlineWeeklyState? state) {
    if (state == null) {
      return const Card(
        key: ValueKey('loading'),
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (!state.hasSubmitted) {
      return _OnlineQuestionCard(
        key: ValueKey('question-$_questionIndex'),
        questionIndex: _questionIndex,
        draft: _draft,
        busy: _busy,
        onChanged: (draft) => setState(() => _draft = draft),
        onNext: _next,
      );
    }
    if (state.waitingForPartner) {
      return const _WaitingCard(
        key: ValueKey('waiting-response'),
        icon: Icons.hourglass_top_rounded,
        title: 'نوبت همراهت است',
        body:
            'پاسخ تو امن ثبت شد. وقتی همراهت چرخه‌اش را کامل کند، پیشنهادها خودکار اینجا می‌آیند.',
      );
    }
    if (state.hasMatch) {
      final selected = state.options.firstWhere(
        (option) => option.id == state.selectedOptionId,
      );
      return _OnlineMatchCard(
        key: const ValueKey('match'),
        experience: selected,
      );
    }
    if (state.waitingForPartnerVote) {
      return const _WaitingCard(
        key: ValueKey('waiting-vote'),
        icon: Icons.how_to_vote_rounded,
        title: 'رأی تو ثبت شد',
        body:
            'انتخابت برای همراهت نمایش داده نمی‌شود. منتظر رأی او می‌مانیم.',
      );
    }
    if (state.noMatch) {
      return _OnlineVotingCard(
        key: const ValueKey('revote'),
        options: state.options,
        busy: _busy,
        title: 'این بار یکی نشد؛ دوباره انتخاب کن',
        subtitle:
            'هیچ‌کس نمی‌فهمد دیگری چه رأیی داده. یک گزینه تازه انتخاب کنید تا به نقطه مشترک برسید.',
        onVote: _vote,
      );
    }
    if (state.readyToVote || state.options.isNotEmpty) {
      return _OnlineVotingCard(
        key: const ValueKey('vote'),
        options: state.options,
        busy: _busy,
        title: 'کدام قرار بیشتر می‌چسبد؟',
        subtitle:
            'پیشنهادها از زمینه مشترک ساخته شده‌اند، نه از نمایش پاسخ خام.',
        onVote: _vote,
      );
    }
    return const _WaitingCard(
      key: ValueKey('preparing'),
      icon: Icons.auto_awesome_rounded,
      title: 'داریم زمینه مشترک را می‌سازیم',
      body: 'چند ثانیه دیگر پیشنهادهای دونفره آماده می‌شوند.',
    );
  }
}

class _OnlineWordmark extends StatelessWidget {
  const _OnlineWordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.all_inclusive_rounded,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Text('Usly', style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _OnlineHeader extends StatelessWidget {
  const _OnlineHeader({required this.state});

  final OnlineWeeklyState? state;

  @override
  Widget build(BuildContext context) {
    final responseCount = state?.responseCount ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatusOrb(
              active: state?.hasSubmitted == true,
              label: 'تو',
            ),
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: .22),
              ),
            ),
            _StatusOrb(
              active: responseCount == 2,
              label: 'همراهت',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'قرار این هفته‌تان',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 6),
        Text(
          'دو پاسخ خصوصی؛ یک زمینه مشترک؛ یک انتخاب واقعی.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _StatusOrb extends StatelessWidget {
  const _StatusOrb({required this.active, required this.label});

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = active ? colors.primary : colors.outline;
    return Row(
      children: [
        AnimatedContainer(
          duration: UslyMotion.quick(context),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            active ? Icons.check_rounded : Icons.person_outline_rounded,
            color: active ? colors.onPrimary : color,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

class _OnlineQuestionCard extends StatelessWidget {
  const _OnlineQuestionCard({
    required this.questionIndex,
    required this.draft,
    required this.busy,
    required this.onChanged,
    required this.onNext,
    super.key,
  });

  final int questionIndex;
  final WeeklyDraft draft;
  final bool busy;
  final ValueChanged<WeeklyDraft> onChanged;
  final VoidCallback onNext;

  static const _titles = [
    'انرژی این هفته‌ات چطور است؟',
    'از وقت دونفره بیشتر چه می‌خواهی؟',
    'چقدر وقت دارید؟',
    'بودجه راحت این هفته چقدر است؟',
    'کدام فضا بیشتر می‌چسبد؟',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Chip(
                  avatar: Icon(Icons.lock_outline_rounded, size: 16),
                  label: Text('پاسخ خصوصی تو'),
                ),
                const Spacer(),
                Text(
                  '${questionIndex + 1} / ۵',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _titles[questionIndex],
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _question(context),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: busy ? null : onNext,
              icon: Icon(
                questionIndex == 4
                    ? Icons.lock_rounded
                    : Icons.arrow_back_rounded,
              ),
              label: Text(
                questionIndex == 4 ? 'ثبت امن پاسخ من' : 'بعدی',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _question(BuildContext context) {
    switch (questionIndex) {
      case 0:
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(5, (index) {
            final value = index + 1;
            return ChoiceChip(
              label: Text('$value'),
              avatar: Icon(
                value <= 2
                    ? Icons.battery_1_bar_rounded
                    : value == 3
                        ? Icons.battery_4_bar_rounded
                        : Icons.battery_full_rounded,
              ),
              selected: draft.energy == value,
              onSelected: (_) =>
                  onChanged(draft.copyWith(energy: value)),
            );
          }),
        );
      case 1:
        return _choiceWrap<WeeklyNeed>(
          values: WeeklyNeed.values,
          selected: draft.need,
          label: _needLabel,
          onSelected: (value) =>
              onChanged(draft.copyWith(need: value)),
        );
      case 2:
        return _choiceWrap<DurationBand>(
          values: DurationBand.values,
          selected: draft.duration,
          label: (value) => switch (value) {
            DurationBand.short => 'کوتاه',
            DurationBand.medium => 'حدود یک ساعت',
            DurationBand.long => 'بیشتر',
          },
          onSelected: (value) =>
              onChanged(draft.copyWith(duration: value)),
        );
      case 3:
        return _choiceWrap<BudgetBand>(
          values: BudgetBand.values,
          selected: draft.budget,
          label: (value) => switch (value) {
            BudgetBand.free => 'رایگان',
            BudgetBand.low => 'کم',
            BudgetBand.medium => 'متوسط',
          },
          onSelected: (value) =>
              onChanged(draft.copyWith(budget: value)),
        );
      default:
        return _choiceWrap<SettingBand>(
          values: SettingBand.values,
          selected: draft.setting,
          label: (value) => switch (value) {
            SettingBand.home => 'خانه',
            SettingBand.outside => 'بیرون',
            SettingBand.either => 'فرقی ندارد',
          },
          onSelected: (value) =>
              onChanged(draft.copyWith(setting: value)),
        );
    }
  }

  Widget _choiceWrap<T>({
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required ValueChanged<T> onSelected,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values
          .map(
            (value) => ChoiceChip(
              label: Text(label(value)),
              selected: value == selected,
              onSelected: (_) => onSelected(value),
            ),
          )
          .toList(),
    );
  }

  String _needLabel(WeeklyNeed value) => switch (value) {
        WeeklyNeed.calm => 'آرامش',
        WeeklyNeed.fun => 'تفریح',
        WeeklyNeed.conversation => 'گفت‌وگو',
        WeeklyNeed.novelty => 'تازگی',
        WeeklyNeed.support => 'حمایت',
        WeeklyNeed.play => 'بازی',
      };
}

class _OnlineVotingCard extends StatelessWidget {
  const _OnlineVotingCard({
    required this.options,
    required this.busy,
    required this.title,
    required this.subtitle,
    required this.onVote,
    super.key,
  });

  final List<OnlineExperience> options;
  final bool busy;
  final String title;
  final String subtitle;
  final ValueChanged<String> onVote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        ...options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: busy ? null : () => onVote(option.id),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(label: Text(_kindLabel(option.kind))),
                          const Spacer(),
                          const Icon(Icons.arrow_back_rounded),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        option.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(
                            icon: Icons.schedule_rounded,
                            label: option.duration,
                          ),
                          _MetaChip(
                            icon: Icons.payments_outlined,
                            label: option.budget,
                          ),
                          _MetaChip(
                            icon: Icons.place_outlined,
                            label: option.setting,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(option.reason),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _kindLabel(String kind) => switch (kind) {
        'easy' => 'آسان',
        'balanced' => 'متعادل',
        _ => 'متفاوت',
      };
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 5),
          Text(label),
        ],
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .94, end: 1),
              duration: UslyMotion.reveal(context),
              curve: Curves.easeOutBack,
              builder: (_, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Icon(icon, size: 48),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _OnlineMatchCard extends StatelessWidget {
  const _OnlineMatchCard({
    required this.experience,
    super.key,
  });

  final OnlineExperience experience;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: .7, end: 1),
                duration: UslyMotion.reveal(context),
                curve: Curves.elasticOut,
                builder: (_, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.secondary],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: colors.onPrimary,
                    size: 38,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'روی یک قرار رسیدید!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              experience.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(experience.instructions),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.schedule_rounded,
                  label: experience.duration,
                ),
                _MetaChip(
                  icon: Icons.payments_outlined,
                  label: experience.budget,
                ),
                _MetaChip(
                  icon: Icons.place_outlined,
                  label: experience.setting,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          IconButton(
            onPressed: onRetry,
            tooltip: 'تلاش دوباره',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _OnlinePrivacySeal extends StatelessWidget {
  const _OnlinePrivacySeal();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.shield_outlined, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'پاسخ‌ها و رأی‌های خام فقط برای صاحب همان حساب قابل خواندن‌اند؛ همراهت فقط نتیجه مشترک را می‌بیند.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _OnlineAmbientBackground extends StatelessWidget {
  const _OnlineAmbientBackground();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const AlignmentDirectional(.8, -.9),
          radius: 1.2,
          colors: [
            colors.secondary.withValues(alpha: .14),
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
