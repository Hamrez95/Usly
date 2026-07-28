import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const UslyApp());

class UslyApp extends StatelessWidget {
  const UslyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Usly',
      locale: const Locale('fa'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9B5A43)),
        scaffoldBackgroundColor: const Color(0xFFFFF8F2),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E2925),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      home: const Directionality(textDirection: TextDirection.rtl, child: HomePage()),
    );
  }
}

class WeeklyDraft {
  int energy;
  String need;
  String budget;
  String duration;
  String setting;

  WeeklyDraft({
    this.energy = 3,
    this.need = 'آرامش',
    this.budget = 'رایگان',
    this.duration = '۳۰ دقیقه',
    this.setting = 'خانه',
  });
}

class Experience {
  final int id;
  final String type;
  final String title;
  final String duration;
  final String budget;
  final String instructions;

  const Experience(this.id, this.type, this.title, this.duration, this.budget, this.instructions);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final drafts = {'a': WeeklyDraft(), 'b': WeeklyDraft()};
  final submitted = <String>{};
  final votes = <String, int>{};
  String partner = 'a';
  int? selectedId;
  bool loading = true;

  WeeklyDraft get active => drafts[partner]!;
  bool get ready => submitted.length == 2;
  String get partnerLabel => partner == 'a' ? 'نفر اول' : 'نفر دوم';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in ['a', 'b']) {
      final d = drafts[key]!;
      d.energy = prefs.getInt('$key.energy') ?? 3;
      d.need = prefs.getString('$key.need') ?? 'آرامش';
      d.budget = prefs.getString('$key.budget') ?? 'رایگان';
      d.duration = prefs.getString('$key.duration') ?? '۳۰ دقیقه';
      d.setting = prefs.getString('$key.setting') ?? 'خانه';
      if (prefs.getBool('$key.submitted') ?? false) submitted.add(key);
      final vote = prefs.getInt('$key.vote');
      if (vote != null) votes[key] = vote;
    }
    selectedId = prefs.getInt('selectedId');
    partner = !submitted.contains('a')
        ? 'a'
        : !submitted.contains('b')
            ? 'b'
            : !votes.containsKey('a')
                ? 'a'
                : 'b';
    setState(() => loading = false);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in ['a', 'b']) {
      final d = drafts[key]!;
      await prefs.setInt('$key.energy', d.energy);
      await prefs.setString('$key.need', d.need);
      await prefs.setString('$key.budget', d.budget);
      await prefs.setString('$key.duration', d.duration);
      await prefs.setString('$key.setting', d.setting);
      await prefs.setBool('$key.submitted', submitted.contains(key));
      final vote = votes[key];
      if (vote == null) {
        await prefs.remove('$key.vote');
      } else {
        await prefs.setInt('$key.vote', vote);
      }
    }
    if (selectedId == null) {
      await prefs.remove('selectedId');
    } else {
      await prefs.setInt('selectedId', selectedId!);
    }
  }

  List<Experience> get options {
    if (!ready) return const [];
    final a = drafts['a']!;
    final b = drafts['b']!;
    final lowEnergy = a.energy <= 2 || b.energy <= 2;
    final atHome = a.setting == 'خانه' || b.setting == 'خانه';
    final short = a.duration == '۳۰ دقیقه' || b.duration == '۳۰ دقیقه';
    final free = a.budget == 'رایگان' || b.budget == 'رایگان';

    if (free) {
      return [
        Experience(1, 'راحت', 'نوشیدنی خانگی بدون موبایل', short ? '۳۰ دقیقه' : '۴۵ دقیقه', 'رایگان', 'با چیزهایی که در خانه دارید یک نوشیدنی آماده کنید و درباره بهترین بخش هفته حرف بزنید.'),
        const Experience(2, 'متعادل', 'قدم‌زدن در محله با یک سؤال تازه', '۴۵ تا ۶۰ دقیقه', 'رایگان', 'یک مسیر نزدیک را انتخاب کنید و هر نفر یک سؤال تازه و سبک از دیگری بپرسد.'),
        Experience(3, 'متفاوت', lowEnergy ? 'بازی کشف خاطره در خانه' : 'قرار با انتخاب تصادفی مسیر', '۶۰ دقیقه', 'رایگان', 'سه انتخاب کوچک را به شانس بسپارید: مسیر، آهنگ و موضوع گفت‌وگو. هیچ خریدی لازم نیست.'),
      ];
    }

    return [
      Experience(1, 'راحت', lowEnergy || atHome ? 'کافه خانگی بدون موبایل' : 'قدم‌زدن و نوشیدنی کوتاه', short ? '۳۰ دقیقه' : '۴۵ دقیقه', 'کم', 'یک نوشیدنی آماده کنید، موبایل‌ها را کنار بگذارید و درباره بهترین بخش هفته حرف بزنید.'),
      Experience(2, 'متعادل', atHome ? 'شام مشترک با پلی‌لیست دونفره' : 'قرار سبک در یک کافه آرام', '۶۰ تا ۹۰ دقیقه', 'متوسط', 'هر نفر سه آهنگ انتخاب کند و در طول برنامه یک سؤال تازه از دیگری بپرسد.'),
      Experience(3, 'متفاوت', lowEnergy ? 'بازی کشف خاطره در خانه' : 'قرار با انتخاب تصادفی مسیر', '۹۰ دقیقه', 'متوسط', 'سه انتخاب کوچک را به شانس بسپارید: مسیر، خوراکی و یک فعالیت کوتاه. هدف، تازگی بدون فشار است.'),
    ];
  }

  Experience? get match {
    if (votes.length != 2 || votes['a'] != votes['b']) return null;
    for (final option in options) {
      if (option.id == votes['a']) return option;
    }
    return null;
  }

  Future<void> _handoff(String label) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('تحویل گوشی'),
        content: Text('گوشی را به $label بدهید. پاسخ و رأی قبلی دیگر قابل مشاهده نیست.'),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text('من $label هستم'))],
      ),
    );
  }

  Future<void> _submit() async {
    if (submitted.contains(partner)) return;
    final wasA = partner == 'a';
    setState(() {
      submitted.add(partner);
      votes.clear();
      selectedId = null;
      partner = ready ? 'a' : (wasA ? 'b' : 'a');
    });
    await _persist();
    await _handoff(ready ? 'نفر اول برای رأی‌دادن' : partnerLabel);
  }

  Future<void> _vote(int id) async {
    if (!ready || votes.containsKey(partner)) return;
    final wasA = partner == 'a';
    setState(() {
      votes[partner] = id;
      selectedId = null;
      if (votes.length < 2) partner = wasA ? 'b' : 'a';
    });
    await _persist();
    if (votes.length < 2) await _handoff(partnerLabel);
  }

  Future<void> _reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      drafts['a'] = WeeklyDraft();
      drafts['b'] = WeeklyDraft();
      submitted.clear();
      votes.clear();
      selectedId = null;
      partner = 'a';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final matched = match;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Usly', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: _reset, tooltip: 'شروع دوباره', icon: const Icon(Icons.refresh_rounded))],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            const Text('کمتر در اپ؛\nبیشتر باهم.', style: TextStyle(fontSize: 42, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
            const SizedBox(height: 8),
            Text('در چند دقیقه حال، زمان و بودجه‌تان را هماهنگ کنید.', style: TextStyle(color: Colors.brown.shade600, fontSize: 16)),
            const SizedBox(height: 22),
            _syncCard(),
            if (ready) ...[
              const SizedBox(height: 18),
              _revealCard(),
              const SizedBox(height: 18),
              Text(votes.length < 2 ? 'نوبت رأی $partnerLabel' : 'نتیجه رأی دونفره', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              ...options.map(_experienceCard),
            ],
            if (ready && votes.length == 2 && matched == null) ...[
              const SizedBox(height: 12),
              const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('هنوز انتخاب مشترکی ندارید. برای حفظ حریم خصوصی رأی‌ها نمایش داده نمی‌شوند؛ از «شروع دوباره» استفاده کنید.'))),
            ],
            if (matched != null) ...[
              const SizedBox(height: 18),
              Card(
                color: const Color(0xFFF1F5E9),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('انتخاب مشترک پیدا شد ✓', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                    const SizedBox(height: 8),
                    Text(matched.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(matched.instructions),
                    const SizedBox(height: 14),
                    FilledButton(onPressed: () async { setState(() => selectedId = matched.id); await _persist(); }, child: Text(selectedId == matched.id ? 'برای این هفته انتخاب شد ✓' : 'انتخاب این برنامه')),
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _syncCard() {
    if (ready) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('پاسخ‌های هفتگی ثبت و قفل شدند ✓', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text('برای جلوگیری از دیدن پاسخ نفر مقابل، فرم‌ها پس از ثبت هر دو نفر دوباره نمایش داده نمی‌شوند.'),
          ]),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('حال این هفته', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Chip(label: Text('پاسخ خصوصی $partnerLabel')),
          const SizedBox(height: 10),
          const Text('سطح انرژی', style: TextStyle(fontWeight: FontWeight.w800)),
          Slider(value: active.energy.toDouble(), min: 1, max: 5, divisions: 4, label: '${active.energy}', onChanged: (value) => setState(() => active.energy = value.round())),
          _dropdown('نیاز اصلی', active.need, ['آرامش', 'تفریح', 'گفت‌وگو', 'تجربه جدید', 'حمایت', 'خنده و بازی'], (value) => setState(() => active.need = value)),
          _dropdown('بودجه', active.budget, ['رایگان', 'کم', 'متوسط'], (value) => setState(() => active.budget = value)),
          _dropdown('زمان', active.duration, ['۳۰ دقیقه', '۶۰ دقیقه', '۹۰ دقیقه'], (value) => setState(() => active.duration = value)),
          _dropdown('فضا', active.setting, ['خانه', 'بیرون', 'فرقی ندارد'], (value) => setState(() => active.setting = value)),
          const SizedBox(height: 12),
          FilledButton(onPressed: _submit, child: const Text('ثبت و قفل پاسخ خصوصی')),
          const SizedBox(height: 8),
          Text('${submitted.contains('a') ? 'نفر اول ✓' : 'نفر اول منتظر'} · ${submitted.contains('b') ? 'نفر دوم ✓' : 'نفر دوم منتظر'}', style: TextStyle(color: Colors.brown.shade500, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> values, ValueChanged<String> onChanged) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
          items: values.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
          onChanged: (x) { if (x != null) onChanged(x); },
        ),
      );

  Widget _revealCard() {
    final same = drafts['a']!.need == drafts['b']!.need;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(same ? 'این هفته روی یک موج هستید' : 'این هفته ترجیح‌های متفاوتی دارید', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('پیشنهادها با انرژی، زمان و محدودیت بودجه هر دو نفر ساخته شدند.'),
          const SizedBox(height: 10),
          const DecoratedBox(decoration: BoxDecoration(color: Color(0xFFF7EDE6), borderRadius: BorderRadius.all(Radius.circular(14))), child: Padding(padding: EdgeInsets.all(12), child: Text('پاسخ‌های خصوصی نمایش داده نمی‌شوند؛ فقط زمینه مشترک استفاده شده است.'))),
        ]),
      ),
    );
  }

  Widget _experienceCard(Experience e) {
    final canVote = votes.length < 2 && !votes.containsKey(partner);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Chip(label: Text(e.type)),
            Text(e.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            Text('${e.duration} · بودجه ${e.budget}', style: TextStyle(color: Colors.brown.shade500)),
            const SizedBox(height: 8),
            Text(e.instructions),
            if (canVote) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: () => _vote(e.id), icon: const Icon(Icons.favorite_border), label: Text('انتخاب خصوصی $partnerLabel')),
            ],
          ]),
        ),
      ),
    );
  }
}
