import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../styles/app_text_styles.dart';
import '../providers/theme_provider.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;

    return Scaffold(
      backgroundColor: currentTheme.primaryColor.withOpacity(0.05),
      appBar: AppBar(
        backgroundColor: currentTheme.primaryColor.withOpacity(0.1),
        elevation: 0,
        title: Text(
          '探索',
          style: AppTextStyles.titleLarge.copyWith(
            color: currentTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(), // 空白的主体内容
    );
  }
} 