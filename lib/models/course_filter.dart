class CourseFilter {
  final AgeRange? ageRange;
  final List<String> courseTypes;
  final TimeRange? timeRange;
  final List<String> difficulties;
  final double? minPrice;
  final double? maxPrice;
  final bool onlineOnly;

  CourseFilter({
    this.ageRange,
    this.courseTypes = const [],
    this.timeRange,
    this.difficulties = const [],
    this.minPrice,
    this.maxPrice,
    this.onlineOnly = false,
  });

  // 检查是否有任何过滤条件被设置
  bool get hasFilters {
    return ageRange != null ||
           courseTypes.isNotEmpty ||
           timeRange != null ||
           difficulties.isNotEmpty ||
           minPrice != null ||
           maxPrice != null ||
           onlineOnly;
  }

  // 获取活跃过滤器数量
  int get activeFiltersCount {
    int count = 0;
    if (ageRange != null) count++;
    if (courseTypes.isNotEmpty) count++;
    if (timeRange != null) count++;
    if (difficulties.isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (onlineOnly) count++;
    return count;
  }

  CourseFilter copyWith({
    AgeRange? ageRange,
    List<String>? courseTypes,
    TimeRange? timeRange,
    List<String>? difficulties,
    double? minPrice,
    double? maxPrice,
    bool? onlineOnly,
  }) {
    return CourseFilter(
      ageRange: ageRange ?? this.ageRange,
      courseTypes: courseTypes ?? this.courseTypes,
      timeRange: timeRange ?? this.timeRange,
      difficulties: difficulties ?? this.difficulties,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      onlineOnly: onlineOnly ?? this.onlineOnly,
    );
  }

  // 清空所有过滤条件
  CourseFilter clear() {
    return CourseFilter();
  }
}

class AgeRange {
  final int minAge;
  final int maxAge;
  final String displayName;

  const AgeRange({
    required this.minAge,
    required this.maxAge,
    required this.displayName,
  });

  static const List<AgeRange> predefinedRanges = [
    AgeRange(minAge: 0, maxAge: 3, displayName: '0-3岁'),
    AgeRange(minAge: 4, maxAge: 6, displayName: '4-6岁'),
    AgeRange(minAge: 7, maxAge: 9, displayName: '7-9岁'),
    AgeRange(minAge: 10, maxAge: 12, displayName: '10-12岁'),
    AgeRange(minAge: 13, maxAge: 18, displayName: '13-18岁'),
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgeRange &&
           other.minAge == minAge &&
           other.maxAge == maxAge;
  }

  @override
  int get hashCode => minAge.hashCode ^ maxAge.hashCode;
}

class TimeRange {
  final String startTime;
  final String endTime;
  final String displayName;

  const TimeRange({
    required this.startTime,
    required this.endTime,
    required this.displayName,
  });

  static const List<TimeRange> predefinedRanges = [
    TimeRange(startTime: '09:00', endTime: '12:00', displayName: '上午时段'),
    TimeRange(startTime: '12:00', endTime: '18:00', displayName: '下午时段'),
    TimeRange(startTime: '18:00', endTime: '21:00', displayName: '晚上时段'),
    TimeRange(startTime: '00:00', endTime: '23:59', displayName: '全天'),
  ];

  // 获取国际化显示名称
  String getLocalizedDisplayName(String locale) {
    if (locale == 'en') {
      switch (displayName) {
        case '上午时段':
          return 'Morning';
        case '下午时段':
          return 'Afternoon';
        case '晚上时段':
          return 'Evening';
        case '全天':
          return 'All Day';
        default:
          return displayName;
      }
    }
    return displayName; // 默认返回中文
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeRange &&
           other.startTime == startTime &&
           other.endTime == endTime;
  }

  @override
  int get hashCode => startTime.hashCode ^ endTime.hashCode;
}

// 预定义的课程类型
class CourseTypes {
  static const List<String> all = [
    '艺术创作',
    '科学探索', 
    '运动健身',
    '音乐舞蹈',
    '语言学习',
    '编程思维',
    '手工制作',
    '自然探索',
    '社交技能',
    '思维训练',
  ];
}

// 预定义的难度等级
class Difficulties {
  static const List<String> all = [
    '入门级',
    '初级',
    '中级',
    '高级',
  ];
} 