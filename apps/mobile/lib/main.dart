import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:usly/app/usly_app.dart';
import 'package:usly/core/backend/usly_backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: UslyBackend.projectUrl,
    publishableKey: UslyBackend.publishableKey,
  );
  final preferences = await SharedPreferences.getInstance();
  runApp(UslyApp(preferences: preferences, client: Supabase.instance.client));
}
