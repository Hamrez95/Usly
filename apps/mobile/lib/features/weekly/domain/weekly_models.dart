enum WeeklyNeed { calm, fun, conversation, novelty, support, play }

enum BudgetBand { free, low, medium }

enum DurationBand { short, medium, long }

enum SettingBand { home, outside, either }

class WeeklyDraft {
  const WeeklyDraft({
    this.energy = 3,
    this.need = WeeklyNeed.calm,
    this.budget = BudgetBand.free,
    this.duration = DurationBand.short,
    this.setting = SettingBand.home,
  });

  final int energy;
  final WeeklyNeed need;
  final BudgetBand budget;
  final DurationBand duration;
  final SettingBand setting;

  WeeklyDraft copyWith({
    int? energy,
    WeeklyNeed? need,
    BudgetBand? budget,
    DurationBand? duration,
    SettingBand? setting,
  }) {
    return WeeklyDraft(
      energy: energy ?? this.energy,
      need: need ?? this.need,
      budget: budget ?? this.budget,
      duration: duration ?? this.duration,
      setting: setting ?? this.setting,
    );
  }

  Map<String, Object> toJson() => {
    'energy': energy,
    'need': need.name,
    'budget': budget.name,
    'duration': duration.name,
    'setting': setting.name,
  };

  factory WeeklyDraft.fromJson(Map<String, dynamic> json) {
    return WeeklyDraft(
      energy: json['energy'] as int? ?? 3,
      need: WeeklyNeed.values.byName(json['need'] as String? ?? 'calm'),
      budget: BudgetBand.values.byName(json['budget'] as String? ?? 'free'),
      duration: DurationBand.values.byName(
        json['duration'] as String? ?? 'short',
      ),
      setting: SettingBand.values.byName(json['setting'] as String? ?? 'home'),
    );
  }
}

class Experience {
  const Experience({
    required this.id,
    required this.type,
    required this.title,
    required this.duration,
    required this.budget,
    required this.setting,
    required this.reason,
    required this.instructions,
  });

  final int id;
  final String type;
  final String title;
  final String duration;
  final String budget;
  final String setting;
  final String reason;
  final String instructions;
}

class WeeklySnapshot {
  const WeeklySnapshot({
    required this.drafts,
    required this.submitted,
    required this.votes,
    required this.partner,
    required this.questionIndex,
    required this.revealSeen,
    required this.variation,
    required this.selectedId,
  });

  factory WeeklySnapshot.initial() => const WeeklySnapshot(
    drafts: [WeeklyDraft(), WeeklyDraft()],
    submitted: <int>{},
    votes: <int, int>{},
    partner: 0,
    questionIndex: 0,
    revealSeen: false,
    variation: 0,
    selectedId: null,
  );

  final List<WeeklyDraft> drafts;
  final Set<int> submitted;
  final Map<int, int> votes;
  final int partner;
  final int questionIndex;
  final bool revealSeen;
  final int variation;
  final int? selectedId;

  bool get bothSubmitted => submitted.length == 2;
  bool get bothVoted => votes.length == 2;
  bool get hasMatch => bothVoted && votes[0] == votes[1];
}

List<Experience> recommend(WeeklySnapshot state) {
  final first = state.drafts[0];
  final second = state.drafts[1];
  final lowEnergy = first.energy <= 2 || second.energy <= 2;
  final free =
      first.budget == BudgetBand.free || second.budget == BudgetBand.free;
  final atHome =
      first.setting == SettingBand.home || second.setting == SettingBand.home;
  final needsTalk =
      first.need == WeeklyNeed.conversation ||
      second.need == WeeklyNeed.conversation;
  final wantsPlay =
      first.need == WeeklyNeed.play || second.need == WeeklyNeed.play;
  final seed = state.variation * 10;

  return [
    Experience(
      id: seed + 1,
      type: 'آسان',
      title: lowEnergy ? 'پناه کوچک دونفره' : 'نوشیدنی و یک سؤال تازه',
      duration: '۳۰ دقیقه',
      budget: free ? 'رایگان' : 'کم',
      setting: 'خانه',
      reason: lowEnergy
          ? 'چون انرژی یکی از شما پایین‌تر است.'
          : 'شروع ساده و بدون برنامه‌ریزی می‌خواهید.',
      instructions: needsTalk
          ? 'موبایل‌ها را کنار بگذارید و هر نفر فقط از بهترین لحظه هفته بگوید.'
          : 'یک نوشیدنی آماده کنید و سه آهنگ انتخاب کنید که حال این هفته‌تان را بهتر می‌کند.',
    ),
    Experience(
      id: seed + 2,
      type: 'متعادل',
      title: atHome
          ? 'آشپزی دونفره با قانون انتخاب تصادفی'
          : 'قدم‌زدن با مسیر ناشناخته',
      duration: '۶۰ دقیقه',
      budget: free ? 'رایگان' : 'کم',
      setting: atHome ? 'خانه' : 'بیرون',
      reason: wantsPlay
          ? 'چون بازی و تنوع در انتخاب هر دو دیده شده.'
          : 'بین آرامش و تازگی تعادل دارد.',
      instructions: atHome
          ? 'سه انتخاب کوچک—غذا، آهنگ و نوشیدنی—را با قرعه بین خودتان تقسیم کنید.'
          : 'یک مسیر نزدیک اما نرفته را انتخاب کنید و وسط راه برای یک خوراکی کوچک توقف کنید.',
    ),
    Experience(
      id: seed + 3,
      type: 'متفاوت',
      title: state.variation.isEven
          ? 'قرار سه انتخاب شانسی'
          : 'ماموریت عکس بدون انتشار',
      duration: '۹۰ دقیقه',
      budget: free ? 'رایگان' : 'متوسط',
      setting: 'فرقی ندارد',
      reason: 'برای شکستن تکرار، بدون بالا بردن فشار یا هزینه.',
      instructions: state.variation.isEven
          ? 'مسیر، خوراکی و فعالیت را روی کاغذ بنویسید و هرکدام را تصادفی انتخاب کنید.'
          : 'هر نفر سه عکس از جزئیات زیبای اطراف بگیرد؛ در پایان فقط برای هم تعریفشان کنید.',
    ),
  ];
}
