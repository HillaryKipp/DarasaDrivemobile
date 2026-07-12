import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  // 1. Preserve splash screen until we are ready to show the first screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 2. Initialize Supabase
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase init error: $e');
    // We continue so the app can show a proper error UI
  }

  // 3. Launch app
  // Note: FlutterNativeSplash.remove() is now handled inside DarasaDriveApp
  runApp(
    const ProviderScope(
      child: DarasaDriveApp(),
    ),
  );
}
