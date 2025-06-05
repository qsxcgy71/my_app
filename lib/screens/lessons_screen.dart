import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:provider/provider.dart';
import '../models/lesson_model.dart';
import '../styles/app_text_styles.dart';
import '../services/lesson_service.dart';
import '../models/app_theme.dart';
import '../providers/theme_provider.dart';
import '../widgets/theme_selector.dart';
import 'lesson_detail_screen.dart';
import '../l10n/app_localizations.dart';
import '../widgets/keyboard_dismisser.dart';
import '../widgets/anti_spam_button.dart';
import '../models/course_filter.dart';

// 响应式布局助手
class ResponsiveHelper {
  static bool isSmallScreen(BuildContext context) => 
      MediaQuery.of(context).size.height < 600;
  
  static bool isVerySmallScreen(BuildContext context) => 
      MediaQuery.of(context).size.height < 500;
  
  static double getFilterPanelMaxHeight(BuildContext context) =>
      MediaQuery.of(context).size.height * (isSmallScreen(context) ? 0.20 : 0.35);
  
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenHeight < 600;
    return EdgeInsets.symmetric(
      horizontal: 20,
      vertical: isSmall ? 4 : 8,
    );
  }
  
  static double getResponsiveSpacing(BuildContext context) {
    return isSmallScreen(context) ? 6 : 10;
  }
  
  // 新增：获取Tab栏的间距 - 进一步缩小
  static double getTabBarSpacing(BuildContext context) {
    return isSmallScreen(context) ? 3 : 5;
  }
  
  // 新增：获取搜索区域的间距 - 大幅缩小
  static double getSearchSectionSpacing(BuildContext context) {
    return isSmallScreen(context) ? 3 : 5;
  }
  
  // 新增：筛选面板内部间距
  static double getFilterPanelInternalSpacing(BuildContext context) {
    return isSmallScreen(context) ? 6 : 8;
  }
}

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> with TickerProviderStateMixin {
  final _lessonService = LessonService();
  final _enrolledRefreshController = RefreshController(initialRefresh: false);
  final _completedRefreshController = RefreshController(initialRefresh: false);
  final _enrolledScrollController = ScrollController();
  final _completedScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  // Tab controller
  late TabController _tabController;
  
  // Data
  List<Lesson> _enrolledLessons = [];
  List<Lesson> _completedLessons = [];
  List<Lesson> _enrolledSearchResults = [];
  List<Lesson> _completedSearchResults = [];
  
  // Search and Filter
  bool _isSearchMode = false;
  String _searchQuery = '';
  CourseFilter _currentFilter = CourseFilter();
  bool _showFilterPanel = false;

  // Calendar
  bool _isCalendarVisible = false;
  late AnimationController _calendarAnimationController;
  late Animation<double> _calendarAnimation;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Pagination
  Map<int, int> _currentPages = {0: 0, 1: 0}; // 为每个tab保存独立的页码
  final int _pageSize = 5;
  Map<int, bool> _hasMoreData = {0: false, 1: false}; // 为每个tab保存独立的加载状态

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 初始化动画控制器
    _calendarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _calendarAnimation = CurvedAnimation(
      parent: _calendarAnimationController,
      curve: Curves.easeInOut,
    );
    
    _loadLessons();
    
    // 搜索监听器
    _searchController.addListener(() {
      _performSearch(_searchController.text);
    });
    
    // 监听tab切换，分别管理不同列表的滚动位置
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _calendarAnimationController.dispose();
    _enrolledRefreshController.dispose();
    _completedRefreshController.dispose();
    _enrolledScrollController.dispose();
    _completedScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.trim();
      _updateSearchResults();
    });
  }

  void _updateSearchResults() {
    // 如果既没有搜索词也没有筛选条件，保持搜索模式但显示空状态
    if (_searchQuery.isEmpty && !_currentFilter.hasFilters) {
      setState(() {
        _enrolledSearchResults = [];
        _completedSearchResults = [];
        // 保持搜索模式但显示提示信息
      });
      return;
    }

    List<Lesson> enrolledResults = List.from(_enrolledLessons);
    List<Lesson> completedResults = List.from(_completedLessons);

    // 文本搜索
    if (_searchQuery.isNotEmpty) {
      enrolledResults = enrolledResults.where((lesson) {
        return lesson.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               lesson.courseName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (lesson.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
               (lesson.courseCategory?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
      
      completedResults = completedResults.where((lesson) {
        return lesson.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               lesson.courseName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (lesson.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
               (lesson.courseCategory?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // 应用过滤器
    if (_currentFilter.hasFilters) {
      // 课程类型过滤
      if (_currentFilter.courseTypes.isNotEmpty) {
        enrolledResults = enrolledResults.where((lesson) {
          return _currentFilter.courseTypes.contains(lesson.courseCategory);
        }).toList();
        
        completedResults = completedResults.where((lesson) {
          return _currentFilter.courseTypes.contains(lesson.courseCategory);
        }).toList();
      }
      
      // 时间段过滤（基于课程开始时间）
      if (_currentFilter.timeRanges.isNotEmpty) {
        enrolledResults = enrolledResults.where((lesson) {
          final hour = lesson.startTime.hour;
          return _currentFilter.timeRanges.any((timeRange) {
            final startHour = int.parse(timeRange.startTime.split(':')[0]);
            final endHour = int.parse(timeRange.endTime.split(':')[0]);
            return hour >= startHour && hour < endHour;
          });
        }).toList();
        
        completedResults = completedResults.where((lesson) {
          final hour = lesson.startTime.hour;
          return _currentFilter.timeRanges.any((timeRange) {
            final startHour = int.parse(timeRange.startTime.split(':')[0]);
            final endHour = int.parse(timeRange.endTime.split(':')[0]);
            return hour >= startHour && hour < endHour;
          });
        }).toList();
      }
    }

    setState(() {
      _enrolledSearchResults = enrolledResults;
      _completedSearchResults = completedResults;
    });
  }

  void _performSearchAndCollapse() {
    _updateSearchResults();
    // 收起键盘
    FocusScope.of(context).unfocus();
    setState(() {
      _showFilterPanel = false;
    });
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        _searchQuery = '';
        _enrolledSearchResults = [];
        _completedSearchResults = [];
        _currentFilter = CourseFilter();
        _showFilterPanel = false;
        // 收起键盘
        FocusScope.of(context).unfocus();
      }
    });
  }

  void _enterSearchMode() {
    setState(() {
      _isSearchMode = true;
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
        
      case 'timeRange':
        final timeRange = value as TimeRange;
        final newTimeRanges = List<TimeRange>.from(_currentFilter.timeRanges);
        if (isSelected) {
          newTimeRanges.remove(timeRange);
        } else {
          newTimeRanges.add(timeRange);
        }
        _applyFilter(_currentFilter.copyWith(timeRanges: newTimeRanges));
        break;
    }
  }

  Future<void> _loadLessons() async {
    try {
      final enrolled = await _lessonService.getEnrolledLessons();
      final completed = await _lessonService.getCompletedLessons();

      if (mounted) {
        setState(() {
          _enrolledLessons = enrolled;
          _completedLessons = completed;
          _currentPages = {0: 0, 1: 0}; // 重置页码
          _hasMoreData = {
            0: enrolled.length > _pageSize,
            1: completed.length > _pageSize,
          };
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _createSampleLessons() async {
    try {
      await _lessonService.createSampleLessons();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('示例课程已创建'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 重新加载课程列表
        await _loadLessons();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建示例课程失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  List<Lesson> _getCurrentLessons() {
    if (_isSearchMode && (_searchQuery.isNotEmpty || _currentFilter.hasFilters)) {
      return _tabController.index == 0 ? _enrolledSearchResults : _completedSearchResults;
    }
    return _tabController.index == 0 ? _enrolledLessons : _completedLessons;
  }

  List<Lesson> _getPaginatedLessons() {
    final lessons = _getCurrentLessons();
    if (_isSearchMode && (_searchQuery.isNotEmpty || _currentFilter.hasFilters)) {
      return lessons;
    }
    final currentPage = _currentPages[_tabController.index] ?? 0;
    final endIndex = (currentPage + 1) * _pageSize;
    return lessons.sublist(0, endIndex.clamp(0, lessons.length));
  }

  void _onRefresh() async {
    try {
      await _loadLessons();
      if (_tabController.index == 0) {
        _enrolledRefreshController.refreshCompleted();
      } else {
        _completedRefreshController.refreshCompleted();
      }
    } catch (e) {
      if (_tabController.index == 0) {
        _enrolledRefreshController.refreshFailed();
      } else {
        _completedRefreshController.refreshFailed();
      }
    }
  }

  void _onLoading() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final currentLessons = _getCurrentLessons();
      final currentPage = _currentPages[_tabController.index] ?? 0;
      final startIndex = (currentPage + 1) * _pageSize;
      
      if (startIndex >= currentLessons.length) {
        if (_tabController.index == 0) {
          _enrolledRefreshController.loadNoData();
        } else {
          _completedRefreshController.loadNoData();
        }
        setState(() {
          _hasMoreData[_tabController.index] = false;
        });
        return;
      }

      setState(() {
        _currentPages[_tabController.index] = currentPage + 1;
        _hasMoreData[_tabController.index] = (currentPage + 2) * _pageSize < currentLessons.length;
      });

      if (_tabController.index == 0) {
        _enrolledRefreshController.loadComplete();
      } else {
        _completedRefreshController.loadComplete();
      }
    } catch (e) {
      if (_tabController.index == 0) {
        _enrolledRefreshController.loadFailed();
      } else {
        _completedRefreshController.loadFailed();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    
    return KeyboardDismisser(
      child: Scaffold(
        backgroundColor: currentTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: currentTheme.backgroundColor,
          elevation: 0,
          title: _isSearchMode ? _buildSearchBar(l10n, currentTheme) : Text(
            l10n.myLessons,
            style: AppTextStyles.titleLarge.copyWith(
              color: currentTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: _isSearchMode ? [
            // 搜索模式下显示取消按钮
            TextButton(
              onPressed: _toggleSearchMode,
              child: Text(
                l10n.cancel,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: currentTheme.primaryColor,
                ),
              ),
            ),
          ] : [
            // 正常模式下显示搜索图标和其他按钮
            IconButton(
              icon: Icon(
                Icons.search,
                color: currentTheme.primaryColor,
              ),
              onPressed: _enterSearchMode,
            ),
            const ThemeSelector(),
            AntiSpamWrapper(
              onTap: _createSampleLessons,
              child: IconButton(
                icon: Icon(
                  Icons.add_circle,
                  color: currentTheme.primaryColor,
                ),
                tooltip: l10n.addTestData,
                onPressed: null, // 由 AntiSpamWrapper 处理
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 搜索和筛选区域 - 紧凑布局
              if (_isSearchMode) ...[
                SizedBox(height: ResponsiveHelper.getSearchSectionSpacing(context)),
                _buildFilterSection(l10n, currentTheme),
                
                // 筛选面板 - 使用更紧凑的布局
                if (_showFilterPanel) ...[
                  SizedBox(height: ResponsiveHelper.getSearchSectionSpacing(context)),
                  _buildFilterPanel(l10n, currentTheme),
                ],
                
                SizedBox(height: ResponsiveHelper.getSearchSectionSpacing(context)),
              ] else
                SizedBox(height: ResponsiveHelper.getTabBarSpacing(context)),
              
              // Tab Bar - 进一步缩小间距
              _buildLessonsTabBar(l10n, currentTheme),
              SizedBox(height: ResponsiveHelper.getTabBarSpacing(context)),

              // 可滚动内容区域 - 使用Expanded确保占满剩余空间
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // 已报名课程列表
                    _buildTabContent(0, l10n, currentTheme),
                    // 已完成课程列表
                    _buildTabContent(1, l10n, currentTheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 统一的Tab内容构建方法，解决布局溢出问题
  Widget _buildTabContent(int tabIndex, AppLocalizations l10n, dynamic currentTheme) {
    final refreshController = tabIndex == 0 ? _enrolledRefreshController : _completedRefreshController;
    final hasMoreData = _hasMoreData[tabIndex] ?? false;

    return SmartRefresher(
      controller: refreshController,
      enablePullDown: true,
      enablePullUp: !_isSearchMode && hasMoreData,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      header: WaterDropHeader(
        complete: Text(l10n.updated, style: AppTextStyles.bodyMedium),
        failed: Text(l10n.updateFailed, style: AppTextStyles.bodyMedium),
      ),
      footer: CustomFooter(
        builder: (BuildContext context, LoadStatus? mode) {
          Widget body;
          if (mode == null || mode == LoadStatus.idle) {
            body = Text(l10n.pullUpToLoadMore, style: AppTextStyles.bodyMedium);
          } else if (mode == LoadStatus.loading) {
            body = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text(l10n.loading, style: AppTextStyles.bodyMedium),
              ],
            );
          } else if (mode == LoadStatus.failed) {
            body = Text(l10n.loadFailed, style: AppTextStyles.bodyMedium.copyWith(color: Colors.red));
          } else if (mode == LoadStatus.canLoading) {
            body = Text(l10n.releaseToLoadMore, style: AppTextStyles.bodyMedium.copyWith(color: currentTheme.primaryColor));
          } else {
            body = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(l10n.allLoaded, style: AppTextStyles.bodyMedium.copyWith(color: Colors.green)),
              ],
            );
          }
          return Container(
            height: 55.0,
            child: Center(child: body),
          );
        },
      ),
      child: _buildLessonsList(tabIndex, l10n),
    );
  }

  // 搜索栏 - 在AppBar中显示，移除搜索按钮
  Widget _buildSearchBar(AppLocalizations l10n, dynamic currentTheme) {
    return Container(
      height: 40,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.searchCoursePlaceholder,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          prefixIcon: Icon(
            Icons.search,
            color: currentTheme.primaryColor.withOpacity(0.5),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: currentTheme.primaryColor.withOpacity(0.5),
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[500]),
        ),
        style: AppTextStyles.bodyMedium.copyWith(
          color: currentTheme.primaryColor,
        ),
        onSubmitted: (value) {
          // 按回车键收起键盘
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  // 筛选区域 - 仿照探索界面设计，实现真实的筛选功能
  Widget _buildFilterSection(AppLocalizations l10n, dynamic currentTheme) {
    // 课程类型筛选
    final quickFilters = [
      {
        'label': '艺术创作',
        'type': 'courseType',
        'value': '艺术创作',
        'isSelected': _currentFilter.courseTypes.contains('艺术创作'),
      },
      {
        'label': '科学探索',
        'type': 'courseType',
        'value': '科学探索',
        'isSelected': _currentFilter.courseTypes.contains('科学探索'),
      },
      {
        'label': '上午时段',
        'type': 'timeRange',
        'value': const TimeRange(startTime: '09:00', endTime: '12:00', displayName: '上午时段'),
        'isSelected': _currentFilter.timeRanges.contains(const TimeRange(startTime: '09:00', endTime: '12:00', displayName: '上午时段')),
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: ResponsiveHelper.isSmallScreen(context) ? 2 : 3,
      ),
      child: Row(
        children: [
          // 快速筛选按钮
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: quickFilters.map((filter) {
                  return Padding(
                    padding: EdgeInsets.only(right: ResponsiveHelper.isSmallScreen(context) ? 6 : 8),
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
          ),
          
          // 更多筛选按钮
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
                  size: 18,
                ),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: const EdgeInsets.all(6),
                tooltip: _showFilterPanel ? l10n.collapseFilter : l10n.moreFilters,
                style: IconButton.styleFrom(
                  backgroundColor: _showFilterPanel 
                      ? currentTheme.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
              ),
              if (_currentFilter.hasFilters)
                Positioned(
                  right: 3,
                  top: 3,
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
                    child: Text(
                      '${_currentFilter.activeFiltersCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
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

  // 筛选面板 - 添加响应式设计
  Widget _buildFilterPanel(AppLocalizations l10n, dynamic currentTheme) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: ResponsiveHelper.isSmallScreen(context) ? 2 : 3,
      ),
      constraints: BoxConstraints(
        maxHeight: ResponsiveHelper.getFilterPanelMaxHeight(context),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveHelper.getFilterPanelInternalSpacing(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 筛选标题和清除按钮
              Row(
                children: [
                  Text(
                    l10n.filterConditions,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: currentTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveHelper.isSmallScreen(context) ? 14 : 16,
                    ),
                  ),
                  const Spacer(),
                  if (_currentFilter.hasFilters)
                    TextButton(
                      onPressed: _clearAllFilters,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: const Size(0, 24),
                      ),
                      child: Text(
                        l10n.clearAll,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: ResponsiveHelper.getFilterPanelInternalSpacing(context)),
              
              // 课程类型筛选
              Text(
                l10n.courseType,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: ResponsiveHelper.isSmallScreen(context) ? 12 : 14,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: CourseTypes.all.map((type) {
                  final isSelected = _currentFilter.courseTypes.contains(type);
                  return _buildFilterChip(
                    label: type,
                    isSelected: isSelected,
                    onTap: () {
                      final newTypes = List<String>.from(_currentFilter.courseTypes);
                      if (isSelected) {
                        newTypes.remove(type);
                      } else {
                        newTypes.add(type);
                      }
                      _applyFilter(_currentFilter.copyWith(courseTypes: newTypes));
                    },
                    currentTheme: currentTheme,
                  );
                }).toList(),
              ),
              
              SizedBox(height: ResponsiveHelper.getFilterPanelInternalSpacing(context)),
              
              // 时间段筛选
              Text(
                l10n.timeSlot,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: ResponsiveHelper.isSmallScreen(context) ? 12 : 14,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: TimeRange.predefinedRanges.map((timeRange) {
                  final isSelected = _currentFilter.timeRanges.contains(timeRange);
                  return _buildFilterChip(
                    label: timeRange.displayName,
                    isSelected: isSelected,
                    onTap: () {
                      final newTimeRanges = List<TimeRange>.from(_currentFilter.timeRanges);
                      if (isSelected) {
                        newTimeRanges.remove(timeRange);
                      } else {
                        newTimeRanges.add(timeRange);
                      }
                      _applyFilter(_currentFilter.copyWith(timeRanges: newTimeRanges));
                    },
                    currentTheme: currentTheme,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 筛选chip
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic currentTheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.isSmallScreen(context) ? 8 : 10,
          vertical: ResponsiveHelper.isSmallScreen(context) ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? currentTheme.primaryColor.withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
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
            fontSize: ResponsiveHelper.isSmallScreen(context) ? 11 : 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 快速筛选chip - 仿照探索界面
  Widget _buildQuickFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic currentTheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.isSmallScreen(context) ? 8 : 10,
          vertical: ResponsiveHelper.isSmallScreen(context) ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? currentTheme.primaryColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            fontSize: ResponsiveHelper.isSmallScreen(context) ? 10 : 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 课程Tab栏 - 保持原有设计
  Widget _buildLessonsTabBar(AppLocalizations l10n, dynamic currentTheme) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: ResponsiveHelper.isSmallScreen(context) ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(ResponsiveHelper.isSmallScreen(context) ? 2 : 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              currentTheme.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                currentTheme.primaryColor,
                currentTheme.secondaryColor,
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: currentTheme.primaryColor.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: currentTheme.primaryColor.withOpacity(0.6),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.isSmallScreen(context) ? 13 : 14,
          ),
          unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveHelper.isSmallScreen(context) ? 13 : 14,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: [
            _buildTab(_isSearchMode && (_searchQuery.isNotEmpty || _currentFilter.hasFilters)
                ? '${l10n.enrolledLessons} (${_enrolledSearchResults.length})'
                : l10n.enrolledLessons, 
              Icons.schedule, 0),
            _buildTab(_isSearchMode && (_searchQuery.isNotEmpty || _currentFilter.hasFilters)
                ? '${l10n.completedLessons} (${_completedSearchResults.length})'
                : l10n.completedLessons, 
              Icons.check_circle, 1),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsList(int tabIndex, AppLocalizations l10n) {
    // 如果在搜索模式但没有搜索条件和筛选条件，显示空状态提示
    if (_isSearchMode && _searchQuery.isEmpty && !_currentFilter.hasFilters) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 60),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.searchHint,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.searchTip,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final lessons = _getCurrentLessons();
    
    // 如果没有课程，显示空状态
    if (lessons.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 60),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tabIndex == 0 ? Icons.schedule : Icons.check_circle,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                tabIndex == 0 ? l10n.noOngoingCourses : l10n.noCompletedCoursesYet,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: tabIndex == 0 ? _enrolledScrollController : _completedScrollController,
      padding: ResponsiveHelper.getResponsivePadding(context).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 60, // 添加底部内边距，确保内容不被遮挡
      ),
      itemCount: _getPaginatedLessons().length,
      itemBuilder: (context, index) {
        final paginatedLessons = _getPaginatedLessons();
        if (index >= paginatedLessons.length) return null;
        return _buildLessonCard(paginatedLessons[index], l10n);
      },
    );
  }

  Widget _buildLessonCard(Lesson lesson, AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LessonDetailScreen(lesson: lesson),
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 课程图片占位符
              Container(
                width: double.infinity,
                height: ResponsiveHelper.isSmallScreen(context) ? 100 : 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade300,
                      Colors.purple.shade300,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  image: lesson.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(lesson.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: lesson.imageUrl == null
                    ? Center(
                        child: Icon(
                          Icons.school,
                          size: ResponsiveHelper.isSmallScreen(context) ? 28 : 36,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              
              // 课程信息 - 横向布局
              Padding(
                padding: EdgeInsets.all(ResponsiveHelper.isSmallScreen(context) ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 左侧：日期和时间
                        Container(
                          width: ResponsiveHelper.isSmallScreen(context) ? 75 : 85,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 日期
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveHelper.isSmallScreen(context) ? 4 : 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: lesson.isPastLesson 
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  lesson.dateString,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: lesson.isPastLesson ? Colors.green : Colors.orange,
                                    fontSize: ResponsiveHelper.isSmallScreen(context) ? 10 : 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // 时间
                              Text(
                                lesson.startTimeString,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: ResponsiveHelper.isSmallScreen(context) ? 11 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // 右侧：课程信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 课程名称（主标题）
                              Text(
                                lesson.courseName,
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: ResponsiveHelper.isSmallScreen(context) ? 16 : 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // 课节标题（内容）
                              Text(
                                lesson.title,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                  fontSize: ResponsiveHelper.isSmallScreen(context) ? 13 : 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
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
    );
  }

  Widget _buildTab(String text, IconData icon, int index) {
    final isSelected = _tabController.index == index;
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: ResponsiveHelper.isSmallScreen(context) ? 14 : 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: ResponsiveHelper.isSmallScreen(context) ? 12 : 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 