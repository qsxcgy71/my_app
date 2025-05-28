import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'screens/main_screen.dart';
import 'screens/forget_password_screen.dart';
import 'screens/register_screen.dart';
import 'styles/app_text_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  String? _verificationId;
  bool _isLoading = false;
  int _tabIndex = 0;
  String _selectedCountryCode = '+852'; // Default to Hong Kong

  void _showError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? '登录失败',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('请输入邮箱和密码');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
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
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        _navigateToHome();
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _verifyPhone() async {
    if (_phoneController.text.isEmpty) {
      _showError('请输入手机号码');
      return;
    }

    setState(() => _isLoading = true);
    final phoneNumber = '$_selectedCountryCode${_phoneController.text.trim()}';
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
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
    if (_verificationId == null || _smsCodeController.text.isEmpty) {
      _showError('请输入验证码');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _smsCodeController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
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
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your account to continue',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 24),
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment(
                      value: 0,
                      label: Text('Email', style: AppTextStyles.button),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Phone', style: AppTextStyles.button),
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
                      labelText: 'Email',
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
                      labelText: 'Password',
                      labelStyle: AppTextStyles.bodyMedium,
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    style: AppTextStyles.bodyMedium,
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _isLoading ? null : _signInWithEmail,
                    child: Text('Login', style: AppTextStyles.button.copyWith(color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgetPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot password?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).primaryColor,
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
                            labelText: 'Phone Number',
                            labelStyle: AppTextStyles.bodyMedium,
                            hintText: 'Enter phone number',
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
                  FilledButton(
                    onPressed: _isLoading ? null : _verifyPhone,
                    child: Text('Send Code', style: AppTextStyles.button.copyWith(color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _smsCodeController,
                    decoration: InputDecoration(
                      labelText: 'SMS Code',
                      labelStyle: AppTextStyles.bodyMedium,
                      prefixIcon: const Icon(Icons.sms),
                    ),
                    style: AppTextStyles.bodyMedium,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _isLoading ? null : _signInWithSmsCode,
                    child: Text('Verify & Login', style: AppTextStyles.button.copyWith(color: Colors.white)),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.g_mobiledata),
                  label: Text(
                    'Continue with Google',
                    style: AppTextStyles.button.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: AppTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign up',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).primaryColor,
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
    );
  }
} 