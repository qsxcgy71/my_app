import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/login_options_screen.dart';
import '../providers/theme_provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 在认证相关页面强制使用设备主题
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ThemeProvider>(context, listen: false).useDeviceTheme();
    });

    return const LoginOptionsScreen();
  }
} 