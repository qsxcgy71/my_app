import 'package:flutter/material.dart';
import '../styles/app_text_styles.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'This feature is under development',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
} 