import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _scriptKey = 'selected_script';
  Locale _currentLocale = const Locale('zh'); // 默认简体中文

  Locale get currentLocale => _currentLocale;

  // 支持的语言列表
  static const List<Locale> supportedLocales = [
    Locale('zh'), // 简体中文
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'), // 繁体中文
    Locale('en'), // 英文
  ];

  // 初始化语言设置
  Future<void> initLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'zh';
    final scriptCode = prefs.getString(_scriptKey);
    _currentLocale = scriptCode != null 
        ? Locale.fromSubtags(languageCode: languageCode, scriptCode: scriptCode)
        : Locale(languageCode);
    notifyListeners();
  }

  // 切换语言
  Future<void> changeLanguage(Locale locale) async {
    if (_currentLocale == locale) return;
    
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
    if (locale.scriptCode != null) {
      await prefs.setString(_scriptKey, locale.scriptCode!);
    } else {
      await prefs.remove(_scriptKey);
    }
    notifyListeners();
  }

  // 获取语言显示名称
  String getLanguageName(Locale locale) {
    if (locale.languageCode == 'zh') {
      if (locale.scriptCode == 'Hant') {
        return '繁體中文';
      }
      return '简体中文';
    }
    return 'English';
  }
} 