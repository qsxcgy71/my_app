import 'package:flutter/material.dart';

class Lesson {
  final String id;
  final String title; // 具体课节名称，如"动物时钟"
  final String? description;
  final String courseName; // 课程名称，如"生活小侦探"
  final String? courseCategory; // 课程类别，如"生活小探"
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final DateTime createdAt;
  final bool isCompleted;
  final String? imageUrl; // 课程图片

  Lesson({
    required this.id,
    required this.title,
    this.description,
    required this.courseName,
    this.courseCategory,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    this.isCompleted = false,
    this.imageUrl,
  });

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
      'courseName': courseName,
      'courseCategory': courseCategory,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'startTime': startDateTime.toIso8601String(),
      'endTime': endDateTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
      'imageUrl': imageUrl,
      'userId': '', // This will be set when saving to Firestore
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map) {
    final dateTime = DateTime.parse(map['date'] as String);
    final startDateTime = DateTime.parse(map['startTime'] as String);
    final endDateTime = DateTime.parse(map['endTime'] as String);
    
    // Convert to local time
    final localDate = dateTime.toLocal();
    final localStartTime = startDateTime.toLocal();
    final localEndTime = endDateTime.toLocal();
    
    return Lesson(
      id: map['id'] as String? ?? '',
      title: map['title'] as String,
      description: map['description'] as String?,
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
    );
  }

  // Copy with method for easy updates
  Lesson copyWith({
    String? id,
    String? title,
    String? description,
    String? courseName,
    String? courseCategory,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    DateTime? createdAt,
    bool? isCompleted,
    String? imageUrl,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseName: courseName ?? this.courseName,
      courseCategory: courseCategory ?? this.courseCategory,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
} 