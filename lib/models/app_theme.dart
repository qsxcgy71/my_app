import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

enum AppThemeType {
  reduce,    // 降溫主題
  tepid,     // 暖和主題
  defence,   // 護衛主題
  dreams,    // 美夢主題
  energize,  // 活力主題
  joyful,    // 喜悅主題
  fresh,     // 清新主題
  peaceful,  // 安定主題
  agile,     // 敏捷主題
  melody,    // 甜聲主題
  respire,   // 呼吸主題
  comfort,   // 舒暢主題
}

class AppThemeData {
  final Color primaryColor;    // 主色，标题文字色，按钮色1
  final Color secondaryColor;  // top bar颜色，按钮色2
  final Color searchBoxColor;  // Searchbox框颜色
  final Color backgroundColor; // 背景色
  final String iconAsset;     // 主题图标资源路径
  final String name;

  const AppThemeData({
    required this.primaryColor,
    required this.secondaryColor,
    required this.searchBoxColor,
    required this.backgroundColor,
    required this.iconAsset,
    required this.name,
  });

  String getLocalizedName(AppLocalizations l10n) {
    switch (name) {
      case '降溫主題':
        return l10n.themeReduce;
      case '暖和主題':
        return l10n.themeTepid;
      case '護衛主題':
        return l10n.themeDefence;
      case '美夢主題':
        return l10n.themeDreams;
      case '活力主題':
        return l10n.themeEnergize;
      case '喜悅主題':
        return l10n.themeJoyful;
      case '清新主題':
        return l10n.themeFresh;
      case '安定主題':
        return l10n.themePeaceful;
      case '敏捷主題':
        return l10n.themeAgile;
      case '甜聲主題':
        return l10n.themeMelody;
      case '呼吸主題':
        return l10n.themeRespire;
      case '舒暢主題':
        return l10n.themeComfort;
      default:
        return name;
    }
  }

  static Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  static final themeData = {
    AppThemeType.reduce: AppThemeData(
      primaryColor: _parseColor('075590'),
      secondaryColor: _parseColor('74C7E6'),
      searchBoxColor: _parseColor('B0E0F3'),
      backgroundColor: _parseColor('E4FAFC'),
      iconAsset: 'assets/theme_icon/theme_reduce.png',
      name: '降溫主題',
    ),
    AppThemeType.tepid: AppThemeData(
      primaryColor: _parseColor('FC7118'),
      secondaryColor: _parseColor('FF9657'),
      searchBoxColor: _parseColor('FFB487'),
      backgroundColor: _parseColor('FFE4DA'),
      iconAsset: 'assets/theme_icon/theme_tepid.png',
      name: '暖和主題',
    ),
    AppThemeType.defence: AppThemeData(
      primaryColor: _parseColor('10A27C'),
      secondaryColor: _parseColor('46C6A4'),
      searchBoxColor: _parseColor('95D7C7'),
      backgroundColor: _parseColor('E3FCF1'),
      iconAsset: 'assets/theme_icon/theme_defence.png',
      name: '護衛主題',
    ),
    AppThemeType.dreams: AppThemeData(
      primaryColor: _parseColor('6B48A6'),
      secondaryColor: _parseColor('A47ED2'),
      searchBoxColor: _parseColor('B6ACD5'),
      backgroundColor: _parseColor('EFE8F7'),
      iconAsset: 'assets/theme_icon/theme_dreams.png',
      name: '美夢主題',
    ),
    AppThemeType.energize: AppThemeData(
      primaryColor: _parseColor('F87172'),
      secondaryColor: _parseColor('FCA9AB'),
      searchBoxColor: _parseColor('FFCFC6'),
      backgroundColor: _parseColor('FFE3DE'),
      iconAsset: 'assets/theme_icon/theme_energize.png',
      name: '活力主題',
    ),
    AppThemeType.joyful: AppThemeData(
      primaryColor: _parseColor('708431'),
      secondaryColor: _parseColor('B9CD62'),
      searchBoxColor: _parseColor('D3DDA8'),
      backgroundColor: _parseColor('ECF5D0'),
      iconAsset: 'assets/theme_icon/theme_joyful.png',
      name: '喜悅主題',
    ),
    AppThemeType.fresh: AppThemeData(
      primaryColor: _parseColor('1B9BA9'),
      secondaryColor: _parseColor('3ACBD4'),
      searchBoxColor: _parseColor('80D9DE'),
      backgroundColor: _parseColor('DFECEE'),
      iconAsset: 'assets/theme_icon/theme_fresh.png',
      name: '清新主題',
    ),
    AppThemeType.peaceful: AppThemeData(
      primaryColor: _parseColor('FFA302'),
      secondaryColor: _parseColor('FFBD3A'),
      searchBoxColor: _parseColor('FFD757'),
      backgroundColor: _parseColor('FFF7CE'),
      iconAsset: 'assets/theme_icon/theme_peaceful.png',
      name: '安定主題',
    ),
    AppThemeType.agile: AppThemeData(
      primaryColor: _parseColor('CE1730'),
      secondaryColor: _parseColor('E9335E'),
      searchBoxColor: _parseColor('FA7594'),
      backgroundColor: _parseColor('FCDDE1'),
      iconAsset: 'assets/theme_icon/theme_agile.png',
      name: '敏捷主題',
    ),
    AppThemeType.melody: AppThemeData(
      primaryColor: _parseColor('694C2B'),
      secondaryColor: _parseColor('A28456'),
      searchBoxColor: _parseColor('D7A16E'),
      backgroundColor: _parseColor('F7ECDC'),
      iconAsset: 'assets/theme_icon/theme_melody.png',
      name: '甜聲主題',
    ),
    AppThemeType.respire: AppThemeData(
      primaryColor: _parseColor('357837'),
      secondaryColor: _parseColor('65B068'),
      searchBoxColor: _parseColor('90D48E'),
      backgroundColor: _parseColor('DBF3DB'),
      iconAsset: 'assets/theme_icon/theme_respire.png',
      name: '呼吸主題',
    ),
    AppThemeType.comfort: AppThemeData(
      primaryColor: _parseColor('73371E'),
      secondaryColor: _parseColor('AB6840'),
      searchBoxColor: _parseColor('D0926C'),
      backgroundColor: _parseColor('FCF0E9'),
      iconAsset: 'assets/theme_icon/theme_comfort.png',
      name: '舒暢主題',
    ),
  };
} 