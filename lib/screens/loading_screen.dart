import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/auth_wrapper.dart';
import '../providers/theme_provider.dart';
import 'main_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 获取主题提供者并立即设置为甜声主题（未登录状态的默认主题）
      if (!mounted) return;
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.useDeviceTheme();
      
      // 等待一小段时间以确保所有数据都已加载
      await Future.delayed(const Duration(seconds: 3));
      
      if (!mounted) return;
      
      // 获取当前用户
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // 如果用户已登录，使用账号主题
        themeProvider.useAccountTheme();
        
        // 导航到主屏幕
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainScreen(initialIndex: 0),
            ),
          );
        }
      } else {
        // 如果用户未登录，保持甜声主题并导航到AuthWrapper
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const AuthWrapper(),
            ),
          );
        }
      }
    } catch (e) {
      print('Error in LoadingScreen: $e');
      // 如果出现错误，等待一段时间后再次尝试
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _initializeApp(); // 重试初始化
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: AssetImage('assets/login/BG_01_ipad@2x.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Image.asset(
                'assets/login/siuromakids_logo_final.png',
                width: size.width * 0.4,  // 让 logo 大小随屏幕大小变化
                height: size.width * 0.4,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              Shimmer.fromColors(
                baseColor: theme.colorScheme.secondary.withOpacity(0.7),
                highlightColor: Colors.white,
                period: const Duration(milliseconds: 1500),
                child: Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}