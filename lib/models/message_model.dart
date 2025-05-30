import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  classReminder, // 上课提醒
  classEnd,      // 下课提醒
  general,       // 普通消息
  system,        // 系统消息
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
  });

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
    );
  }
} 