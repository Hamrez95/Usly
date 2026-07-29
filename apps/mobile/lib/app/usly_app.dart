import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:usly/core/theme/usly_theme.dart';
import 'package:usly/features/auth/presentation/auth_gate.dart';
import 'package:usly/features/weekly/data/local_weekly_store.dart';
import 'package:usly/features/weekly/presentation/weekly_ritual_page.dart';

class UslyApp extends StatefulWidget {
  const UslyApp({required this.preferences, this.client, super.key});

  final SharedPreferences preferences;
  final SupabaseClient? client;

  @override
  State<UslyApp> createState() => _UslyAppState();
}

class _UslyAppState extends State<UslyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = switch (widget.preferences.getString('usly.theme')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> _toggleTheme() async {
    final brightness = Theme.of(context).brightness;
    final next =
        brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() => _themeMode = next);
    await widget.preferences.setString('usly.theme', next.name);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Usly',
      theme: UslyTheme.light(),
      darkTheme: UslyTheme.dark(),
      themeMode: _themeMode,
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: widget.client == null
          ? WeeklyRitualPage(
              store: LocalWeeklyStore(widget.preferences),
              onToggleTheme: _toggleTheme,
            )
          : AuthGate(
              client: widget.client!,
              preferences: widget.preferences,
              onToggleTheme: _toggleTheme,
            ),
    );
  }
}
