import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ChangeNotifier {
  LanguageController._internal();
  
  static final LanguageController instance = LanguageController._internal();
  
  Locale _locale = const Locale('tr', 'TR');
  Locale get locale => _locale;
  
  String get languageCode => _locale.languageCode;
  String get languageName => _locale.languageCode == 'tr' ? 'Türkçe' : 'English';
  
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedLang = prefs.getString('languageCode');
    if (storedLang != null) {
      _locale = Locale(storedLang, storedLang == 'tr' ? 'TR' : 'US');
    }
    notifyListeners();
  }
  
  Future<void> changeLanguage(String langCode) async {
    if (_locale.languageCode == langCode) return;
    _locale = Locale(langCode, langCode == 'tr' ? 'TR' : 'US');
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', langCode);
  }
}
