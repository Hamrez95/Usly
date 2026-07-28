import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const UslyApp());

class UslyApp extends StatelessWidget {
  const UslyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF9B5A43);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Usly',
      locale: const Locale('fa'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
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

  Map<String, Object> toJson() => {
        'energy': energy,
        'need': need,
        'budget': budget,
        'duration': duration,
        'setting': setting,
      };
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      partner = prefs.getString('partner') ?? 'a';
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
      loading = false;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('partner', partner);
    for (final key in ['a', 'b']) {
      final d = drafts[key]!;
      await prefs.setInt('$key.energy', d.energy);
      await prefs.setString('$key.need', d.need);
      await prefs.setString('$key.budget', d.budget);
      await prefs.setString('$key.duration', d.duration);
      await prefs.setString('$key.setting', d.setting);
      await prefs.setBool('$key.submitted', submitted.contains(key));
      if (votes[key] case final int vote) {
        await prefs.setInt('$key.vote', vote);
      } else {
        await prefs.remove('$key.vote');
      }
    }
    if (selectedId case final int id) {
      await prefs.setInt('selectedId', id);
    } else {
      await prefs.remove('selectedId');
    }
  }

  List<Experience> get options {
    if (!ready) return const [];
    final a = drafts['a']!;
    final b = drafts['b']!;
    final lowEnergy = a.energy <= 2 || b.energy <= 2;
    final atHome = a.setting == 'خانه' || b.setting == 'خانه';
    final short = a.duration == '۳۰ دقیقه' || b.duration == '۳۰ دقیقه';
    return [
      Experience(1, 'راحت', lowEnergy || atHome ? 'کافه خانگی بدون موبایل' : 'قدم‌زدن و نوشیدنی کوتاه', short ? '۳۰ دقیقه' : '۴۵ دقیقه', 'کم', 'یک نوشیدنی آماده کنید، موبایل‌ها را کنار بگذارید و درباره بهترین بخش هفته حرف بزنید.'),
      Experience(2, 'متعادل', atHome ? 'شام مشترک با پلی‌لیست دونفره' : 'قرار سبک در یک کافه آرام', '۶۰ تا ۹۰ دقیقه', a.budget == 'رایگان' || b.budget == 'رایگان' ? 'کم' : 'متوسط', 'هر نفر سه آهنگ انتخاب کند و در طول برنامه یک سؤال تازه از دیگری بپرسد.'),
      Experience(3, 'متفاوت', lowEnergy ? 'بازی کشف خاطره در خانه' : 'قرار با انتخاب تصادفی مسیر', '۹۰ دقیقه', 'متوسط', 'سه انتخاب کوچک را به شانس بسپارید: مسیر، خوراکی و یک فعالیت کوتاه. هدف، تازگی بدون فشار است.'),
    ];
  }

  Experience? get match {
    if (votes.length != 2 || votes['a'] != votes['b']) return null;
    return options.where((x) => x.id == votes['a']).firstOrNull;
  }

  Future<void> _submit() async {
    setState(() {
      submitted.add(partner);
      votes.clear();
      selectedId = null;
      if (!ready) partner = partner == 'a' ? 'b' : 'a';
    });
    await _persist();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ready ? 'پیشنهادهای مشترک آماده شد.' : 'پاسخ خصوصی ثبت شد؛ حالا نوبت نفر دوم است.')));
  }

  Future<void> _vote(int id) async {
    setState(() {
      votes[partner] = id;
      selectedId = null;
      partner = partner == 'a' ? 'b' : 'a';
    });
    await _persist();
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
              const Text('سه پیشنهاد برای شما', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              ...options.map(_experienceCard),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('حال این هفته', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [ButtonSegment(value: 'a', label: Text('نفر اول')), ButtonSegment(value: 'b', label: Text('نفر دوم'))],
            selected: {partner},
            onSelectionChanged: (value) => setState(() => partner = value.first),
          ),
          const SizedBox(height: 18),
          const Text('سطح انرژی', style: TextStyle(fontWeight: FontWeight.w800)),
          Slider(value: active.energy.toDouble(), min: 1, max: 5, divisions: 4, label: '${active.energy}', onChanged: (value) => setState(() => active.energy = value.round())),
          _dropdown('نیاز اصلی', active.need, ['آرامش', 'تفریح', 'گفت‌وگو', 'تجربه جدید', 'حمایت', 'خنده و بازی'], (value) => setState(() => active.need = value)),
          _dropdown('بودجه', active.budget, ['رایگان', 'کم', 'متوسط'], (value) => setState(() => active.budget = value)),
          _dropdown('زمان', active.duration, ['۳۰ دقیقه', '۶۰ دقیقه', '۹۰ دقیقه'], (value) => setState(() => active.duration = value)),
          _dropdown('فضا', active.setting, ['خانه', 'بیرون', 'فرقی ندارد'], (value) => setState(() => active.setting = value)),
          const SizedBox(height: 12),
          FilledButton(onPressed: _submit, child: Text(submitted.contains(partner) ? 'به‌روزرسانی پاسخ خصوصی' : 'ثبت خصوصی پاسخ')),
          const SizedBox(height: 8),
          Text('پاسخ نفر مقابل نمایش داده نمی‌شود. ${submitted.contains('a') ? 'نفر اول ✓' : 'نفر اول منتظر'} · ${submitted.contains('b') ? 'نفر دوم ✓' : 'نفر دوم منتظر'}', style: TextStyle(color: Colors.brown.shade500, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> values, ValueChanged<String> onChanged) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
          items: values.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
          onChanged: (x) { if (x != null) onChanged(x); },
        ),
      );

  Widget _revealCard() {
    final a = drafts['a']!;
    final b = drafts['b']!;
    final same = a.need == b.need;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(same ? 'این هفته روی یک موج هستید' : 'این هفته ترجیح‌های متفاوتی دارید', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('پیشنهادها با انرژی قابل‌مدیریت، محدودیت زمانی و بودجه هر دو نفر ساخته شدند.'),
          const SizedBox(height: 10),
          const DecoratedBox(decoration: BoxDecoration(color: Color(0xFFF7EDE6), borderRadius: BorderRadius.all(Radius.circular(14))), child: Padding(padding: EdgeInsets.all(12), child: Text('پاسخ‌های خصوصی نمایش داده نمی‌شوند؛ فقط زمینه مشترک استفاده شده است.'))),
        ]),
      ),
    );
  }

  Widget _experienceCard(Experience e) => Padding(
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
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: () => _vote(e.id), icon: Icon(votes[partner] == e.id ? Icons.check_circle : Icons.favorite_border), label: Text('رأی ${partner == 'a' ? 'نفر اول' : 'نفر دوم'}')),
            ]),
          ),
        ),
      );
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
