import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../styles/app_text_styles.dart';
import '../models/app_theme.dart';
import '../providers/theme_provider.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final currentTheme = themeProvider.currentThemeData;
        
        return PopupMenuButton<AppThemeType>(
          initialValue: themeProvider.currentTheme,
          tooltip: '选择主题',
          icon: Icon(
            Icons.palette,
            color: currentTheme.primaryColor,
          ),
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          itemBuilder: (context) => AppThemeData.themeData.entries.map((entry) {
            final theme = entry.value;
            final isSelected = entry.key == themeProvider.currentTheme;
            
            return PopupMenuItem<AppThemeType>(
              value: entry.key,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      theme.icon,
                      color: theme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      theme.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: theme.primaryColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isSelected) ...[
                      const Spacer(),
                      Icon(
                        Icons.check_circle,
                        color: theme.primaryColor,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
          onSelected: (AppThemeType selectedTheme) {
            themeProvider.setTheme(selectedTheme);
          },
        );
      },
    );
  }
} 