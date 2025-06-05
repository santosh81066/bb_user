// File: lib/Providers/language_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en', 'English'),
  telugu('te', 'తెలుగు'),
  hindi('hi', 'हिंदी'),
  tamil('ta', 'தமிழ்'),
  kannada('kn', 'ಕನ್ನಡ'),
  malayalam('ml', 'മലയാളം');

  const AppLanguage(this.code, this.displayName);
  final String code;
  final String displayName;
}

class LanguageNotifier extends StateNotifier<AppLanguage> {
  static const String _languageKey = 'selected_language';

  LanguageNotifier() : super(AppLanguage.english) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);

      if (languageCode != null) {
        final language = AppLanguage.values.firstWhere(
              (lang) => lang.code == languageCode,
          orElse: () => AppLanguage.english,
        );
        state = language;
      }
    } catch (e) {
      print('Error loading language: $e');
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.code);
      state = language;
    } catch (e) {
      print('Error saving language: $e');
    }
  }

  Locale get locale => Locale(state.code);
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>(
      (ref) => LanguageNotifier(),
);