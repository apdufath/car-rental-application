import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/dark_theme.dart';
import 'core/providers/app_settings_provider.dart';
import 'core/providers/router_provider.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload SharedPreferences synchronously for instant Riverpod availability
  final sharedPrefs = await SharedPreferences.getInstance();

  // Try initializing Firebase (Temporarily commented out to force fully working Simulation Mode out-of-the-box!)
  try {
    // final opts = DefaultFirebaseOptions.currentPlatform;
    // debugPrint('Current platform options: apiKey=${opts.apiKey}, appId=${opts.appId}, projectId=${opts.projectId}');
    // await Firebase.initializeApp(options: opts);
    debugPrint('Firebase initialization bypassed for Simulation Mode.');
  } catch (e) {
    debugPrint('Firebase initialization bypassed or failed. Local simulation mode active: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const AbaarsoApp(),
    ),
  );
}


class AbaarsoApp extends ConsumerWidget {
  const AbaarsoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch dynamic app settings (Language/Locale & Dark Mode Theme)
    final settings = ref.watch(appSettingsProvider);
    
    // 2. Watch GoRouter instance containing fully role-gated pages
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Abaarso Car Rental',
      debugShowCheckedModeBanner: false,
      
      // Theme settings
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: DarkTheme.darkTheme,

      // Localization settings
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // Router settings
      routerConfig: router,
    );
  }
}
