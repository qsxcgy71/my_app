import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

enum AppThemeType {
  blue,
  purple,
  green,
  orange,
  red,
  pink,
  teal,
  indigo,
  brown,
  grey,
  cyan,
  amber,
}

class AppThemeData {
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final String name;

  const AppThemeData({
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.name,
  });

  String getLocalizedName(AppLocalizations l10n) {
    switch (name) {
      case '海洋蓝':
        return l10n.themeOceanBlue;
      case '神秘紫':
        return l10n.themeMysteryPurple;
      case '森林绿':
        return l10n.themeForestGreen;
      case '活力橙':
        return l10n.themeVibrantOrange;
      case '热情红':
        return l10n.themePassionRed;
      case '浪漫粉':
        return l10n.themeRomanticPink;
      case '青碧绿':
        return l10n.themeTealGreen;
      case '靛青蓝':
        return l10n.themeIndigoBlue;
      case '大地棕':
        return l10n.themeEarthBrown;
      case '优雅灰':
        return l10n.themeElegantGrey;
      case '清新青':
        return l10n.themeFreshCyan;
      case '金秋黄':
        return l10n.themeGoldenAmber;
      default:
        return name;
    }
  }

  static final themeData = {
    AppThemeType.blue: AppThemeData(
      primaryColor: Colors.blue,
      secondaryColor: Colors.blueAccent,
      icon: Icons.water_drop,
      name: '海洋蓝',
    ),
    AppThemeType.purple: AppThemeData(
      primaryColor: Colors.purple,
      secondaryColor: Colors.purpleAccent,
      icon: Icons.format_paint,
      name: '神秘紫',
    ),
    AppThemeType.green: AppThemeData(
      primaryColor: Colors.green,
      secondaryColor: Colors.greenAccent,
      icon: Icons.forest,
      name: '森林绿',
    ),
    AppThemeType.orange: AppThemeData(
      primaryColor: Colors.orange,
      secondaryColor: Colors.orangeAccent,
      icon: Icons.sunny,
      name: '活力橙',
    ),
    AppThemeType.red: AppThemeData(
      primaryColor: Colors.red,
      secondaryColor: Colors.redAccent,
      icon: Icons.favorite,
      name: '热情红',
    ),
    AppThemeType.pink: AppThemeData(
      primaryColor: Colors.pink,
      secondaryColor: Colors.pinkAccent,
      icon: Icons.spa,
      name: '浪漫粉',
    ),
    AppThemeType.teal: AppThemeData(
      primaryColor: Colors.teal,
      secondaryColor: Colors.tealAccent,
      icon: Icons.waves,
      name: '青碧绿',
    ),
    AppThemeType.indigo: AppThemeData(
      primaryColor: Colors.indigo,
      secondaryColor: Colors.indigoAccent,
      icon: Icons.nights_stay,
      name: '靛青蓝',
    ),
    AppThemeType.brown: AppThemeData(
      primaryColor: Colors.brown,
      secondaryColor: Colors.brown.shade300,
      icon: Icons.terrain,
      name: '大地棕',
    ),
    AppThemeType.grey: AppThemeData(
      primaryColor: Colors.grey,
      secondaryColor: Colors.grey.shade400,
      icon: Icons.cloud,
      name: '优雅灰',
    ),
    AppThemeType.cyan: AppThemeData(
      primaryColor: Colors.cyan,
      secondaryColor: Colors.cyanAccent,
      icon: Icons.pool,
      name: '清新青',
    ),
    AppThemeType.amber: AppThemeData(
      primaryColor: Colors.amber,
      secondaryColor: Colors.amberAccent,
      icon: Icons.wb_sunny,
      name: '金秋黄',
    ),
  };
} 