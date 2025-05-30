import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'services/language_service.dart';
import 'services/auth_service.dart';
import 'providers/theme_provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Firebase App Check in debug mode
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      // Use debug provider for development
      appleProvider: AppleProvider.debug,
    );
    
    print('Firebase App Check initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageService()),
        Provider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, ThemeProvider>(
      builder: (context, languageService, themeProvider, child) {
        return RefreshConfiguration(
          headerBuilder: () => WaterDropHeader(
            waterDropColor: themeProvider.currentThemeData.primaryColor,
            complete: Text(
              'Refresh completed',
              style: TextStyle(color: Colors.grey[600]),
            ),
            failed: Text(
              'Refresh failed',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          footerBuilder: () => ClassicFooter(
            loadStyle: LoadStyle.ShowWhenLoading,
            completeDuration: const Duration(milliseconds: 500),
          ),
          headerTriggerDistance: 80.0,
          springDescription: const SpringDescription(
            stiffness: 170,
            damping: 16,
            mass: 1.9
          ),
          maxOverScrollExtent: 100,
          maxUnderScrollExtent: 0,
          enableScrollWhenRefreshCompleted: true,
          enableLoadingWhenFailed: true,
          hideFooterWhenNotFull: false,
          enableBallisticLoad: true,
          child: MaterialApp(
            title: 'Kids Profile',
            theme: themeProvider.themeData,
            // 国际化配置
            locale: languageService.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LanguageService.supportedLocales,
            home: const AuthWrapper(),
          ),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Timer? _authCheckTimer;
  
  @override
  void initState() {
    super.initState();
    // 定期检查认证状态，防止卡住
    _authCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          // 强制刷新状态
        });
      }
    });
  }
  
  @override
  void dispose() {
    _authCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        print('AuthWrapper - ConnectionState: ${snapshot.connectionState}');
        print('AuthWrapper - HasData: ${snapshot.hasData}');
        print('AuthWrapper - User: ${snapshot.data?.uid ?? 'null'}');
        
        // 强制检查Firebase当前用户状态
        final currentUser = FirebaseAuth.instance.currentUser;
        print('AuthWrapper - Firebase currentUser: ${currentUser?.uid ?? 'null'}');
        
        // 如果没有用户，直接显示登录页面
        if (currentUser == null) {
          print('AuthWrapper - No user, showing LoginScreen');
          return const LoginScreen();
        }
        
        // 等待认证状态加载，但减少等待时间
        if (snapshot.connectionState == ConnectionState.waiting && 
            snapshot.data == null) {
          print('AuthWrapper - Waiting for auth state...');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // 有用户登录，显示主界面
        if (currentUser != null) {
          print('AuthWrapper - User is authenticated, showing MainScreen');
          return const MainScreen();
        } else {
          print('AuthWrapper - User is not authenticated, showing LoginScreen');
          return const LoginScreen();
        }
      },
    );
  }
}
