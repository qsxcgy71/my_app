import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
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
      // 等待Firebase Auth初始化完成
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 获取当前用户
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // 确保主题数据已加载
        if (!mounted) return;
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        await themeProvider.init();
        
        // 等待一小段时间以确保所有数据都已加载
        await Future.delayed(const Duration(seconds: 1));
        
        if (!mounted) return;
        // 导航到主屏幕
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainScreen(initialIndex: 0),
          ),
        );
      } else {
        // 如果没有用户登录，导航到AuthWrapper
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
          ),
        );
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 使用app_icon_1.png图片
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/app_icon/app_icon_1.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 