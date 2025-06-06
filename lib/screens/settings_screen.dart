import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../styles/app_text_styles.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../models/app_theme.dart';
import 'loading_screen.dart';
import '../widgets/auth_wrapper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageService = Provider.of<LanguageService>(context);
    final _authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectTheme, style: AppTextStyles.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          // Language Section
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language, style: AppTextStyles.bodyLarge),
            trailing: DropdownButton<Locale>(
              value: languageService.currentLocale,
              items: [
                DropdownMenuItem(
                  value: const Locale('en'),
                  child: Text(l10n.english, style: AppTextStyles.bodyMedium),
                ),
                DropdownMenuItem(
                  value: const Locale('zh'),
                  child: Text(l10n.chinese, style: AppTextStyles.bodyMedium),
                ),
                DropdownMenuItem(
                  value: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
                  child: Text('繁體中文', style: AppTextStyles.bodyMedium),
                ),
              ],
              onChanged: (Locale? locale) {
                if (locale != null) {
                  languageService.changeLanguage(locale);
                }
              },
            ),
          ),
          const Divider(),

          // Theme Section
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text(l10n.selectTheme, style: AppTextStyles.bodyLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: AppThemeType.values.map((themeType) {
                final themeData = AppThemeData.themeData[themeType]!;
                final isSelected = themeProvider.currentTheme == themeType;
                
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 48) / 2,
                  child: ChoiceChip(
                    labelPadding: EdgeInsets.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeData.backgroundColor,
                          ),
                          child: Image.asset(
                            themeData.iconAsset,
                            width: 24,
                            height: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Center(
                            child: Text(
                              themeData.getLocalizedName(l10n),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isSelected ? Colors.white : themeData.primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: themeData.primaryColor,
                    backgroundColor: themeData.backgroundColor,
                    onSelected: (bool selected) {
                      if (selected) {
                        themeProvider.setTheme(themeType);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),

          // Logout Section
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n.logout, 
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.red),
            ),
            onTap: () => _showLogoutConfirmation(context, l10n, _authService),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context, AppLocalizations l10n, AuthService authService) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.confirmLogout, style: AppTextStyles.titleLarge),
          content: Text(
            l10n.logoutMessage,
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel, style: AppTextStyles.bodyMedium),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.logout, style: AppTextStyles.bodyMedium),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // 先导航到 loading 页面
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoadingScreen()),
        (route) => false,
      );
      
      // 执行登出操作
      await authService.signOut();
      
      // 登出后延迟一小段时间再导航到登录选项页面
      await Future.delayed(const Duration(milliseconds: 800));
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      }
    }
  }
} 