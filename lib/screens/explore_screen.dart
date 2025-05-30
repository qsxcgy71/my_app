import 'package:flutter/material.dart';
import '../styles/app_text_styles.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('探索', style: AppTextStyles.titleLarge),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              '探索功能即将上线',
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
} 