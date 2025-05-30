import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../styles/app_text_styles.dart';
import '../models/app_theme.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  Widget _buildColorSwatch(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final currentTheme = themeProvider.currentThemeData;
        
        return PopupMenuButton<AppThemeType>(
          initialValue: themeProvider.currentTheme,
          tooltip: l10n.selectTheme,
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentTheme.backgroundColor,
            ),
            child: Image.asset(
              currentTheme.iconAsset,
              width: 24,
              height: 24,
            ),
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
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.backgroundColor,
                      ),
                      child: Image.asset(
                        theme.iconAsset,
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            theme.getLocalizedName(l10n),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: theme.primaryColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildColorSwatch(theme.primaryColor),
                              _buildColorSwatch(theme.secondaryColor),
                              _buildColorSwatch(theme.searchBoxColor),
                              _buildColorSwatch(theme.backgroundColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: theme.primaryColor,
                        size: 18,
                      ),
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