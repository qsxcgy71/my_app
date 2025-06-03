import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/lesson_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // 获取用户消息
  Stream<List<Message>> getMessages() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('messages')
          .where('userId', isEqualTo: _currentUserId)
          // 暂时移除orderBy以避免索引问题，在客户端排序
          .snapshots()
          .map((snapshot) {
        final messages = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Message.fromMap(data);
        }).toList();
        
        // 在客户端按创建时间排序
        messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return messages;
      });
    } catch (e) {
      print('Error getting messages: $e');
      return Stream.value([]);
    }
  }

  // 获取未读消息数量
  Stream<int> getUnreadCount() {
    if (_currentUserId == null) {
      return Stream.value(0);
    }

    try {
      return _firestore
          .collection('messages')
          .where('userId', isEqualTo: _currentUserId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      print('Error getting unread count: $e');
      return Stream.value(0);
    }
  }

  // 标记消息为已读
  Future<void> markAsRead(String messageId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking message as read: $e');
      rethrow;
    }
  }

  // 一键标记所有消息为已读
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      final unreadMessages = await _firestore
          .collection('messages')
          .where('userId', isEqualTo: _currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all messages as read: $e');
      rethrow;
    }
  }

  // 删除消息
  Future<void> deleteMessage(String messageId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  // 创建课程提醒消息
  Future<void> createClassReminder(Lesson lesson, {bool isEndReminder = false}) async {
    if (_currentUserId == null) return;

    try {
      final message = Message(
        id: '',
        title: isEndReminder ? '课程即将结束' : '课程即将开始',
        content: isEndReminder 
            ? '课程《${lesson.title}》即将在15分钟后结束，请做好接送准备。'
            : '课程《${lesson.title}》即将在15分钟后开始，请及时参加。',
        type: isEndReminder ? MessageType.classEnd : MessageType.classReminder,
        messageKey: isEndReminder ? 'class_ending_soon' : 'class_starting_soon',
        messageParams: {
          'courseName': lesson.courseName ?? lesson.title,
        },
        createdAt: DateTime.now(),
        lessonId: lesson.id,
        extraData: {
          'lessonTitle': lesson.title,
          'lessonTime': lesson.timeString,
          'courseName': lesson.courseName,
        },
      );

      final data = message.toMap();
      data['userId'] = _currentUserId;

      await _firestore.collection('messages').add(data);
    } catch (e) {
      print('Error creating class reminder: $e');
      rethrow;
    }
  }

  // 创建课程完成消息
  Future<void> createClassCompletedMessage(String courseName) async {
    if (_currentUserId == null) return;

    try {
      final message = Message(
        id: '',
        title: '课程完成',
        content: '恭喜！您的孩子已完成《$courseName》课程，可以查看课程总结与作品展示。',
        type: MessageType.general,

        createdAt: DateTime.now(),
        extraData: {
          'courseName': courseName,
        },
      );

      final data = message.toMap();
      data['userId'] = _currentUserId;

      await _firestore.collection('messages').add(data);
    } catch (e) {
      print('Error creating class completed message: $e');
      rethrow;
    }
  }

  // 创建一般消息
  Future<void> createMessage({
    required String title,
    required String content,
    MessageType type = MessageType.general,
    String? lessonId,
    String? imageUrl,
    Map<String, dynamic>? extraData,
  }) async {
    if (_currentUserId == null) return;

    try {
      final message = Message(
        id: '',
        title: title,
        content: content,
        type: type,
        createdAt: DateTime.now(),
        lessonId: lessonId,
        imageUrl: imageUrl,
        extraData: extraData,
      );

      final data = message.toMap();
      data['userId'] = _currentUserId;

      await _firestore.collection('messages').add(data);
    } catch (e) {
      print('Error creating message: $e');
      rethrow;
    }
  }

  // 批量创建示例消息（用于测试）
  Future<void> createSampleMessages() async {
    if (_currentUserId == null) return;

    final sampleMessages = [
      Message(
        id: '',
        title: '欢迎使用Kids Profile！',
        content: '感谢您选择我们的儿童教育平台，让我们一起为孩子创造美好的学习体验。',
        type: MessageType.system,
        messageKey: 'welcome',
        createdAt: DateTime.now(),
      ),
      Message(
        id: '',
        title: '课程提醒',
        content: '您为孩子预订的《动物世界探索》课程将在明天下午2:00开始，请准时参加。',
        type: MessageType.classReminder,
        messageKey: 'class_reminder',
        messageParams: {
          'courseName': '动物世界探索',
        },
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        extraData: {
          'courseName': '动物世界探索',
        },
      ),
      Message(
        id: '',
        title: '课程完成',
        content: '恭喜！您的孩子已完成《创意绘画基础》课程，可以查看课程总结和作品展示。',
        type: MessageType.general,
        messageKey: 'class_completed',
        messageParams: {
          'courseName': '创意绘画基础',
        },
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        extraData: {
          'courseName': '创意绘画基础',
        },
      ),
    ];

    try {
      for (final message in sampleMessages) {
        final data = message.toMap();
        data['userId'] = _currentUserId;
        await _firestore.collection('messages').add(data);
      }
    } catch (e) {
      print('Error creating sample messages: $e');
    }
  }
} 