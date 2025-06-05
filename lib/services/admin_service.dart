import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import 'message_service.dart';

/// 管理员服务 - 用于发送系统级消息和管理功能
class AdminService {
  final _firestore = FirebaseFirestore.instance;
  final _messageService = MessageService();

  // ===========================================
  // 系统级消息发送 (仅限管理员)
  // ===========================================

  /// 发送应用更新通知给所有用户
  Future<void> broadcastAppUpdate({
    required String version,
    required List<String> features,
    required bool isRequired,
    List<String>? targetUserIds, // 如果为null，则发送给所有用户
  }) async {
    try {
      if (targetUserIds == null) {
        // 获取所有用户ID
        final usersSnapshot = await _firestore.collection('profiles').get();
        targetUserIds = usersSnapshot.docs.map((doc) => doc.id).toList();
      }

      // 批量发送更新通知
      for (final userId in targetUserIds) {
        await _sendMessageToUser(
          userId: userId,
          sendMessage: () => _messageService.sendAppUpdateMessage(version, features, isRequired),
        );
      }
    } catch (e) {
      print('Error broadcasting app update: $e');
      rethrow;
    }
  }

  /// 发送系统维护通知给所有用户
  Future<void> broadcastMaintenanceNotification({
    required DateTime startTime,
    required DateTime endTime,
    required String reason,
    List<String>? targetUserIds,
  }) async {
    try {
      if (targetUserIds == null) {
        final usersSnapshot = await _firestore.collection('profiles').get();
        targetUserIds = usersSnapshot.docs.map((doc) => doc.id).toList();
      }

      for (final userId in targetUserIds) {
        await _sendMessageToUser(
          userId: userId,
          sendMessage: () => _messageService.sendMaintenanceMessage(startTime, endTime, reason),
        );
      }
    } catch (e) {
      print('Error broadcasting maintenance notification: $e');
      rethrow;
    }
  }

  /// 发送政策更新通知给所有用户
  Future<void> broadcastPolicyUpdate({
    required String policyType,
    required String summary,
    List<String>? targetUserIds,
  }) async {
    try {
      if (targetUserIds == null) {
        final usersSnapshot = await _firestore.collection('profiles').get();
        targetUserIds = usersSnapshot.docs.map((doc) => doc.id).toList();
      }

      for (final userId in targetUserIds) {
        await _sendMessageToUser(
          userId: userId,
          sendMessage: () => _messageService.sendPolicyUpdateMessage(policyType, summary),
        );
      }
    } catch (e) {
      print('Error broadcasting policy update: $e');
      rethrow;
    }
  }

  // ===========================================
  // 课程相关管理功能
  // ===========================================

  /// 发送课程更新通知给已报名用户
  Future<void> notifyCourseUpdate({
    required String courseId,
    required Course course,
    required String updateType,
    required String details,
  }) async {
    try {
      // 查找所有报名此课程的用户
      final enrolledUsers = await _getEnrolledUsersForCourse(courseId);
      
      for (final userId in enrolledUsers) {
        await _sendMessageToUser(
          userId: userId,
          sendMessage: () => _messageService.sendCourseUpdateMessage(course, updateType, details),
        );
      }
    } catch (e) {
      print('Error notifying course update: $e');
      rethrow;
    }
  }

  /// 发送课程推荐给特定用户群体
  Future<void> sendCourseRecommendations({
    required List<Course> courses,
    required String reason,
    List<String>? targetUserIds,
    Map<String, dynamic>? filters, // 用于筛选目标用户的条件
  }) async {
    try {
      List<String> userIds = targetUserIds ?? [];
      
      if (userIds.isEmpty && filters != null) {
        // 根据筛选条件获取目标用户
        userIds = await _getUsersByFilters(filters);
      }
      
      if (userIds.isEmpty) {
        // 默认发送给所有用户
        final usersSnapshot = await _firestore.collection('profiles').get();
        userIds = usersSnapshot.docs.map((doc) => doc.id).toList();
      }

      for (final userId in userIds) {
        await _sendMessageToUser(
          userId: userId,
          sendMessage: () => _messageService.sendCourseRecommendationMessage(courses, reason),
        );
      }
    } catch (e) {
      print('Error sending course recommendations: $e');
      rethrow;
    }
  }

  // ===========================================
  // 批量提醒功能
  // ===========================================

