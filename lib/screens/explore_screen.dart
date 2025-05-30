import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'dart:async';
=======
import 'package:provider/provider.dart';
import '../styles/app_text_styles.dart';
import '../providers/theme_provider.dart';
>>>>>>> origin/dev

import '../styles/app_text_styles.dart';
import '../l10n/app_localizations.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';
import '../services/auth_service.dart';
import 'course_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final CourseService _courseService = CourseService();
  final AuthService _authService = AuthService();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Course> _featuredCourses = [];
  List<Course> _allCourses = [];
  List<Course> _searchResults = [];
  
  bool _isLoading = true;
  bool _isSearchMode = false;
  String _searchQuery = '';
  
  // 分页相关
  int _currentPage = 0;
  final int _pageSize = 3;
  bool _hasMoreData = false;

  // 图片轮播相关
  final Map<String, Timer> _imageTimers = {};
  final Map<String, int> _currentImageIndex = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    // 清理所有定时器
    for (final timer in _imageTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
        _isSearchMode = query.isNotEmpty;
      });
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearchMode = false;
      });
      return;
    }

    try {
      final results = await _courseService.searchCourses(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      print('Search error: $e');
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final featured = await _courseService.getFeaturedCourses();
      final coursePage = await _courseService.getCoursesPage(0, _pageSize);
      
      if (mounted) {
        setState(() {
          _featuredCourses = featured;
          _allCourses = coursePage;
          _currentPage = 0;
          _hasMoreData = coursePage.length == _pageSize;
          _isLoading = false;
        });
        
        // 启动图片轮播
        _startImageCarousels();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startImageCarousels() {
    final allCourses = [..._featuredCourses, ..._allCourses];
    
    for (final course in allCourses) {
      if (course.imageUrls.length > 1) {
        _currentImageIndex[course.id] = 0;
        _imageTimers[course.id] = Timer.periodic(
          const Duration(seconds: 3),
          (timer) {
            if (mounted) {
              setState(() {
                _currentImageIndex[course.id] = 
                    (_currentImageIndex[course.id]! + 1) % course.imageUrls.length;
              });
            }
          },
        );
      }
    }
  }

  void _onRefresh() async {
    try {
      await _loadInitialData();
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  void _onLoading() async {
    try {
      final nextPage = await _courseService.getCoursesPage(_currentPage + 1, _pageSize);
      
      if (nextPage.isEmpty) {
        _refreshController.loadNoData();
        setState(() => _hasMoreData = false);
        return;
      }

      setState(() {
        _allCourses.addAll(nextPage);
        _currentPage++;
        _hasMoreData = nextPage.length == _pageSize;
      });

      // 为新课程启动轮播
      for (final course in nextPage) {
        if (course.imageUrls.length > 1 && !_imageTimers.containsKey(course.id)) {
          _currentImageIndex[course.id] = 0;
          _imageTimers[course.id] = Timer.periodic(
            const Duration(seconds: 3),
            (timer) {
              if (mounted) {
                setState(() {
                  _currentImageIndex[course.id] = 
                      (_currentImageIndex[course.id]! + 1) % course.imageUrls.length;
                });
              }
            },
          );
        }
      }

      _refreshController.loadComplete();
    } catch (e) {
      _refreshController.loadFailed();
    }
  }

  String _getGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n.goodMorning;
    } else if (hour < 18) {
      return l10n.goodAfternoon;
    } else {
      return l10n.goodEvening;
    }
  }

  String _getUserDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0] ?? 'Melody';
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        enablePullUp: !_isSearchMode && _hasMoreData,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        header: WaterDropHeader(
          complete: Text('Updated!', style: AppTextStyles.bodyMedium),
          failed: Text('Update Failed', style: AppTextStyles.bodyMedium),
        ),
        footer: CustomFooter(
          builder: (context, mode) {
            Widget body;
            if (mode == LoadStatus.loading) {
              body = Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text("Loading more...", style: AppTextStyles.bodyMedium),
                ],
              );
            } else if (mode == LoadStatus.noMore) {
              body = Text("All courses loaded", style: AppTextStyles.bodyMedium);
            } else {
              body = Text("Pull up to load more", style: AppTextStyles.bodyMedium);
            }
            return Container(
              height: 55.0,
              child: Center(child: body),
            );
          },
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部安全区域
              const SizedBox(height: 50),
              
              // 问候语区域
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade50,
                      Colors.purple.shade50,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting(l10n)}，',
                            style: AppTextStyles.titleLarge.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            _getUserDisplayName(),
                            style: AppTextStyles.titleLarge.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 可爱的头像
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          '🐑',
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 搜索框
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchAllCourses,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              
              const SizedBox(height: 24),
              
              if (_isSearchMode) ...[
                // 搜索结果
                _buildSearchResults(l10n),
              ] else ...[
                // 热门课程
                _buildFeaturedCourses(l10n),
                
                const SizedBox(height: 32),
                
                // 全部课程
                _buildAllCourses(l10n),
              ],
              
              const SizedBox(height: 100),
            ],
=======
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;

    return Scaffold(
      backgroundColor: currentTheme.primaryColor.withOpacity(0.05),
      appBar: AppBar(
        backgroundColor: currentTheme.primaryColor.withOpacity(0.1),
        elevation: 0,
        title: Text(
          '探索',
          style: AppTextStyles.titleLarge.copyWith(
            color: currentTheme.primaryColor,
            fontWeight: FontWeight.w600,
>>>>>>> origin/dev
          ),
        ),
      ),
      body: Container(), // 空白的主体内容
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n) {
    if (_searchResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                l10n.noSearchResults,
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '${l10n.searchResults} (${_searchResults.length})',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return _buildCourseCard(_searchResults[index]);
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedCourses(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                l10n.popularCourses,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _featuredCourses.length,
            itemBuilder: (context, index) {
              return Container(
                width: 280,
                margin: EdgeInsets.only(right: index < _featuredCourses.length - 1 ? 16 : 0),
                child: _buildFeaturedCourseCard(_featuredCourses[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllCourses(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            l10n.allCourses,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _allCourses.length,
          itemBuilder: (context, index) {
            return _buildCourseCard(_allCourses[index]);
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedCourseCard(Course course) {
    final currentImageIndex = _currentImageIndex[course.id] ?? 0;
    final imageUrl = course.imageUrls.isNotEmpty 
        ? course.imageUrls[currentImageIndex] 
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _navigateToCourseDetail(course),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 课程图片
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
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
                          colors: [Colors.blue.shade300, Colors.purple.shade300],
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    if (imageUrl == null)
                      Center(
                        child: Icon(Icons.school, size: 48, color: Colors.white),
                      ),
                    // 评分标签
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.orange, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              course.rating.toString(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 课程信息
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            course.instructor,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            course.enrolledCountString,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    final currentImageIndex = _currentImageIndex[course.id] ?? 0;
    final imageUrl = course.imageUrls.isNotEmpty 
        ? course.imageUrls[currentImageIndex] 
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToCourseDetail(course),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 课程图片
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
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
                          colors: [Colors.blue.shade300, Colors.purple.shade300],
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? Center(
                        child: Icon(Icons.school, size: 32, color: Colors.white),
                      )
                    : null,
              ),
              
              // 课程信息
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            course.rating.toString(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.schedule, color: Colors.grey[600], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            course.durationString,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCourseDetail(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailScreen(course: course),
      ),
    );
  }
} 