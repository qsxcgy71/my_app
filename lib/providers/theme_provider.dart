import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  late SharedPreferences _prefs;
  AppThemeType _currentTheme = AppThemeType.reduce;  // Default to reduce theme

  AppThemeType get currentTheme => _currentTheme;
  AppThemeData get currentThemeData => AppThemeData.themeData[_currentTheme]!;

  // Initialize the provider and load saved theme
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadThemeFromFirebase();
    
    // 监听用户登录状态变化
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadThemeFromFirebase();
      } else {
        // 用户登出时，使用默认主题
        _currentTheme = AppThemeType.reduce;
        notifyListeners();
      }
    });
  }

  // 从 Firebase 加载主题设置
  Future<void> _loadThemeFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        // 如果用户未登录，使用本地存储的主题
        final savedTheme = _prefs.getString(_themeKey);
        if (savedTheme != null) {
          _currentTheme = AppThemeType.values.firstWhere(
            (type) => type.toString() == savedTheme,
            orElse: () => AppThemeType.reduce,
          );
          notifyListeners();
        }
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('theme')) {
        final savedTheme = doc.data()!['theme'] as String;
        _currentTheme = AppThemeType.values.firstWhere(
          (type) => type.toString() == savedTheme,
          orElse: () => AppThemeType.reduce,
        );
        // 同步到本地存储，以便在离线时使用
        await _prefs.setString(_themeKey, _currentTheme.toString());
        notifyListeners();
      } else {
        // 如果用户文档不存在或没有主题设置，使用本地存储的主题
        final savedTheme = _prefs.getString(_themeKey);
        if (savedTheme != null) {
          _currentTheme = AppThemeType.values.firstWhere(
            (type) => type.toString() == savedTheme,
            orElse: () => AppThemeType.reduce,
          );
          // 将本地主题同步到 Firebase
          await _saveThemeToFirebase(_currentTheme);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error loading theme from Firebase: $e');
      // 发生错误时，尝试使用本地存储的主题
      final savedTheme = _prefs.getString(_themeKey);
      if (savedTheme != null) {
        _currentTheme = AppThemeType.values.firstWhere(
          (type) => type.toString() == savedTheme,
          orElse: () => AppThemeType.reduce,
        );
        notifyListeners();
      }
    }
  }

  // 保存主题设置到 Firebase
  Future<void> _saveThemeToFirebase(AppThemeType theme) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'theme': theme.toString(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving theme to Firebase: $e');
    }
  }

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

  Future<void> setTheme(AppThemeType theme) async {
    if (_currentTheme != theme) {
      _currentTheme = theme;
      // 立即通知监听器以更新 UI
      notifyListeners();
      
      // 保存到本地存储
      await _prefs.setString(_themeKey, theme.toString());
      
      // 保存到 Firebase
      await _saveThemeToFirebase(theme);
    }
  }
} 