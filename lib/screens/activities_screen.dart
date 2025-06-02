import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../models/activity_model.dart';
import '../styles/app_text_styles.dart';
import '../services/activity_service.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> with TickerProviderStateMixin {
  final _activityService = ActivityService();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Activity>> _activities = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Search functionality
  bool _isSearching = false;
  String _searchQuery = '';
  List<Activity> _searchResults = [];
  
  // Pagination and scroll preservation
  List<Activity> _selectedDayActivities = [];
  int _currentPage = 0;
  final int _pageSize = 5;
  bool _hasMoreData = false;
  double _savedScrollPosition = 0.0;
  bool _shouldPreserveScroll = false;
  
  // Animation controllers
  late AnimationController _calendarAnimationController;
  late Animation<double> _calendarAnimation;
  bool _isCalendarExpanded = true;

  @override
  void initState() {
    super.initState();
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
    _calendarAnimationController.forward();
    _loadActivities();
    
    // Search listener
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        if (_searchQuery.isNotEmpty) {
          _performSearch();
        } else {
          _searchResults = [];
        }
      });
    });
  }

  @override
  void dispose() {
    _calendarAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchQuery.toLowerCase();
    _searchResults = [];
    
    _activities.forEach((date, activities) {
      for (final activity in activities) {
        if (activity.title.toLowerCase().contains(query) ||
            (activity.description?.toLowerCase().contains(query) ?? false)) {
          _searchResults.add(activity);
        }
      }
    });
    
    // Sort search results by date
    _searchResults.sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime));
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _cancelSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
      _searchResults = [];
    });
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

  void _toggleCalendar() {
    setState(() {
      _isCalendarExpanded = !_isCalendarExpanded;
    });
    if (_isCalendarExpanded) {
      _calendarAnimationController.forward();
    } else {
      _calendarAnimationController.reverse();
    }
  }

  Future<void> _loadActivities() async {
    try {
      final activities = await _activityService.getMonthActivities(_focusedDay);

      if (mounted) {
        setState(() {
          _activities = activities;
          _updateSelectedDayActivities();
          if (_searchQuery.isNotEmpty) {
            _performSearch();
          }
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _updateSelectedDayActivities() {
    final previousPageSize = (_currentPage + 1) * _pageSize;
    
    if (_selectedDay == null) {
      _selectedDayActivities = [];
    } else {
      final dateKey = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
      );
      _selectedDayActivities = _activities[dateKey] ?? [];
    }
    
    // Reset pagination but try to maintain previously loaded items
    if (_selectedDayActivities.length > _pageSize) {
      // If we had more items loaded before, keep them loaded
      final itemsToShow = previousPageSize > _pageSize ? previousPageSize : _pageSize;
      _currentPage = ((itemsToShow - 1) / _pageSize).floor();
      
      // Ensure we don't go beyond available items
      final maxPage = ((_selectedDayActivities.length - 1) / _pageSize).floor();
      if (_currentPage > maxPage) {
        _currentPage = maxPage;
      }
      
      _hasMoreData = ((_currentPage + 1) * _pageSize) < _selectedDayActivities.length;
    } else {
      _currentPage = 0;
      _hasMoreData = _selectedDayActivities.length > _pageSize;
    }
  }

  List<Activity> _getPaginatedActivities() {
    if (_isSearching && _searchQuery.isNotEmpty) {
      return _searchResults;
    }
    
    final endIndex = (_currentPage + 1) * _pageSize;
    return _selectedDayActivities.take(endIndex).toList();
  }

  void _onRefresh() async {
    try {
      await _loadActivities();
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  void _onLoading() async {
    if (_isSearching) {
      _refreshController.loadNoData();
      return;
    }
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final startIndex = (_currentPage + 1) * _pageSize;
      if (startIndex >= _selectedDayActivities.length) {
        _refreshController.loadNoData();
        setState(() {
          _hasMoreData = false;
        });
        return;
      }

      setState(() {
        _currentPage++;
        if ((_currentPage + 1) * _pageSize >= _selectedDayActivities.length) {
          _hasMoreData = false;
        }
      });

      _refreshController.loadComplete();
    } catch (e) {
      _refreshController.loadFailed();
    }
  }

  Future<void> _showAddActivityDialog([DateTime? date, Activity? editActivity]) async {
    date ??= _selectedDay ?? DateTime.now();
    
    final titleController = TextEditingController(text: editActivity?.title ?? '');
    final descriptionController = TextEditingController(text: editActivity?.description ?? '');
    DateTime selectedDate = editActivity?.date ?? date;
    TimeOfDay? startTime = editActivity?.time;
    TimeOfDay? endTime = editActivity?.endTime;
    bool isAllDay = startTime == null && endTime == null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: AppTextStyles.bodyMedium.copyWith(color: Colors.red)),
                    ),
                    Text(
                      editActivity == null ? 'New Event' : 'Edit Event',
                      style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                    TextButton(
                      onPressed: () => _saveActivity(
                        context, 
                        titleController, 
                        descriptionController, 
                        selectedDate, 
                        isAllDay ? null : startTime,
                        isAllDay ? null : endTime,
                        editActivity,
                      ),
                      child: Text('Save', style: AppTextStyles.bodyMedium.copyWith(color: Colors.blue, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          labelStyle: AppTextStyles.bodyMedium,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        style: AppTextStyles.bodyLarge,
                        textCapitalization: TextCapitalization.words,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // All Day Toggle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('All Day', style: AppTextStyles.bodyLarge),
                            Switch.adaptive(
                              value: isAllDay,
                              onChanged: (value) {
                                setModalState(() {
                                  isAllDay = value;
                                  if (!value) {
                                    if (startTime == null) {
                                      startTime = TimeOfDay.now();
                                    }
                                    if (endTime == null) {
                                      endTime = TimeOfDay(
                                        hour: (startTime!.hour + 1) % 24,
                                        minute: startTime!.minute,
                                      );
                                    }
                                  }
                                });
                              },
                              activeColor: Colors.blue,
          ),
        ],
      ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Date Selection
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                                Text('Date', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600])),
                                const SizedBox(height: 4),
              Text(
                                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                  style: AppTextStyles.bodyLarge,
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  setModalState(() {
                                    selectedDate = date;
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                      
                      // Time Selection (only if not all day)
                      if (!isAllDay) ...[
                        const SizedBox(height: 16),
                        // Start Time
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Start Time', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600])),
                                  const SizedBox(height: 4),
            Text(
                                    startTime?.format(context) ?? 'Select start time',
                                    style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
                              IconButton(
            onPressed: () async {
                                  final time = await showTimePicker(
                context: context,
                                    initialTime: startTime ?? TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setModalState(() {
                                      startTime = time;
                                      // Auto-set end time to 1 hour later if not set
                                      if (endTime == null || (endTime!.hour * 60 + endTime!.minute) <= (time.hour * 60 + time.minute)) {
                                        endTime = TimeOfDay(
                                          hour: (time.hour + 1) % 24,
                                          minute: time.minute,
                                        );
                                      }
                                    });
                                  }
                                },
                                icon: const Icon(Icons.access_time, color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        // End Time
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('End Time', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600])),
                                  const SizedBox(height: 4),
                                  Text(
                                    endTime?.format(context) ?? 'Select end time',
                                    style: AppTextStyles.bodyLarge,
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: endTime ?? TimeOfDay(
                                      hour: (startTime?.hour ?? TimeOfDay.now().hour + 1) % 24,
                                      minute: startTime?.minute ?? TimeOfDay.now().minute,
                                    ),
                                  );
                                  if (time != null) {
                                    setModalState(() {
                                      endTime = time;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.access_time, color: Colors.blue),
          ),
        ],
      ),
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                      
                      // Description
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: AppTextStyles.bodyMedium,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          alignLabelWithHint: true,
              ),
                  style: AppTextStyles.bodyMedium,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      
                      const SizedBox(height: 100), // Extra space for keyboard
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

  Future<void> _saveActivity(
    BuildContext context,
    TextEditingController titleController,
    TextEditingController descriptionController,
    DateTime selectedDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    Activity? editActivity,
  ) async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for the activity')),
      );
      return;
    }

    // Validate time logic
    if (startTime != null && endTime != null) {
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      if (startMinutes >= endMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        return;
      }
    }

    try {
      Activity? newActivityWithId;

      if (editActivity == null) {
        // Add new activity
        newActivityWithId = await _activityService.addActivity(
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          date: selectedDate,
          startTime: startTime,
          endTime: endTime,
        );
        
        // Update local state immediately
        final dateKey = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        
        setState(() {
          if (_activities[dateKey] == null) {
            _activities[dateKey] = [];
          }
          _activities[dateKey]!.add(newActivityWithId!);
          _activities[dateKey]!.sort((a, b) {
            if (a.time == null && b.time != null) return -1;
            if (a.time != null && b.time == null) return 1;
            if (a.time == null && b.time == null) {
              return a.createdAt.compareTo(b.createdAt);
            }
            return a.fullDateTime.compareTo(b.fullDateTime);
          });
          _updateSelectedDayActivities();
          if (_searchQuery.isNotEmpty) {
            _performSearch();
          }
        });
      } else {
        // Update existing activity - preserve scroll position
        _saveScrollPosition();
        _shouldPreserveScroll = true;

        await _activityService.updateActivity(
          activityId: editActivity.id,
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          date: selectedDate,
          startTime: startTime,
          endTime: endTime,
          createdAt: editActivity.createdAt,
        );
        
        // Update local state immediately
        setState(() {
          // Remove from old date
          final oldDateKey = DateTime(editActivity.date.year, editActivity.date.month, editActivity.date.day);
          _activities[oldDateKey]?.removeWhere((a) => a.id == editActivity.id);
          if (_activities[oldDateKey]?.isEmpty == true) {
            _activities.remove(oldDateKey);
          }
          
          // Add to new date
          final newDateKey = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
          if (_activities[newDateKey] == null) {
            _activities[newDateKey] = [];
          }
          final updatedActivity = Activity(
            id: editActivity.id,
            title: titleController.text.trim(),
            description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
            date: selectedDate,
            time: startTime,
            endTime: endTime,
            createdAt: editActivity.createdAt,
          );
          _activities[newDateKey]!.add(updatedActivity);
          _activities[newDateKey]!.sort((a, b) {
            if (a.time == null && b.time != null) return -1;
            if (a.time != null && b.time == null) return 1;
            if (a.time == null && b.time == null) {
              return a.createdAt.compareTo(b.createdAt);
            }
            return a.fullDateTime.compareTo(b.fullDateTime);
          });
          _updateSelectedDayActivities();
          if (_searchQuery.isNotEmpty) {
            _performSearch();
          }
        });
      }

                if (mounted) {
        Navigator.pop(context);
        
        if (editActivity == null && newActivityWithId != null) {
          // For new activities, scroll to the newly added item
          await _scrollToNewActivity(newActivityWithId);
        } else {
          // For edits, restore the previous scroll position
          _restoreScrollPosition();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(editActivity == null ? 'Activity added successfully' : 'Activity updated successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving activity: $e')),
        );
      }
    }
  }

  Future<void> _scrollToNewActivity(Activity newActivity) async {
    // Wait for the UI to update
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted || !_scrollController.hasClients) return;

    // First, ensure the new activity is visible by expanding pagination if needed
    final allActivities = _selectedDayActivities;
    final newActivityIndex = allActivities.indexWhere((a) => a.id == newActivity.id);
    
    if (newActivityIndex != -1) {
      // Ensure we have enough pages loaded to show the new activity
      final requiredPages = (newActivityIndex / _pageSize).floor();
      if (requiredPages > _currentPage) {
        setState(() {
          _currentPage = requiredPages;
          _hasMoreData = ((_currentPage + 1) * _pageSize) < _selectedDayActivities.length;
        });
        
        // Wait for the state to update
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      // Now find the index in the paginated list
      final paginatedActivities = _getPaginatedActivities();
      final paginatedIndex = paginatedActivities.indexWhere((a) => a.id == newActivity.id);
      
      if (paginatedIndex != -1) {
        // Calculate scroll position
        // Account for: AppBar, Calendar, Headers, and list items
        const appBarHeight = 56.0;
        const calendarHeight = 400.0; // Approximate expanded calendar height
        const headerHeight = 100.0; // Events header
        const itemHeight = 100.0; // Each list item
        
        final totalHeaderHeight = appBarHeight + calendarHeight + headerHeight;
        final targetScrollPosition = totalHeaderHeight + (paginatedIndex * itemHeight);
        
        // Get viewport dimensions
        final viewportHeight = _scrollController.position.viewportDimension;
        final maxScroll = _scrollController.position.maxScrollExtent;
        
        // Center the item in the viewport, but don't go beyond bounds
        final centeredPosition = targetScrollPosition - (viewportHeight / 3); // Show item in upper third
        final finalScrollPosition = centeredPosition.clamp(0.0, maxScroll);
        
        // Smooth scroll to the new item
        await _scrollController.animateTo(
          finalScrollPosition,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _highlightNewActivity(String activityId) {
    // This could be enhanced with actual visual highlighting
    // For now, we'll just ensure the scroll position is correct
    // You could add a highlighting animation here if desired
  }

  Future<void> _deleteActivity(Activity activity) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delete Event', style: AppTextStyles.titleLarge),
          content: Text(
            'Are you sure you want to delete "${activity.title}"? This action cannot be undone.',
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
              child: Text('Delete', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
    
    if (confirm != true) return;
    
    // Always preserve scroll position for delete operations
    _saveScrollPosition();
    _shouldPreserveScroll = true;
    
    try {
      await _activityService.deleteActivity(activity.id);
      
      // Update local state immediately
      setState(() {
        final dateKey = DateTime(activity.date.year, activity.date.month, activity.date.day);
        _activities[dateKey]?.removeWhere((a) => a.id == activity.id);
        if (_activities[dateKey]?.isEmpty == true) {
          _activities.remove(dateKey);
        }
        _updateSelectedDayActivities();
        if (_searchQuery.isNotEmpty) {
          _performSearch();
        }
      });
      
      if (mounted) {
        // Always restore scroll position after delete
        _restoreScrollPosition();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isSelectedDayToday = _selectedDay != null && 
        DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day) == today;

    return Scaffold(
      appBar: _isSearching 
        ? AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: _cancelSearch,
            ),
            title: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search events...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
              style: AppTextStyles.bodyLarge,
            ),
            actions: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              TextButton(
                onPressed: _cancelSearch,
                child: Text(
                  'Cancel',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
                ),
              ),
            ],
          )
        : AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Calendar',
              style: AppTextStyles.titleLarge.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.black),
                onPressed: _startSearch,
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.black),
                onPressed: () => _showAddActivityDialog(_selectedDay),
              ),
            ],
          ),
      body: SmartRefresher(
        enablePullDown: true,
        enablePullUp: _isSearching ? false : _hasMoreData,
        header: WaterDropHeader(
          complete: Text(
            'Calendar Updated!',
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
              body = Text("↑ Pull up to load more events", style: AppTextStyles.bodyMedium);
            } else if (mode == LoadStatus.idle) {
              body = Text("↑ Pull up to load more events", style: AppTextStyles.bodyMedium);
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
                  Text("Loading more events...", style: AppTextStyles.bodyMedium),
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
                  Text("All events loaded", style: AppTextStyles.bodyMedium.copyWith(color: Colors.green)),
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
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Calendar (hidden during search)
            if (!_isSearching) ...[
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _calendarAnimation,
                  builder: (context, child) => Container(
                    margin: const EdgeInsets.all(16),
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
                      children: [
                        // Calendar toggle header
                        GestureDetector(
                          onTap: _toggleCalendar,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: _isCalendarExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 300),
                                  child: const Icon(Icons.expand_more, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Calendar body
                        SizeTransition(
                          sizeFactor: _calendarAnimation,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TableCalendar<Activity>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
                              eventLoader: _getEventsForDay,
                              startingDayOfWeek: StartingDayOfWeek.sunday,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
                                if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
                                    // Reset pagination when switching days
                                    _currentPage = 0;
                                    _updateSelectedDayActivities();
            });
                                }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
            _loadActivities();
          },
          calendarStyle: CalendarStyle(
                                outsideDaysVisible: false,
                                weekendTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.red[400]),
                                holidayTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.red[400]),
                                defaultTextStyle: AppTextStyles.bodyMedium,
                                selectedTextStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.w600,
                                ),
                                todayTextStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: isSelectedDayToday ? Colors.white : Colors.blue, 
                                  fontWeight: FontWeight.w600,
                                ),
                                selectedDecoration: BoxDecoration(
                                  color: isSelectedDayToday ? Colors.green : Colors.blue,
              shape: BoxShape.circle,
                                  border: isSelectedDayToday ? Border.all(color: Colors.green.shade700, width: 2) : null,
                                ),
                                todayDecoration: BoxDecoration(
                                  color: isSelectedDayToday ? Colors.green : Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelectedDayToday ? Colors.green.shade700 : Colors.blue, 
                                    width: isSelectedDayToday ? 2 : 1,
                                  ),
                                ),
                                markerDecoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                markersMaxCount: 3,
                                markersAlignment: Alignment.bottomCenter,
                                markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
                                markerSize: 6,
                              ),
                              headerStyle: const HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                leftChevronVisible: false,
                                rightChevronVisible: false,
                                headerPadding: EdgeInsets.zero,
                                headerMargin: EdgeInsets.zero,
                              ),
                              daysOfWeekStyle: DaysOfWeekStyle(
                                weekdayStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500),
                                weekendStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.red[400], fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
            
            // Search Results or Selected Day Events Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                  children: [
                    Text(
                          _isSearching && _searchQuery.isNotEmpty
                              ? 'Search Results'
                              : _selectedDay != null 
                                  ? 'Events for ${_getSelectedDayString()}'
                                  : 'Events',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!_isSearching && isSelectedDayToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                        child: Text(
                              'TODAY',
                          style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if ((_isSearching && _searchResults.isNotEmpty) || (!_isSearching && _selectedDayActivities.isNotEmpty))
                      Text(
                        _isSearching 
                            ? '${_searchResults.length} found'
                            : '${_getPaginatedActivities().length} of ${_selectedDayActivities.length}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            
            // Events List
            if ((_isSearching && _searchResults.isEmpty && _searchQuery.isNotEmpty) ||
                (!_isSearching && _selectedDayActivities.isEmpty))
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(32),
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
                    children: [
                      Icon(
                        _isSearching ? Icons.search_off : Icons.event_note, 
                        size: 48, 
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isSearching 
                            ? 'No events found'
                            : 'No events on this day',
                        style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSearching 
                            ? 'Try a different search term'
                            : 'Tap + to add your first event',
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[500]),
                      ),
                    ],
                          ),
                        ),
                      )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final paginatedActivities = _getPaginatedActivities();
                    
                    if (index >= paginatedActivities.length) {
                      return const SizedBox.shrink();
                    }
                    
                    final activity = paginatedActivities[index];
                    
                    return Container(
                      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: activity.time == null ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            activity.time == null ? Icons.event : Icons.schedule,
                            color: activity.time == null ? Colors.blue : Colors.orange,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          activity.title,
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                            const SizedBox(height: 4),
                            Text(
                              activity.timeString,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: activity.time == null ? Colors.blue : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_isSearching) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${activity.date.month}/${activity.date.day}/${activity.date.year}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                                      if (activity.description?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                                        Text(
                                          activity.description!,
                                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddActivityDialog(activity.date, activity);
                            } else if (value == 'delete') {
                              _deleteActivity(activity);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, size: 20, color: Colors.blue),
                                  const SizedBox(width: 12),
                                  Text('Edit', style: AppTextStyles.bodyMedium),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete, size: 20, color: Colors.red),
                                  const SizedBox(width: 12),
                                  Text('Delete', style: AppTextStyles.bodyMedium.copyWith(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showAddActivityDialog(activity.date, activity),
                            ),
                          );
                        },
                  childCount: _getPaginatedActivities().length,
                ),
              ),
            
            // Show pagination hint
            if (!_isSearching && _selectedDayActivities.isNotEmpty && _hasMoreData)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Pull up to load more events',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            
            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  List<Activity> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _activities[dateKey] ?? [];
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _getSelectedDayString() {
    if (_selectedDay == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    
    if (selectedDate == today) {
      return 'Today';
    } else if (selectedDate == tomorrow) {
      return 'Tomorrow';
    } else {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final weekday = weekdays[_selectedDay!.weekday - 1];
      return '$weekday, ${_selectedDay!.month}/${_selectedDay!.day}';
    }
  }
} 