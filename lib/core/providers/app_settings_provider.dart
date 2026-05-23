import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_strings.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences was not overridden in ProviderScope');
});

class AppSettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final bool isFirstRun;

  AppSettingsState({
    required this.themeMode,
    required this.locale,
    required this.isFirstRun,
  });

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? isFirstRun,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      isFirstRun: isFirstRun ?? this.isFirstRun,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  final SharedPreferences _prefs;

  AppSettingsNotifier(this._prefs)
      : super(
          AppSettingsState(
            themeMode: (_prefs.getBool('is_dark_theme') ?? false) ? ThemeMode.dark : ThemeMode.light,
            locale: const Locale('en'),
            isFirstRun: _prefs.getBool(AppStrings.keyFirstRun) ?? true,
          ),
        );

  Future<void> toggleTheme(bool isDark) async {
    await _prefs.setBool('is_dark_theme', isDark);
    state = state.copyWith(themeMode: isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setLocale(String langCode) async {
    await _prefs.setString('language_code', 'en');
    state = state.copyWith(locale: const Locale('en'));
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(AppStrings.keyFirstRun, false);
    state = state.copyWith(isFirstRun: false);
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppSettingsNotifier(prefs);
});

