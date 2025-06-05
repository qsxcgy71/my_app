import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/profile_model.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';

class MessageService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ===========================================
  // 1. 认证与账户管理消息
  // ===========================================

  /// 发送欢迎消息 - 新用户注册成功后
  Future<void> sendWelcomeMessage(String? userName) async {
    final title = '欢迎加入儿童档案！';
    final content = '''
亲爱的${userName ?? '家长'}，欢迎您！

📚 在这里，您可以：
• 为孩子报名精彩课程
• 记录孩子的成长时刻
• 查看课程学习报告
• 与其他家长交流经验

🌟 建议您先完善孩子的个人资料，这样我们就能为您推荐更合适的课程了！

祝您和孩子度过美好的学习时光！
    '''.trim();

    await _sendMessage(
      type: MessageType.welcome,
      title: title,
      content: content,
      extraData: {
        'userName': userName,
        'actionType': 'complete_profile',
      },
    );
  }

  /// 发送密码重置确认消息
  Future<void> sendPasswordResetConfirmation() async {
    await _sendMessage(
      type: MessageType.passwordReset,
      title: '密码重置成功',
      content: '您的账户密码已成功重置。如果这不是您本人的操作，请立即联系客服。',
      extraData: {
        'resetTime': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送资料更新通知
  Future<void> sendProfileUpdateNotification(String updateType, String details) async {
    String title;
    String content;

    switch (updateType) {
      case 'name':
        title = '姓名更新成功';
        content = '您的姓名已更新为：$details';
        break;
      case 'avatar':
        title = '头像更新成功';
        content = '您的头像已成功更新';
        break;
      case 'phone':
        title = '手机号更新成功';
        content = '您的手机号已更新为：$details';
        break;
      default:
        title = '资料更新成功';
        content = '您的个人资料已成功更新';
    }

    await _sendMessage(
      type: MessageType.profileUpdate,
      title: title,
      content: content,
      extraData: {
        'updateType': updateType,
        'details': details,
        'updateTime': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送第三方账号绑定/解绑通知
  Future<void> sendAccountBindingNotification(String provider, bool isBound) async {
    final action = isBound ? '绑定' : '解绑';
    final providerName = _getProviderDisplayName(provider);

    await _sendMessage(
      type: MessageType.accountBinding,
      title: '$providerName账号${action}成功',
      content: '您已成功${action}$providerName账号，现在可以使用$providerName快速登录。',
      extraData: {
        'provider': provider,
        'isBound': isBound,
        'operationTime': DateTime.now().toIso8601String(),
      },
    );
  }

  // ===========================================
  // 2. 课程与学习消息
  // ===========================================

  /// 发送课程报名成功消息
  Future<void> sendCourseEnrollmentMessage(Course course, List<ChildInfo> children) async {
    final childNames = children.map((c) => c.name).join('、');
    await _sendMessage(
      type: MessageType.courseEnrollment,
      title: '课程报名成功',
      content: '恭喜！$childNames 已成功报名课程《${course.title}》。请按时参加课程，期待孩子的精彩表现！',
      extraData: {
        'courseId': course.id,
        'courseName': course.title,
        'childrenIds': children.map((c) => c.id).toList(),
        'childrenNames': children.map((c) => c.name).toList(),
        'enrollmentTime': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送课程即将开始提醒
  Future<void> sendCourseReminderMessage(Lesson lesson, int minutesBefore) async {
    String timeDesc;
    if (minutesBefore >= 60) {
      timeDesc = '${minutesBefore ~/ 60}小时';
    } else {
      timeDesc = '${minutesBefore}分钟';
    }

    await _sendMessage(
      type: MessageType.courseReminder,
      title: '课程即将开始',
      content: '《${lesson.courseName}》将在${timeDesc}后开始。请为孩子做好准备，准时参加课程。',
      extraData: {
        'lessonId': lesson.id,
        'courseName': lesson.courseName,
        'startTime': lesson.startDateTime.toIso8601String(),
        'minutesBefore': minutesBefore,
      },
    );
  }

  /// 发送课程即将结束提醒
  Future<void> sendCourseEndingSoonMessage(Lesson lesson, int minutesBefore) async {
    await _sendMessage(
      type: MessageType.courseEndingSoon,
      title: '课程即将结束',
      content: '《${lesson.courseName}》将在${minutesBefore}分钟后结束。请做好接送准备。',
      extraData: {
        'lessonId': lesson.id,
        'courseName': lesson.courseName,
        'endTime': lesson.endDateTime.toIso8601String(),
        'minutesBefore': minutesBefore,
      },
    );
  }

  /// 发送课程完成通知
  Future<void> sendCourseCompletedMessage(Lesson lesson) async {
    final childNames = lesson.enrolledChildren.map((c) => c.name).join('、');
    
    await _sendMessage(
      type: MessageType.courseCompleted,
      title: '课程完成',
      content: '''
恭喜！$childNames 已完成《${lesson.courseName}》的学习。

📸 课程照片和视频已上传，您可以在课程详情中查看
📊 学习报告正在生成中，稍后您将收到详细的学习分析

感谢您对孩子教育的支持！
      '''.trim(),
      extraData: {
        'lessonId': lesson.id,
        'courseName': lesson.courseName,
        'childrenNames': lesson.enrolledChildren.map((c) => c.name).toList(),
        'completionTime': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送课程内容更新通知
  Future<void> sendCourseUpdateMessage(Course course, String updateType, String details) async {
    String updateDesc;
    switch (updateType) {
      case 'time':
        updateDesc = '上课时间';
        break;
      case 'instructor':
        updateDesc = '授课老师';
        break;
      case 'location':
        updateDesc = '上课地点';
        break;
      case 'syllabus':
        updateDesc = '课程大纲';
        break;
      default:
        updateDesc = '课程信息';
    }

    await _sendMessage(
      type: MessageType.courseUpdated,
      title: '课程信息更新',
      content: '您报名的课程《${course.title}》的${updateDesc}有变动：\n\n$details\n\n请及时查看详情并做好相应准备。',
      extraData: {
        'courseId': course.id,
        'courseName': course.title,
        'updateType': updateType,
        'details': details,
        'updateTime': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送新课程推荐消息
  Future<void> sendCourseRecommendationMessage(List<Course> recommendedCourses, String reason) async {
    final courseNames = recommendedCourses.take(3).map((c) => c.title).join('、');
    
    await _sendMessage(
      type: MessageType.courseRecommendation,
      title: '为您推荐新课程',
      content: '''
根据${reason}，我们为您推荐以下课程：

${courseNames}${recommendedCourses.length > 3 ? ' 等' : ''}

🌟 这些课程非常适合您的孩子，快来看看吧！
      '''.trim(),
      extraData: {
        'recommendedCourseIds': recommendedCourses.map((c) => c.id).toList(),
        'reason': reason,
        'recommendationTime': DateTime.now().toIso8601String(),
      },
    );
  }

  // ===========================================
  // 3. 孩子档案管理消息
  // ===========================================

  /// 发送添加孩子成功消息
  Future<void> sendChildAddedMessage(ChildInfo child) async {
    await _sendMessage(
      type: MessageType.childAdded,
      title: '孩子档案创建成功',
      content: '${child.name}的档案已成功创建！现在您可以为${child.name}报名各种有趣的课程了。',
      extraData: {
        'childId': child.id,
        'childName': child.name,
        'addTime': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送孩子档案更新消息
  Future<void> sendChildUpdatedMessage(ChildInfo child, String updateType) async {
    String updateDesc;
    switch (updateType) {
      case 'name':
        updateDesc = '姓名';
        break;
      case 'birthDate':
        updateDesc = '生日';
        break;
      case 'photo':
        updateDesc = '头像';
        break;
      default:
        updateDesc = '信息';
    }

    await _sendMessage(
      type: MessageType.childUpdated,
      title: '孩子档案更新成功',
      content: '${child.name}的${updateDesc}已成功更新。',
      extraData: {
        'childId': child.id,
        'childName': child.name,
        'updateType': updateType,
        'updateTime': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送孩子档案删除确认消息
  Future<void> sendChildDeletedMessage(String childName) async {
    await _sendMessage(
      type: MessageType.childDeleted,
      title: '孩子档案已删除',
      content: '${childName}的档案已被删除。相关的课程记录和学习数据也已同步删除。',
      extraData: {
        'childName': childName,
        'deleteTime': DateTime.now().toIso8601String(),
      },
    );
  }

  // ===========================================
  // 4. 系统与维护消息
  // ===========================================

  /// 发送应用版本更新通知
  Future<void> sendAppUpdateMessage(String version, List<String> features, bool isRequired) async {
    final urgency = isRequired ? '重要更新' : '版本更新';
    final actionText = isRequired ? '请尽快更新以确保正常使用。' : '建议您及时更新以享受新功能。';
    
    final featureList = features.map((f) => '• $f').join('\n');

    await _sendMessage(
      type: MessageType.appUpdate,
      title: '$urgency v$version',
      content: '''
新版本已发布！

✨ 本次更新内容：
$featureList

$actionText
      '''.trim(),
      extraData: {
        'version': version,
        'features': features,
        'isRequired': isRequired,
        'releaseTime': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送系统维护通知
  Future<void> sendMaintenanceMessage(DateTime startTime, DateTime endTime, String reason) async {
    final duration = endTime.difference(startTime);
    final durationText = duration.inHours > 0 
        ? '约${duration.inHours}小时${duration.inMinutes % 60}分钟'
        : '约${duration.inMinutes}分钟';

    await _sendMessage(
      type: MessageType.systemMaintenance,
      title: '系统维护通知',
      content: '''
为了提供更好的服务，我们将进行系统维护：

🕐 维护时间：${_formatDateTime(startTime)} - ${_formatDateTime(endTime)}
⏰ 预计时长：$durationText
🔧 维护内容：$reason

维护期间，部分功能可能暂时无法使用，请您谅解。
      '''.trim(),
      extraData: {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'reason': reason,
        'notificationTime': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送政策更新通知
  Future<void> sendPolicyUpdateMessage(String policyType, String summary) async {
    String policyName;
    switch (policyType) {
      case 'terms':
        policyName = '服务条款';
        break;
      case 'privacy':
        policyName = '隐私政策';
        break;
      case 'refund':
        policyName = '退费政策';
        break;
      default:
        policyName = '相关政策';
    }

    await _sendMessage(
      type: MessageType.policyUpdate,
      title: '$policyName更新',
      content: '''
我们更新了$policyName，主要变更如下：

$summary

请在设置中查看完整的最新条款。继续使用我们的服务即表示您同意新的条款。
      '''.trim(),
      extraData: {
        'policyType': policyType,
        'summary': summary,
        'updateTime': DateTime.now().toIso8601String(),
      },
    );
  }

  // ===========================================
  // 辅助方法
  // ===========================================

  /// 通用消息发送方法
  Future<void> _sendMessage({
    required MessageType type,
    required String title,
    required String content,
    Map<String, dynamic>? extraData,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final message = Message(
        id: '',
        title: title,
        content: content,
        type: type,
        createdAt: DateTime.now(),
        extraData: extraData ?? {},
      );

      final data = message.toMap();
      data['userId'] = userId;
      await _firestore.collection('messages').add(data);
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  /// 获取第三方登录提供商的显示名称
  String _getProviderDisplayName(String provider) {
    switch (provider) {
      case 'google.com':
        return 'Google';
      case 'apple.com':
        return 'Apple';
      case 'facebook.com':
        return 'Facebook';
      default:
        return provider;
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}月${dateTime.day}日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // ===========================================
  // UI支持方法
  // ===========================================

  /// 获取用户消息流
  Stream<List<Message>> getMessages() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

      return _firestore
          .collection('messages')
        .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => Message.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          
          // 在客户端进行排序，避免复合索引
        messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return messages;
      });
  }

  /// 获取未读消息数量
  Stream<int> getUnreadCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

      return _firestore
          .collection('messages')
        .where('userId', isEqualTo: userId)
          .snapshots()
        .map((snapshot) {
          // 在客户端进行过滤，避免复合索引
          return snapshot.docs
              .where((doc) => doc.data()['isRead'] == false)
              .length;
        });
  }

  /// 标记单个消息为已读
  Future<void> markAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  /// 标记所有消息为已读
  Future<void> markAllAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final unreadMessages = await _firestore
          .collection('messages')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all messages as read: $e');
    }
  }

  /// 删除消息
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  /// 创建示例消息（用于测试和演示）
  Future<void> createSampleMessages() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // 1. 认证与账户管理消息
      await sendWelcomeMessage('测试用户');
      await sendPasswordResetConfirmation();
      await sendProfileUpdateNotification('name', '张三');
      await sendAccountBindingNotification('google.com', true);

      // 2. 课程与学习消息 (需要模拟数据)
      await _sendMessage(
        type: MessageType.courseEnrollment,
        title: '课程报名成功',
        content: '恭喜！小明 已成功报名课程《艺术创意工坊》。请按时参加课程，期待孩子的精彩表现！',
        extraData: {
          'courseName': '艺术创意工坊',
          'childName': '小明',
        },
      );

      await _sendMessage(
        type: MessageType.courseReminder,
        title: '课程即将开始',
        content: '《音乐启蒙天地》将在30分钟后开始。请为孩子做好准备，准时参加课程。',
        extraData: {
          'courseName': '音乐启蒙天地',
        },
      );

      await _sendMessage(
        type: MessageType.courseCompleted,
        title: '课程完成',
        content: '恭喜！小红 已完成《数学启蒙乐园》的学习。课程照片和视频已上传，学习报告正在生成中。',
        extraData: {
          'courseName': '数学启蒙乐园',
          'childName': '小红',
        },
      );

      // 3. 孩子档案管理消息 (需要模拟数据)
      await _sendMessage(
        type: MessageType.childAdded,
        title: '孩子档案创建成功',
        content: '小华的档案已成功创建！现在您可以为小华报名各种有趣的课程了。',
        extraData: {
          'childName': '小华',
        },
      );

      await _sendMessage(
        type: MessageType.childUpdated,
        title: '孩子档案更新成功',
        content: '小李的头像已成功更新。',
        extraData: {
          'childName': '小李',
          'updateType': 'photo',
        },
      );

      // 4. 系统与维护消息
      await sendAppUpdateMessage('2.1.0', ['新增消息分类功能', '优化课程报名流程', '修复已知bug'], false);
      
      await sendMaintenanceMessage(
        DateTime.now().add(const Duration(days: 1)), 
        DateTime.now().add(const Duration(days: 1, hours: 2)), 
        '系统升级优化'
      );

      await sendPolicyUpdateMessage('privacy', '我们更新了数据收集和使用条款，更好地保护您的隐私。');

    } catch (e) {
      print('Error creating sample messages: $e');
      rethrow;
    }
  }
} 