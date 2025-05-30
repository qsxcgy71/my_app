import 'package:flutter/material.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> imageUrls; // 多张图片用于轮播
  final int totalLessons;
  final Duration totalDuration;
  final String instructor;
  final double rating;
  final int enrolledCount;
  final bool isFeatured;
  final DateTime createdAt;
  final List<CourseLesson> lessons;
  
  // 新增过滤器字段
  final int recommendedAge; // 推荐年龄
  final String difficulty; // 难度等级
  final double price; // 价格
  final bool isOnline; // 是否在线课程

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrls,
    required this.totalLessons,
    required this.totalDuration,
    required this.instructor,
    required this.rating,
    required this.enrolledCount,
    required this.isFeatured,
    required this.createdAt,
    required this.lessons,
    this.recommendedAge = 6, // 默认推荐年龄
    this.difficulty = '初级', // 默认难度
    this.price = 0.0, // 默认免费
    this.isOnline = true, // 默认在线课程
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      totalLessons: json['totalLessons'] ?? 0,
      totalDuration: Duration(minutes: json['totalDurationMinutes'] ?? 0),
      instructor: json['instructor'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      enrolledCount: json['enrolledCount'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lessons: (json['lessons'] as List<dynamic>? ?? [])
          .map((lessonJson) => CourseLesson.fromJson(lessonJson))
          .toList(),
      recommendedAge: json['recommendedAge'] ?? 6,
      difficulty: json['difficulty'] ?? '初级',
      price: (json['price'] ?? 0.0).toDouble(),
      isOnline: json['isOnline'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'imageUrls': imageUrls,
      'totalLessons': totalLessons,
      'totalDurationMinutes': totalDuration.inMinutes,
      'instructor': instructor,
      'rating': rating,
      'enrolledCount': enrolledCount,
      'isFeatured': isFeatured,
      'createdAt': createdAt.toIso8601String(),
      'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
      'recommendedAge': recommendedAge,
      'difficulty': difficulty,
      'price': price,
      'isOnline': isOnline,
    };
  }

  String getDurationString(Locale locale) {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;
    
    if (locale.languageCode == 'zh') {
      if (hours > 0) {
        return '${hours}小时${minutes}分钟';
      } else {
        return '${minutes}分钟';
      }
    } else {
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m';
      }
    }
  }

  String getEnrolledCountString(Locale locale) {
    if (locale.languageCode == 'zh') {
      if (enrolledCount >= 1000) {
        return '${(enrolledCount / 1000).toStringAsFixed(1)}k人已报名';
      } else {
        return '${enrolledCount}人已报名';
      }
    } else {
      if (enrolledCount >= 1000) {
        return '${(enrolledCount / 1000).toStringAsFixed(1)}k enrolled';
      } else {
        return '$enrolledCount enrolled';
      }
    }
  }

  // 格式化价格显示
  String get priceString {
    if (price == 0) {
      return '免费';
    } else {
      return '¥${price.toStringAsFixed(0)}';
    }
  }

  // 保留旧方法以保持兼容性，默认使用中文
  String get durationString => getDurationString(const Locale('zh'));
  String get enrolledCountString => getEnrolledCountString(const Locale('zh'));
}

class CourseLesson {
  final String id;
  final String title;
  final String description;
  final Duration duration;
  final int order;
  final String? videoUrl;
  final bool isPreview;

  CourseLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.order,
    this.videoUrl,
    required this.isPreview,
  });

  factory CourseLesson.fromJson(Map<String, dynamic> json) {
    return CourseLesson(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      duration: Duration(minutes: json['durationMinutes'] ?? 0),
      order: json['order'] ?? 0,
      videoUrl: json['videoUrl'],
      isPreview: json['isPreview'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'durationMinutes': duration.inMinutes,
      'order': order,
      'videoUrl': videoUrl,
      'isPreview': isPreview,
    };
  }

  String getDurationString(Locale locale) {
    final minutes = duration.inMinutes;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}:${remainingMinutes.toString().padLeft(2, '0')}';
    } else {
      if (locale.languageCode == 'zh') {
        return '${minutes}分钟';
      } else {
        return '${minutes}m';
      }
    }
  }

  // 保留旧方法以保持兼容性，默认使用中文
  String get durationString => getDurationString(const Locale('zh'));
} 