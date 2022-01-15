
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController with ChangeNotifier{

  bool? isDark;
  ThemeMode? themeMode ;


  setTheme(bool isDark)async{
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    _prefs.setBool('isDark', isDark);
  }

  getTheme()async{
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    isDark = _prefs.getBool('isDark')??false;
    themeMode = isDark!?ThemeMode.dark :ThemeMode.light;
    notifyListeners();
  }

}