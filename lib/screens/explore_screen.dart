import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../styles/app_text_styles.dart';
import '../models/course_model.dart';
import '../models/course_filter.dart';
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
  CourseFilter _currentFilter = CourseFilter();
  bool _showFilterPanel = false;
  
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
      _updateSearchResults();
    });
  }

  void _updateSearchResults() {
    List<Course> results = List.from(_allCourses);
    
    // 文本搜索
    if (_searchQuery.isNotEmpty) {
      results = results.where((course) {
        return course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               course.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               course.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               course.instructor.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // 应用过滤器
    if (_currentFilter.hasFilters) {
      // 年龄过滤
      if (_currentFilter.ageRange != null) {
        results = results.where((course) {
          return course.recommendedAge >= _currentFilter.ageRange!.minAge &&
                 course.recommendedAge <= _currentFilter.ageRange!.maxAge;
        }).toList();
      }
      
      // 课程类型过滤
      if (_currentFilter.courseTypes.isNotEmpty) {
        results = results.where((course) {
          return _currentFilter.courseTypes.contains(course.category);
        }).toList();
      }
      
      // 难度过滤
      if (_currentFilter.difficulties.isNotEmpty) {
        results = results.where((course) {
          return _currentFilter.difficulties.contains(course.difficulty);
        }).toList();
      }
      
      // 价格过滤
      if (_currentFilter.minPrice != null) {
        results = results.where((course) => course.price >= _currentFilter.minPrice!).toList();
      }
      if (_currentFilter.maxPrice != null) {
        results = results.where((course) => course.price <= _currentFilter.maxPrice!).toList();
      }
      
      // 在线课程过滤
      if (_currentFilter.onlineOnly) {
        results = results.where((course) => course.isOnline).toList();
      }
    }
    
    setState(() {
      _searchResults = results;
      _isSearchMode = _searchQuery.isNotEmpty || _currentFilter.hasFilters;
      // 执行搜索后自动收起筛选面板
      _showFilterPanel = false;
    });
  }

  void _applyFilter(CourseFilter newFilter) {
    setState(() {
      _currentFilter = newFilter;
    });
    _updateSearchResults();
  }

  void _clearAllFilters() {
    setState(() {
      _currentFilter = CourseFilter();
      _searchController.clear();
      _searchQuery = '';
      _showFilterPanel = false;
    });
    _updateSearchResults();
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
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l10n.searchAllCourses,
                          border: InputBorder.none,
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
                    // 筛选按钮
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _showFilterPanel = !_showFilterPanel;
                              });
                              // 如果正在收起面板且有搜索内容或筛选条件，则执行搜索
                              if (!_showFilterPanel && (_searchQuery.isNotEmpty || _currentFilter.hasFilters)) {
                                _updateSearchResults();
                              }
                            },
                            icon: Icon(
                              _showFilterPanel ? Icons.filter_list_off : Icons.filter_list,
                              color: _currentFilter.hasFilters 
                                  ? currentTheme.primaryColor 
                                  : currentTheme.primaryColor.withOpacity(0.6),
                            ),
                          ),
                          if (_currentFilter.hasFilters)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  '${_currentFilter.activeFiltersCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // 搜索确认按钮
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ElevatedButton(
                        onPressed: _updateSearchResults,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _showFilterPanel ? l10n.searchAndCollapse : l10n.search, 
                          style: const TextStyle(fontSize: 14)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 筛选面板
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showFilterPanel 
                    ? _buildFilterPanel(l10n, currentTheme)
                    : const SizedBox.shrink(),
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
              if (_currentFilter.hasFilters) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: Text(
                    l10n.clearFilters,
                    style: TextStyle(color: currentTheme.primaryColor),
                  ),
                ),
              ],
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
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.searchResults} (${_searchResults.length})',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: currentTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_currentFilter.hasFilters)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: currentTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.filtersApplied(_currentFilter.activeFiltersCount),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: currentTheme.primaryColor,
                    ),
                  ),
                ),
            ],
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

  Widget _buildFilterPanel(AppLocalizations l10n, dynamic currentTheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: currentTheme.searchBoxColor.withOpacity(0.3),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 筛选标题和清除按钮
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.filterConditions,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: currentTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentFilter.hasFilters)
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: Text(
                      l10n.clearAll,
                      style: TextStyle(color: currentTheme.primaryColor),
                    ),
                  ),
              ],
            ),
          ),
          
          // 可滚动内容区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 年龄范围
                  _buildFilterSection(
                    title: l10n.suitableAge,
                    content: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip(
                          label: l10n.noAgeLimit,
                          isSelected: _currentFilter.ageRange == null,
                          onTap: () {
                            _applyFilter(_currentFilter.copyWith(ageRange: null));
                          },
                          currentTheme: currentTheme,
                        ),
                        ...AgeRange.predefinedRanges.map((ageRange) =>
                          _buildFilterChip(
                            label: ageRange.displayName,
                            isSelected: _currentFilter.ageRange == ageRange,
                            onTap: () {
                              _applyFilter(_currentFilter.copyWith(ageRange: ageRange));
                            },
                            currentTheme: currentTheme,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 课程类型
                  _buildFilterSection(
                    title: l10n.courseType,
                    content: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CourseTypes.all.map((type) =>
                        _buildFilterChip(
                          label: type,
                          isSelected: _currentFilter.courseTypes.contains(type),
                          onTap: () {
                            final newTypes = List<String>.from(_currentFilter.courseTypes);
                            if (newTypes.contains(type)) {
                              newTypes.remove(type);
                            } else {
                              newTypes.add(type);
                            }
                            _applyFilter(_currentFilter.copyWith(courseTypes: newTypes));
                          },
                          currentTheme: currentTheme,
                        ),
                      ).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 时间段
                  _buildFilterSection(
                    title: l10n.classTime,
                    content: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip(
                          label: l10n.noTimeLimit,
                          isSelected: _currentFilter.timeRange == null,
                          onTap: () {
                            _applyFilter(_currentFilter.copyWith(timeRange: null));
                          },
                          currentTheme: currentTheme,
                        ),
                        ...TimeRange.predefinedRanges.map((timeRange) =>
                          _buildFilterChip(
                            label: timeRange.getLocalizedDisplayName(Localizations.localeOf(context).languageCode),
                            isSelected: _currentFilter.timeRange == timeRange,
                            onTap: () {
                              _applyFilter(_currentFilter.copyWith(timeRange: timeRange));
                            },
                            currentTheme: currentTheme,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 难度等级
                  _buildFilterSection(
                    title: l10n.difficultyLevel,
                    content: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Difficulties.all.map((difficulty) =>
                        _buildFilterChip(
                          label: difficulty,
                          isSelected: _currentFilter.difficulties.contains(difficulty),
                          onTap: () {
                            final newDifficulties = List<String>.from(_currentFilter.difficulties);
                            if (newDifficulties.contains(difficulty)) {
                              newDifficulties.remove(difficulty);
                            } else {
                              newDifficulties.add(difficulty);
                            }
                            _applyFilter(_currentFilter.copyWith(difficulties: newDifficulties));
                          },
                          currentTheme: currentTheme,
                        ),
                      ).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 其他选项
                  CheckboxListTile(
                    title: Text(l10n.onlineCoursesOnly),
                    value: _currentFilter.onlineOnly,
                    onChanged: (value) {
                      _applyFilter(_currentFilter.copyWith(onlineOnly: value ?? false));
                    },
                    activeColor: currentTheme.primaryColor,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic currentTheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? currentTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? currentTheme.primaryColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
} 