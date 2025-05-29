import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/profile_model.dart';

class ProfileService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  // 获取用户档案
  Future<UserProfile?> getUserProfile() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore.collection('profiles').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromMap({
          ...doc.data()!,
          'userId': userId,
        });
      }
      return null;
    } catch (e) {
      print('Error loading profile: $e');
      throw Exception('Failed to load profile');
    }
  }

  // 创建或更新用户档案
  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('profiles')
          .doc(profile.userId)
          .set(profile.toMap());
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile');
    }
  }

  // 添加或更新子女信息
  Future<void> updateChild(String userId, List<ChildInfo> updatedChildren) async {
    try {
      await _firestore.collection('profiles').doc(userId).update({
        'children': updatedChildren.map((c) => c.toMap()).toList(),
      });
    } catch (e) {
      print('Error updating child: $e');
      throw Exception('Failed to update child information');
    }
  }

  // 删除子女信息
  Future<void> deleteChild(String userId, String childId, String? photoUrl) async {
    try {
      // 删除照片
      if (photoUrl != null) {
        try {
          final photoRef = _storage.refFromURL(photoUrl);
          await photoRef.delete();
        } catch (e) {
          print('Failed to delete photo: $e');
        }
      }

      // 获取当前档案
      final doc = await _firestore.collection('profiles').doc(userId).get();
      if (!doc.exists) return;

      final profile = UserProfile.fromMap({
        ...doc.data()!,
        'userId': userId,
      });

      // 更新子女列表
      final updatedChildren = profile.children.where((c) => c.id != childId).toList();
      await _firestore.collection('profiles').doc(userId).update({
        'children': updatedChildren.map((c) => c.toMap()).toList(),
      });
    } catch (e) {
      print('Error deleting child: $e');
      throw Exception('Failed to delete child profile');
    }
  }

  // 上传子女照片
  Future<String?> uploadChildPhoto(File imageFile, String userId, String childId) async {
    try {
      print('Uploading image for child: $childId');
      final ref = _storage.ref().child('child_photos/$userId/$childId.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      print('Image uploaded successfully. URL: $url');
      return url;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image');
    }
  }

  // 更新子女照片
  Future<void> updateChildPhoto(String userId, ChildInfo child, String photoUrl) async {
    try {
      final doc = await _firestore.collection('profiles').doc(userId).get();
      if (!doc.exists) return;

      final profile = UserProfile.fromMap({
        ...doc.data()!,
        'userId': userId,
      });

      final updatedChildren = List<ChildInfo>.from(profile.children);
      final index = updatedChildren.indexWhere((c) => c.id == child.id);
      
      if (index != -1) {
        updatedChildren[index] = ChildInfo(
          id: child.id,
          name: child.name,
          birthDate: child.birthDate,
          photoUrl: photoUrl,
        );

        await _firestore.collection('profiles').doc(userId).update({
          'children': updatedChildren.map((c) => c.toMap()).toList(),
        });
      }
    } catch (e) {
      print('Error updating child photo: $e');
      throw Exception('Failed to update child photo');
    }
  }

  // 删除子女照片
  Future<void> deleteChildPhoto(String childId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final ref = _storage.ref().child('child_photos/$userId/$childId.jpg');
      await ref.delete();
    } catch (e) {
      print('Error deleting child photo: $e');
      throw Exception('Failed to delete child photo');
    }
  }
} 