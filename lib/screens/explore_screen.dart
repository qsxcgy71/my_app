import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../styles/app_text_styles.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';
import '../screens/course_detail_screen.dart';
import '../providers/theme_provider.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final CourseService _courseService = CourseService();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Course> _allCourses = [];
  List<Course> _searchResults = [];
  bool _isLoading = true;
  bool _isSearchMode = false;
  String _searchQuery = '';
  
  // Pagination
  int _currentPage = 0;
  final int _pageSize = 3;
  bool _hasMoreData = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _searchController.addListener(() {
      _performSearch(_searchController.text);
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await _courseService.getAllCourses();
      if (mounted) {
        setState(() {
          _allCourses = courses;
          _isLoading = false;
          _hasMoreData = courses.length > _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.trim();
      if (_searchQuery.isEmpty) {
        _searchResults.clear();
        _isSearchMode = false;
      } else {
        _isSearchMode = true;
        _searchResults = _allCourses.where((course) {
          return course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 course.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 course.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 course.instructor.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  void _onRefresh() async {
    await _loadCourses();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final startIndex = (_currentPage + 1) * _pageSize;
    if (startIndex >= _allCourses.length) {
      _refreshController.loadNoData();
      setState(() {
        _hasMoreData = false;
      });
      return;
    }

    setState(() {
      _currentPage++;
      if ((_currentPage + 1) * _pageSize >= _allCourses.length) {
        _hasMoreData = false;
      }
    });

    _refreshController.loadComplete();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return AppLocalizations.of(context)!.goodMorning;
    } else if (hour < 18) {
      return AppLocalizations.of(context)!.goodAfternoon;
    } else {
      return AppLocalizations.of(context)!.goodEvening;
    }
  }

  String _getUserDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0] ?? 'Melody';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    
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
          builder: (BuildContext context, LoadStatus? mode) {
            Widget body;
            if (mode == null || mode == LoadStatus.idle) {
              body = Text("↑ Pull up to load more", style: AppTextStyles.bodyMedium);
            } else if (mode == LoadStatus.loading) {
              body = Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  Text("Loading...", style: AppTextStyles.bodyMedium),
                ],
              );
            } else if (mode == LoadStatus.failed) {
              body = Text("Load Failed! Tap to retry", style: AppTextStyles.bodyMedium.copyWith(color: Colors.red));
            } else if (mode == LoadStatus.canLoading) {
              body = Text("↑ Release to load more", style: AppTextStyles.bodyMedium.copyWith(color: currentTheme.primaryColor));
            } else {
              body = Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text("All loaded", style: AppTextStyles.bodyMedium.copyWith(color: Colors.green)),
                ],
              );
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
              //const SizedBox(height: 50),
              
              // 问候语区域
              Container(
                width: MediaQuery.of(context).size.width,
                height: 200,
                padding: const EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      currentTheme.backgroundColor,
                      currentTheme.backgroundColor.withOpacity(0.8),
                      currentTheme.backgroundColor.withOpacity(0.5),
                      currentTheme.backgroundColor.withOpacity(0),
                    ],
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background pattern
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.8,
                        child: Transform.scale(
                          scale: 1.5,
                          child: Image.asset(
                            'assets/theme_wellcome/pattern.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    // Hero image
                    Positioned(
                      right: 0,
                      bottom: -60,
                      width: 200,
                      height: 200,
                      child: Transform.rotate(
                        angle: 0.05, // 约-5.7度
                        child: Image.asset(
                          'assets/theme_wellcome/theme_${themeProvider.currentTheme.toString().split('.').last.toLowerCase()}_hero.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // Greeting text
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()},',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: currentTheme.primaryColor,
                              fontSize: 28,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getUserDisplayName(),
                            style: AppTextStyles.titleLarge.copyWith(
                              color: currentTheme.primaryColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              //const SizedBox(height: 24),
              
              // 搜索栏
              Container(
                //height: 100,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: currentTheme.searchBoxColor,
                    width: 3.0,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchAllCourses,
                    //border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    prefixIcon: Icon(
                      Icons.search,
                      color: currentTheme.primaryColor.withOpacity(0.5),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: currentTheme.primaryColor.withOpacity(0.5),
                            ),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[500]),
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: currentTheme.primaryColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              if (_isSearchMode) ...[
                // 搜索结果
                _buildSearchResults(l10n, currentTheme),
              ] else ...[
                // 热门课程
                _buildFeaturedCourses(l10n, currentTheme),
                
                const SizedBox(height: 32),
                
                // 全部课程
                _buildAllCourses(l10n, currentTheme),
              ],
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n, dynamic currentTheme) {
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
            style: AppTextStyles.titleMedium.copyWith(
              color: currentTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return _buildCourseCard(_searchResults[index], currentTheme);
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedCourses(AppLocalizations l10n, dynamic currentTheme) {
    final featuredCourses = _allCourses.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            l10n.featuredCourses,
            style: AppTextStyles.titleMedium.copyWith(
              color: currentTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: featuredCourses.length,
            itemBuilder: (context, index) {
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                child: _buildFeaturedCourseCard(featuredCourses[index], currentTheme),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllCourses(AppLocalizations l10n, dynamic currentTheme) {
    final endIndex = (_currentPage + 1) * _pageSize;
    final paginatedCourses = _allCourses.take(endIndex).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            l10n.allCourses,
            style: AppTextStyles.titleMedium.copyWith(
              color: currentTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
            ),
            const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: paginatedCourses.length,
          itemBuilder: (context, index) {
            return _buildCourseCard(paginatedCourses[index], currentTheme);
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedCourseCard(Course course, dynamic currentTheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToCourseDetail(course),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                currentTheme.primaryColor,
                currentTheme.secondaryColor,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: currentTheme.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  course.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.white.withOpacity(0.8), size: 16),
                    const SizedBox(width: 4),
            Text(
                      course.instructor,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.category,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course, dynamic currentTheme) {
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        currentTheme.primaryColor.withOpacity(0.8),
                        currentTheme.secondaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            course.instructor,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: currentTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              course.category,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: currentTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
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