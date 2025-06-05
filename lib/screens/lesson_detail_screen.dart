import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../models/profile_model.dart';
import '../styles/app_text_styles.dart';
import '../l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../services/lesson_service.dart';
import '../services/profile_service.dart';
import 'photo_view_screen.dart';
import '../widgets/keyboard_dismisser.dart';
import '../services/media_compression_service.dart';
import 'dart:io';
import 'video_player_screen.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailScreen({
    super.key,
    required this.lesson,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final LessonService _lessonService = LessonService();
  final ProfileService _profileService = ProfileService();
  bool _isUploading = false;
  List<ChildInfo> _enrolledChildren = []; // 已报名的学员
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndEnrolledChildren();
  }

  // 加载用户资料和已报名学员
  Future<void> _loadUserProfileAndEnrolledChildren() async {
    try {
      final profile = await _profileService.getUserProfile();
      if (mounted && profile != null) {
        setState(() {
          _userProfile = profile;
        });
        
        // 加载已报名的学员
        await _loadEnrolledChildren();
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // 加载已报名的学员
  Future<void> _loadEnrolledChildren() async {
    if (_userProfile == null || widget.lesson.courseId.isEmpty) return;
    
    try {
      final enrolledChildren = await _lessonService.getEnrolledChildrenForCourseWithFullInfo(
        widget.lesson.courseId,
        _userProfile!.children,
      );
      if (mounted) {
        setState(() {
          _enrolledChildren = enrolledChildren;
        });
      }
    } catch (e) {
      print('Error loading enrolled children: $e');
    }
  }

  // 请求存储权限
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isDenied) {
        final manageStatus = await Permission.manageExternalStorage.request();
        return manageStatus.isGranted;
      }
      return status.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    return true;
  }

  // 下载文件
  Future<void> _downloadFile(String url, String fileName, String type) async {
    try {
      // 请求权限
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要存储权限才能下载文件'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 显示下载进度
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('正在下载$type...'),
            ],
          ),
        ),
      );

      // 下载文件
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // 获取下载目录
        Directory? directory;
        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
          if (directory != null) {
            // 创建自定义下载目录
            final customDir = Directory('${directory.path}/MyApp/Downloads');
            if (!await customDir.exists()) {
              await customDir.create(recursive: true);
            }
            directory = customDir;
          }
        } else if (Platform.isIOS) {
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory != null) {
          // 确保文件名有正确的扩展名
          String finalFileName = fileName;
          if (type == '照片' && !fileName.toLowerCase().endsWith('.jpg') && !fileName.toLowerCase().endsWith('.png')) {
            finalFileName = '$fileName.jpg';
          } else if (type == '视频' && !fileName.toLowerCase().endsWith('.mp4')) {
            finalFileName = '$fileName.mp4';
          }

          final file = File('${directory.path}/$finalFileName');
          await file.writeAsBytes(response.bodyBytes);

          if (mounted) {
            Navigator.of(context).pop(); // 关闭进度对话框
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$type下载成功：${file.path}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        throw Exception('下载失败：HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 显示媒体选项菜单
  void _showMediaOptions(String url, String description, String type) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                type == '照片' ? Icons.photo : Icons.videocam,
                color: Colors.blue,
              ),
              title: Text('查看$type'),
              onTap: () {
                Navigator.pop(context);
                if (type == '照片') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoViewScreen(
                        photos: widget.lesson.photos,
                        initialIndex: widget.lesson.photos.indexWhere((p) => p.url == url),
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                        videoUrl: url,
                        title: description,
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.download,
                color: Colors.green,
              ),
              title: Text('下载$type'),
              onTap: () {
                Navigator.pop(context);
                final fileName = '${widget.lesson.title}_${DateTime.now().millisecondsSinceEpoch}';
                _downloadFile(url, fileName, type);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.cancel,
                color: Colors.grey,
              ),
              title: const Text('取消'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadMedia() async {
    // 显示选择媒体类型的对话框
    final mediaType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择媒体类型'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('选择照片'),
                onTap: () => Navigator.of(context).pop('photo'),
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('选择视频'),
                onTap: () => Navigator.of(context).pop('video'),
              ),
            ],
          ),
        );
      },
    );

    if (mediaType == null) return;

    final ImagePicker picker = ImagePicker();
    
    try {
      XFile? file;
      
      if (mediaType == 'photo') {
        file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      } else if (mediaType == 'video') {
        file = await picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 10), // 限制视频长度
        );
      }

      if (file == null) return;

      setState(() {
        _isUploading = true;
      });

      // 使用媒体压缩服务压缩文件
      final originalFile = File(file.path);
      String finalPath = file.path;
      
      if (MediaCompressionService.isValidMediaFile(originalFile)) {
        try {
          dynamic compressedResult;
          
          if (mediaType == 'photo') {
            compressedResult = await MediaCompressionService.smartCompressMedia(
              originalFile,
              targetSizeKB: 500,
              targetSizeMB: 50, // 这个参数对图片无效，但需要提供
              onProgress: (message) {
                print('压缩进度: $message');
              },
            );
          } else if (mediaType == 'video') {
            compressedResult = await MediaCompressionService.smartCompressMedia(
              originalFile,
              targetSizeKB: 500, // 这个参数对视频无效，但需要提供
              targetSizeMB: 20,  // 视频目标大小20MB
              onProgress: (message) {
                print('压缩进度: $message');
              },
            );
          }
          
          if (compressedResult != null) {
            if (mediaType == 'photo' && compressedResult is List<int>) {
              // 图片压缩结果是字节数组，需要保存为临时文件
              final tempDir = Directory.systemTemp;
              final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
              await tempFile.writeAsBytes(compressedResult);
              finalPath = tempFile.path;
            } else if (mediaType == 'video' && compressedResult.path != null) {
              // 视频压缩结果是MediaInfo对象
              finalPath = compressedResult.path!;
              print('视频压缩成功: 原始路径 ${file.path}, 压缩后路径 $finalPath');
            }
          }
        } catch (e) {
          print('压缩失败，使用原文件: $e');
          // 如果压缩失败，使用原文件
        }
      }

      // 上传媒体文件并更新课程
      if (mediaType == 'photo') {
      await _lessonService.addLessonPhoto(
        widget.lesson.id,
          finalPath,
        description: '课程照片',
      );
      } else if (mediaType == 'video') {
        await _lessonService.addLessonVideo(
          widget.lesson.id,
          finalPath,
          description: '课程视频',
        );
      }

      // 重新获取最新的课程数据
      final updatedLesson = await _lessonService.getLessonById(widget.lesson.id);
      if (mounted && updatedLesson != null) {
        setState(() {
          widget.lesson.photos.clear();
          widget.lesson.photos.addAll(updatedLesson.photos);
          // 更新videos字段
          widget.lesson.videos.clear();
          widget.lesson.videos.addAll(updatedLesson.videos);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上传${mediaType == 'photo' ? '照片' : '视频'}失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildMediaGrid(BuildContext context) {
    // 如果课程未完成，返回空
    if (!widget.lesson.isPastLesson) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '课程媒体',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              // 添加媒体按钮
              _isUploading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: _pickAndUploadMedia,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    tooltip: '添加照片或视频',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.lesson.photos.isEmpty && widget.lesson.videos.isEmpty) ...[
            // 没有媒体时显示提示信息
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.perm_media_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无照片或视频',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!_isUploading) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _pickAndUploadMedia,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('添加照片或视频'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        textStyle: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            // 有媒体时显示水平滚动的媒体列表
            SizedBox(
              height: 200, // 固定高度
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.lesson.photos.length + widget.lesson.videos.length + 1,
                itemBuilder: (context, index) {
                  final totalPhotos = widget.lesson.photos.length;
                  final totalVideos = widget.lesson.videos.length;
                  final totalMedia = totalPhotos + totalVideos;
                  
                  // 如果是最后一个位置，显示"查看全部"按钮
                  if (index == totalMedia) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhotoViewScreen(
                                  photos: widget.lesson.photos,
                                  initialIndex: 0,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.perm_media_outlined,
                                  size: 32,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '查看全部\n${totalMedia}个',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.grey[600],
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // 显示照片
                  if (index < totalPhotos) {
                  final photo = widget.lesson.photos[index];
                  return Padding(
                      padding: const EdgeInsets.only(right: 8),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GestureDetector(
                        onTap: () {
                            _showMediaOptions(photo.url, photo.description, '照片');
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: photo.url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.grey[400],
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  // 下载图标
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.download,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  
                  // 显示视频（如果有）
                  final videoIndex = index - totalPhotos;
                  if (videoIndex < widget.lesson.videos.length) {
                    final video = widget.lesson.videos[videoIndex];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GestureDetector(
                          onTap: () {
                            _showMediaOptions(video.url, video.description, '视频');
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  // 视频缩略图
                                  if (video.thumbnailUrl != null)
                                    CachedNetworkImage(
                                      imageUrl: video.thumbnailUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.videocam,
                                          color: Colors.grey[400],
                                          size: 32,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.videocam,
                                        color: Colors.grey[400],
                                        size: 32,
                                      ),
                                    ),
                                  // 播放按钮覆盖层
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  // 下载图标
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.download,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return KeyboardDismisser(
      child: Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              // 确保键盘被隐藏
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
        ),
        title: Text(
          l10n.lessonDetails,
          style: AppTextStyles.titleLarge.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 课程图片
            if (widget.lesson.imageUrl != null) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  image: widget.lesson.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(widget.lesson.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: widget.lesson.imageUrl == null
                    ? Center(
                        child: Icon(
                          Icons.school,
                          size: 60,
                          color: Colors.grey[600],
                        ),
                      )
                    : null,
              ),
            ] else ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade400,
                      Colors.purple.shade400,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.school,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 照片展示板块（仅在课程完成时显示）
            if (widget.lesson.isPastLesson) ...[
                _buildMediaGrid(context),
              const SizedBox(height: 20),
            ],

            // 已报名学员显示
            if (_enrolledChildren.isNotEmpty) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.green.shade100,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.groups,
                            color: Colors.green.shade600,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '已报名学员',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_enrolledChildren.length}人',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _enrolledChildren.map((child) {
                        final age = child.birthDate != null 
                            ? DateTime.now().year - child.birthDate!.year 
                            : 0;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.green.shade200,
                                backgroundImage: child.photoUrl != null
                                    ? NetworkImage(child.photoUrl!)
                                    : null,
                                child: child.photoUrl == null
                                    ? Text(
                                        child.name.isNotEmpty ? child.name[0] : '?',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    child.name,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (age > 0) ...[
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${age}岁',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 课程信息卡片
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 课程类别
                  if (widget.lesson.courseCategory != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.lesson.courseCategory!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 课程名称
                  Text(
                    widget.lesson.courseName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 课节标题
                  Text(
                    widget.lesson.title,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 时间信息
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        widget.lesson.timeString,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 日期信息
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.lesson.date.year}年${widget.lesson.date.month}月${widget.lesson.date.day}日',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 状态信息
                  Row(
                    children: [
                      Icon(
                        widget.lesson.isPastLesson ? Icons.check_circle : Icons.schedule,
                        size: 20,
                        color: widget.lesson.isPastLesson ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.lesson.isPastLesson ? l10n.completed : l10n.enrolled,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          color: widget.lesson.isPastLesson ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 课程描述
            if (widget.lesson.description != null && widget.lesson.description!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.courseIntroduction,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        widget.lesson.description!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          height: 1.6,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 课程详细信息
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.courseInfo,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow(l10n.startTime, widget.lesson.startTimeString, l10n),
                  _buildInfoRow(l10n.endTime, _formatTime(widget.lesson.endTime), l10n),
                  _buildInfoRow(l10n.courseDate, widget.lesson.dateString, l10n),
                  _buildInfoRow(l10n.courseStatus, widget.lesson.isPastLesson ? l10n.completed : l10n.enrolled, l10n),
                  
                  if (widget.lesson.courseCategory != null)
                    _buildInfoRow(l10n.courseCategory, widget.lesson.courseCategory!, l10n),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour;
    final minute = timeOfDay.minute;
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
} 