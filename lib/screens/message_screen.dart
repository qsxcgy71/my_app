import 'package:flutter/material.dart';
import '../styles/app_text_styles.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('消息', style: AppTextStyles.titleLarge),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              '消息功能即将上线',
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
} 