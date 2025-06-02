import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'main_screen.dart';
import 'forget_password_screen.dart';
import 'register_screen.dart';
import '../styles/app_text_styles.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../widgets/keyboard_dismisser.dart';
import '../widgets/anti_spam_button.dart';
import 'package:country_code_picker/country_code_picker.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  String? _verificationId;
  bool _isLoading = false;
  int _tabIndex = 0;
  String _selectedCountryCode = '+852'; // Default to Hong Kong

  // 显示语言选择对话框
  void _showLanguageDialog() {
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

  void _showError(String? message) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? l10n.loginFailed,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen(initialIndex: 0)),
    );
  }

  Future<void> _signInWithEmail() async {
    final l10n = AppLocalizations.of(context)!;
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError(l10n.pleaseEnterEmailAndPassword);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        _navigateToHome();
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null && mounted) {
        _navigateToHome();
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _verifyPhone() async {
    final l10n = AppLocalizations.of(context)!;
    if (_phoneController.text.isEmpty) {
      _showError(l10n.pleaseEnterPhoneNumber);
      return;
    }

    setState(() => _isLoading = true);
    final phoneNumber = '$_selectedCountryCode${_phoneController.text.trim()}';
    await _authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _authService.signInWithCredential(credential);
        if (mounted) {
          _navigateToHome();
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        _showError(e.message);
        setState(() => _isLoading = false);
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _signInWithSmsCode() async {
    final l10n = AppLocalizations.of(context)!;
    if (_verificationId == null || _smsCodeController.text.isEmpty) {
      _showError(l10n.pleaseEnterVerificationCode);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signInWithPhoneNumber(
        _verificationId!,
        _smsCodeController.text.trim(),
      );
      if (mounted) {
        _navigateToHome();
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return KeyboardDismissibleScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 语言选择按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AntiSpamWrapper(
                          onTap: _showLanguageDialog,
                          child: TextButton.icon(
                            icon: const Icon(Icons.language),
                            label: Text(l10n.language),
                            onPressed: null, // 由 AntiSpamWrapper 处理
                          ),
                        ),
                      ],
                    ),
                    
                    Text(
                      l10n.welcomeBack,
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.signInToContinue,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(
                          value: 0,
                          label: Text(l10n.email, style: AppTextStyles.button),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text(l10n.phone, style: AppTextStyles.button),
                        ),
                      ],
                      selected: {_tabIndex},
                      onSelectionChanged: (s) => setState(() => _tabIndex = s.first),
                    ),
                    const SizedBox(height: 16),
                    if (_tabIndex == 0) ...[
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: l10n.email,
                          labelStyle: AppTextStyles.bodyMedium,
                          prefixIcon: const Icon(Icons.email),
                        ),
                        style: AppTextStyles.bodyMedium,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: l10n.password,
                          labelStyle: AppTextStyles.bodyMedium,
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        style: AppTextStyles.bodyMedium,
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      AntiSpamButton(
                        onPressed: _isLoading ? null : _signInWithEmail,
                        child: Text(l10n.login, style: AppTextStyles.button.copyWith(color: Colors.white)),
                      ),
                      AntiSpamWrapper(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgetPasswordScreen(),
                            ),
                          );
                        },
                        child: TextButton(
                          onPressed: null, // 由 AntiSpamWrapper 处理
                          child: Text(
                            l10n.forgotPassword,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          // 国家代码选择器区域
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.withOpacity(0.1), // 淡灰色背景，增强对比度
                            ),
                            width: 115, // 固定宽度，便于对齐
                            height: 56, // 与 TextField 高度一致
                            child: CountryCodePicker(
                              onChanged: (CountryCode countryCode) {
                                setState(() {
                                  _selectedCountryCode = countryCode.dialCode ?? '+852';
                                });
                              },
                              initialSelection: 'HK',
                              favorite: const ['HK', 'CN'],
                              showCountryOnly: false,
                              showOnlyCountryWhenClosed: false,
                              alignLeft: false,
                              textStyle: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 16,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                              dialogBackgroundColor: Colors.white,
                              barrierColor: Colors.black54,
                              flagWidth: 24,
                              padding: EdgeInsets.zero,
                              boxDecoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // 手机号输入框
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: l10n.phoneNumber,
                                labelStyle: AppTextStyles.bodyMedium,
                                hintText: l10n.enterPhoneNumber,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              ),
                              style: AppTextStyles.bodyMedium,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AntiSpamButton(
                        onPressed: _isLoading ? null : _verifyPhone,
                        child: Text(l10n.sendCode, style: AppTextStyles.button.copyWith(color: Colors.white)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _smsCodeController,
                        decoration: InputDecoration(
                          labelText: l10n.smsCode,
                          labelStyle: AppTextStyles.bodyMedium,
                          prefixIcon: const Icon(Icons.sms),
                        ),
                        style: AppTextStyles.bodyMedium,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      AntiSpamButton(
                        onPressed: _isLoading ? null : _signInWithSmsCode,
                        child: Text(l10n.verifyAndLogin, style: AppTextStyles.button.copyWith(color: Colors.white)),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    AntiSpamButton(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ).copyWith(
                        elevation: MaterialStateProperty.all(0),
                        side: MaterialStateProperty.all(
                          BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        backgroundColor: MaterialStateProperty.all(Colors.transparent),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.g_mobiledata),
                          const SizedBox(width: 8),
                          Text(
                            l10n.continueWithGoogle,
                            style: AppTextStyles.button.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.dontHaveAccount,
                          style: AppTextStyles.bodyMedium,
                        ),
                        AntiSpamWrapper(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: TextButton(
                            onPressed: null, // 由 AntiSpamWrapper 处理
                            child: Text(
                              l10n.signUp,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 