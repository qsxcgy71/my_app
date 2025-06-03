import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/lesson_model.dart';
import 'video_compression_service.dart';

class LessonService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

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

  // 根据ID获取课程
  Future<Lesson?> getLessonById(String lessonId) async {
    try {
      final doc = await _firestore.collection('lessons').doc(lessonId).get();
      if (!doc.exists) return null;

      return Lesson.fromMap({
        ...doc.data()!,
        'id': doc.id,
      });
    } catch (e) {
      return null;
    }
  }

  // 添加课程照片
  Future<void> addLessonPhoto(String lessonId, String localImagePath, {String? description}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // 1. 上传图片到Firebase Storage
      final file = File(localImagePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final photoId = 'lesson_photos/$lessonId/$timestamp';
      
      final uploadTask = _storage.ref(photoId).putFile(file);
      final snapshot = await uploadTask;
      final photoUrl = await snapshot.ref.getDownloadURL();

      // 2. 创建照片对象
      final photo = LessonPhoto(
        id: photoId,
        url: photoUrl,
        thumbnailUrl: photoUrl, // 这里可以添加缩略图处理逻辑
        takenAt: DateTime.now(),
        description: description ?? '课程照片',
      );

      // 3. 更新课程文档，添加新照片
      await _firestore.collection('lessons').doc(lessonId).update({
        'photos': FieldValue.arrayUnion([photo.toMap()]),
      });
    } catch (e) {
      throw Exception('上传照片失败: $e');
    }
  }

  // 添加课程视频
  Future<void> addLessonVideo(String lessonId, String localVideoPath, {String? description}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // 1. 上传视频到Firebase Storage
      final file = File(localVideoPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final videoId = 'lesson_videos/$lessonId/$timestamp';
      
      final uploadTask = _storage.ref(videoId).putFile(file);
      final snapshot = await uploadTask;
      final videoUrl = await snapshot.ref.getDownloadURL();

      // 2. 生成视频缩略图
      String? thumbnailUrl;
      try {
        final thumbnail = await VideoCompressionService.generateThumbnail(file);
        if (thumbnail != null) {
          final thumbnailId = 'lesson_thumbnails/$lessonId/${timestamp}_thumb';
          final thumbnailUploadTask = _storage.ref(thumbnailId).putFile(thumbnail);
          final thumbnailSnapshot = await thumbnailUploadTask;
          thumbnailUrl = await thumbnailSnapshot.ref.getDownloadURL();
          
          // 删除本地临时缩略图文件
          try {
            await thumbnail.delete();
          } catch (e) {
            print('删除临时缩略图文件失败: $e');
          }
        }
      } catch (e) {
        print('生成视频缩略图失败: $e');
        // 即使缩略图生成失败，视频仍然可以上传
      }

      // 3. 获取文件大小和视频信息
      final fileSize = await file.length();
      int? duration;
      
      try {
        final videoInfo = await VideoCompressionService.getVideoInfo(file);
        if (videoInfo?.duration != null) {
          duration = (videoInfo!.duration! / 1000).round(); // 转换为秒
        }
      } catch (e) {
        print('获取视频信息失败: $e');
      }

      // 4. 创建视频对象
      final video = LessonVideo(
        id: videoId,
        url: videoUrl,
        thumbnailUrl: thumbnailUrl,
        takenAt: DateTime.now(),
        description: description ?? '课程视频',
        fileSize: fileSize,
        duration: duration,
      );

      // 5. 更新课程文档，添加新视频
      await _firestore.collection('lessons').doc(lessonId).update({
        'videos': FieldValue.arrayUnion([video.toMap()]),
      });
    } catch (e) {
      throw Exception('上传视频失败: $e');
    }
  }

  // 删除课程照片
  Future<void> deleteLessonPhoto(String lessonId, String photoId) async {
    try {
      // 1. 从Storage中删除照片
      await _storage.ref(photoId).delete();

      // 2. 从课程文档中移除照片记录
      final doc = await _firestore.collection('lessons').doc(lessonId).get();
      if (!doc.exists) return;

      final photos = (doc.data()?['photos'] as List? ?? [])
          .where((photo) => photo['id'] != photoId)
          .toList();

      await doc.reference.update({'photos': photos});
    } catch (e) {
      throw Exception('删除照片失败: $e');
    }
  }

  // 删除课程视频
  Future<void> deleteLessonVideo(String lessonId, String videoId) async {
    try {
      // 1. 从Storage中删除视频
      await _storage.ref(videoId).delete();

      // 2. 从课程文档中移除视频记录
      final doc = await _firestore.collection('lessons').doc(lessonId).get();
      if (!doc.exists) return;

      final videos = (doc.data()?['videos'] as List? ?? [])
          .where((video) => video['id'] != videoId)
          .toList();

      await doc.reference.update({'videos': videos});
    } catch (e) {
      throw Exception('删除视频失败: $e');
    }
  }
} 