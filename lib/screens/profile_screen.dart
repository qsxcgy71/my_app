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
import '../widgets/keyboard_dismisser.dart';
import '../widgets/anti_spam_button.dart';
import '../widgets/auth_wrapper.dart';
import 'loading_screen.dart';
import '../providers/theme_provider.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: profile?.name ?? '');
    final phoneController = TextEditingController(text: profile?.phone ?? '');
    final emailController = TextEditingController(
      text: profile?.email ?? _auth.currentUser?.email ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          profile == null ? l10n.createProfile : l10n.editProfile,
          style: AppTextStyles.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.yourName,
                  labelStyle: AppTextStyles.bodyMedium,
                ),
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: l10n.phone,
                  labelStyle: AppTextStyles.bodyMedium,
                ),
                keyboardType: TextInputType.phone,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: l10n.email,
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
            child: Text(l10n.cancel, style: AppTextStyles.bodyMedium),
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
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: child?.name ?? '');
    DateTime? selectedDate = child?.birthDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          child == null ? l10n.addChild : l10n.editChild,
          style: AppTextStyles.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.childName,
                  labelStyle: AppTextStyles.bodyMedium,
                ),
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  selectedDate == null
                      ? l10n.selectBirthDate
                      : l10n.birthDate(selectedDate.toString().split(' ')[0]),
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
            child: Text(l10n.cancel, style: AppTextStyles.bodyMedium),
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
                      content: Text(child == null ? l10n.childAddSuccess : l10n.childUpdateSuccess),
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
    final l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.confirmDeleteProfile, style: AppTextStyles.titleLarge),
          content: Text(
            l10n.confirmDeleteProfileMessage,
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel, style: AppTextStyles.bodyMedium),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete, style: AppTextStyles.bodyMedium),
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
          SnackBar(
            content: Text(l10n.childDeleteSuccess),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
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
    
    final l10n = AppLocalizations.of(context)!;
    _saveScrollPosition();
    _shouldPreserveScroll = true;
    
    try {
      _isImagePickerActive = true;
      
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(l10n.selectPhotoSource),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: Text(l10n.takePhoto),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text(l10n.chooseFromGallery),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );
      
      if (source == null) {
        print('No source selected');
        _shouldPreserveScroll = false;
        return;
      }
      
      final XFile? image = await _imagePicker.pickImage(
        source: source,
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
              SnackBar(
                content: Text(l10n.photoUpdateSuccess),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
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
          SnackBar(content: Text(l10n.photoUpdateFailed)),
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
          l10n.profileUpdated,
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
            body = Text(l10n.pullToRefresh, style: AppTextStyles.bodyMedium);
          } else if (mode == LoadStatus.idle) {
            body = Text(l10n.pullToRefresh, style: AppTextStyles.bodyMedium);
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
                Text(l10n.loadingMore, style: AppTextStyles.bodyMedium),
              ],
            );
          } else if (mode == LoadStatus.failed) {
            body = Text(l10n.loadFailed, style: AppTextStyles.bodyMedium.copyWith(color: Colors.red));
          } else if (mode == LoadStatus.canLoading) {
            body = Text(l10n.releaseToLoad, style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).primaryColor));
          } else {
            body = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(l10n.allChildrenLoaded, style: AppTextStyles.bodyMedium.copyWith(color: Colors.green)),
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
                      color: Theme.of(context).primaryColor,
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
                  child: Text(l10n.createProfile, style: AppTextStyles.button),
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
                    l10n.children(_userProfile!.children.length.toString()),
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
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
                        l10n.showingXofY(
                          _getPaginatedChildren().length.toString(),
                          _userProfile!.children.length.toString(),
                        ),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (_hasMoreChildren)
                        Text(
                          l10n.scrollDownForMore,
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
                          subtitle: Text(
                            child.birthDate != null 
                              ? l10n.birthDate(child.birthDate.toString().split(' ')[0])
                              : l10n.birthDate(l10n.unknown),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
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
          AntiSpamButton(
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
    OverlayEntry? loadingOverlay;
    
    try {
      print('Profile: Starting logout process...');
      
      // 使用Overlay显示加载状态，避免对话框context问题
      if (mounted) {
        loadingOverlay = OverlayEntry(
          builder: (context) => Material(
            color: Colors.black54,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('正在退出登录...'),
                  ],
                ),
              ),
            ),
          ),
        );
        Overlay.of(context).insert(loadingOverlay!);
        isLoadingDialogShown = true;
      }

      // 等待一小段时间确保UI显示
      await Future.delayed(const Duration(milliseconds: 100));

      // 使用Provider获取AuthService
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // 先导航到LoadingScreen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoadingScreen()),
          (route) => false,
        );
      }
      
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
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      // 确保移除加载overlay
      if (isLoadingDialogShown && loadingOverlay != null) {
        try {
          loadingOverlay!.remove();
          print('Profile: Loading overlay removed');
        } catch (e) {
          print('Profile: Error removing overlay: $e');
        }
      }
    }
  }
}