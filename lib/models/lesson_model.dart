import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  final String id;
  final String title; // 具体课节名称，如"动物时钟"
  final String? description;
  final String courseId; // 新增：关联的课程ID
  final String courseName; // 课程名称，如"生活小侦探"
  final String? courseCategory; // 课程类别，如"生活小探"
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final DateTime createdAt;
  final bool isCompleted;
  final String? imageUrl; // 课程图片
  final List<LessonPhoto> photos; // 课程照片列表
  List<LessonVideo> videos; // 课程视频列表 - 改为非final以便修改
  final String? childId; // 新增：关联的孩子ID
  final String? childName; // 新增：关联的孩子名称
  final String? instructor; // 新增：讲师

  Lesson({
    required this.id,
    required this.title,
    this.description,
    required this.courseId, // 构造函数添加
    required this.courseName,
    this.courseCategory,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    this.isCompleted = false,
    this.imageUrl,
    this.photos = const [],
    List<LessonVideo>? videos,
    this.childId, // 构造函数添加
    this.childName, // 构造函数添加
    this.instructor, // 构造函数添加
  }) : videos = videos ?? []; // 提供默认空列表

  // Get full DateTime for start time
  DateTime get startDateTime {
    return DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
  }

  // Get full DateTime for end time
  DateTime get endDateTime {
    return DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );
  }

  // Check if lesson is in the past (completed automatically)
  bool get isPastLesson {
    final now = DateTime.now();
    return endDateTime.isBefore(now);
  }

  // Get formatted time string
  String get timeString {
    final startFormatted = _formatTime(startTime);
    final endFormatted = _formatTime(endTime);
    return '$startFormatted - $endFormatted';
  }

  // Get formatted date string
  String get dateString {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                   'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}';
  }

  // Get start time formatted as "10:00 am"
  String get startTimeString {
    return _formatTime(startTime);
  }

  String _formatTime(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour;
    final minute = timeOfDay.minute;
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'courseId': courseId, // toMap添加
      'courseName': courseName,
      'courseCategory': courseCategory,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'startTime': startDateTime.toIso8601String(),
      'endTime': endDateTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
      'imageUrl': imageUrl,
      'photos': photos.map((photo) => photo.toMap()).toList(),
      'videos': videos.map((video) => video.toMap()).toList(),
      'childId': childId,
      'childName': childName,
      'instructor': instructor, // toMap添加
      'userId': '', // This will be set when saving to Firestore
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map, String id) {
    final dateTime = DateTime.parse(map['date'] as String);
    final startDateTime = DateTime.parse(map['startTime'] as String);
    final endDateTime = DateTime.parse(map['endTime'] as String);
    
    // Convert to local time
    final localDate = dateTime.toLocal();
    final localStartTime = startDateTime.toLocal();
    final localEndTime = endDateTime.toLocal();
    
    return Lesson(
      id: id, // 使用传入的id
      title: map['title'] as String,
      description: map['description'] as String?,
      courseId: map['courseId'] as String? ?? '', // fromMap添加
      courseName: map['courseName'] as String,
      courseCategory: map['courseCategory'] as String?,
      date: DateTime(localDate.year, localDate.month, localDate.day),
      startTime: TimeOfDay(hour: localStartTime.hour, minute: localStartTime.minute),
      endTime: TimeOfDay(hour: localEndTime.hour, minute: localEndTime.minute),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String).toLocal()
          : DateTime.now(),
      isCompleted: map['isCompleted'] as bool? ?? false,
      imageUrl: map['imageUrl'] as String?,
      photos: (map['photos'] as List<dynamic>?)?.map((photo) => LessonPhoto.fromMap(photo)).toList() ?? [],
      videos: (map['videos'] as List<dynamic>?)?.map((video) => LessonVideo.fromMap(video)).toList() ?? [],
      childId: map['childId'] as String?,
      childName: map['childName'] as String?,
      instructor: map['instructor'] as String?, // fromMap添加
    );
  }

  // Copy with method for easy updates
  Lesson copyWith({
    String? id,
    String? title,
    String? description,
    String? courseId,
    String? courseName,
    String? courseCategory,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    DateTime? createdAt,
    bool? isCompleted,
    String? imageUrl,
    List<LessonPhoto>? photos,
    List<LessonVideo>? videos,
    String? childId,
    String? childName,
    String? instructor,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      courseCategory: courseCategory ?? this.courseCategory,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      imageUrl: imageUrl ?? this.imageUrl,
      photos: photos ?? this.photos,
      videos: videos ?? this.videos,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      instructor: instructor ?? this.instructor,
    );
  }
}

class LessonPhoto {
  final String id;
  final String url;
  final String thumbnailUrl;
  final DateTime takenAt;
  final String description;

  LessonPhoto({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    required this.takenAt,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'takenAt': takenAt.toIso8601String(),
      'description': description,
    };
  }

  factory LessonPhoto.fromMap(Map<String, dynamic> map) {
    return LessonPhoto(
      id: map['id'] as String,
      url: map['url'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String,
      takenAt: DateTime.parse(map['takenAt'] as String),
      description: map['description'] as String,
    );
  }
}

class LessonVideo {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final DateTime takenAt;
  final String description;
  final int? duration; // 视频时长（秒）
  final int? fileSize; // 文件大小（字节）

  LessonVideo({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.takenAt,
    required this.description,
    this.duration,
    this.fileSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'takenAt': takenAt.toIso8601String(),
      'description': description,
      'duration': duration,
      'fileSize': fileSize,
    };
  }

  factory LessonVideo.fromMap(Map<String, dynamic> map) {
    return LessonVideo(
      id: map['id'] as String,
      url: map['url'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      takenAt: DateTime.parse(map['takenAt'] as String),
      description: map['description'] as String,
      duration: map['duration'] as int?,
      fileSize: map['fileSize'] as int?,
    );
  }
} 