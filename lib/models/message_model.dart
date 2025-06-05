import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  general,
  enrollment,
  
  // 1. 认证与账户管理消息
  welcome,           // 注册成功/欢迎消息
  passwordReset,     // 密码重置确认
  profileUpdate,     // 资料更新通知
  accountBinding,    // 第三方账号绑定/解绑
  
  // 2. 课程与学习消息
  courseEnrollment,  // 课程报名成功（重命名原有的enrollment）
  courseReminder,    // 课程即将开始提醒
  courseEndingSoon,  // 课程即将结束提醒
  courseCompleted,   // 课程完成通知
  courseUpdated,     // 课程内容更新
  courseRecommendation, // 新课程推荐
  
  // 3. 孩子档案管理消息
  childAdded,        // 添加孩子成功
  childUpdated,      // 孩子档案更新
  childDeleted,      // 孩子档案删除确认
  
  // 4. 系统与维护消息
  appUpdate,         // 应用版本更新
  systemMaintenance, // 系统维护通知
  policyUpdate,      // 服务条款/隐私政策更新
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

  // 获取消息类型图标路径
  String get typeIconPath {
    switch (type) {
      // 1. 认证与账户管理消息
      case MessageType.welcome:
      case MessageType.passwordReset:
      case MessageType.profileUpdate:
      case MessageType.accountBinding:
        return 'assets/messages/account_ico.svg';
        
      // 2. 课程与学习消息
      case MessageType.courseEnrollment:
      case MessageType.courseReminder:
      case MessageType.courseEndingSoon:
      case MessageType.courseCompleted:
      case MessageType.courseUpdated:
      case MessageType.courseRecommendation:
        return 'assets/messages/course_ico.svg';
        
      // 3. 孩子档案管理消息
      case MessageType.childAdded:
      case MessageType.childUpdated:
      case MessageType.childDeleted:
        return 'assets/messages/kids_ico.svg';
        
      // 4. 系统与维护消息
      case MessageType.appUpdate:
      case MessageType.systemMaintenance:
      case MessageType.policyUpdate:
        return 'assets/messages/system_ico.svg';
        
      // 默认消息类型
      case MessageType.general:
      case MessageType.enrollment: // 保持向后兼容
      default:
        return 'assets/messages/course_ico.svg';
    }
  }

  // 获取消息类型主颜色
  String get typePrimaryColor {
    switch (type) {
      // 1. 认证与账户管理消息 - 蓝色系
      case MessageType.welcome:
      case MessageType.passwordReset:
      case MessageType.profileUpdate:
      case MessageType.accountBinding:
        return '#3355B2';
        
      // 2. 课程与学习消息 - 绿色系
      case MessageType.courseEnrollment:
      case MessageType.courseReminder:
      case MessageType.courseEndingSoon:
      case MessageType.courseCompleted:
      case MessageType.courseUpdated:
      case MessageType.courseRecommendation:
        return '#5F7930';
        
      // 3. 孩子档案管理消息 - 橙色系
      case MessageType.childAdded:
      case MessageType.childUpdated:
      case MessageType.childDeleted:
        return '#F88400';
        
      // 4. 系统与维护消息 - 红色系
      case MessageType.appUpdate:
      case MessageType.systemMaintenance:
      case MessageType.policyUpdate:
        return '#E84155';
        
      // 默认消息类型
      case MessageType.general:
      case MessageType.enrollment: // 保持向后兼容
      default:
        return '#5F7930'; // 默认使用课程绿色
    }
  }

  // 获取消息类型背景颜色
  String get typeBackgroundColor {
    switch (type) {
      // 1. 认证与账户管理消息 - 蓝色背景
      case MessageType.welcome:
      case MessageType.passwordReset:
      case MessageType.profileUpdate:
      case MessageType.accountBinding:
        return '#D6E9F4';
        
      // 2. 课程与学习消息 - 绿色背景
      case MessageType.courseEnrollment:
      case MessageType.courseReminder:
      case MessageType.courseEndingSoon:
      case MessageType.courseCompleted:
      case MessageType.courseUpdated:
      case MessageType.courseRecommendation:
        return '#ECF2D2';
        
      // 3. 孩子档案管理消息 - 橙色背景
      case MessageType.childAdded:
      case MessageType.childUpdated:
      case MessageType.childDeleted:
        return '#FFF3D9';
        
      // 4. 系统与维护消息 - 红色背景
      case MessageType.appUpdate:
      case MessageType.systemMaintenance:
      case MessageType.policyUpdate:
        return '#FFE4E4';
        
      // 默认消息类型
      case MessageType.general:
      case MessageType.enrollment: // 保持向后兼容
      default:
        return '#ECF2D2'; // 默认使用课程绿色背景
    }
  }

  // 获取消息分类名称
  String getMessageCategoryName(String languageCode) {
    switch (type) {
      // 1. 认证与账户管理消息
      case MessageType.welcome:
      case MessageType.passwordReset:
      case MessageType.profileUpdate:
      case MessageType.accountBinding:
        return languageCode == 'zh' ? '认证与帐户管理讯息' : 
               languageCode == 'en' ? 'Authentication & Account Management' : 
               '認證與帳戶管理訊息'; // 繁体中文
        
      // 2. 课程与学习消息
      case MessageType.courseEnrollment:
      case MessageType.courseReminder:
      case MessageType.courseEndingSoon:
      case MessageType.courseCompleted:
      case MessageType.courseUpdated:
      case MessageType.courseRecommendation:
        return languageCode == 'zh' ? '课程与学习讯息' : 
               languageCode == 'en' ? 'Course & Learning Messages' : 
               '課程與學習訊息'; // 繁体中文
        
      // 3. 孩子档案管理消息
      case MessageType.childAdded:
      case MessageType.childUpdated:
      case MessageType.childDeleted:
        return languageCode == 'zh' ? '孩子档案管理讯息' : 
               languageCode == 'en' ? 'Child Profile Management' : 
               '孩子檔案管理訊息'; // 繁体中文
        
      // 4. 系统与维护消息
      case MessageType.appUpdate:
      case MessageType.systemMaintenance:
      case MessageType.policyUpdate:
        return languageCode == 'zh' ? '系统与维护讯息' : 
               languageCode == 'en' ? 'System & Maintenance Messages' : 
               '系統與維護訊息'; // 繁体中文
        
      // 默认消息类型
      case MessageType.general:
      case MessageType.enrollment: // 保持向后兼容
      default:
        return languageCode == 'zh' ? '一般讯息' : 
               languageCode == 'en' ? 'General Messages' : 
               '一般訊息'; // 繁体中文
    }
  }

  // 获取消息类型图标 (保留用于向后兼容)
  String get typeIcon {
    switch (type) {
      // 认证与账户管理
      case MessageType.welcome:
        return '👋';
      case MessageType.passwordReset:
        return '🔐';
      case MessageType.profileUpdate:
        return '👤';
      case MessageType.accountBinding:
        return '🔗';
        
      // 课程与学习
      case MessageType.courseEnrollment:
      case MessageType.enrollment: // 向后兼容
        return '🎉';
      case MessageType.courseReminder:
        return '🔔';
      case MessageType.courseEndingSoon:
        return '⏰';
      case MessageType.courseCompleted:
        return '🏆';
      case MessageType.courseUpdated:
        return '📝';
      case MessageType.courseRecommendation:
        return '💡';
        
      // 孩子档案管理
      case MessageType.childAdded:
        return '👶';
      case MessageType.childUpdated:
        return '✏️';
      case MessageType.childDeleted:
        return '🗑️';
        
      // 系统与维护
      case MessageType.appUpdate:
        return '📱';
      case MessageType.systemMaintenance:
        return '⚙️';
      case MessageType.policyUpdate:
        return '📋';
        
      // 默认
      case MessageType.general:
      default:
        return '💬';
    }
  }

  // 获取消息类型颜色 (保留用于向后兼容，使用新的主颜色)
  String get typeColor => typePrimaryColor;

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