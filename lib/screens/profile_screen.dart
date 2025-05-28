import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import '../models/profile_model.dart';
import '../styles/app_text_styles.dart'; // 引入自定义字体样式

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;
  final _imagePicker = ImagePicker();
  bool _isImagePickerActive = false;

  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore.collection('profiles').doc(userId).get();
        if (doc.exists) {
          setState(() {
            _userProfile = UserProfile.fromMap({
              ...doc.data()!,
              'userId': userId,
            });
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _showEditProfileDialog([UserProfile? profile]) async {
    final nameController = TextEditingController(text: profile?.name ?? '');
    final phoneController = TextEditingController(text: profile?.phone ?? '');
    final emailController = TextEditingController(
      text: profile?.email ?? _auth.currentUser?.email ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          profile == null ? 'Create Profile' : 'Edit Profile',
          style: AppTextStyles.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  labelStyle: AppTextStyles.bodyMedium,
                ),
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: AppTextStyles.bodyMedium,
                ),
                keyboardType: TextInputType.phone,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: AppTextStyles.bodyMedium,
                ),
                keyboardType: TextInputType.emailAddress,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () async {
              final userId = _auth.currentUser?.uid;
              if (userId == null) return;
              final newProfile = UserProfile(
                userId: userId,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim(),
                children: profile?.children ?? [],
              );
              await _firestore
                  .collection('profiles')
                  .doc(userId)
                  .set(newProfile.toMap());
              if (mounted) {
                Navigator.pop(context);
                _loadUserProfile();
              }
            },
            child: Text('Save', style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddChildDialog([ChildInfo? child]) async {
    final nameController = TextEditingController(text: child?.name ?? '');
    DateTime? selectedDate = child?.birthDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          child == null ? 'Add Child' : 'Edit Child',
          style: AppTextStyles.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Child Name',
                  labelStyle: AppTextStyles.bodyMedium,
                ),
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  selectedDate == null
                      ? 'Select Birth Date'
                      : 'Birth Date: ${selectedDate.toString().split(' ')[0]}',
                  style: AppTextStyles.bodyMedium,
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    selectedDate = date;
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final userId = _auth.currentUser?.uid;
              if (userId == null) return;
              final newChild = ChildInfo(
                id: child?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                birthDate: selectedDate,
                photoUrl: child?.photoUrl,
              );
              final updatedChildren = List<ChildInfo>.from(
                  _userProfile?.children ?? []);
              if (child != null) {
                final index = updatedChildren
                    .indexWhere((c) => c.id == child.id);
                if (index != -1) {
                  updatedChildren[index] = newChild;
                }
              } else {
                updatedChildren.add(newChild);
              }
              await _firestore.collection('profiles').doc(userId).update({
                'children': updatedChildren.map((c) => c.toMap()).toList(),
              });
              if (mounted) {
                Navigator.pop(context);
                _loadUserProfile();
              }
            },
            child: Text('Save', style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChild(String childId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Profile', style: AppTextStyles.titleLarge),
          content: Text(
            'Are you sure you want to delete this profile? This action cannot be undone.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: AppTextStyles.bodyMedium),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Delete', style: AppTextStyles.bodyMedium),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    try {
      final child = _userProfile?.children.firstWhere((c) => c.id == childId);
      if (child?.photoUrl != null) {
        try {
          final photoRef = _storage.refFromURL(child!.photoUrl!);
          await photoRef.delete();
        } catch (e) {
          print('Failed to delete photo: $e');
        }
      }
      final updatedChildren =
          _userProfile?.children.where((c) => c.id != childId).toList() ?? [];
      await _firestore.collection('profiles').doc(userId).update({
        'children': updatedChildren.map((c) => c.toMap()).toList(),
      });
      _loadUserProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting profile: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage(File imageFile, String childId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;
      
      print('Uploading image for child: $childId');
      final ref = _storage.ref().child('child_photos/$userId/$childId.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      print('Image uploaded successfully. URL: $url');
      return url;
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  Future<void> _pickImage(ChildInfo child) async {
    if (_isImagePickerActive) {
      print('Image picker is already active');
      return;
    }
    
    try {
      _isImagePickerActive = true;
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image == null) {
        print('No image selected');
        return;
      }
      
      print('Image picked: ${image.path}');
      final imageFile = File(image.path);
      final photoUrl = await _uploadImage(imageFile, child.id);
      
      if (photoUrl != null) {
        print('Updating child profile with new photo URL');
        final userId = _auth.currentUser?.uid;
        if (userId == null) return;
        
        final updatedChildren = List<ChildInfo>.from(_userProfile?.children ?? []);
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
          
          print('Profile updated successfully');
          _loadUserProfile();
        }
      }
    } catch (e) {
      print('Error picking/uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      _isImagePickerActive = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_userProfile == null)
            Center(
              child: ElevatedButton(
                onPressed: _showEditProfileDialog,
                child: Text('Create Profile', style: AppTextStyles.button),
              ),
            )
          else ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(_userProfile!.name, style: AppTextStyles.bodyLarge),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userProfile!.phone, style: AppTextStyles.bodyMedium),
                    Text(_userProfile!.email, style: AppTextStyles.bodyMedium),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditProfileDialog(_userProfile),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Children',
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 20),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddChildDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._userProfile!.children.map((child) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: GestureDetector(
                          onTap: () => _pickImage(child),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey[200],
                            child: child.photoUrl != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: child.photoUrl!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      cacheManager: null,
                                      maxHeightDiskCache: 1024,
                                      maxWidthDiskCache: 1024,
                                      memCacheHeight: 1024,
                                      memCacheWidth: 1024,
                                      errorListener: (error) {
                                        print('CachedNetworkImage error: $error');
                                      },
                                      useOldImageOnUrlChange: true,
                                      placeholder: (context, url) => const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) {
                                        print('Error loading image: $url, Error: $error');
                                        return Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            const Icon(Icons.error),
                                            Positioned(
                                              bottom: 0,
                                              child: IconButton(
                                                iconSize: 16,
                                                icon: const Icon(Icons.refresh),
                                                onPressed: () {
                                                  CachedNetworkImage.evictFromCache(url);
                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                      imageBuilder: (context, imageProvider) => Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.add_a_photo),
                          ),
                        ),
                        title: Text(child.name, style: AppTextStyles.bodyLarge),
                        subtitle: child.birthDate != null
                            ? Text(
                                'Birth Date: ${child.birthDate.toString().split(' ')[0]}',
                                style: AppTextStyles.bodyMedium,
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showAddChildDialog(child),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteChild(child.id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}