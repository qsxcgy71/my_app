import 'dart:math';
import '../models/course_model.dart';

class CourseService {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  // 模拟课程数据
  List<Course> _courses = [];
  bool _isInitialized = false;

  Future<void> _initializeCourses() async {
    if (_isInitialized) return;

    _courses = [
      Course(
        id: 'course_1',
        title: '儿童编程启蒙',
        description: '通过有趣的游戏和动画，让孩子们学习编程的基本概念，培养逻辑思维能力。',
        category: '编程',
        imageUrls: [
          'https://images.unsplash.com/photo-1515879218367-8466d910aaa4?w=400',
          'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=400',
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
        ],
        totalLessons: 12,
        totalDuration: const Duration(hours: 8),
        instructor: '张老师',
        rating: 4.8,
        enrolledCount: 1250,
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lessons: [
          CourseLesson(
            id: 'lesson_1_1',
            title: '什么是编程？',
            description: '了解编程的基本概念',
            duration: const Duration(minutes: 25),
            order: 1,
            isPreview: true,
          ),
          CourseLesson(
            id: 'lesson_1_2',
            title: '我的第一个程序',
            description: '创建简单的动画程序',
            duration: const Duration(minutes: 30),
            order: 2,
            isPreview: false,
          ),
        ],
      ),
      Course(
        id: 'course_2',
        title: '数学思维训练',
        description: '通过趣味数学游戏，提升孩子的数学思维和解决问题的能力。',
        category: '数学',
        imageUrls: [
          'https://images.unsplash.com/photo-1596495578065-6e0763fa1178?w=400',
          'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400',
          'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=400',
        ],
        totalLessons: 15,
        totalDuration: const Duration(hours: 10),
        instructor: '李老师',
        rating: 4.7,
        enrolledCount: 980,
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        lessons: [
          CourseLesson(
            id: 'lesson_2_1',
            title: '数字的奥秘',
            description: '探索数字的有趣规律',
            duration: const Duration(minutes: 20),
            order: 1,
            isPreview: true,
          ),
        ],
      ),
      Course(
        id: 'course_3',
        title: '创意美术课堂',
        description: '激发孩子的艺术天赋，学习绘画技巧和色彩搭配。',
        category: '美术',
        imageUrls: [
          'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=400',
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
          'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=400',
        ],
        totalLessons: 10,
        totalDuration: const Duration(hours: 6),
        instructor: '王老师',
        rating: 4.9,
        enrolledCount: 750,
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        lessons: [
          CourseLesson(
            id: 'lesson_3_1',
            title: '色彩的世界',
            description: '认识基本颜色和搭配',
            duration: const Duration(minutes: 35),
            order: 1,
            isPreview: true,
          ),
        ],
      ),
      Course(
        id: 'course_4',
        title: '英语口语训练',
        description: '通过互动游戏和情景对话，提升孩子的英语口语表达能力。',
        category: '英语',
        imageUrls: [
          'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=400',
          'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=400',
          'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400',
        ],
        totalLessons: 20,
        totalDuration: const Duration(hours: 12),
        instructor: 'Sarah老师',
        rating: 4.6,
        enrolledCount: 1500,
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        lessons: [
          CourseLesson(
            id: 'lesson_4_1',
            title: 'Hello World!',
            description: '基础英语问候语',
            duration: const Duration(minutes: 15),
            order: 1,
            isPreview: true,
          ),
        ],
      ),
      Course(
        id: 'course_5',
        title: '科学实验室',
        description: '通过有趣的科学实验，培养孩子的观察力和探索精神。',
        category: '科学',
        imageUrls: [
          'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=400',
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
          'https://images.unsplash.com/photo-1582719471384-894fbb16e074?w=400',
        ],
        totalLessons: 8,
        totalDuration: const Duration(hours: 5),
        instructor: '陈老师',
        rating: 4.5,
        enrolledCount: 650,
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        lessons: [
          CourseLesson(
            id: 'lesson_5_1',
            title: '神奇的化学反应',
            description: '观察有趣的化学现象',
            duration: const Duration(minutes: 40),
            order: 1,
            isPreview: true,
          ),
        ],
      ),
    ];

    _isInitialized = true;
  }

  // 获取所有课程
  Future<List<Course>> getAllCourses() async {
    await _initializeCourses();
    return List.from(_courses);
  }

  // 获取热门课程
  Future<List<Course>> getFeaturedCourses() async {
    await _initializeCourses();
    return _courses.where((course) => course.isFeatured).toList();
  }

  // 搜索课程
  Future<List<Course>> searchCourses(String query) async {
    await _initializeCourses();
    if (query.isEmpty) return [];

    return _courses.where((course) {
      return course.title.toLowerCase().contains(query.toLowerCase()) ||
             course.description.toLowerCase().contains(query.toLowerCase()) ||
             course.category.toLowerCase().contains(query.toLowerCase()) ||
             course.instructor.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // 根据分类获取课程
  Future<List<Course>> getCoursesByCategory(String category) async {
    await _initializeCourses();
    return _courses.where((course) => course.category == category).toList();
  }

  // 获取课程详情
  Future<Course?> getCourseById(String courseId) async {
    await _initializeCourses();
    try {
      return _courses.firstWhere((course) => course.id == courseId);
    } catch (e) {
      return null;
    }
  }

  // 获取所有分类
  Future<List<String>> getAllCategories() async {
    await _initializeCourses();
    return _courses.map((course) => course.category).toSet().toList();
  }

  // 模拟分页加载
  Future<List<Course>> getCoursesPage(int page, int pageSize) async {
    await _initializeCourses();
    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, _courses.length);
    
    if (startIndex >= _courses.length) return [];
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    return _courses.sublist(startIndex, endIndex);
  }
} 