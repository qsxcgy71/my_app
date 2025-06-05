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
import '../widgets/keyboard_dismisser.dart';
import '../widgets/anti_spam_button.dart';
import '../models/app_theme.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'dart:async';
import 'dart:math';

import '../services/profile_service.dart';
import '../models/profile_model.dart';


class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final CourseService _courseService = CourseService();
  final ProfileService _profileService = ProfileService();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final ScrollController _scrollController = ScrollController();
  final ScrollController _featuredCoursesController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _searchFieldKey = GlobalKey(); // 搜索框的key
  Timer? _autoScrollTimer;

  List<Course> _allCourses = [];
  List<Course> _searchResults = [];
  bool _isLoading = true;
  bool _isSearchMode = false;
  String _searchQuery = '';
  CourseFilter _currentFilter = CourseFilter();
  bool _showFilterPanel = false;
  UserProfile? _userProfile;
  
  // Pagination
  int _currentPage = 0;
  final int _pageSize = 3;
  bool _hasMoreData = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadUserProfile();
    _searchController.addListener(() {
      _performSearch(_searchController.text);
    });
    _setupAutoScroll();
    _checkAssetExists();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    _featuredCoursesController.dispose();
    _searchController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _setupAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) return;
      
      if (_featuredCoursesController.hasClients) {
        final maxScrollExtent = _featuredCoursesController.position.maxScrollExtent;
        final currentPosition = _featuredCoursesController.offset;
        final targetPosition = currentPosition >= maxScrollExtent ? 0.0 : currentPosition + 280.0;
        
        _featuredCoursesController.animateTo(
          targetPosition,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
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

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.trim();
      _updateSearchResults();
    });
  }

  void _performSearchAndCollapse() {
    _updateSearchResults();
    setState(() {
      _showFilterPanel = false;
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
      // 年龄过滤 - 支持多个年龄范围
      if (_currentFilter.ageRanges.isNotEmpty) {
        results = results.where((course) {
          return _currentFilter.ageRanges.any((ageRange) {
            return course.recommendedAge >= ageRange.minAge &&
                   course.recommendedAge <= ageRange.maxAge;
          });
        }).toList();
      }
      
      // 课程类型过滤
      if (_currentFilter.courseTypes.isNotEmpty) {
        results = results.where((course) {
          return _currentFilter.courseTypes.contains(course.category);
        }).toList();
      }
      
      // 时间段过滤 - 支持多个时间段（这里假设课程有时间段属性，暂时跳过实际过滤）
      if (_currentFilter.timeRanges.isNotEmpty) {
        // 注意：由于Course模型目前没有时间段信息，这里暂时不过滤
        // 如果需要实际过滤，需要在Course模型中添加时间段信息
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
    });
  }

  void _applyFilter(CourseFilter newFilter) {
    setState(() {
      _currentFilter = newFilter;
    });
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
    try {
      await Future.wait([
        _loadCourses(),
        _loadUserProfile(), // 同时刷新用户profile
      ]);
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
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

  Widget _buildGreeting() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    
    return Text(
      _getGreeting(),
      style: TextStyle(
        fontSize: 24,
        fontFamily: 'GenSenRounded',
        color: currentTheme.primaryColor,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0.5,
      ),
    );
  }

  String _getUserDisplayName() {
    // 优先使用用户在profile中设置的名字
    if (_userProfile?.name != null && _userProfile!.name.isNotEmpty) {
      return _userProfile!.name;
    }
    
    // 其次使用Firebase Auth中的displayName
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    
    // 最后使用邮箱前缀或默认名称
    return user?.email?.split('@')[0] ?? 'Melody';
  }

  String _getHeroImagePath(AppThemeType theme) {
    if (theme == AppThemeType.default_theme) {
      return 'assets/theme_wellcome/theme_siufa_hero.png';
    }
    final themeName = theme.toString().split('.').last.toLowerCase();
    return 'assets/theme_wellcome/theme_${themeName}_hero.png';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    final heroImagePath = _getHeroImagePath(themeProvider.currentTheme);
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return SmartKeyboardDismisser(
      excludeWidgets: [_searchFieldKey], // 排除搜索框，点击搜索框不会隐藏键盘
      child: Scaffold(
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
                // 问候语区域
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 180,
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 8),
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
                          angle: 0.05,
                          child: Image.asset(
                            heroImagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading hero image: $error');
                              print('Stack trace: $stackTrace');
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red),
                                  color: Colors.grey[200],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, size: 40, color: Colors.red),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error: $error',
                                      style: const TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
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
                            _buildGreeting(),
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
                
                const SizedBox(height: 16),
                
                // 新的搜索和筛选布局
                _buildSearchAndFilterSection(l10n, currentTheme),
                
                // 筛选面板 (如果显示)
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
      ),
    );
  }

  // 新的搜索和筛选布局
  Widget _buildSearchAndFilterSection(AppLocalizations l10n, dynamic currentTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // 搜索框 - 简化设计，移除内部筛选按钮
          Container(
            key: _searchFieldKey,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: currentTheme.searchBoxColor,
                width: 3.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.searchAllCourses,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.search,
                            color: currentTheme.primaryColor.withOpacity(0.5),
                            size: 18,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
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
                ),
                
                // 搜索确认按钮
                Container(
                  margin: const EdgeInsets.all(4),
                  child: AntiSpamButton(
                    onPressed: _performSearchAndCollapse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                      minimumSize: const Size(65, 34),
                    ),
                    child: Text(
                      l10n.search,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 筛选条件区域 - 新设计
          _buildQuickFiltersSection(l10n, currentTheme),
          
          // 活动筛选条件显示 (如果有的话)
          if (_currentFilter.hasFilters) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildActiveFiltersChips(l10n, currentTheme)),
                const SizedBox(width: 8),
                // 清除筛选按钮
                TextButton.icon(
                  onPressed: _clearAllFilters,
                  icon: Icon(Icons.clear_all, size: 16, color: Colors.grey[600]),
                  label: Text(
                    l10n.clearAll,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 快速筛选条件区域
  Widget _buildQuickFiltersSection(AppLocalizations l10n, dynamic currentTheme) {
    // 预设的快速筛选条件 - 只保留3个最常用的
    final quickFilters = [
      {
        'label': '艺术创作',
        'type': 'courseType',
        'value': '艺术创作',
        'isSelected': _currentFilter.courseTypes.contains('艺术创作'),
      },
      {
        'label': '4-6岁',
        'type': 'ageRange',
        'value': const AgeRange(minAge: 4, maxAge: 6, displayName: '4-6岁'),
        'isSelected': _currentFilter.ageRanges.contains(const AgeRange(minAge: 4, maxAge: 6, displayName: '4-6岁')),
      },
      {
        'label': '在线课程',
        'type': 'online',
        'value': true,
        'isSelected': _currentFilter.onlineOnly,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // 筛选条件chips - 展开占用空间
          Expanded(
            child: Row(
              children: quickFilters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildQuickFilterChip(
                    label: filter['label'] as String,
                    isSelected: filter['isSelected'] as bool,
                    onTap: () => _handleQuickFilterTap(filter),
                    currentTheme: currentTheme,
                  ),
                );
              }).toList(),
            ),
          ),
          
          // 更多筛选按钮 - 改小
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showFilterPanel = !_showFilterPanel;
                  });
                },
                icon: Icon(
                  _showFilterPanel ? Icons.expand_less : Icons.tune,
                  color: _currentFilter.hasFilters 
                      ? currentTheme.primaryColor 
                      : currentTheme.primaryColor.withOpacity(0.7),
                  size: 20,
                ),
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                padding: const EdgeInsets.all(8),
                tooltip: _showFilterPanel ? l10n.collapseFilter : l10n.moreFilters,
                style: IconButton.styleFrom(
                  backgroundColor: _showFilterPanel 
                      ? currentTheme.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
              ),
              if (_currentFilter.hasFilters)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                    child: Text(
                      '${_currentFilter.activeFiltersCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 快速筛选chip
  Widget _buildQuickFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic currentTheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? currentTheme.primaryColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? currentTheme.primaryColor
                : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? currentTheme.primaryColor
                : Colors.grey[700],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 处理快速筛选点击
  void _handleQuickFilterTap(Map<String, dynamic> filter) {
    final type = filter['type'] as String;
    final value = filter['value'];
    final isSelected = filter['isSelected'] as bool;

    switch (type) {
      case 'courseType':
        final newTypes = List<String>.from(_currentFilter.courseTypes);
        if (isSelected) {
          newTypes.remove(value);
        } else {
          newTypes.add(value);
        }
        _applyFilter(_currentFilter.copyWith(courseTypes: newTypes));
        break;
        
      case 'ageRange':
        final ageRange = value as AgeRange;
        final newAgeRanges = List<AgeRange>.from(_currentFilter.ageRanges);
        if (isSelected) {
          newAgeRanges.remove(ageRange);
        } else {
          newAgeRanges.add(ageRange);
        }
        _applyFilter(_currentFilter.copyWith(ageRanges: newAgeRanges));
        break;
        
      case 'online':
        _applyFilter(_currentFilter.copyWith(onlineOnly: !isSelected));
        break;
    }
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
            if (index >= _searchResults.length) return null;
            return _buildCourseCard(_searchResults[index], currentTheme);
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedCourses(AppLocalizations l10n, dynamic currentTheme) {
    // 使用 sublist 替代 take，并确保不会越界
    final featuredCourses = _allCourses.sublist(0, min(3, _allCourses.length));
    
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
            controller: _featuredCoursesController,
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
    // 使用 sublist 替代 take，并确保 endIndex 不会超出列表长度
    final paginatedCourses = _allCourses.sublist(0, endIndex.clamp(0, _allCourses.length));
    
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
                          isSelected: _currentFilter.ageRanges.isEmpty,
                          onTap: () {
                            // 清除所有年龄范围选择
                            _applyFilter(_currentFilter.copyWith(ageRanges: []));
                          },
                          currentTheme: currentTheme,
                        ),
                        ...AgeRange.predefinedRanges.map<Widget>((ageRange) =>
                          _buildFilterChip(
                            label: ageRange.displayName,
                            isSelected: _currentFilter.ageRanges.contains(ageRange),
                            onTap: () {
                              final newAgeRanges = List<AgeRange>.from(_currentFilter.ageRanges);
                              if (newAgeRanges.contains(ageRange)) {
                                newAgeRanges.remove(ageRange);
                              } else {
                                newAgeRanges.add(ageRange);
                              }
                              _applyFilter(_currentFilter.copyWith(ageRanges: newAgeRanges));
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
                      children: CourseTypes.all.map<Widget>((type) =>
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
                          isSelected: _currentFilter.timeRanges.isEmpty,
                          onTap: () {
                            // 清除所有时间段选择
                            _applyFilter(_currentFilter.copyWith(timeRanges: []));
                          },
                          currentTheme: currentTheme,
                        ),
                        ...TimeRange.predefinedRanges.map<Widget>((timeRange) =>
                          _buildFilterChip(
                            label: timeRange.getLocalizedDisplayName(Localizations.localeOf(context).languageCode),
                            isSelected: _currentFilter.timeRanges.contains(timeRange),
                            onTap: () {
                              final newTimeRanges = List<TimeRange>.from(_currentFilter.timeRanges);
                              if (newTimeRanges.contains(timeRange)) {
                                newTimeRanges.remove(timeRange);
                              } else {
                                newTimeRanges.add(timeRange);
                              }
                              _applyFilter(_currentFilter.copyWith(timeRanges: newTimeRanges));
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
                      children: Difficulties.all.map<Widget>((difficulty) =>
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

  Widget _buildActiveFiltersChips(AppLocalizations l10n, dynamic currentTheme) {
    List<Widget> chips = [];
    
    if (_currentFilter.ageRanges.isNotEmpty) {
      for (final ageRange in _currentFilter.ageRanges) {
        chips.add(_buildActiveFilterChip(
          '${ageRange.minAge}-${ageRange.maxAge}岁',
          currentTheme,
          onRemove: () {
            setState(() {
              final newAgeRanges = List<AgeRange>.from(_currentFilter.ageRanges);
              newAgeRanges.remove(ageRange);
              _currentFilter = _currentFilter.copyWith(ageRanges: newAgeRanges);
              _updateSearchResults();
            });
          },
        ));
      }
    }
    
    if (_currentFilter.courseTypes.isNotEmpty) {
      for (final type in _currentFilter.courseTypes) {
        chips.add(_buildActiveFilterChip(
          type,
          currentTheme,
          onRemove: () {
            setState(() {
              final newTypes = List<String>.from(_currentFilter.courseTypes);
              newTypes.remove(type);
              _currentFilter = _currentFilter.copyWith(courseTypes: newTypes);
              _updateSearchResults();
            });
          },
        ));
      }
    }
    
    if (_currentFilter.difficulties.isNotEmpty) {
      for (final difficulty in _currentFilter.difficulties) {
        chips.add(_buildActiveFilterChip(
          difficulty,
          currentTheme,
          onRemove: () {
            setState(() {
              final newDifficulties = List<String>.from(_currentFilter.difficulties);
              newDifficulties.remove(difficulty);
              _currentFilter = _currentFilter.copyWith(difficulties: newDifficulties);
              _updateSearchResults();
            });
          },
        ));
      }
    }
    
    if (_currentFilter.onlineOnly) {
      chips.add(_buildActiveFilterChip(
        l10n.onlineCoursesOnly,
        currentTheme,
        onRemove: () {
          setState(() {
            _currentFilter = _currentFilter.copyWith(onlineOnly: false);
            _updateSearchResults();
          });
        },
      ));
    }
    
    if (chips.isEmpty) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, dynamic currentTheme, {VoidCallback? onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: currentTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: currentTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: currentTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.transparent,
                ),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: currentTheme.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _checkAssetExists() async {
    try {
      final byteData = await rootBundle.load('assets/theme_wellcome/theme_siufa_hero.png');
      print('Successfully loaded theme_siufa_hero.png, size: ${byteData.lengthInBytes} bytes');
    } catch (e, stackTrace) {
      print('Error checking asset: $e');
      print('Stack trace: $stackTrace');
    }
  }
} 