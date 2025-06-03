import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import 'main_screen.dart';
import '../styles/app_text_styles.dart';
import '../services/auth_service.dart';
import '../widgets/keyboard_dismisser.dart';
import '../widgets/anti_spam_button.dart';
import '../screens/loading_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  void _showError(String? message) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? l10n.registrationFailed,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _signUp() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showError(l10n.pleaseEnterAllFields);
      return;
    }

    if (password != confirm) {
      _showError(l10n.passwordsDoNotMatch);
      return;
    }

    if (password.length < 6) {
      _showError(l10n.passwordTooShort);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.registerWithEmail(email, password);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoadingScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return KeyboardDismissibleScaffold(
      appBar: AppBar(
        title: Text(
          l10n.createAccount,
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
      ),
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
                    Text(
                      l10n.signUpTitle,
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        labelStyle: AppTextStyles.bodyMedium,
                        prefixIcon: const Icon(Icons.email),
                      ),
                      style: AppTextStyles.bodyMedium,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        labelStyle: AppTextStyles.bodyMedium,
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      style: AppTextStyles.bodyMedium,
                      obscureText: true,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmController,
                      decoration: InputDecoration(
                        labelText: l10n.confirmPassword,
                        labelStyle: AppTextStyles.bodyMedium,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      style: AppTextStyles.bodyMedium,
                      obscureText: true,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 24),
                    AntiSpamButton(
                      onPressed: _isLoading ? null : _signUp,
                      child: Text(l10n.createAccount, style: AppTextStyles.button.copyWith(color: Colors.white)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.alreadyHaveAccount,
                          style: AppTextStyles.bodyMedium,
                        ),
                        AntiSpamWrapper(
                          onTap: () => Navigator.pop(context),
                          child: TextButton(
                            onPressed: null, // 由 AntiSpamWrapper 处理
                            child: Text(
                              l10n.signIn,
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