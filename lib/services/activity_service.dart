import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/activity_model.dart';

class ActivityService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  static const int pageSize = 5;
  
  // 存储每个日期的最后一个文档，用于分页
  final Map<DateTime, DocumentSnapshot> _lastDocuments = {};

  // 获取指定月份的活动
  Future<Map<DateTime, List<Activity>>> getMonthActivities(DateTime focusedDay) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {};

    try {
      final startDate = DateTime(focusedDay.year, focusedDay.month, 1);
      final endDate = DateTime(focusedDay.year, focusedDay.month + 1, 0);

      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .get();

      final activities = <DateTime, List<Activity>>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        try {
          final activity = Activity.fromMap({
            ...data,
            'id': doc.id,
          });

          if (activity.date.year == focusedDay.year && 
              activity.date.month == focusedDay.month) {
            
            final dateKey = DateTime(
              activity.date.year,
              activity.date.month,
              activity.date.day,
            );
            
            if (activities[dateKey] == null) {
              activities[dateKey] = [];
            }
            activities[dateKey]!.add(activity);
          }
        } catch (e) {
          continue;
        }
      }

      // Sort activities within each day by time
      activities.forEach((date, dayActivities) {
        dayActivities.sort((a, b) {
          if (a.time == null && b.time != null) return -1;
          if (a.time != null && b.time == null) return 1;
          if (a.time == null && b.time == null) {
            return a.createdAt.compareTo(b.createdAt);
          }
          return a.fullDateTime.compareTo(b.fullDateTime);
        });
      });

      return activities;
    } catch (e) {
      // Handle error silently
      return {};
    }
  }

  // 加载更多活动
  Future<({Map<DateTime, List<Activity>> activities, bool hasMore})> loadMoreActivities({
    required DateTime focusedDay,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return (activities: <DateTime, List<Activity>>{}, hasMore: false);
    }

    try {
      final lastDoc = _lastDocuments[focusedDay];
      if (lastDoc == null) {
        return (activities: <DateTime, List<Activity>>{}, hasMore: false);
      }

      final startDate = DateTime(focusedDay.year, focusedDay.month, 1);
      final endDate = DateTime(focusedDay.year, focusedDay.month + 1, 0);

      final query = _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true)
          .startAfterDocument(lastDoc)
          .limit(pageSize);

      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        return (activities: <DateTime, List<Activity>>{}, hasMore: false);
      }

      _lastDocuments[focusedDay] = snapshot.docs.last;
      final activities = <DateTime, List<Activity>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dateStr = data['date'] as String;
        final activityDate = DateTime.parse(dateStr);

        if (activityDate.year == focusedDay.year && 
            activityDate.month == focusedDay.month) {
          final activity = Activity.fromMap({
            ...data,
            'id': doc.id,
          });
          
          final date = DateTime(
            activity.date.year,
            activity.date.month,
            activity.date.day,
          );
          
          if (activities[date] == null) {
            activities[date] = [];
          }
          activities[date]!.add(activity);
        }
      }

      return (
        activities: activities,
        hasMore: snapshot.docs.length >= pageSize
      );
    } catch (e) {
      print('Error loading more activities: $e');
      return (activities: <DateTime, List<Activity>>{}, hasMore: false);
    }
  }

  // 清除分页状态
  void clearPaginationState() {
    _lastDocuments.clear();
  }

  // 添加新活动
  Future<Activity> addActivity({
    required String title,
    required DateTime date,
    String? description,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final activity = Activity(
      id: '',
      title: title.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      date: date,
      time: startTime,
      endTime: endTime,
      createdAt: DateTime.now(),
    );

    final activityData = activity.toMap();
    activityData['userId'] = userId;
    
    final docRef = await _firestore.collection('activities').add(activityData);
    return activity.copyWith(id: docRef.id);
  }

  // 更新活动
  Future<void> updateActivity({
    required String activityId,
    required String title,
    required DateTime date,
    String? description,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    required DateTime createdAt,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final activity = Activity(
      id: activityId,
      title: title.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      date: date,
      time: startTime,
      endTime: endTime,
      createdAt: createdAt,
    );

    final activityData = activity.toMap();
    activityData['userId'] = userId;
    
    await _firestore.collection('activities').doc(activityId).update(activityData);
  }

  // 删除活动
  Future<void> deleteActivity(String activityId) async {
    await _firestore.collection('activities').doc(activityId).delete();
  }
} 