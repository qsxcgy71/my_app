import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 获取用户资料
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      print('Get user profile error: $e');
      rethrow;
    }
  }

  // 更新用户资料
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await _firestore.collection('users').doc(user.uid).set(
        data,
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Update user profile error: $e');
      rethrow;
    }
  }

  // 创建新用户资料
  Future<void> createUserProfile(User user, {Map<String, dynamic>? additionalData}) async {
    try {
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'phoneNumber': user.phoneNumber,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      };

      await _firestore.collection('users').doc(user.uid).set(userData);
    } catch (e) {
      print('Create user profile error: $e');
      rethrow;
    }
  }

  // 更新最后登录时间
  Future<void> updateLastLoginTime() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Update last login time error: $e');
      // 不抛出异常，因为这不是关键操作
    }
  }

  // 删除用户资料
  Future<void> deleteUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    } catch (e) {
      print('Delete user profile error: $e');
      rethrow;
    }
  }
} 