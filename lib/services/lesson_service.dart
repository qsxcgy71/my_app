import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/lesson_model.dart';
import 'video_compression_service.dart';
import '../models/course_model.dart';
import '../models/profile_model.dart';
import '../services/message_service.dart';
import '../models/message_model.dart';

class LessonService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  final MessageService _messageService = MessageService();

  // 获取已报读的课程（未来的课程）
  Future<List<Lesson>> getEnrolledLessons() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final now = DateTime.now();
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('lessons')
          .get();

      final lessons = <Lesson>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        try {
          final lesson = Lesson.fromMap(data, doc.id);

          // 只包含未来的课程（已报读但未上）
          if (!lesson.isCompleted && lesson.endDateTime.isAfter(now)) {
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
          .collection('users')
          .doc(userId)
          .collection('lessons')
          .get();

      final lessons = <Lesson>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        try {
          final lesson = Lesson.fromMap(data, doc.id);

          // 只包含过去的课程（已完成）
          if (lesson.isCompleted || lesson.endDateTime.isBefore(now)) {
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
          .collection('users')
          .doc(userId)
          .collection('lessons')
          .get();

      final lessons = <Lesson>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        try {
          final lesson = Lesson.fromMap(data, doc.id);
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
    String? description,
    required String courseId,
    required String courseName,
    String? courseCategory,
    String? imageUrl,
    String? instructor,
    required DateTime date,
    required DateTime startTimeDateTime,
    required DateTime endTimeDateTime,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final lesson = Lesson(
      id: '',
      title: title.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      courseId: courseId,
      courseName: courseName.trim(),
      courseCategory: courseCategory?.trim().isEmpty == true ? null : courseCategory?.trim(),
      date: date,
      startTime: TimeOfDay.fromDateTime(startTimeDateTime),
      endTime: TimeOfDay.fromDateTime(endTimeDateTime),
      instructor: instructor?.trim().isEmpty == true ? null : instructor?.trim(),
      isCompleted: false,
      imageUrl: imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      createdAt: DateTime.now(),
    );

    final lessonData = lesson.toMap();
    
    final docRef = await _firestore.collection('users').doc(userId).collection('lessons').add(lessonData);
    return lesson.copyWith(id: docRef.id);
  }

  // 更新课程
  Future<void> updateLesson({
    required String lessonId,
    required String title,
    String? description,
    required String courseId,
    required String courseName,
    String? courseCategory,
    String? imageUrl,
    String? instructor,
    required DateTime date,
    required DateTime startTimeDateTime,
    required DateTime endTimeDateTime,
    required bool isCompleted,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final lesson = Lesson(
      id: lessonId,
      title: title.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      courseId: courseId,
      courseName: courseName.trim(),
      courseCategory: courseCategory?.trim().isEmpty == true ? null : courseCategory?.trim(),
      date: date,
      startTime: TimeOfDay.fromDateTime(startTimeDateTime),
      endTime: TimeOfDay.fromDateTime(endTimeDateTime),
      instructor: instructor?.trim().isEmpty == true ? null : instructor?.trim(),
      isCompleted: isCompleted,
      imageUrl: imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      createdAt: DateTime.now(),
    );

    final lessonData = lesson.toMap();
    
    await _firestore.collection('users').doc(userId).collection('lessons').doc(lessonId).update(lessonData);
  }

  // 删除课程
  Future<void> deleteLesson(String lessonId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore.collection('users').doc(userId).collection('lessons').doc(lessonId).delete();
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

    final sampleLessons = [
      Lesson(
        id: 'lesson_1_sample',
        courseId: 'course_id_1',
        title: '儿童绘画基础',
        courseName: '儿童绘画基础',
        courseCategory: '艺术创作',
        date: DateTime.now().add(const Duration(days: 1)),
        startTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(days: 1))),
        endTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(days: 1, hours: 1))),
        instructor: '王老师',
        isCompleted: false,
        description: '学习基础绘画技巧，激发儿童艺术天赋。',
        imageUrl: 'https://placehold.co/600x400/add8e6/000000.png?text=Painting',
        createdAt: DateTime.now(),
      ),
      Lesson(
        id: 'lesson_2_sample',
        courseId: 'course_id_2',
        title: '趣味科学实验',
        courseName: '趣味科学实验',
        courseCategory: '科学探索',
        date: DateTime.now().add(const Duration(days: 3)),
        startTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(days: 3))),
        endTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(days: 3, hours: 1, minutes: 30))),
        instructor: '李老师',
        isCompleted: false,
        description: '通过有趣的实验，培养孩子的科学思维。',
        imageUrl: 'https://placehold.co/600x400/90ee90/000000.png?text=Science',
        createdAt: DateTime.now(),
      ),
      Lesson(
        id: 'lesson_3_sample',
        courseId: 'course_id_3',
        title: '乐高编程入门',
        courseName: '乐高编程入门',
        courseCategory: '编程机器人',
        date: DateTime.now().subtract(const Duration(days: 5)),
        startTime: TimeOfDay.fromDateTime(DateTime.now().subtract(const Duration(days: 5))),
        endTime: TimeOfDay.fromDateTime(DateTime.now().subtract(const Duration(days: 5, hours: 1))),
        instructor: '张老师',
        isCompleted: true,
        description: '学习乐高机器人编程基础，培养逻辑思维。',
        imageUrl: 'https://placehold.co/600x400/d3d3d3/000000.png?text=Lego',
        createdAt: DateTime.now(),
      ),
    ];

    final batch = _firestore.batch();
    for (var lesson in sampleLessons) {
      final docRef = _firestore.collection('users').doc(userId).collection('lessons').doc(lesson.id);
      batch.set(docRef, lesson.toMap());
    }
    await batch.commit();
  }

  // 根据ID获取课程
  Future<Lesson?> getLessonById(String lessonId) async {
    try {
      final doc = await _firestore.collection('lessons').doc(lessonId).get();
      if (!doc.exists) return null;

      return Lesson.fromMap({
        ...doc.data()!,
        'id': doc.id,
      }, doc.id);
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

  // 新增：报名课程方法
  Future<void> enrollCourse(Course course, List<ChildInfo> children) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('用户未登录');
    }

    final batch = _firestore.batch();
    final userLessonsCollection = _firestore.collection('users').doc(user.uid).collection('lessons');

    for (final child in children) {
      // 创建Lesson对象
      final lesson = Lesson(
        id: '${course.id}_${child.id}_${DateTime.now().millisecondsSinceEpoch}',
        courseId: course.id,
        title: course.title,
        courseName: course.title,
        courseCategory: course.category,
        date: DateTime.now().add(const Duration(days: 7)),
        startTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(days: 7))),
        endTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(days: 7, hours: 1))),
        instructor: course.instructor,
        isCompleted: false,
        imageUrl: course.imageUrls.isNotEmpty ? course.imageUrls.first : null,
        description: course.description,
        childId: child.id,
        childName: child.name,
        createdAt: DateTime.now(),
      );

      // 检查是否已经报名过此课程（针对此孩子）
      final existingLesson = await userLessonsCollection
          .where('courseId', isEqualTo: course.id)
          .where('childId', isEqualTo: child.id)
          .limit(1)
          .get();

      if (existingLesson.docs.isNotEmpty) {
        print('课程 ${course.title} 已经为孩子 ${child.name} 报名。跳过。');
        continue;
      }

      final docRef = userLessonsCollection.doc(lesson.id);
      batch.set(docRef, lesson.toMap());
    }

    await batch.commit();
    print('课程报名成功，已添加到Firestore。');

    // 发送报名成功消息
    if (children.isNotEmpty) {
      String childNames = children.map((c) => c.name).join('、');
      String messageTitle = '报名成功通知';
      String messageContent = '您已成功为 $childNames 报名课程《${course.title}》。请留意上课时间！';

      // 创建一个系统消息
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: messageTitle,
        content: messageContent,
        type: MessageType.system,
        createdAt: DateTime.now(),
        isRead: false,
        extraData: {
          'courseId': course.id,
          'courseName': course.title,
          'childIds': children.map((c) => c.id).toList(),
          'childNames': children.map((c) => c.name).toList(),
        },
      );
      await _messageService.addMessage(message);
      print('报名成功消息已发送。');
    }
  }

  // 新增：更新课程完成状态的方法
  Future<void> updateLessonCompletionStatus(String lessonId, bool isCompleted) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore.collection('users').doc(userId).collection('lessons').doc(lessonId).update({
      'isCompleted': isCompleted,
    });
  }
} 