import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'firebase/firebase_options.dart';
import 'screens/main_screen.dart';
import 'screens/loading_screen.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/language_service.dart';
import 'services/payment_service.dart';
import 'l10n/app_localizations.dart';
import 'widgets/auth_wrapper.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.appAttest,
    );

    // Initialize Stripe
    await PaymentService.initializeStripe();

    // Initialize LanguageService
    final languageService = LanguageService();
    await languageService.initLanguage();

    // Initialize ThemeProvider and load saved theme
    final themeProvider = ThemeProvider();
    await themeProvider.init();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: languageService),
          ChangeNotifierProvider.value(value: themeProvider),
          Provider(create: (_) => AuthService()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('Error initializing app: $e');
    // 即使出错也要启动应用
    final themeProvider = ThemeProvider();
    // 即使在catch块中也要尝试初始化主题
    try {
      await themeProvider.init();
    } catch (initError) {
      print('Error initializing theme provider: $initError');
    }
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageService()),
          ChangeNotifierProvider.value(value: themeProvider),
          Provider(create: (_) => AuthService()),
        ],
        child: const MyApp(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'My App',
      theme: themeProvider.themeData,
      locale: languageService.currentLocale,
      supportedLocales: LanguageService.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LoadingScreen(),
    );
  }
}
