import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invent_app_redesign/services/auth_service.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _currentTheme = ThemeData.light();
  String _themeName = 'light';

  ThemeData get currentTheme => _currentTheme;
  String get themeName => _themeName;

  final AuthService _authService = AuthService();

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await _authService.loadUserPreferences(user.uid);
      _setThemeFromString(prefs['theme'] ?? 'light', notify: false);
    }
  }

  void setTheme(String themeName) async {
    _setThemeFromString(themeName);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final locale = _themeName; // сохранит текущую тему
      final language = ''; // не трогаем язык отсюда
      await _authService.saveUserPreferences(user.uid, themeName, language);
    }
  }

  void _setThemeFromString(String themeName, {bool notify = true}) {
    _themeName = themeName;
    _currentTheme = themeName == 'dark' ? ThemeData.dark() : ThemeData.light();
    if (notify) notifyListeners();
  }
}
