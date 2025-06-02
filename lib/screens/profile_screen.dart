import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../models/profile_model.dart';
import '../styles/app_text_styles.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  final _auth = FirebaseAuth.instance;
  final _authService = AuthService();
  final _imagePicker = ImagePicker();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final ScrollController _scrollController = ScrollController();
  bool _isImagePickerActive = false;

  UserProfile? _userProfile;
  bool _isLoading = true;
  
  // Pagination variables for children list - increased to fill ~2 screens
  int _currentChildrenPage = 0;
  final int _childrenPageSize = 12; // Show 12 children per page (about 2 screens)
  bool _hasMoreChildren = false;
  
  // Scroll position preservation
  double _savedScrollPosition = 0.0;
  bool _shouldPreserveScroll = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _saveScrollPosition() {
    if (_scrollController.hasClients) {
      _savedScrollPosition = _scrollController.offset;
    }
  }

  void _restoreScrollPosition() {
    if (_shouldPreserveScroll && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _savedScrollPosition,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
        _shouldPreserveScroll = false;
      });
    }
  }

  Future<void> _updateUserProfileLocally(UserProfile updatedProfile) async {
    setState(() {
      _userProfile = updatedProfile;
      _hasMoreChildren = (_userProfile?.children.length ?? 0) > (_currentChildrenPage + 1) * _childrenPageSize;
    });
    _restoreScrollPosition();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _profileService.getUserProfile();
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          // Reset pagination when loading profile
          _currentChildrenPage = 0;
          _hasMoreChildren = (_userProfile?.children.length ?? 0) > _childrenPageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onRefresh() async {
    try {
      await _loadUserProfile();
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  void _onLoadingMoreChildren() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络延迟
      
      final totalChildren = _userProfile?.children.length ?? 0;
      final nextPageStartIndex = (_currentChildrenPage + 1) * _childrenPageSize;
      
      if (nextPageStartIndex >= totalChildren) {
        _refreshController.loadNoData();
        setState(() {
          _hasMoreChildren = false;
        });
        return;
      }

      setState(() {
        _currentChildrenPage++;
        _hasMoreChildren = ((_currentChildrenPage + 1) * _childrenPageSize) < totalChildren;
      });

      _refreshController.loadComplete();
    } catch (e) {
      _refreshController.loadFailed();
    }
  }

  List<ChildInfo> _getPaginatedChildren() {
    if (_userProfile?.children == null) return [];
    
    final endIndex = (_currentChildrenPage + 1) * _childrenPageSize;
    return _userProfile!.children.take(endIndex).toList();
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

              try {
                await _profileService.updateProfile(newProfile);
                if (mounted) {
                  Navigator.pop(context);
                  _loadUserProfile();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating profile: $e')),
                  );
                }
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
              
              _saveScrollPosition();
              _shouldPreserveScroll = true;
              
              final userId = _auth.currentUser?.uid;
              if (userId == null) return;
              
              final newChild = ChildInfo(
                id: child?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                birthDate: selectedDate,
                photoUrl: child?.photoUrl,
              );
              
              final updatedChildren = List<ChildInfo>.from(_userProfile?.children ?? []);
              
              if (child != null) {
                // Edit existing child
                final index = updatedChildren.indexWhere((c) => c.id == child.id);
                if (index != -1) {
                  updatedChildren[index] = newChild;
                }
              } else {
                // Add new child
                updatedChildren.add(newChild);
              }
              
              try {
                await _profileService.updateProfile(UserProfile(
                  userId: _userProfile!.userId,
                  name: _userProfile!.name,
                  phone: _userProfile!.phone,
                  email: _userProfile!.email,
                  children: updatedChildren,
                ));
                
                if (mounted) {
                  Navigator.pop(context);
                  
                  // Update locally instead of full refresh
                  final updatedProfile = UserProfile(
                    userId: _userProfile!.userId,
                    name: _userProfile!.name,
                    phone: _userProfile!.phone,
                    email: _userProfile!.email,
                    children: updatedChildren,
                  );
                  
                  await _updateUserProfileLocally(updatedProfile);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(child == null ? 'Child added successfully' : 'Child updated successfully'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving child: $e')),
                  );
                }
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
    
    _saveScrollPosition();
    _shouldPreserveScroll = true;
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      final child = _userProfile?.children.firstWhere((c) => c.id == childId);
      
      // Delete photo from storage if exists
      if (child?.photoUrl != null) {
        try {
          await _profileService.deleteChildPhoto(child!.id);
        } catch (e) {
          print('Failed to delete photo: $e');
        }
      }
      
      final updatedChildren = _userProfile?.children.where((c) => c.id != childId).toList() ?? [];
      
      await _profileService.updateProfile(UserProfile(
        userId: _userProfile!.userId,
        name: _userProfile!.name,
        phone: _userProfile!.phone,
        email: _userProfile!.email,
        children: updatedChildren,
      ));
      
      if (mounted) {
        // Update locally instead of full refresh
        final updatedProfile = UserProfile(
          userId: _userProfile!.userId,
          name: _userProfile!.name,
          phone: _userProfile!.phone,
          email: _userProfile!.email,
          children: updatedChildren,
        );
        
        await _updateUserProfileLocally(updatedProfile);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Child deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting child: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ChildInfo child) async {
    if (_isImagePickerActive) {
      print('Image picker is already active');
      return;
    }
    
    _saveScrollPosition();
    _shouldPreserveScroll = true;
    
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
        _shouldPreserveScroll = false; // Reset if cancelled
        return;
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      print('Image picked: ${image.path}');
      final imageFile = File(image.path);
      
      final photoUrl = await _profileService.uploadChildPhoto(imageFile, userId, child.id);
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
          
          await _profileService.updateProfile(UserProfile(
            userId: _userProfile!.userId,
            name: _userProfile!.name,
            phone: _userProfile!.phone,
            email: _userProfile!.email,
            children: updatedChildren,
          ));
          
          print('Profile updated successfully');
          
          if (mounted) {
            // Update locally instead of full refresh
            final updatedProfile = UserProfile(
              userId: _userProfile!.userId,
              name: _userProfile!.name,
              phone: _userProfile!.phone,
              email: _userProfile!.email,
              children: updatedChildren,
            );
            
            await _updateUserProfileLocally(updatedProfile);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo updated successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        _shouldPreserveScroll = false; // Reset if upload failed
      }
    } catch (e) {
      print('Error picking/uploading image: $e');
      _shouldPreserveScroll = false; // Reset on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating photo: $e')),
        );
      }
    } finally {
      _isImagePickerActive = false;
    }
  }

  // Debug method to add test children - remove in production
  Future<void> _addTestChildren() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final testChildren = <ChildInfo>[];
    for (int i = 1; i <= 20; i++) {
      testChildren.add(ChildInfo(
        id: 'test_child_$i',
        name: 'Test Child $i',
        birthDate: DateTime(2020 + (i % 5), (i % 12) + 1, (i % 28) + 1),
      ));
    }

    final existingChildren = _userProfile?.children ?? <ChildInfo>[];
    final allChildren = [...existingChildren, ...testChildren];

    try {
      await _profileService.updateProfile(UserProfile(
        userId: _userProfile!.userId,
        name: _userProfile!.name,
        phone: _userProfile!.phone,
        email: _userProfile!.email,
        children: allChildren,
      ));
      await _loadUserProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added 20 test children for pagination demo'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding test children: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SmartRefresher(
      enablePullDown: true,
      enablePullUp: _hasMoreChildren,
      header: WaterDropHeader(
        complete: Text(
          'Profile Updated!',
          style: AppTextStyles.bodyMedium,
        ),
        failed: Text(
          'Update Failed',
          style: AppTextStyles.bodyMedium,
        ),
      ),
      footer: CustomFooter(
        builder: (BuildContext context, LoadStatus? mode) {
          Widget body;
          if (mode == null) {
            body = Text("↑ Pull up to load more children", style: AppTextStyles.bodyMedium);
          } else if (mode == LoadStatus.idle) {
            body = Text("↑ Pull up to load more children", style: AppTextStyles.bodyMedium);
          } else if (mode == LoadStatus.loading) {
            body = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text("Loading more children...", style: AppTextStyles.bodyMedium),
              ],
            );
          } else if (mode == LoadStatus.failed) {
            body = Text("Load Failed! Tap to retry", style: AppTextStyles.bodyMedium.copyWith(color: Colors.red));
          } else if (mode == LoadStatus.canLoading) {
            body = Text("↑ Release to load more", style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).primaryColor));
          } else {
            body = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text("All children loaded", style: AppTextStyles.bodyMedium.copyWith(color: Colors.green)),
              ],
            );
          }
          return Container(
            height: 55.0,
            child: Center(child: body),
          );
        },
      ),
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoadingMoreChildren,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和登出按钮区域
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    l10n.profile,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => _showLogoutConfirmation(context, l10n),
                    icon: const Icon(Icons.logout),
                    tooltip: l10n.logout,
                    color: Colors.red,
                    iconSize: 24,
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                    'Children (${_userProfile!.children.length} total)',
                    style: AppTextStyles.titleLarge.copyWith(fontSize: 20),
                  ),
                  Row(
                    children: [
                      // Test button - remove in production
                      IconButton(
                        icon: const Icon(Icons.science, color: Colors.orange),
                        tooltip: 'Add Test Data',
                        onPressed: _addTestChildren,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _showAddChildDialog,
                      ),
                    ],
                  ),
                ],
              ),
              if (_userProfile!.children.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${_getPaginatedChildren().length} of ${_userProfile!.children.length}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (_hasMoreChildren)
                        Text(
                          'Scroll down for more',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              ..._getPaginatedChildren().map((child) => Card(
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
              // Add spacing at bottom to ensure proper pull-up loading
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.confirmLogout,
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          l10n.logoutMessage,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: AppTextStyles.button.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              l10n.logout,
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performLogout(context, l10n);
    }
  }

  Future<void> _performLogout(BuildContext context, AppLocalizations l10n) async {
    bool isLoadingDialogShown = false;
    
    try {
      print('Profile: Starting logout process...');
      
      // 显示加载状态
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            isLoadingDialogShown = true;
            return WillPopScope(
              onWillPop: () async => false, // 防止用户关闭对话框
              child: const AlertDialog(
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('正在退出登录...'),
                  ],
                ),
              ),
            );
          },
        );
      }

      // 使用Provider获取AuthService
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // 执行退出登录
      await authService.signOut();
      
      print('Profile: Logout completed successfully');
      
    } catch (e) {
      print('Profile: Logout error: $e');
      
      // 根据错误类型显示不同的错误信息
      String errorMessage = l10n.profileLogoutFailed;
      if (e.toString().contains('Google signOut: false')) {
        errorMessage = '退出Google账号失败，请重试';
      } else if (e.toString().contains('Firebase signOut: false')) {
        errorMessage = '退出Firebase失败，请重试';
      } else if (e.toString().contains('Sign out incomplete')) {
        errorMessage = '退出登录不完整，建议重启应用';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '重试',
              textColor: Colors.white,
              onPressed: () {
                // 递归调用重试
                _showLogoutConfirmation(context, l10n);
              },
            ),
          ),
        );
        
        // 如果是退出不完整，显示紧急退出选项
        if (e.toString().contains('Sign out incomplete')) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    '可以尝试紧急退出（强制清除）',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 6),
                  action: SnackBarAction(
                    label: '紧急退出',
                    textColor: Colors.white,
                    onPressed: () async {
                      await _performForceLogout(context);
                    },
                  ),
                ),
              );
            }
          });
        }
      }
    } finally {
      // 确保关闭加载对话框
      if (isLoadingDialogShown && mounted) {
        try {
          Navigator.of(context).pop();
          print('Profile: Loading dialog closed');
        } catch (e) {
          print('Profile: Error closing loading dialog: $e');
        }
      }
      
      // 等待一小段时间确保状态更新
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 强制导航到登录界面（无论成功还是失败）
      if (mounted) {
        print('Profile: Navigating to login screen...');
        try {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
          print('Profile: Navigation completed');
        } catch (e) {
          print('Profile: Navigation error: $e');
          // 如果导航失败，尝试替代方法
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    }
  }

  Future<void> _performForceLogout(BuildContext context) async {
    bool isLoadingDialogShown = false;
    
    try {
      // 显示强制退出加载状态
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            isLoadingDialogShown = true;
            return WillPopScope(
              onWillPop: () async => false,
              child: const AlertDialog(
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('强制退出中...'),
                  ],
                ),
              ),
            );
          },
        );
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.forceSignOut();
      
      print('Profile: Force logout completed');
    } catch (e) {
      print('Profile: Force logout error: $e');
    } finally {
      // 确保关闭加载对话框
      if (isLoadingDialogShown && mounted) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          print('Profile: Error closing force logout dialog: $e');
        }
      }
      
      // 强制导航到登录界面
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}