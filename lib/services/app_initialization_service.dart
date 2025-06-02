import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../providers/theme_provider.dart';
import 'profile_service.dart';
import 'lesson_service.dart';

class AppInitializationService {
  final BuildContext context;
  final void Function(String) onStatusUpdate;

  AppInitializationService({
    required this.context,
    required this.onStatusUpdate,
  });

  Future<bool> initializeApp() async {
    try {
      // 1. Initialize theme
      onStatusUpdate('Loading theme...');
      final themeProvider = ThemeProvider();
      await themeProvider.init();

      // 2. Check authentication status
      onStatusUpdate('Checking authentication...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      // 3. Load user profile
      onStatusUpdate('Loading profile...');
      final profileService = ProfileService();
      await profileService.getUserProfile();

      // 4. Load initial lessons data
      onStatusUpdate('Loading lessons...');
      final lessonService = LessonService();
      await Future.wait([
        lessonService.getEnrolledLessons(),
        lessonService.getCompletedLessons(),
      ]);

      return true;
    } catch (e) {
      print('Error during app initialization: $e');
      return false;
    }
  }
} 