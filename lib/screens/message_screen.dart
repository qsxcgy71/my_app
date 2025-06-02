import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
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
            Text(l10n.messages, style: AppTextStyles.titleLarge),
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
          StreamBuilder<int>(
            stream: _messageService.getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: currentTheme.primaryColor),
                onSelected: (value) {
                  switch (value) {
                    case 'mark_all_read':
                      if (unreadCount > 0) _markAllAsRead();
                      break;
                    case 'create_sample':
                      _createSampleMessages();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    enabled: unreadCount > 0,
                    child: Row(
                      children: [
                        Icon(Icons.done_all, 
                             color: unreadCount > 0 ? currentTheme.primaryColor : Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          l10n.markAllAsRead,
                          style: TextStyle(
                            color: unreadCount > 0 ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'create_sample',
                    child: Row(
                      children: [
                        Icon(Icons.add_comment, color: currentTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(l10n.createSampleMessages),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Message>>(
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

          return SmartRefresher(
            controller: _refreshController,
            enablePullDown: true,
            enablePullUp: false,
            onRefresh: _onRefresh,
            header: WaterDropHeader(
              complete: Text('Updated!', style: AppTextStyles.bodyMedium),
              failed: Text('Update Failed', style: AppTextStyles.bodyMedium),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildMessageCard(messages[index], currentTheme);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, dynamic currentTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  currentTheme.primaryColor.withOpacity(0.1),
                  currentTheme.secondaryColor.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.mail_outline,
              size: 48,
              color: currentTheme.primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noMessages,
            style: AppTextStyles.titleMedium.copyWith(
              color: currentTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.yourMessagesWillAppearHere,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _createSampleMessages,
            icon: const Icon(Icons.add, size: 20),
            label: Text(l10n.createSampleMessages),
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
    );
  }

  Widget _buildMessageCard(Message message, dynamic currentTheme) {
    final isUnread = !message.isRead;
    final l10n = AppLocalizations.of(context)!;
    
    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
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
          builder: (context) => AlertDialog(
            title: Text(l10n.confirmDelete),
            content: Text(l10n.confirmDeleteMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isUnread 
                ? Border.all(color: currentTheme.primaryColor.withOpacity(0.3), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 消息类型图标
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTypeColor(message.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.typeIcon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                message.title, // 直接使用message.title
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                  color: isUnread ? Colors.black87 : Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.getFormattedTime(Localizations.localeOf(context).languageCode),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message.content, // 直接使用message.content
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isUnread ? Colors.black87 : Colors.grey[600],
                  fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (message.extraData != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${l10n.courseInfo}: ${message.extraData!['courseName'] ?? ''}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(MessageType type) {
    switch (type) {
      case MessageType.classReminder:
        return Colors.orange;
      case MessageType.classEnd:
        return Colors.green;
      case MessageType.general:
        return Colors.blue;
      case MessageType.system:
        return Colors.grey;
    }
  }
} 