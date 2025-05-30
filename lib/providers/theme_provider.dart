import 'package:flutter/material.dart';
import '../models/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.blue;

  AppThemeType get currentTheme => _currentTheme;
  AppThemeData get currentThemeData => AppThemeData.themeData[_currentTheme]!;

  ThemeData get themeData {
    final themeData = AppThemeData.themeData[_currentTheme]!;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeData.primaryColor,
        primary: themeData.primaryColor,
        secondary: themeData.secondaryColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: themeData.primaryColor.withOpacity(0.1),
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: themeData.primaryColor.withOpacity(0.2),
      ),
      cardTheme: CardThemeData(
        color: themeData.primaryColor.withOpacity(0.05),
        elevation: 2,
        shadowColor: themeData.primaryColor.withOpacity(0.1),
      ),
      iconTheme: IconThemeData(
        color: themeData.primaryColor,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: themeData.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  void setTheme(AppThemeType theme) {
    if (_currentTheme != theme) {
      _currentTheme = theme;
      notifyListeners();
    }
  }
} 