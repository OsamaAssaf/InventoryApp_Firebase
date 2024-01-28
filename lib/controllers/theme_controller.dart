import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ThemeController with ChangeNotifier {
  bool? isDark;
  ThemeMode? themeMode;

  setTheme(bool isDark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDark', isDark);
  }

  getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isDark = prefs.getBool('isDark') ?? false;
    themeMode = isDark! ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
