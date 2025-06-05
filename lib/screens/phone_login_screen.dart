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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 顶部拖拽指示器
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 标题栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Text(
                    l10n.selectCountryRegion,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: currentThemeData.primaryColor,
                      fontFamily: 'GenSenRounded',
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: currentThemeData.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: currentThemeData.primaryColor,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            // 分隔线
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    currentThemeData.secondaryColor.withOpacity(0.3),
                    currentThemeData.primaryColor.withOpacity(0.3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 国家列表
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _countryCodes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final country = _countryCodes[index];
                  final isSelected = _selectedCountry.code == country.code;
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? currentThemeData.primaryColor.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                            ? currentThemeData.primaryColor.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: currentThemeData.primaryColor.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),

                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() => _selectedCountry = country);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // 国旗
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: currentThemeData.backgroundColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    country.flag,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 国家信息
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      country.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: currentThemeData.primaryColor,
                                        fontFamily: 'GenSenRounded',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${country.code} • ${country.getLengthDescription(context)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: currentThemeData.secondaryColor.withOpacity(0.8),
                                        fontFamily: 'GenSenRounded',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 选中指示器
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: currentThemeData.primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
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
            const SizedBox(height: 24),
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