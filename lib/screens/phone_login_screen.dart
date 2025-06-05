import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/app_theme.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';
import 'main_screen.dart';
import 'loading_screen.dart';

class CountryCode {
  final String name;
  final String code;
  final String flag;
  final int minLength;
  final int maxLength;
  final String pattern; // 电话号码的正则表达式模式

  const CountryCode({
    required this.name,
    required this.code,
    required this.flag,
    required this.minLength,
    required this.maxLength,
    required this.pattern,
  });

  bool isValidPhoneNumber(String number) {
    if (number.length < minLength || number.length > maxLength) {
      return false;
    }
    final RegExp regex = RegExp(pattern);
    return regex.hasMatch(number);
  }

  String getLengthDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (minLength == maxLength) {
      return l10n.digits(minLength);
    }
    return l10n.digitsRange(minLength, maxLength);
  }
}

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _smsController = TextEditingController();
  bool _isVerifyingPhone = false; // 获取验证码按钮的加载状态
  bool _isVerifyingSms = false;   // 登录按钮的加载状态
  bool _codeSent = false;
  String _verificationId = '';
  
  // 添加倒计时相关变量
  Timer? _countdownTimer;
  int _countdownSeconds = 0;
  static const int _totalCountdownSeconds = 60;

  // 更新国家代码列表，添加电话号码验证规则
  final List<CountryCode> _countryCodes = [
    CountryCode(
      name: '中国', 
      code: '+86', 
      flag: '🇨🇳',
      minLength: 11,
      maxLength: 11,
      pattern: r'^1[3-9]\d{9}$',
    ),
    CountryCode(
      name: '香港', 
      code: '+852', 
      flag: '🇭🇰',
      minLength: 8,
      maxLength: 8,
      pattern: r'^\d{8}$',
    ),
    CountryCode(
      name: '澳门', 
      code: '+853', 
      flag: '🇲🇴',
      minLength: 8,
      maxLength: 8,
      pattern: r'^\d{8}$',
    ),
    CountryCode(
      name: '台湾', 
      code: '+886', 
      flag: '🇹🇼',
      minLength: 9,
      maxLength: 9,
      pattern: r'^\d{9}$',
    ),
  ];

  CountryCode _selectedCountry = CountryCode(
    name: '香港', 
    code: '+852', 
    flag: '🇭🇰',
    minLength: 8,
    maxLength: 8,
    pattern: r'^\d{8}$',
  );

  void _showCountryCodePicker() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currentThemeData = themeProvider.currentThemeData;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    l10n.selectCountryRegion,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                      fontFamily: 'GenSenRounded',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.secondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _countryCodes.length,
                itemBuilder: (context, index) {
                  final country = _countryCodes[index];
                  return ListTile(
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      country.name,
                      style: TextStyle(
                        color: colorScheme.secondary,
                        fontFamily: 'GenSenRounded',
                      ),
                    ),
                    trailing: Text(
                      country.getLengthDescription(context),
                      style: TextStyle(
                        color: colorScheme.secondary,
                        fontFamily: 'GenSenRounded',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      setState(() => _selectedCountry = country);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startCountdown() {
    _countdownSeconds = _totalCountdownSeconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          _countdownTimer?.cancel();
        }
      });
    });
  }

  Future<void> _verifyPhone() async {
    final l10n = AppLocalizations.of(context)!;
    final phoneNumber = _phoneController.text.trim();
    
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterPhoneNumber)),
      );
      return;
    }
    
    if (!_selectedCountry.isValidPhoneNumber(phoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterValidPhoneNumber(
          _selectedCountry.name,
          _selectedCountry.getLengthDescription(context),
        ))),
      );
      return;
    }

    if (_countdownSeconds > 0) return;

    setState(() => _isVerifyingPhone = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '${_selectedCountry.code}${phoneNumber}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          String message = l10n.verificationFailed;
          if (e.code == 'invalid-phone-number') {
            message = l10n.invalidPhoneNumber;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          setState(() => _isVerifyingPhone = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isVerifyingPhone = false;
          });
          _startCountdown();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.verificationCodeSent)),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
            _isVerifyingPhone = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.verificationCodeExpired)),
          );
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() => _isVerifyingPhone = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.verificationFailed)),
      );
    }
  }

  Future<void> _verifySmsCode() async {
    final l10n = AppLocalizations.of(context)!;
    final smsCode = _smsController.text.trim();
    if (smsCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterVerificationCode)),
      );
      return;
    }

    setState(() => _isVerifyingSms = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );
      await _signInWithCredential(credential);
    } finally {
      if (mounted) {
        setState(() => _isVerifyingSms = false);
      }
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.verificationFailed)),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _smsController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentThemeData = themeProvider.currentThemeData;
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
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
          l10n.phoneLogin,
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
          // 背景层
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
          // 内容层
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
                                      l10n.welcomeBack,
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
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    enabled: !_codeSent,
                                    style: TextStyle(
                                      color: colorScheme.secondary,
                                      fontFamily: 'GenSenRounded',
                                    ),
                                    decoration: InputDecoration(
                                      labelText: l10n.phoneNumber,
                                      helperText: l10n.pleaseEnterPhoneNumberWithLength(
                                        _selectedCountry.getLengthDescription(context)
                                      ),
                                      helperStyle: TextStyle(
                                        color: colorScheme.secondary.withOpacity(0.7),
                                        fontFamily: 'GenSenRounded',
                                      ),
                                      labelStyle: TextStyle(
                                        color: colorScheme.secondary.withOpacity(0.7),
                                        fontFamily: 'GenSenRounded',
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: currentThemeData.searchBoxColor.withOpacity(0.7),width:2),
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
                                      disabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: currentThemeData.searchBoxColor),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      errorStyle: const TextStyle(
                                        fontFamily: 'GenSenRounded',
                                      ),
                                      prefixIcon: TextButton(
                                        onPressed: !_codeSent ? _showCountryCodePicker : null,
                                        style: ButtonStyle(
                                          padding: MaterialStateProperty.all(EdgeInsets.zero),
                                          minimumSize: MaterialStateProperty.all(const Size(80, 0)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(width: 12),
                                            Text(
                                              '${_selectedCountry.flag} ${_selectedCountry.code}',
                                              style: TextStyle(
                                                color: colorScheme.secondary.withOpacity(_codeSent ? 0.5 : 1.0),
                                                fontFamily: 'GenSenRounded',
                                                fontSize: 16,
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              color: colorScheme.secondary.withOpacity(_codeSent ? 0.5 : 1.0),
                                            ),
                                          ],
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(_codeSent ? 0.7 : 0.9),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: (_isVerifyingPhone || _countdownSeconds > 0) ? null : _verifyPhone,
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
                                      child: Opacity(
                                        opacity: _countdownSeconds > 0 ? 0.5 : 1.0,
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
                                            child: _isVerifyingPhone
                                                ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                    ),
                                                  )
                                                : Text(
                                                    _countdownSeconds > 0 
                                                        ? l10n.resendCode(_countdownSeconds)
                                                        : l10n.getVerificationCode,
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
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _smsController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                      color: colorScheme.secondary,
                                      fontFamily: 'GenSenRounded',
                                    ),
                                    decoration: InputDecoration(
                                      labelText: l10n.verificationCode,
                                      labelStyle: TextStyle(
                                        color: colorScheme.secondary.withOpacity(0.7),
                                        fontFamily: 'GenSenRounded',
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: currentThemeData.searchBoxColor.withOpacity(0.7),width:2),
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
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isVerifyingSms ? null : _verifySmsCode,
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
                                          child: _isVerifyingSms
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : Text(
                                                  l10n.login,
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