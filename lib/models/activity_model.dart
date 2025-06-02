import 'package:flutter/material.dart';

class Activity {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final TimeOfDay? time;
  final TimeOfDay? endTime;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.time,
    this.endTime,
    required this.createdAt,
  });

  // Get full DateTime including time for proper sorting
  DateTime get fullDateTime {
    if (time != null) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        time!.hour,
        time!.minute,
      );
    }
    return date;
  }

  // Get formatted time string with start and end times
  String get timeString {
    if (time != null) {
      final startFormatted = _formatTime(time!);
      
      if (endTime != null) {
        final endFormatted = _formatTime(endTime!);
        return '$startFormatted - $endFormatted';
      } else {
        return startFormatted;
      }
    }
    return 'All Day';
  }

  String _formatTime(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour;
    final minute = timeOfDay.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'date': fullDateTime.toIso8601String(), // Store full datetime
      'createdAt': createdAt.toIso8601String(),
      'userId': '', // This will be set when saving to Firestore
    };

    // Only add endTime if it exists
    if (endTime != null) {
      final endDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        endTime!.hour,
        endTime!.minute,
      );
      map['endTime'] = endDateTime.toIso8601String();
    }

    return map;
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    final dateTime = DateTime.parse(map['date'] as String);
    
    // Convert to local time to avoid timezone issues
    final localDateTime = dateTime.toLocal();
    
    // Parse end time if it exists
    TimeOfDay? endTime;
    if (map['endTime'] != null) {
      final endDateTime = DateTime.parse(map['endTime'] as String).toLocal();
      endTime = TimeOfDay(hour: endDateTime.hour, minute: endDateTime.minute);
    }
    
    return Activity(
      id: map['id'] as String? ?? '', // Handle case where id might be null
      title: map['title'] as String,
      description: map['description'] as String?,
      date: DateTime(localDateTime.year, localDateTime.month, localDateTime.day),
      time: localDateTime.hour != 0 || localDateTime.minute != 0
          ? TimeOfDay(hour: localDateTime.hour, minute: localDateTime.minute)
          : null,
      endTime: endTime,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String).toLocal()
          : DateTime.now(), // Fallback if createdAt is missing
    );
  }

  // Copy with method for easy updates
  Activity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? time,
    TimeOfDay? endTime,
    DateTime? createdAt,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 