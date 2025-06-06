import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/profile_model.dart';
import 'profile_service.dart';
import 'message_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final ProfileService _profileService = ProfileService();
  static final MessageService _messageService = MessageService();

  // 获取当前用户
  User? get currentUser => _auth.currentUser;

  String get currentUserDisplayName => 
      _auth.currentUser?.displayName ?? 
      _auth.currentUser?.email ?? 
      'User';

  // 监听认证状态变化
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google登录
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google sign in error: $e');
      rethrow;
    }
  }

  // 邮箱密码登录
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } catch (e) {
      print('Email sign in error: $e');
      rethrow;
    }
  }

  // 手机号登录 - 发送验证码
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  // 手机号登录 - 验证码登录
  Future<UserCredential> signInWithPhoneNumber(
    String verificationId,
    String smsCode,
  ) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Phone sign in error: $e');
      rethrow;
    }
  }

  // 重置密码
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }

  // 注册新用户
  static Future<UserCredential> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      // 注册成功后发送欢迎消息
      if (userCredential.user != null) {
        try {
          // 获取用户资料以获得姓名，如果没有则使用邮箱前缀
          final profile = await _profileService.getUserProfile();
          final userName = profile?.name ?? email.split('@').first;
          await _messageService.sendWelcomeMessage(userName);
        } catch (e) {
          print('Error sending welcome message: $e');
          // 即使发送消息失败，也不影响注册过程
        }
      }
      
      return userCredential;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  // 退出登录
  Future<void> signOut() async {
    try {
      print('Starting sign out process...');
      
      // 获取当前认证状态
      final currentUser = _auth.currentUser;
      print('Current user before signout: ${currentUser?.uid ?? 'null'}');
      
      // 存储清理状态
      bool googleSignOutSuccess = true;
      bool googleDisconnectSuccess = true;
      bool firebaseSignOutSuccess = true;
      
      // 尝试清除Google登录状态
      try {
        print('Attempting to sign out from Google...');
        await _googleSignIn.signOut().timeout(const Duration(seconds: 10));
        print('Google signOut completed');
      } catch (e) {
        print('Google signOut failed: $e');
        googleSignOutSuccess = false;
      }
      
      // 尝试断开Google连接
      try {
        print('Attempting to disconnect Google...');
        await _googleSignIn.disconnect().timeout(const Duration(seconds: 10));
        print('Google disconnect completed');
      } catch (e) {
        print('Google disconnect failed: $e');
        googleDisconnectSuccess = false;
      }
      
      // 清除Firebase认证状态
      try {
        print('Attempting to sign out from Firebase...');
        await _auth.signOut().timeout(const Duration(seconds: 10));
        print('Firebase signOut completed');
      } catch (e) {
        print('Firebase signOut failed: $e');
        firebaseSignOutSuccess = false;
      }
      
      // 等待状态更新，但设置超时
      print('Waiting for auth state to update...');
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // 验证退出状态
      final userAfterSignOut = _auth.currentUser;
      print('Current user after signout: ${userAfterSignOut?.uid ?? 'null'}');
      
      if (userAfterSignOut != null) {
        print('Warning: User still exists after signout, attempting force signout...');
        try {
          await _auth.signOut().timeout(const Duration(seconds: 5));
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print('Force signout also failed: $e');
        }
      }
      
      // 检查最终状态
      final finalUser = _auth.currentUser;
      print('Final user state: ${finalUser?.uid ?? 'null'}');
      
      // 即使用户仍然存在，也不抛出异常，让UI层处理
      if (finalUser != null) {
        print('WARNING: User still exists after all signout attempts');
        // 不抛出异常，让应用继续执行
      }
      
      print('Sign out process completed');
    } catch (e) {
      print('Sign out error: $e');
      // 不重新抛出异常，让应用继续执行
    }
  }

  // 强制清除认证状态（用于调试和紧急情况）
  Future<void> forceSignOut() async {
    try {
      print('Force signing out...');
      
      // 多次尝试Firebase退出
      for (int i = 0; i < 3; i++) {
        try {
          await _auth.signOut();
          print('Firebase signOut attempt ${i + 1} completed');
          break;
        } catch (e) {
          print('Firebase signOut attempt ${i + 1} failed: $e');
          if (i == 2) rethrow;
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      
      // 尝试Google退出（不抛出异常）
      try {
        await _googleSignIn.signOut();
        print('Google signOut completed');
      } catch (e) {
        print('Google signOut failed (ignored): $e');
      }
      
      try {
        await _googleSignIn.disconnect();
        print('Google disconnect completed');
      } catch (e) {
        print('Google disconnect failed (ignored): $e');
      }
      
      // 最终验证
      await Future.delayed(const Duration(milliseconds: 500));
      final finalUser = _auth.currentUser;
      print('Force sign out completed - final user: ${finalUser?.uid ?? 'null'}');
      
      if (finalUser != null) {
        print('Warning: User still exists after force signout');
      }
    } catch (e) {
      print('Force sign out error: $e');
      // 即使出错也继续，确保清除状态
    }
  }

  // 使用凭证登录
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    try {
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Credential sign in error: $e');
      rethrow;
    }
  }
} 