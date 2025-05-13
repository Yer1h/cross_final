import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invent_app_redesign/services/auth_service.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('en');
  final AuthService _authService = AuthService();

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await _authService.loadUserPreferences(user.uid);
      final langCode = prefs['language'] ?? 'en';
      _locale = Locale(langCode);
      notifyListeners();
    }
  }

  void setLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final theme = ''; // не трогаем тему отсюда
      await _authService.saveUserPreferences(user.uid, theme, languageCode);
    }
  }
}
