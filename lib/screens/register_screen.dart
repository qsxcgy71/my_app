import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../styles/app_text_styles.dart';
import '../widgets/keyboard_dismisser.dart';
import '../widgets/anti_spam_button.dart';
import '../providers/theme_provider.dart';
import 'loading_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoadingScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      final l10n = AppLocalizations.of(context)!;
      String message = l10n.registrationFailed;
      if (e.code == 'weak-password') {
        message = l10n.weakPassword;
      } else if (e.code == 'email-already-in-use') {
        message = l10n.emailAlreadyInUse;
      } else if (e.code == 'invalid-email') {
        message = l10n.invalidEmailFormat;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.registrationFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentThemeData = themeProvider.currentThemeData;
    final l10n = AppLocalizations.of(context)!;

    return KeyboardDismissibleScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.secondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          l10n.createAccount,
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'GenSenRounded',
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                image: const DecorationImage(
                  image: AssetImage('assets/login/BG_01_ipad@2x.png'),
                  fit: BoxFit.cover,
                  opacity: 0.5,
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      l10n.welcome,
                                      style: TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'GenSenRounded',
                                        foreground: Paint()
                                          ..shader = LinearGradient(
                                            colors: [
                                              colorScheme.secondary,
                                              colorScheme.primary,
                                            ],
                                          ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(
                                      color: colorScheme.secondary,
                                      fontFamily: 'GenSenRounded',
                                    ),
                                    decoration: InputDecoration(
                                      labelText: l10n.email,
                                      labelStyle: TextStyle(
                                        color: colorScheme.secondary.withOpacity(0.7),
                                        fontFamily: 'GenSenRounded',
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: currentThemeData.searchBoxColor.withOpacity(0.7), width: 2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: currentThemeData.searchBoxColor.withOpacity(0.7), width: 3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: theme.colorScheme.error.withOpacity(0.7), width: 2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: theme.colorScheme.error.withOpacity(0.7), width: 3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      errorStyle: const TextStyle(
                                        fontFamily: 'GenSenRounded',
                                      ),
                                      prefixIcon: Icon(Icons.email_outlined, color: colorScheme.secondary.withOpacity(0.7)),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.9),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return l10n.pleaseEnterEmail;
                                      }
                                      if (!value.contains('@')) {
                                        return l10n.pleaseEnterValidEmail;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: TextStyle(
                                      color: colorScheme.secondary,
                                      fontFamily: 'GenSenRounded',
                                    ),
                                    decoration: InputDecoration(
                                      labelText: l10n.password,
                                      labelStyle: TextStyle(
                                        color: colorScheme.secondary.withOpacity(0.7),
                                        fontFamily: 'GenSenRounded',
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: currentThemeData.searchBoxColor.withOpacity(0.7), width: 2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: currentThemeData.searchBoxColor.withOpacity(0.7), width: 3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: theme.colorScheme.error.withOpacity(0.7), width: 2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: theme.colorScheme.error.withOpacity(0.7), width: 3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      errorStyle: const TextStyle(
                                        fontFamily: 'GenSenRounded',
                                      ),
                                      prefixIcon: Icon(Icons.lock_outline, color: colorScheme.secondary.withOpacity(0.7)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          color: colorScheme.secondary.withOpacity(0.7),
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.9),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return l10n.pleaseEnterPassword;
                                      }
                                      if (value.length < 6) {
                                        return l10n.passwordTooShort;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    style: TextStyle(
                                      color: colorScheme.secondary,
                                      fontFamily: 'GenSenRounded',
                                    ),
                                    decoration: InputDecoration(
                                      labelText: l10n.confirmPassword,
                                      labelStyle: TextStyle(
                                        color: colorScheme.secondary.withOpacity(0.7),
                                        fontFamily: 'GenSenRounded',
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: currentThemeData.searchBoxColor.withOpacity(0.7), width: 2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: currentThemeData.searchBoxColor.withOpacity(0.7), width: 3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: theme.colorScheme.error.withOpacity(0.7), width: 2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: theme.colorScheme.error.withOpacity(0.7), width: 3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      errorStyle: const TextStyle(
                                        fontFamily: 'GenSenRounded',
                                      ),
                                      prefixIcon: Icon(Icons.lock_outline, color: colorScheme.secondary.withOpacity(0.7)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                          color: colorScheme.secondary.withOpacity(0.7),
                                        ),
                                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.9),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return l10n.pleaseConfirmPassword;
                                      }
                                      if (value != _passwordController.text) {
                                        return l10n.passwordsDoNotMatch;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleRegister,
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                        foregroundColor: MaterialStateProperty.all(Colors.white),
                                        shape: MaterialStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                        ),
                                        elevation: MaterialStateProperty.all(0),
                                        overlayColor: MaterialStateProperty.resolveWith(
                                          (states) => states.contains(MaterialState.pressed)
                                              ? Colors.white.withOpacity(0.1)
                                              : null,
                                        ),
                                        padding: MaterialStateProperty.all(EdgeInsets.zero),
                                      ),
                                      child: Ink(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              colorScheme.secondary,
                                              colorScheme.primary,
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : Text(
                                                  l10n.register,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                    fontFamily: 'GenSenRounded',
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ButtonStyle(
                                      overlayColor: MaterialStateProperty.all(Colors.transparent),
                                      splashFactory: NoSplash.splashFactory,
                                    ),
                                    child: Text(
                                      l10n.haveAccount,
                                      style: TextStyle(
                                        color: colorScheme.secondary.withOpacity(0.7),
                                        fontSize: 14,
                                        fontFamily: 'GenSenRounded',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 