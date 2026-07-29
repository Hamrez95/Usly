import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:usly/core/theme/usly_theme.dart';
import 'package:usly/core/widgets/usly_brand.dart';
import 'package:usly/features/weekly/data/local_weekly_store.dart';
import 'package:usly/features/weekly/domain/weekly_models.dart';

class WeeklyRitualPage extends StatefulWidget {
  const WeeklyRitualPage({
    required this.store,
    required this.onToggleTheme,
    super.key,
  });

  final LocalWeeklyStore store;
  final VoidCallback onToggleTheme;

  @override
  State<WeeklyRitualPage> createState() => _WeeklyRitualPageState();
}

class _WeeklyRitualPageState extends State<WeeklyRitualPage> {
  late WeeklySnapshot _state;

  @override
  void initState() {
    super.initState();
    _state = widget.store.load();
  }

  String get _partnerLabel => _state.partner == 0 ? 'تو' : 'همراهت';
  WeeklyDraft get _draft => _state.drafts[_state.partner];

  void _replace({
    List<WeeklyDraft>? drafts,
    Set<int>? submitted,
    Map<int, int>? votes,
    int? partner,
    int? questionIndex,
    bool? revealSeen,
    int? variation,
    int? selectedId,
    bool clearSelection = false,
  }) {
    setState(() {
      _state = WeeklySnapshot(
        drafts: drafts ?? _state.drafts,
        submitted: submitted ?? _state.submitted,
        votes: votes ?? _state.votes,
        partner: partner ?? _state.partner,
        questionIndex: questionIndex ?? _state.questionIndex,
        revealSeen: revealSeen ?? _state.revealSeen,
        variation: variation ?? _state.variation,
        selectedId: clearSelection ? null : (selectedId ?? _state.selectedId),
      );
    });
    widget.store.save(_state);
  }

  void _updateDraft(WeeklyDraft draft) {
    final drafts = [..._state.drafts]..[_state.partner] = draft;
    _replace(drafts: drafts);
  }

  Future<void> _nextQuestion() async {
    HapticFeedback.selectionClick();
    if (_state.questionIndex < 4) {
      _replace(questionIndex: _state.questionIndex + 1);
      return;
    }
    final submitted = {..._state.submitted, _state.partner};
    final nextPartner = submitted.length == 1 ? 1 - _state.partner : 0;
    _replace(
      submitted: submitted,
      partner: nextPartner,
      questionIndex: 0,
      votes: const {},
      revealSeen: false,
      clearSelection: true,
    );
    await _showHandoff(
      submitted.length == 1 ? 'حالا نوبت همراهت است' : 'هر دو پاسخ آماده‌اند',
      submitted.length == 1
          ? 'صفحه کاملاً پوشیده شده؛ گوشی را با خیال راحت تحویل بده.'
          : 'پاسخ‌های خام نمایش داده نمی‌شوند. فقط زمینه مشترک ساخته می‌شود.',
    );
  }

