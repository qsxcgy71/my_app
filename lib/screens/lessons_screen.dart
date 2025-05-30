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

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> with TickerProviderStateMixin {
  final _lessonService = LessonService();
  final _refreshController = RefreshController(initialRefresh: false);
  final _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  // Tab controller
  late TabController _tabController;
  
  // Data
  List<Lesson> _enrolledLessons = [];
  List<Lesson> _completedLessons = [];
  List<Lesson> _searchResults = [];
  
  // Search
  bool _isSearchMode = false;
  String _searchQuery = '';

  // Calendar
  bool _isCalendarVisible = false;
  late AnimationController _calendarAnimationController;
  late Animation<double> _calendarAnimation;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 5;
  bool _hasMoreData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
    
    _calendarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _calendarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _calendarAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _loadLessons();
    
    _tabController.addListener(() {
      if (!_isSearchMode) {
        setState(() {
          _currentPage = 0;
          _hasMoreData = _getCurrentLessons().length > _pageSize;
        });
      }
    });

    _searchController.addListener(() {
      _performSearch(_searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        _searchQuery = '';
        _searchResults.clear();
        _currentPage = 0;
        _hasMoreData = _getCurrentLessons().length > _pageSize;
      }
    });
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _searchQuery = query.trim();
    });

    try {
      final results = await _lessonService.searchLessons(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      // Handle search error silently
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
          _hasMoreData = _getCurrentLessons().length > _pageSize;
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
    if (_isSearchMode && _searchQuery.isNotEmpty) {
      return _searchResults;
    }
    return _tabController.index == 0 ? _enrolledLessons : _completedLessons;
  }

  List<Lesson> _getPaginatedLessons() {
    if (_isSearchMode && _searchQuery.isNotEmpty) {
      return _searchResults; // 搜索结果不分页，显示所有结果
    }
    final lessons = _getCurrentLessons();
    final endIndex = (_currentPage + 1) * _pageSize;
    return lessons.take(endIndex).toList();
  }

  void _onRefresh() async {
    try {
      await _loadLessons();
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  void _onLoading() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final startIndex = (_currentPage + 1) * _pageSize;
      final currentLessons = _getCurrentLessons();
      
      if (startIndex >= currentLessons.length) {
        _refreshController.loadNoData();
        setState(() {
          _hasMoreData = false;
        });
        return;
      }

      setState(() {
        _currentPage++;
        if ((_currentPage + 1) * _pageSize >= currentLessons.length) {
          _hasMoreData = false;
        }
      });

      _refreshController.loadComplete();
    } catch (e) {
      _refreshController.loadFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    
    return Scaffold(
      backgroundColor: currentTheme.primaryColor.withOpacity(0.05),
      appBar: AppBar(
        backgroundColor: currentTheme.primaryColor.withOpacity(0.1),
        elevation: 0,
        title: Text(
          _isSearchMode ? '搜索课程' : '我的课程',
          style: AppTextStyles.titleLarge.copyWith(
            color: currentTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isSearchMode) ...[
            TextButton(
              onPressed: _toggleSearchMode,
              child: Text(
                '取消',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: currentTheme.primaryColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ] else ...[
            IconButton(
              icon: Icon(
                Icons.search,
                color: currentTheme.primaryColor,
              ),
              onPressed: _toggleSearchMode,
            ),
            const ThemeSelector(),
            IconButton(
              icon: Icon(
                Icons.add_circle,
                color: currentTheme.primaryColor,
              ),
              onPressed: _createSampleLessons,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search Bar (only visible in search mode)
          if (_isSearchMode) ...[
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: currentTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '搜索课程名称、类别或描述...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: Icon(Icons.search, color: currentTheme.primaryColor.withOpacity(0.6)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: currentTheme.primaryColor.withOpacity(0.6)),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: currentTheme.primaryColor.withOpacity(0.6)),
                ),
                style: AppTextStyles.bodyMedium.copyWith(color: currentTheme.primaryColor),
              ),
            ),
          ],

          // Tab Bar (hidden in search mode)
          if (!_isSearchMode) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: currentTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
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
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: currentTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: currentTheme.primaryColor.withOpacity(0.6),
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: [
                    _buildTab('已报读课程', Icons.schedule, 0),
                    _buildTab('已完成课程', Icons.check_circle, 1),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Lessons List
          Expanded(
            child: _isSearchMode
                ? _buildSearchResults()
                : SmartRefresher(
                    header: WaterDropHeader(
                      complete: Text(
                        'Updated!',
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
                          body = Text("↑ Pull up to load more", style: AppTextStyles.bodyMedium);
                        } else if (mode == LoadStatus.idle) {
                          body = Text("↑ Pull up to load more", style: AppTextStyles.bodyMedium);
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
                              Text("Loading...", style: AppTextStyles.bodyMedium),
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
                    controller: _refreshController,
                    onRefresh: _onRefresh,
                    onLoading: _onLoading,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLessonsList(_enrolledLessons),
                        _buildLessonsList(_completedLessons),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsList(List<Lesson> lessons) {
    if (lessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _tabController.index == 0 ? '暂无已报读课程' : '暂无已完成课程',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final paginatedLessons = _getPaginatedLessons();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: paginatedLessons.length,
      itemBuilder: (context, index) {
        final lesson = paginatedLessons[index];
        return _buildLessonCard(lesson);
      },
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
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
          margin: const EdgeInsets.only(bottom: 16),
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
                height: 120,
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
                          size: 36,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              
              // 课程信息 - 横向布局
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧：日期和时间
                    Container(
                      width: 80,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 日期
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
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
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // 时间
                          Text(
                            lesson.startTimeString,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
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
                              fontSize: 18,
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
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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

  Widget _buildTab(String text, IconData icon, int index) {
    final isSelected = _tabController.index == index;
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(text),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return Center(
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
              '请输入搜索关键词',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '可搜索课程名称、类别或描述',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '没有找到相关课程',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '尝试使用其他关键词搜索',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search results header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '搜索结果 (${_searchResults.length})',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Search results list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final lesson = _searchResults[index];
              return _buildSearchResultCard(lesson);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(Lesson lesson) {
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
          margin: const EdgeInsets.only(bottom: 16),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 状态标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: lesson.isPastLesson 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lesson.isPastLesson ? '已完成' : '已报读',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: lesson.isPastLesson ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // 课程名称（主标题）
                Text(
                  lesson.courseName,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 18,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 课节标题（内容）
                Text(
                  lesson.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // 日期和时间信息
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      lesson.timeString,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${lesson.date.year}年${lesson.date.month}月${lesson.date.day}日',
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
      ),
    );
  }
} 