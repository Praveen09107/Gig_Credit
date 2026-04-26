import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../app/app_constants.dart';

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _loadFromHive();
  }

  Future<void> _loadFromHive() async {
    final box = Hive.box(AppConstants.hiveBoxSettings);
    final lang = box.get('language', defaultValue: 'en');
    state = lang;
  }

  Future<void> setLanguage(String lang) async {
    if (AppConstants.supportedLanguages.contains(lang)) {
      final box = Hive.box(AppConstants.hiveBoxSettings);
      await box.put('language', lang);
      state = lang;
    }
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});
