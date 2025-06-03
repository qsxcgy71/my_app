import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../styles/app_text_styles.dart';
import '../services/auth_service.dart';
import '../widgets/keyboard_dismisser.dart';
import '../widgets/anti_spam_button.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  void _showMessage(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(l10n.pleaseEnterEmail, true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.resetPassword(email);
      if (mounted) {
        _showMessage(l10n.resetPasswordSuccess, false);
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? l10n.resetPasswordFailed, true);
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
          l10n.forgetPasswordTitle,
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
                      l10n.forgetPasswordTitle,
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.forgetPasswordDescription,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
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
                    const SizedBox(height: 24),
                    AntiSpamButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      child: Text(l10n.resetPassword, style: AppTextStyles.button.copyWith(color: Colors.white)),
                    ),
                    const SizedBox(height: 16),
                    AntiSpamWrapper(
                      onTap: () => Navigator.pop(context),
                      child: TextButton(
                        onPressed: null, // 由 AntiSpamWrapper 处理
                        child: Text(
                          l10n.backToLogin,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
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