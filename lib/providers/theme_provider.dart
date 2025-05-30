import 'package:flutter/material.dart';
import '../models/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.reduce;  // Default to reduce theme

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
        background: themeData.backgroundColor,
        surface: themeData.backgroundColor,
      ),
      scaffoldBackgroundColor: themeData.backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: themeData.secondaryColor,
        foregroundColor: themeData.primaryColor,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: themeData.primaryColor.withOpacity(0.2),
        backgroundColor: themeData.backgroundColor,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: themeData.primaryColor.withOpacity(0.1),
      ),
      iconTheme: IconThemeData(
        color: themeData.primaryColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        //focusedBorder: OutlineInputBorder(
        //  borderRadius: BorderRadius.circular(30),
        //  borderSide: BorderSide(
        //      color: themeData.primaryColor,
        //  ),
        //),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: themeData.primaryColor),
        titleMedium: TextStyle(color: themeData.primaryColor),
        titleSmall: TextStyle(color: themeData.primaryColor),
        bodyLarge: TextStyle(color: themeData.primaryColor),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: themeData.primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: themeData.primaryColor,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeData.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: themeData.primaryColor,
          side: BorderSide(color: themeData.primaryColor),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: themeData.primaryColor,
        ),
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