  Future<void> _vote(int id) async {
    HapticFeedback.mediumImpact();
    final votes = {..._state.votes, _state.partner: id};
    final nextPartner = votes.length == 1 ? 1 - _state.partner : _state.partner;
    _replace(votes: votes, partner: nextPartner);
    if (votes.length == 1) {
      await _showHandoff(
        'رأی خصوصی ثبت شد',
        'گزینه‌ای که انتخاب کردی نمایش داده نمی‌شود. گوشی را به همراهت بده.',
      );
    } else if (votes[0] == votes[1]) {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _showHandoff(String title, String body) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: UslyMotion.standard(context),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: _HandoffScreen(title: title, body: body),
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.restart_alt_rounded),
        title: const Text('این هفته از نو شروع شود؟'),
        content: const Text(
          'فقط پاسخ‌ها، رأی‌ها و انتخاب همین هفته پاک می‌شود. تنظیمات اپ باقی می‌ماند.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('نه، نگهش دار'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('شروع دوباره'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.store.reset();
    if (!mounted) return;
    setState(() => _state = WeeklySnapshot.initial());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('چرخه این هفته از نو شروع شد.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = !_state.bothSubmitted
        ? _SyncPanel(
            key: ValueKey('sync-${_state.partner}-${_state.questionIndex}'),
            partnerLabel: _partnerLabel,
            questionIndex: _state.questionIndex,
            draft: _draft,
            submittedCount: _state.submitted.length,
            onChanged: _updateDraft,
            onNext: _nextQuestion,
          )
        : !_state.revealSeen
            ? _RevealPanel(
                key: const ValueKey('reveal'),
                aligned: _state.drafts[0].need == _state.drafts[1].need,
                onContinue: () => _replace(revealSeen: true),
              )
            : !_state.bothVoted
                ? _VotingPanel(
                    key: ValueKey('vote-${_state.partner}-${_state.variation}'),
                    partnerLabel: _partnerLabel,
                    options: recommend(_state),
                    onVote: _vote,
                  )
                : _state.hasMatch
                    ? _MatchPanel(
                        key: const ValueKey('match'),
                        experience: recommend(
                          _state,
                        ).firstWhere((item) => item.id == _state.votes[0]),
                        selected: _state.selectedId != null,
                        onSelect: () => _replace(selectedId: _state.votes[0]),
                      )
                    : _NoMatchPanel(
                        key: const ValueKey('no-match'),
                        onRevote: () => _replace(votes: const {}, partner: 0),
                        onRefresh: () => _replace(
                          votes: const {},
                          partner: 0,
                          variation: _state.variation + 1,
                        ),
                      );

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
            onPressed: _confirmReset,
            tooltip: 'شروع دوباره این هفته',
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          SafeArea(
            top: false,
            child: ListView(
              padding: EdgeInsetsDirectional.fromSTEB(
                UslySpacing.pagePadding(context),
                8,
                UslySpacing.pagePadding(context),
                40,
              ),
              children: [
                _CouplePulseHeader(state: _state),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: UslyMotion.standard(context),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, .04),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: content,
                ),
                const SizedBox(height: 32),
                const _PrivacySeal(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CouplePulseHeader extends StatelessWidget {
  const _CouplePulseHeader({required this.state});

  final WeeklySnapshot state;

  @override
  Widget build(BuildContext context) {
    final step = !state.bothSubmitted
        ? state.submitted.length
        : !state.revealSeen
            ? 2
            : !state.bothVoted
                ? 3
                : 4;
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label: 'پیشرفت آیین هفتگی، مرحله ${step + 1} از ۵',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PulseDot(active: state.submitted.contains(0), label: 'تو'),
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: colors.primary.withValues(alpha: .24),
                ),
              ),
              _PulseDot(active: state.submitted.contains(1), label: 'همراهت'),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              duration: UslyMotion.standard(context),
              tween: Tween(begin: 0, end: (step + 1) / 5),
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: colors.primary.withValues(alpha: .10),
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'کمتر در اپ؛ بیشتر باهم.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 6),
          Text(
            'یک هماهنگی کوتاه برای یک قرار واقعی در همین هفته.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.active, required this.label});

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;
    return Row(
      children: [
        AnimatedContainer(
          duration: UslyMotion.quick(context),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: active ? 1 : .12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            active ? Icons.check_rounded : Icons.person_outline_rounded,
            size: 17,
            color: active ? Theme.of(context).colorScheme.onPrimary : color,
          ),
        ),
        const SizedBox(width: 7),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

class _SyncPanel extends StatelessWidget {
  const _SyncPanel({
    required this.partnerLabel,
    required this.questionIndex,
    required this.draft,
    required this.submittedCount,
    required this.onChanged,
    required this.onNext,
    super.key,
  });

  final String partnerLabel;
  final int questionIndex;
  final WeeklyDraft draft;
  final int submittedCount;
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
                Chip(
                  avatar: const Icon(Icons.lock_outline_rounded, size: 16),
                  label: Text('پاسخ خصوصی $partnerLabel'),
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
              onPressed: onNext,
              icon: Icon(
                questionIndex == 4
                    ? Icons.lock_rounded
                    : Icons.arrow_back_rounded,
              ),
              label: Text(questionIndex == 4 ? 'ثبت امن پاسخ‌ها' : 'بعدی'),
            ),
            if (submittedCount == 1) ...[
              const SizedBox(height: 12),
              Text(
                'پاسخ نفر اول امن ثبت شده؛ پاسخ خام او اینجا نمایش داده نمی‌شود.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _question(BuildContext context) {
    switch (questionIndex) {
      case 0:
        return LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = constraints.maxWidth < 340
                ? constraints.maxWidth
                : (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(5, (index) {
                final value = index + 1;
                final selected = draft.energy == value;
                return SizedBox(
                  width: tileWidth,
                  child: _ChoiceTile(
                    label: const [
                      'خیلی کم',
                      'کم',
                      'معمولی',
                      'خوب',
                      'پر انرژی',
                    ][index],
                    icon: const [
                      Icons.battery_0_bar,
                      Icons.battery_2_bar,
                      Icons.battery_4_bar,
                      Icons.battery_5_bar,
                      Icons.battery_full,
                    ][index],
                    selected: selected,
                    compact: true,
                    onTap: () => onChanged(draft.copyWith(energy: value)),
                  ),
                );
              }),
            );
          },
        );
      case 1:
        return _ChoiceWrap<WeeklyNeed>(
          value: draft.need,
          values: const {
            WeeklyNeed.calm: ('آرامش', Icons.spa_outlined),
            WeeklyNeed.fun: ('تفریح', Icons.celebration_outlined),
            WeeklyNeed.conversation: (
              'گفت‌وگو',
              Icons.chat_bubble_outline_rounded,
            ),
            WeeklyNeed.novelty: ('تجربه تازه', Icons.explore_outlined),
            WeeklyNeed.support: ('حمایت', Icons.handshake_outlined),
            WeeklyNeed.play: ('خنده و بازی', Icons.casino_outlined),
          },
          onChanged: (value) => onChanged(draft.copyWith(need: value)),
        );
      case 2:
        return _ChoiceWrap<DurationBand>(
          value: draft.duration,
          values: const {
            DurationBand.short: ('۳۰ دقیقه', Icons.timelapse_rounded),
            DurationBand.medium: ('۶۰ دقیقه', Icons.schedule_rounded),
            DurationBand.long: ('۹۰ دقیقه', Icons.hourglass_bottom_rounded),
          },
          onChanged: (value) => onChanged(draft.copyWith(duration: value)),
        );
      case 3:
        return _ChoiceWrap<BudgetBand>(
          value: draft.budget,
          values: const {
            BudgetBand.free: ('رایگان', Icons.volunteer_activism_outlined),
            BudgetBand.low: ('کم', Icons.local_cafe_outlined),
            BudgetBand.medium: ('متوسط', Icons.wallet_outlined),
          },
          onChanged: (value) => onChanged(draft.copyWith(budget: value)),
        );
      default:
        return _ChoiceWrap<SettingBand>(
          value: draft.setting,
          values: const {
            SettingBand.home: ('خانه', Icons.home_outlined),
            SettingBand.outside: ('بیرون', Icons.park_outlined),
            SettingBand.either: ('فرقی ندارد', Icons.shuffle_rounded),
          },
          onChanged: (value) => onChanged(draft.copyWith(setting: value)),
        );
    }
  }
}

class _ChoiceWrap<T> extends StatelessWidget {
  const _ChoiceWrap({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final T value;
  final Map<T, (String, IconData)> values;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values.entries
          .map(
            (entry) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - 76) / 2,
              child: _ChoiceTile(
                label: entry.value.$1,
                icon: entry.value.$2,
                selected: entry.key == value,
                onTap: () => onChanged(entry.key),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: UslyMotion.quick(context),
          constraints: BoxConstraints(minHeight: compact ? 68 : 82),
          padding: EdgeInsets.all(compact ? 10 : 14),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: .15)
                : colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontSize: compact ? 13 : 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevealPanel extends StatelessWidget {
  const _RevealPanel({
    required this.aligned,
    required this.onContinue,
    super.key,
  });

  final bool aligned;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: TweenAnimationBuilder<double>(
                duration: UslyMotion.reveal(context),
                tween: Tween(begin: 0, end: 1),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => CustomPaint(
                  painter: _ConvergingPathsPainter(
                    progress: value,
                    primary: Theme.of(context).colorScheme.primary,
                    secondary: Theme.of(context).colorScheme.secondary,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Text(
              aligned
                  ? 'این هفته روی یک ریتم هستید'
                  : 'دو ریتم متفاوت، یک قرار ممکن',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              aligned
                  ? 'پیشنهادها روی نقطه مشترک شما تمرکز می‌کنند.'
                  : 'پیشنهادها طوری چیده شده‌اند که محدودیت هیچ‌کدام نادیده گرفته نشود.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('دیدن سه پیشنهاد'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VotingPanel extends StatelessWidget {
  const _VotingPanel({
    required this.partnerLabel,
    required this.options,
    required this.onVote,
    super.key,
  });

  final String partnerLabel;
  final List<Experience> options;
  final ValueChanged<int> onVote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'انتخاب خصوصی $partnerLabel',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'یک گزینه را انتخاب کن؛ رأی تو برای همراهت نمایش داده نمی‌شود.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        ...options.indexed.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ExperienceCard(
              experience: entry.$2,
              accentIndex: entry.$1,
              onVote: () => onVote(entry.$2.id),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.experience,
    required this.accentIndex,
    required this.onVote,
  });

  final Experience experience;
  final int accentIndex;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      UslyPalette.of(context).coral,
    ];
    final accent = colors[accentIndex % colors.length];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: .25)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(label: Text(experience.type)),
                const SizedBox(height: 8),
                Text(
                  experience.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _Meta(
                      icon: Icons.schedule_rounded,
                      label: experience.duration,
                    ),
                    _Meta(
                      icon: Icons.wallet_outlined,
                      label: experience.budget,
                    ),
                    _Meta(
                      icon: Icons.place_outlined,
                      label: experience.setting,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 19,
                          color: accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(experience.reason)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  experience.instructions,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onVote,
                  icon: const Icon(Icons.favorite_border_rounded),
                  label: const Text('انتخاب خصوصی'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _NoMatchPanel extends StatelessWidget {
  const _NoMatchPanel({
    required this.onRevote,
    required this.onRefresh,
    super.key,
  });

  final VoidCallback onRevote;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.alt_route_rounded,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'این بار انتخاب مشترک پیدا نشد',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'رأی‌ها همچنان خصوصی‌اند. پاسخ‌های هفتگی‌تان هم پاک نمی‌شود.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('سه پیشنهاد تازه'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRevote,
              icon: const Icon(Icons.how_to_vote_outlined),
              label: const Text('روی همین‌ها دوباره رأی بدهیم'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchPanel extends StatelessWidget {
  const _MatchPanel({
    required this.experience,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final Experience experience;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: TweenAnimationBuilder<double>(
                duration: UslyMotion.reveal(context),
                curve: Curves.elasticOut,
                tween: Tween(begin: .7, end: 1),
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: .25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.done_all_rounded,
                    size: 44,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'انتخاب مشترک پیدا شد',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              experience.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(experience.instructions),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: selected ? null : onSelect,
              icon: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.calendar_month_outlined,
              ),
              label: Text(
                selected ? 'برای این هفته ثبت شد' : 'ثبت برای این هفته',
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'گام بعدی نسخه آنلاین: زمان‌بندی، انجام و بازخورد دونفره.',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HandoffScreen extends StatelessWidget {
  const _HandoffScreen({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 84,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 28),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
                const SizedBox(height: 14),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withValues(alpha: .85),
                      ),
                ),
                const SizedBox(height: 42),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('صفحه امن است؛ ادامه'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacySeal extends StatelessWidget {
  const _PrivacySeal();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'حریم خصوصی: پاسخ خام هر نفر برای طرف مقابل نمایش داده نمی‌شود',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 17,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              'پاسخ‌های خام نمایش داده نمی‌شوند؛ فقط برای ساخت پیشنهاد استفاده می‌شوند.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _AmbientPainter(
          primary: Theme.of(context).colorScheme.primary,
          secondary: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({required this.primary, required this.secondary});

  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * .08, size.height * .16),
      size.width * .42,
      Paint()
        ..shader = RadialGradient(
          colors: [
            secondary.withValues(alpha: .12),
            secondary.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * .08, size.height * .16),
            radius: size.width * .42,
          ),
        ),
    );
    canvas.drawCircle(
      Offset(size.width * .92, size.height * .72),
      size.width * .50,
      Paint()
        ..shader = RadialGradient(
          colors: [
            primary.withValues(alpha: .10),
            primary.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * .92, size.height * .72),
            radius: size.width * .50,
          ),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) =>
      oldDelegate.primary != primary || oldDelegate.secondary != secondary;
}

class _ConvergingPathsPainter extends CustomPainter {
  _ConvergingPathsPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
  });

  final double progress;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .62);
    final left = Offset(size.width * .17, size.height * .25);
    final right = Offset(size.width * .83, size.height * .25);
    final leftPath = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(
        size.width * .28,
        size.height * .72,
        center.dx,
        center.dy,
      );
    final rightPath = Path()
      ..moveTo(right.dx, right.dy)
      ..quadraticBezierTo(
        size.width * .72,
        size.height * .72,
        center.dx,
        center.dy,
      );
    _drawPartial(canvas, leftPath, primary, progress);
    _drawPartial(canvas, rightPath, secondary, progress);
    canvas.drawCircle(left, 13, Paint()..color = primary);
    canvas.drawCircle(right, 13, Paint()..color = secondary);
    if (progress > .86) {
      canvas.drawCircle(
        center,
        10 + 8 * math.sin((progress - .86) / .14 * math.pi),
        Paint()..color = primary.withValues(alpha: .8),
      );
    }
  }

  void _drawPartial(Canvas canvas, Path path, Color color, double value) {
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * value),
      Paint()
        ..color = color
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ConvergingPathsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
