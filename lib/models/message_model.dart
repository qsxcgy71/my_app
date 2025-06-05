import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  classReminder, // 上课提醒
  classEnd,      // 下课提醒
  general,       // 普通消息
  system,        // 系统消息
  enrollment,    // 报名成功
}

class Message {
  final String id;
  final String title;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final bool isRead;
  final String? lessonId; // 关联的课程ID
  final String? imageUrl; // 消息图片
  final Map<String, dynamic>? extraData; // 额外数据
  final String? messageKey; // 消息类型键，用于国际化
  final Map<String, String>? messageParams; // 消息参数

  Message({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.lessonId,
    this.imageUrl,
    this.extraData,
    this.messageKey,
    this.messageParams,
  });

  // 根据语言获取本地化标题
  String getLocalizedTitle(String languageCode) {
    if (messageKey == null) return title;
    
    switch (messageKey!) {
      case 'welcome':
        return languageCode == 'zh' ? '欢迎使用Kids Profile！' : 'Welcome to Kids Profile!';
      case 'class_reminder':
        return languageCode == 'zh' ? '课程提醒' : 'Class Reminder';
      case 'class_completed':
        return languageCode == 'zh' ? '课程完成' : 'Class Completed';
      case 'class_starting_soon':
        return languageCode == 'zh' ? '课程即将开始' : 'Class Starting Soon';
      case 'class_ending_soon':
        return languageCode == 'zh' ? '课程即将结束' : 'Class Ending Soon';
      default:
        return title;
    }
  }

  // 根据语言获取本地化内容
  String getLocalizedContent(String languageCode) {
    if (messageKey == null) return content;
    
    final courseName = messageParams?['courseName'] ?? '';
    
    switch (messageKey!) {
      case 'welcome':
        return languageCode == 'zh' 
            ? '感谢您选择我们的儿童教育平台，让我们一起为孩子创造美好的学习体验。'
            : 'Thank you for choosing our children\'s education platform. Let\'s create wonderful learning experiences for your child together.';
      case 'class_reminder':
        return languageCode == 'zh' 
            ? '您为孩子预订的《$courseName》课程将在明天下午2:00开始，请准时参加。'
            : 'The "$courseName" class you booked for your child will start tomorrow at 2:00 PM. Please attend on time.';
      case 'class_completed':
        return languageCode == 'zh' 
            ? '恭喜！您的孩子已完成《$courseName》课程，可以查看课程总结与作品展示。'
            : 'Congratulations! Your child has completed the "$courseName" course. You can view the course summary and artwork showcase.';
      case 'class_starting_soon':
        return languageCode == 'zh' 
            ? '课程《$courseName》即将在15分钟后开始，请及时参加。'
            : 'The class "$courseName" will start in 15 minutes. Please join on time.';
      case 'class_ending_soon':
        return languageCode == 'zh' 
            ? '课程《$courseName》即将在15分钟后结束，请做好接送准备。'
            : 'The class "$courseName" will end in 15 minutes. Please prepare for pickup.';
      default:
        return content;
    }
  }

  // 获取消息类型图标
  String get typeIcon {
    switch (type) {
      case MessageType.classReminder:
        return '🔔';
      case MessageType.classEnd:
        return '🏁';
      case MessageType.general:
        return '💬';
      case MessageType.system:
        return '⚙️';
      case MessageType.enrollment:
        return '🎉';
    }
  }

  // 获取消息类型颜色
  String get typeColor {
    switch (type) {
      case MessageType.classReminder:
        return '#FF9800'; // 橙色
      case MessageType.classEnd:
        return '#4CAF50'; // 绿色
      case MessageType.general:
        return '#2196F3'; // 蓝色
      case MessageType.system:
        return '#9E9E9E'; // 灰色
      case MessageType.enrollment:
        return '#E91E63'; // 粉色
    }
  }

  // 格式化时间显示
  String getFormattedTime(String locale) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return locale == 'zh' ? '刚刚' : 'Just now';
    } else if (difference.inMinutes < 60) {
      return locale == 'zh' 
          ? '${difference.inMinutes}分钟前' 
          : '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return locale == 'zh' 
          ? '${difference.inHours}小时前' 
          : '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return locale == 'zh' 
          ? '${difference.inDays}天前' 
          : '${difference.inDays} days ago';
    } else {
      return locale == 'zh' 
          ? '${createdAt.month}月${createdAt.day}日'
          : '${_getMonthName(createdAt.month)} ${createdAt.day}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // 保留原有方法以保持兼容性，默认使用中文
  String get formattedTime => getFormattedTime('zh');

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'lessonId': lessonId,
      'imageUrl': imageUrl,
      'extraData': extraData,
      'messageKey': messageKey,
      'messageParams': messageParams,
      'userId': '', // 这将在保存时设置
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String? ?? '',
      title: map['title'] as String,
      content: map['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MessageType.general,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String).toLocal(),
      isRead: map['isRead'] as bool? ?? false,
      lessonId: map['lessonId'] as String?,
      imageUrl: map['imageUrl'] as String?,
      extraData: map['extraData'] as Map<String, dynamic>?,
      messageKey: map['messageKey'] as String?,
      messageParams: map['messageParams'] != null
          ? Map<String, String>.from(map['messageParams'])
          : null,
    );
  }

  Message copyWith({
    String? id,
    String? title,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    bool? isRead,
    String? lessonId,
    String? imageUrl,
    Map<String, dynamic>? extraData,
    String? messageKey,
    Map<String, String>? messageParams,
  }) {
    return Message(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      lessonId: lessonId ?? this.lessonId,
      imageUrl: imageUrl ?? this.imageUrl,
      extraData: extraData ?? this.extraData,
      messageKey: messageKey ?? this.messageKey,
      messageParams: messageParams ?? this.messageParams,
    );
  }
} 