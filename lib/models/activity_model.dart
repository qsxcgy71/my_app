import 'package:flutter/material.dart';

class Activity {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final TimeOfDay? time;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.time,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    final dateTime = DateTime.parse(map['date'] as String);
    return Activity(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      date: DateTime(dateTime.year, dateTime.month, dateTime.day),
      time: dateTime.hour != 0 || dateTime.minute != 0
          ? TimeOfDay(hour: dateTime.hour, minute: dateTime.minute)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
} 