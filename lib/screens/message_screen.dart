import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../styles/app_text_styles.dart';
import '../l10n/app_localizations.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';
import '../providers/theme_provider.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final MessageService _messageService = MessageService();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh() async {
    // 模拟刷新延迟
    await Future.delayed(const Duration(milliseconds: 1000));
    _refreshController.refreshCompleted();
  }

  Future<void> _markAllAsRead() async {
    try {
      await _messageService.markAllAsRead();
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.allMessagesMarkedAsRead),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.operationFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _messageService.deleteMessage(messageId);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.messageDeleted),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.deleteFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createSampleMessages() async {
    try {
      await _messageService.createSampleMessages();
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.sampleMessagesCreated),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.createFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentThemeData;
    
    return Scaffold(
      backgroundColor: currentTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              l10n.messages,
              style: AppTextStyles.titleLarge.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            StreamBuilder<int>(
              stream: _messageService.getUnreadCount(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                if (unreadCount == 0) return const SizedBox.shrink();
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: currentTheme.backgroundColor,
        foregroundColor: currentTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'create_samples') {
                _createSampleMessages();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'create_samples',
                child: Text(l10n.createSampleMessages),
              ),
              // 这里可以添加更多选项
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 60),
        child: StreamBuilder<List<Message>>(
          stream: _messageService.getMessages(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      l10n.loadMessagesFailed,
                      style: AppTextStyles.bodyLarge.copyWith(color: Colors.red[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final messages = snapshot.data ?? [];

            if (messages.isEmpty) {
              return _buildEmptyState(l10n, currentTheme);
            }

            return ListView.separated(
              itemCount: messages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageItem(message, l10n, currentTheme);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, dynamic currentTheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noMessages,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.yourMessagesWillAppearHere,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createSampleMessages,
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('创建示例消息'),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(Message message, AppLocalizations l10n, dynamic currentTheme) {
    final isUnread = !message.isRead;
    final currentLanguage = Localizations.localeOf(context).languageCode;
    
    // 获取本地化的标题和内容
    final localizedTitle = message.getLocalizedTitle(currentLanguage);
    final localizedContent = message.getLocalizedContent(currentLanguage);
    
    // 获取消息分类名称
    final categoryName = message.getMessageCategoryName(currentLanguage);
    
    // 解析颜色值
    final primaryColor = Color(int.parse(message.typePrimaryColor.substring(1), radix: 16) + 0xFF000000);
    final backgroundColor = Color(int.parse(message.typeBackgroundColor.substring(1), radix: 16) + 0xFF000000);

    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        final l10n = AppLocalizations.of(context)!;
        return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.confirmDelete),
            content: Text(l10n.confirmDeleteMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) {
        _deleteMessage(message.id);
      },
      child: GestureDetector(
        onTap: () async {
          if (isUnread) {
            await _messageService.markAsRead(message.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isUnread ? Colors.white : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            // 移除边框变化，使用背景色区分已读/未读
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isUnread ? 0.08 : 0.03),
                blurRadius: isUnread ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 消息图标（小图标）
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isUnread ? backgroundColor.withOpacity(0.8) : backgroundColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SvgPicture.asset(
                    message.typeIconPath,
                    colorFilter: ColorFilter.mode(
                      isUnread ? primaryColor : primaryColor.withOpacity(0.6),
                      BlendMode.srcIn,
                    ),
                    placeholderBuilder: (context) => Icon(
                      _getFallbackIcon(message.type),
                      color: isUnread ? primaryColor : primaryColor.withOpacity(0.6),
                      size: 20,
                    ),
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        _getFallbackIcon(message.type),
                        color: isUnread ? primaryColor : primaryColor.withOpacity(0.6),
                        size: 20,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // 消息内容区域
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题和时间行
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              localizedTitle,
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                                color: isUnread ? Colors.black87 : Colors.grey[600],
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            message.getFormattedTime(currentLanguage),
                            style: TextStyle(
                              color: isUnread ? Colors.grey[500] : Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // 消息内容
                      Text(
                        localizedContent,
                        style: TextStyle(
                          color: isUnread ? Colors.black54 : Colors.grey[500],
                          fontSize: 13,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // 额外信息（如果有）
                      if (message.extraData != null && message.extraData!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getExtraDataText(message, l10n),
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // 未读标识
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _getExtraDataText(Message message, AppLocalizations l10n) {
    final extraData = message.extraData!;
    
    if (extraData['courseName'] != null) {
      return '${l10n.courseInfo}: ${extraData['courseName']}';
    } else if (extraData['childName'] != null) {
      return '相关孩子: ${extraData['childName']}';
    } else if (extraData['version'] != null) {
      return '版本: ${extraData['version']}';
    } else if (extraData['updateType'] != null) {
      return '更新类型: ${extraData['updateType']}';
    }
    
    return '详细信息可用';
  }

  Color _getTypeColor(MessageType type) {
    // 创建临时消息对象以获取颜色
    final tempMessage = Message(
      id: '',
      title: '',
      content: '',
      type: type,
      createdAt: DateTime.now(),
    );
    
    return Color(int.parse(tempMessage.typePrimaryColor.substring(1), radix: 16) + 0xFF000000);
  }

  IconData _getFallbackIcon(MessageType type) {
    switch (type) {
      // 1. 认证与账户管理消息
      case MessageType.welcome:
        return Icons.person_add;
      case MessageType.passwordReset:
        return Icons.lock_reset;
      case MessageType.profileUpdate:
        return Icons.person;
      case MessageType.accountBinding:
        return Icons.link;
        
      // 2. 课程与学习消息
      case MessageType.courseEnrollment:
      case MessageType.enrollment: // 向后兼容
        return Icons.school;
      case MessageType.courseReminder:
        return Icons.notifications;
      case MessageType.courseEndingSoon:
        return Icons.schedule;
      case MessageType.courseCompleted:
        return Icons.task_alt;
      case MessageType.courseUpdated:
        return Icons.update;
      case MessageType.courseRecommendation:
        return Icons.recommend;
        
      // 3. 孩子档案管理消息
      case MessageType.childAdded:
        return Icons.child_care;
      case MessageType.childUpdated:
        return Icons.edit;
      case MessageType.childDeleted:
        return Icons.delete;
        
      // 4. 系统与维护消息
      case MessageType.appUpdate:
        return Icons.system_update;
      case MessageType.systemMaintenance:
        return Icons.build;
      case MessageType.policyUpdate:
        return Icons.policy;
        
      // 默认
      case MessageType.general:
      default:
        return Icons.message;
    }
  }
} 