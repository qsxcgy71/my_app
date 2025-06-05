import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _deviceThemeKey = 'device_theme';
  static const String _accountThemeKey = 'account_theme';
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  late SharedPreferences _prefs;
  
  // 设备主题（用于未登录状态，固定为default_theme主题）
  AppThemeType _deviceTheme = AppThemeType.default_theme;
  // 账号主题（用于登录状态，新用户默认为default_theme主题）
  AppThemeType _accountTheme = AppThemeType.default_theme;
  // 是否使用账号主题
  bool _useAccountTheme = false;

  // 获取当前应该使用的主题
  AppThemeType get currentTheme {
    final theme = _useAccountTheme ? _accountTheme : AppThemeType.default_theme;
    // print('Current theme: $theme (useAccountTheme: $_useAccountTheme)');
    return theme;
  }
  AppThemeData get currentThemeData => AppThemeData.themeData[currentTheme]!;

  // 初始化提供者并加载保存的主题
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // 检查当前是否有登录用户
    final user = _auth.currentUser;
    _useAccountTheme = user != null;
    
    if (_useAccountTheme) {
      // 首先尝试从本地缓存加载账号主题
      final savedAccountTheme = _prefs.getString(_accountThemeKey);
      if (savedAccountTheme != null) {
        _accountTheme = AppThemeType.values.firstWhere(
          (type) => type.toString() == savedAccountTheme,
          orElse: () => AppThemeType.default_theme,
        );
        print('Loaded account theme from cache: $_accountTheme');
      }
      
      // 然后异步从Firebase加载（这会覆盖本地缓存如果Firebase有更新的数据）
      await _loadAccountTheme();
    }
    
    // 监听用户登录状态变化
    _auth.authStateChanges().listen((User? user) async {
      final wasUsingAccountTheme = _useAccountTheme;
      _useAccountTheme = user != null;
      
      if (user != null && !wasUsingAccountTheme) {
        // 用户刚登录，加载账号主题
        print('User logged in, loading account theme...');
        await _loadAccountTheme();
      } else if (user == null && wasUsingAccountTheme) {
        // 用户退出登录，切换到设备主题
        print('User logged out, switching to device theme');
        notifyListeners();
      }
    });
  }

  // 从 Firebase 加载账号主题设置
  Future<void> _loadAccountTheme() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      print('Loading account theme for user: ${user.uid}');
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('theme')) {
        final savedTheme = doc.data()!['theme'] as String;
        final newTheme = AppThemeType.values.firstWhere(
          (type) => type.toString() == savedTheme,
          orElse: () => AppThemeType.default_theme,
        );
        
        if (_accountTheme != newTheme) {
          _accountTheme = newTheme;
          print('Updated account theme from Firebase: $_accountTheme');
        }
        
        // 保存到本地缓存
        await _prefs.setString(_accountThemeKey, _accountTheme.toString());
        notifyListeners();
      } else {
        // 如果用户文档不存在或没有主题设置，使用default_theme主题作为初始账号主题
        print('No theme found in Firebase, using default default_theme theme');
        _accountTheme = AppThemeType.default_theme;
        await _saveAccountTheme(_accountTheme);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading theme from Firebase: $e');
      // 发生错误时，尝试使用本地缓存的账号主题
      final savedAccountTheme = _prefs.getString(_accountThemeKey);
      if (savedAccountTheme != null) {
        final cachedTheme = AppThemeType.values.firstWhere(
          (type) => type.toString() == savedAccountTheme,
          orElse: () => AppThemeType.default_theme,
        );
        if (_accountTheme != cachedTheme) {
          _accountTheme = cachedTheme;
          print('Fallback to cached account theme: $_accountTheme');
          notifyListeners();
        }
      } else {
        // 如果连本地缓存也没有，使用默认的default_theme主题
        if (_accountTheme != AppThemeType.default_theme) {
          _accountTheme = AppThemeType.default_theme;
          print('Fallback to default default_theme theme');
          notifyListeners();
        }
      }
    }
  }

  // 保存账号主题设置到 Firebase
  Future<void> _saveAccountTheme(AppThemeType theme) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'theme': theme.toString(),
        }, SetOptions(merge: true));
        await _prefs.setString(_accountThemeKey, theme.toString());
      }
    } catch (e) {
      print('Error saving theme to Firebase: $e');
    }
  }

  // 保存设备主题到本地存储
  Future<void> _saveDeviceTheme(AppThemeType theme) async {
    // 未登录状态不允许更改主题
    return;
  }

  ThemeData get themeData {
    final themeData = AppThemeData.themeData[currentTheme]!;
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

  // 设置主题
  Future<void> setTheme(AppThemeType theme) async {
    if (_useAccountTheme) {
      // 如果是登录状态，更新账号主题
      if (_accountTheme != theme) {
        print('Setting account theme to: $theme');
        _accountTheme = theme;
        notifyListeners();
        await _saveAccountTheme(theme);
      }
    } else {
      print('Cannot set theme: not using account theme');
    }
    // 未登录状态不允许更改主题
  }

  // 强制使用设备主题（用于登录页面等）
  void useDeviceTheme() {
    if (_useAccountTheme) {
      print('Switching to device theme (default_theme)...');
      _useAccountTheme = false;
      notifyListeners();
    }
  }

  // 强制使用账号主题（用于主页面等）
  Future<void> useAccountTheme() async {
    final user = _auth.currentUser;
    if (user != null) {
      if (!_useAccountTheme) {
        print('Switching to account theme...');
        _useAccountTheme = true;
        // 确保加载了最新的账号主题
        await _loadAccountTheme();
      }
    } else {
      print('Cannot use account theme: user not logged in');
    }
  }

  // 保存当前主题为设备主题
  Future<void> saveCurrentThemeAsDeviceTheme() async {
    // 未登录状态不允许更改主题，所以这个方法不再需要
    return;
  }

  // 强制刷新当前用户的主题设置
  Future<void> refreshCurrentTheme() async {
    final user = _auth.currentUser;
    if (user != null && _useAccountTheme) {
      print('Refreshing current theme...');
      await _loadAccountTheme();
    }
  }

  // 获取调试信息
  String getDebugInfo() {
    return 'ThemeProvider Debug:\n'
        '- useAccountTheme: $_useAccountTheme\n'
        '- accountTheme: $_accountTheme\n'
        '- deviceTheme: $_deviceTheme\n'
        '- currentTheme: $currentTheme\n'
        '- currentUser: ${_auth.currentUser?.uid ?? "null"}';
  }
} 