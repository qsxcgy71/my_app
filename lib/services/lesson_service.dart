import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/lesson_model.dart';

class LessonService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // 获取已报读的课程（未来的课程）
  Future<List<Lesson>> getEnrolledLessons() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final now = DateTime.now();
      
      final snapshot = await _firestore
          .collection('lessons')
          .where('userId', isEqualTo: userId)
          .get();

      final lessons = <Lesson>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        try {
          final lesson = Lesson.fromMap({
            ...data,
            'id': doc.id,
          });

          // 只包含未来的课程（已报读但未上）
          if (lesson.endDateTime.isAfter(now)) {
            lessons.add(lesson);
          }
        } catch (e) {
          continue;
        }
      }

      // 按时间从近到远排序
      lessons.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

      return lessons;
    } catch (e) {
      return [];
    }
  }

  // 获取已完成的课程（过去的课程）
  Future<List<Lesson>> getCompletedLessons() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final now = DateTime.now();
      
      final snapshot = await _firestore
          .collection('lessons')
          .where('userId', isEqualTo: userId)
          .get();

      final lessons = <Lesson>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        try {
          final lesson = Lesson.fromMap({
            ...data,
            'id': doc.id,
          });

          // 只包含过去的课程（已完成）
          if (lesson.endDateTime.isBefore(now)) {
            lessons.add(lesson);
          }
        } catch (e) {
          continue;
        }
      }

      // 按时间从近到远排序（最近完成的在前）
      lessons.sort((a, b) => b.startDateTime.compareTo(a.startDateTime));

      return lessons;
    } catch (e) {
      return [];
    }
  }

  // 获取所有课程
  Future<List<Lesson>> getAllLessons() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('lessons')
          .where('userId', isEqualTo: userId)
          .get();

      final lessons = <Lesson>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        try {
          final lesson = Lesson.fromMap({
            ...data,
            'id': doc.id,
          });
          lessons.add(lesson);
        } catch (e) {
          continue;
        }
      }

      return lessons;
    } catch (e) {
      return [];
    }
  }

  // 添加新课程
  Future<Lesson> addLesson({
    required String title,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    String? description,
    required String courseName,
    String? courseCategory,
    String? imageUrl,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final lesson = Lesson(
      id: '',
      title: title.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      courseName: courseName.trim(),
      courseCategory: courseCategory?.trim().isEmpty == true ? null : courseCategory?.trim(),
      date: date,
      startTime: startTime,
      endTime: endTime,
      createdAt: DateTime.now(),
      imageUrl: imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
    );

    final lessonData = lesson.toMap();
    lessonData['userId'] = userId;
    
    final docRef = await _firestore.collection('lessons').add(lessonData);
    return lesson.copyWith(id: docRef.id);
  }

  // 更新课程
  Future<void> updateLesson({
    required String lessonId,
    required String title,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    String? description,
    required String courseName,
    String? courseCategory,
    String? imageUrl,
    required DateTime createdAt,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final lesson = Lesson(
      id: lessonId,
      title: title.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      courseName: courseName.trim(),
      courseCategory: courseCategory?.trim().isEmpty == true ? null : courseCategory?.trim(),
      date: date,
      startTime: startTime,
      endTime: endTime,
      createdAt: createdAt,
      imageUrl: imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
    );

    final lessonData = lesson.toMap();
    lessonData['userId'] = userId;
    
    await _firestore.collection('lessons').doc(lessonId).update(lessonData);
  }

  // 删除课程
  Future<void> deleteLesson(String lessonId) async {
    await _firestore.collection('lessons').doc(lessonId).delete();
  }

  // 标记课程为已完成
  Future<void> markLessonCompleted(String lessonId) async {
    await _firestore.collection('lessons').doc(lessonId).update({
      'isCompleted': true,
    });
  }

  // 搜索课程
  Future<List<Lesson>> searchLessons(String query) async {
    final allLessons = await getAllLessons();
    final searchQuery = query.toLowerCase();
    
    return allLessons.where((lesson) {
      return lesson.title.toLowerCase().contains(searchQuery) ||
             (lesson.description?.toLowerCase().contains(searchQuery) ?? false) ||
             (lesson.courseCategory?.toLowerCase().contains(searchQuery) ?? false) ||
             (lesson.courseName.toLowerCase().contains(searchQuery));
    }).toList();
  }

  // 创建示例课程数据（仅用于测试）
  Future<void> createSampleLessons() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final sampleLessons = [
      // 已报读课程（未来的课程）
      Lesson(
        id: '',
        title: '动物时钟:认识时间和分钟',
        description: '通过有趣的动物主题学习时间概念，认识时钟和分钟的关系。',
        courseName: '生活小侦探',
        courseCategory: '生活小探',
        date: now.add(const Duration(days: 1)),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        createdAt: now,
      ),
      Lesson(
        id: '',
        title: '植物的秘密',
        description: '观察植物的生长过程，了解植物的基本结构和需求。',
        courseName: '生活小侦探',
        courseCategory: '生活小探',
        date: now.add(const Duration(days: 3)),
        startTime: const TimeOfDay(hour: 14, minute: 30),
        endTime: const TimeOfDay(hour: 15, minute: 30),
        createdAt: now,
      ),
      Lesson(
        id: '',
        title: '数字游戏大挑战',
        description: '通过趣味游戏学习数字认知和基础运算。',
        courseName: '数学启蒙乐园',
        courseCategory: '数学启蒙',
        date: now.add(const Duration(days: 5)),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        createdAt: now,
      ),
      Lesson(
        id: '',
        title: '英语故事时间',
        description: '通过有趣的英语故事培养语言兴趣和听力理解能力。',
        courseName: '快乐英语启蒙',
        courseCategory: '语言学习',
        date: now.add(const Duration(days: 7)),
        startTime: const TimeOfDay(hour: 16, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
        createdAt: now,
      ),
      
      // 已完成课程（过去的课程）
      Lesson(
        id: '',
        title: '水彩画基础技巧',
        description: '学习基本的水彩画技巧，发挥想象力创作艺术作品。',
        courseName: '艺术创意工坊',
        courseCategory: '艺术创意',
        date: now.subtract(const Duration(days: 2)),
        startTime: const TimeOfDay(hour: 15, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 0),
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Lesson(
        id: '',
        title: '乐器认知和节奏感培养',
        description: '认识不同乐器，通过音乐游戏培养节奏感。',
        courseName: '音乐启蒙天地',
        courseCategory: '音乐教育',
        date: now.subtract(const Duration(days: 5)),
        startTime: const TimeOfDay(hour: 11, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      Lesson(
        id: '',
        title: '厨房里的科学',
        description: '在厨房中探索科学原理，了解食物的变化过程。',
        courseName: '生活小侦探',
        courseCategory: '生活小探',
        date: now.subtract(const Duration(days: 8)),
        startTime: const TimeOfDay(hour: 10, minute: 30),
        endTime: const TimeOfDay(hour: 11, minute: 30),
        createdAt: now.subtract(const Duration(days: 15)),
      ),
    ];

    for (final lesson in sampleLessons) {
      try {
        final lessonData = lesson.toMap();
        lessonData['userId'] = userId;
        await _firestore.collection('lessons').add(lessonData);
      } catch (e) {
        print('Error creating sample lesson: $e');
      }
    }
  }
} 