  /// 批量发送课程开始提醒
  Future<void> sendBatchCourseReminders({
    required DateTime targetDate,
    required int minutesBefore,
  }) async {
    try {
      // 查找指定日期的所有课程
      final lessonsSnapshot = await _firestore
          .collectionGroup('lessons')
          .where('date', isGreaterThanOrEqualTo: targetDate.toIso8601String().split('T')[0])
          .where('date', isLessThan: targetDate.add(Duration(days: 1)).toIso8601String().split('T')[0])
          .get();

      for (final doc in lessonsSnapshot.docs) {
        try {
          final lesson = Lesson.fromMap(doc.data(), doc.id);
          final userId = doc.reference.parent.parent!.id;
          
          // 检查是否需要发送提醒（基于课程开始时间）
          final reminderTime = lesson.startDateTime.subtract(Duration(minutes: minutesBefore));
          final now = DateTime.now();
          
          if (reminderTime.isBefore(now) && lesson.startDateTime.isAfter(now)) {
            await _sendMessageToUser(
              userId: userId,
              sendMessage: () => _messageService.sendCourseReminderMessage(lesson, minutesBefore),
            );
          }
        } catch (e) {
          print('Error processing lesson reminder: $e');
          continue;
        }
      }
    } catch (e) {
      print('Error sending batch course reminders: $e');
      rethrow;
    }
  }

  /// 批量发送课程结束提醒
  Future<void> sendBatchCourseEndingReminders({
    required DateTime targetDate,
    required int minutesBefore,
  }) async {
    try {
      final lessonsSnapshot = await _firestore
          .collectionGroup('lessons')
          .where('date', isGreaterThanOrEqualTo: targetDate.toIso8601String().split('T')[0])
          .where('date', isLessThan: targetDate.add(Duration(days: 1)).toIso8601String().split('T')[0])
          .get();

      for (final doc in lessonsSnapshot.docs) {
        try {
          final lesson = Lesson.fromMap(doc.data(), doc.id);
          final userId = doc.reference.parent.parent!.id;
          
          final reminderTime = lesson.endDateTime.subtract(Duration(minutes: minutesBefore));
          final now = DateTime.now();
          
          if (reminderTime.isBefore(now) && lesson.endDateTime.isAfter(now)) {
            await _sendMessageToUser(
              userId: userId,
              sendMessage: () => _messageService.sendCourseEndingSoonMessage(lesson, minutesBefore),
            );
          }
        } catch (e) {
          print('Error processing lesson ending reminder: $e');
          continue;
        }
      }
    } catch (e) {
      print('Error sending batch course ending reminders: $e');
      rethrow;
    }
  }

  // ===========================================
  // 辅助方法
  // ===========================================

  /// 获取指定课程的所有已报名用户
  Future<List<String>> _getEnrolledUsersForCourse(String courseId) async {
    final lessonsSnapshot = await _firestore
        .collectionGroup('lessons')
        .where('courseId', isEqualTo: courseId)
        .get();

    final userIds = <String>{};
    for (final doc in lessonsSnapshot.docs) {
      final userId = doc.reference.parent.parent!.id;
      userIds.add(userId);
    }

    return userIds.toList();
  }

  /// 根据筛选条件获取用户
  Future<List<String>> _getUsersByFilters(Map<String, dynamic> filters) async {
    // 这里可以根据不同的筛选条件来查询用户
    // 例如：孩子年龄范围、地区、兴趣标签等
    
    Query query = _firestore.collection('profiles');
    
    // 示例筛选条件
    if (filters.containsKey('hasChildren')) {
      query = query.where('children', isNotEqualTo: []);
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /// 向指定用户发送消息的通用方法
  Future<void> _sendMessageToUser({
    required String userId,
    required Future<void> Function() sendMessage,
  }) async {
    try {
      // 临时切换到目标用户身份来发送消息
      // 注意：在实际应用中，这需要适当的权限管理
      await sendMessage();
    } catch (e) {
      print('Error sending message to user $userId: $e');
      // 不中断批量操作
    }
  }

  // ===========================================
  // 统计和分析方法
  // ===========================================

  /// 获取消息发送统计
  Future<Map<String, int>> getMessageStatistics() async {
    try {
      final messagesSnapshot = await _firestore.collection('messages').get();
      final stats = <String, int>{};
      
      for (final doc in messagesSnapshot.docs) {
        final type = doc.data()['type'] as String;
        stats[type] = (stats[type] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      print('Error getting message statistics: $e');
      return {};
    }
  }

  /// 获取用户参与度统计
  Future<Map<String, dynamic>> getUserEngagementStats() async {
    try {
      final usersSnapshot = await _firestore.collection('profiles').get();
      final messagesSnapshot = await _firestore.collection('messages').get();
      
      return {
        'totalUsers': usersSnapshot.docs.length,
        'totalMessages': messagesSnapshot.docs.length,
        'averageMessagesPerUser': messagesSnapshot.docs.length / usersSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting user engagement stats: $e');
      return {};
    }
  }
} 