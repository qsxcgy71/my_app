import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../models/app_theme.dart';
import 'email_login_screen.dart';
import 'phone_login_screen.dart';
import 'main_screen.dart';
import 'loading_screen.dart';
import 'register_screen.dart';

class LoginOptionsScreen extends StatelessWidget {
  const LoginOptionsScreen({super.key});

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (userCredential.user != null && context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoadingScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败: ${e.toString()}')),
        );
      }
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LanguageService.supportedLocales.map((locale) {
            final languageService = Provider.of<LanguageService>(context);
            final isSelected = languageService.currentLocale == locale;
            
            return ListTile(
              title: Text(languageService.getLanguageName(locale)),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                languageService.changeLanguage(locale);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentThemeData = themeProvider.currentThemeData;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: AssetImage('assets/login/BG_01_ipad@2x.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 语言选择按钮
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showLanguageDialog(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.language, color: currentThemeData.secondaryColor.withOpacity(0.3)),
                            const SizedBox(width: 8),
                            Text(
                              languageService.getLanguageName(languageService.currentLocale),
                              style: TextStyle(
                                color: currentThemeData.secondaryColor.withOpacity(0.3),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'GenSenRounded',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Image.asset(
                'assets/login/siuromakids_logo_final.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const Spacer(flex: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLoginButton(
                      context,
                      l10n?.emailLogin ?? '使用电邮登入',
                      Icons.email_outlined,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmailLoginScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLoginButton(
                      context,
                      l10n?.googleLogin ?? '使用Google登入',
                      Icons.g_mobiledata,
                      () => _handleGoogleSignIn(context),
                    ),
                    const SizedBox(height: 16),
                    _buildLoginButton(
                      context,
                      l10n?.phoneLogin ?? '使用电话登入',
                      Icons.phone_outlined,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PhoneLoginScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: l10n?.dontHaveAccount ?? '还没有帐户？',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontFamily: 'GenSenRounded',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextSpan(
                        text: l10n?.signUp ?? '注册',
                        style: TextStyle(
                          color: currentThemeData.secondaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'GenSenRounded',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    final bool isGoogleLogin = text == AppLocalizations.of(context)?.googleLogin;
    final currentThemeData = Provider.of<ThemeProvider>(context).currentThemeData;
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.white),
          foregroundColor: MaterialStateProperty.all(currentThemeData.secondaryColor),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(
                color: currentThemeData.searchBoxColor,
                width: 2,
              ),
            ),
          ),
          elevation: MaterialStateProperty.all(0),
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGoogleLogin)
              SvgPicture.asset(
                'assets/login/google-icon-logo.svg',
                width: 22,
                height: 22,
              )
            else
              Icon(icon, size: 24, color: currentThemeData.secondaryColor),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: currentThemeData.secondaryColor,
                fontFamily: 'GenSenRounded',
              ),
            ),
          ],
        ),
      ),
    );
  }
} 