import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../models/profile_model.dart';
import '../services/lesson_service.dart';
import '../services/profile_service.dart';
import '../services/payment_service.dart';
import '../services/message_service.dart';
import '../styles/app_text_styles.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Timer? _imageTimer;
  int _currentImageIndex = 0;
  
  // 新增状态变量
  final LessonService _lessonService = LessonService();
  final ProfileService _profileService = ProfileService();
  UserProfile? _userProfile;
  bool _isLoadingChildren = false;
  List<String> _selectedChildIds = []; // 选中的孩子ID列表

  final LessonService _lessonService = LessonService();
  final ProfileService _profileService = ProfileService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserProfile? _userProfile;
  bool _isLoadingChildren = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    if (widget.course.imageUrls.length > 1) {
      _startImageCarousel();
    }
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    super.dispose();
  }

  void _startImageCarousel() {
    _imageTimer = Timer.periodic(
      const Duration(seconds: 4),
      (timer) {
        if (mounted) {
          setState(() {
            _currentImageIndex = (_currentImageIndex + 1) % widget.course.imageUrls.length;
          });
        }
      },
    );
  }

  // 加载用户资料
  Future<void> _loadUserProfile() async {
    try {
      final profile = await _profileService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // 显示选择孩子的弹窗
  Future<void> _showEnrollChildrenDialog() async {
    if (_userProfile == null || _userProfile!.children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先在个人资料中添加孩子信息'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 获取已报名的孩子并筛选出未报名的孩子
    final enrolledChildren = await _lessonService.getEnrolledChildrenForCourseWithFullInfo(
      widget.course.id,
      _userProfile!.children,
    );
    
    final availableChildren = _userProfile!.children
        .where((child) => !enrolledChildren.any((enrolled) => enrolled.id == child.id))
        .toList();

    if (availableChildren.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('所有孩子都已报名此课程'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    setState(() {
      _selectedChildIds.clear();
    });

    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // 拖拽指示器
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              
              // 标题栏
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.school,
                            color: Colors.blue.shade600,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '选择报名孩子',
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '为《${widget.course.title}》课程报名',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 分割线
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.grey[200]!,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 提示文字
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      '请选择要报名的孩子（可多选）',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '已选择 ${_selectedChildIds.length} 人',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.orange.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 孩子列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: availableChildren.length,
                  itemBuilder: (context, index) {
                    final child = availableChildren[index];
                    final isSelected = _selectedChildIds.contains(child.id);
                    final age = child.birthDate != null 
                        ? DateTime.now().year - child.birthDate!.year 
                        : 0;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.blue.shade300 : Colors.grey[200]!,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected 
                                ? Colors.blue.withOpacity(0.15)
                                : Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                _selectedChildIds.remove(child.id);
                              } else {
                                _selectedChildIds.add(child.id);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                // 选择状态指示器
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? Colors.blue.shade600 : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? Colors.blue.shade600 : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected 
                                      ? Icon(Icons.check, color: Colors.white, size: 14)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                
                                // 孩子头像
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Colors.blue.shade100,
                                    backgroundImage: child.photoUrl != null
                                        ? NetworkImage(child.photoUrl!)
                                        : null,
                                    child: child.photoUrl == null
                                        ? Text(
                                            child.name.isNotEmpty ? child.name[0] : '?',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade700,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        child.name,
                                        style: AppTextStyles.titleMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          if (age > 0) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${age}岁',
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: Colors.orange.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          if (child.birthDate != null) ...[
                                            Icon(
                                              Icons.cake,
                                              size: 16,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${child.birthDate!.month}月${child.birthDate!.day}日',
                                              style: AppTextStyles.bodySmall.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // 底部确认按钮
              Container(
                padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedChildIds.isEmpty || _isLoadingChildren 
                            ? null 
                            : () => _enrollSelectedChildren(setModalState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          disabledBackgroundColor: Colors.grey[300],
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.grey[500],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoadingChildren) ...[
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ] else ...[
                              Icon(Icons.check_circle, size: 20),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _isLoadingChildren 
                                  ? '报名中...' 
                                  : '确认报名 (${_selectedChildIds.length}人)',
                              style: AppTextStyles.button.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 执行批量报名
  Future<void> _enrollSelectedChildren(StateSetter setModalState) async {
    if (_selectedChildIds.isEmpty || _userProfile == null) return;

    setModalState(() {
      _isLoadingChildren = true;
    });

    try {
      final selectedChildren = _userProfile!.children
          .where((child) => _selectedChildIds.contains(child.id))
          .toList();

      // 集成支付流程
      final paymentService = PaymentService();
      final paymentSuccess = await paymentService.processCoursePayment(
        course: widget.course,
        selectedChildren: selectedChildren,
        context: context,
      );

      if (paymentSuccess) {
        // 支付成功后进行实际的课程报名
        await _lessonService.enrollCourse(widget.course, selectedChildren);
        
        // 发送课程报名成功消息
        final messageService = MessageService();
        await messageService.sendCourseEnrollmentMessage(widget.course, selectedChildren);
        
        if (mounted) {
          Navigator.pop(context); // 关闭弹窗
          
          // 显示成功提示（支付对话框已经显示过，这里不再重复显示）
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('报名失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setModalState(() {
        _isLoadingChildren = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final course = widget.course;
    final imageUrl = course.imageUrls.isNotEmpty 
        ? course.imageUrls[_currentImageIndex] 
        : null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          image: imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          gradient: imageUrl == null
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                                )
                              : null,
                        ),
                        child: imageUrl == null
                            ? Center(
                                child: Icon(Icons.school, size: 80, color: Colors.white),
                              )
                            : null,
                      ),
                      
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                course.category,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              course.title,
                              style: AppTextStyles.titleLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.orange, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  course.rating.toString(),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.people, color: Colors.white, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  course.enrolledCountString,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      if (course.imageUrls.length > 1)
                        Positioned(
                          top: 100,
                          right: 20,
                          child: Column(
                            children: course.imageUrls.asMap().entries.map((entry) {
                              return Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == entry.key
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Course description
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
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
                        course.description,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(Icons.person, '讲师', course.instructor),
                      _buildInfoRow(Icons.category, '类别', course.category),
                      _buildInfoRow(Icons.payments, '价格', '${course.price} 元'),
                      _buildInfoRow(Icons.online_prediction, '线上课程', course.isOnline ? '是' : '否'),
                      _buildInfoRow(Icons.calendar_today, '推荐年龄', '${course.recommendedAge} 岁'),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: AntiSpamButton(
              onPressed: _isLoadingChildren ? null : () => _showEnrollChildrenDialog(widget.course),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                
                const SizedBox(height: 32),
                
                // Enroll button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  width: double.infinity,
                  child: Column(
                    children: [
                      // 价格显示
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: course.price == 0 ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: course.price == 0 ? Colors.green : Colors.blue,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.price == 0 ? '免费课程' : '课程价格',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      course.price == 0 ? '¥0' : '¥${course.price.toStringAsFixed(0)}',
                                      style: AppTextStyles.titleLarge.copyWith(
                                        color: course.price == 0 ? Colors.green : Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                    if (course.price == 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'FREE',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            if (course.price == 0)
                              Icon(Icons.school, color: Colors.green, size: 32)
                            else
                              Icon(Icons.payment, color: Colors.blue, size: 32),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 报名按钮
                      ElevatedButton(
                        onPressed: () {
                          _showEnrollChildrenDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: course.price == 0 ? Colors.green : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              course.price == 0 ? Icons.school : Icons.shopping_cart,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              course.price == 0 ? '立即报名（免费）' : '立即购买并报名',
                              style: AppTextStyles.button.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
} 