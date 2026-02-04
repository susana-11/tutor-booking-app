import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_models.dart';
import 'voice_message_player.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onForward;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for received messages
            if (!isMe && showAvatar) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  message.senderName.isNotEmpty 
                      ? message.senderName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ] else if (!isMe) ...[
              const SizedBox(width: 40), // Space for avatar alignment
            ],
            
            // Message content
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Reply preview
                  if (message.replyTo != null) _buildReplyPreview(),
                  
                  // Main message bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _getBubbleColor(),
                      borderRadius: _getBorderRadius(),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sender name for group chats
                        if (!isMe && message.senderName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              message.senderName,
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        
                        // Message content
                        _buildMessageContent(),
                        
                        // Message metadata
                        const SizedBox(height: 4),
                        _buildMessageMetadata(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Spacing for sent messages
            if (isMe) const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    final replyTo = message.replyTo!;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: AppTheme.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyTo.senderName,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            replyTo.content,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return _buildTextContent();
      case MessageType.image:
        return _buildImageContent();
      case MessageType.document:
        return _buildDocumentContent();
      case MessageType.audio:
      case MessageType.voice:
        return _buildAudioContent();
      case MessageType.video:
        return _buildVideoContent();
      case MessageType.system:
        return _buildSystemContent();
      case MessageType.booking:
        return _buildBookingContent();
      case MessageType.payment:
        return _buildPaymentContent();
      case MessageType.call:
        return _buildCallContent();
      default:
        return _buildTextContent();
    }
  }

  Widget _buildTextContent() {
    return SelectableText(
      message.content,
      style: TextStyle(
        color: isMe ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
    );
  }

  Widget _buildImageContent() {
    // Get image URL and convert to absolute URL
    final imageUrl = message.attachments.isNotEmpty 
        ? message.attachments.first.url 
        : '';
    
    final fullImageUrl = imageUrl.startsWith('http') 
        ? imageUrl 
        : 'https://tutor-app-backend-wtru.onrender.com$imageUrl';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.attachments.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              fullImageUrl,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print('❌ Image load error: $error');
                print('❌ Image URL: $fullImageUrl');
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 50),
                      SizedBox(height: 8),
                      Text('Failed to load image', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ),
        if (message.content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            message.content,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentContent() {
    final attachment = message.attachments.isNotEmpty 
        ? message.attachments.first 
        : null;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isMe ? Colors.white : Colors.grey[100])?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getDocumentIcon(attachment?.mimeType),
            color: isMe ? Colors.white70 : Colors.grey[600],
            size: 32,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment?.name ?? 'Document',
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (attachment != null)
                  Text(
                    _formatFileSize(attachment.size),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.download,
            color: isMe ? Colors.white70 : Colors.grey[600],
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioContent() {
    // Get audio URL from attachments
    final audioUrl = message.attachments.isNotEmpty 
        ? message.attachments.first.url 
        : '';
    
    // Convert relative URL to absolute URL
    final fullAudioUrl = audioUrl.startsWith('http') 
        ? audioUrl 
        : 'https://tutor-app-backend-wtru.onrender.com$audioUrl';
    
    final duration = message.attachments.isNotEmpty && message.attachments.first.duration != null
        ? Duration(seconds: message.attachments.first.duration!)
        : null;

    if (audioUrl.isEmpty) {
      return Text(
        'Voice message',
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
      );
    }

    return VoiceMessagePlayer(
      audioUrl: fullAudioUrl,
      isSentByMe: isMe,
      duration: duration,
    );
  }

  Widget _buildVideoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 200,
                height: 150,
                color: Colors.black,
                child: message.attachments.isNotEmpty && 
                       message.attachments.first.thumbnail != null
                    ? Image.network(
                        message.attachments.first.thumbnail!,
                        fit: BoxFit.cover,
                      )
                    : const Icon(
                        Icons.video_library,
                        color: Colors.white,
                        size: 50,
                      ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (message.content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            message.content,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSystemContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message.content,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBookingContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Session Booking',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.content,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[700],
                    side: BorderSide(color: Colors.blue[300]!),
                  ),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Payment',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCallContent() {
    final callData = message.callData;
    if (callData == null) return _buildTextContent();

    final callType = callData['callType'] ?? 'voice';
    final status = callData['status'] ?? 'ended';
    final duration = callData['duration'];

    // Determine icon and color based on call type and status
    IconData icon;
    Color color;
    String statusText;

    if (callType == 'video') {
      icon = Icons.videocam;
    } else {
      icon = Icons.call;
    }

    switch (status) {
      case 'declined':
        color = Colors.red;
        statusText = 'Declined';
        icon = Icons.call_end;
        break;
      case 'missed':
        color = Colors.orange;
        statusText = 'Missed';
        icon = Icons.phone_missed;
        break;
      case 'ended':
        color = Colors.green;
        if (duration != null && duration > 0) {
          final minutes = duration ~/ 60;
          final seconds = duration % 60;
          statusText = '${minutes}:${seconds.toString().padLeft(2, '0')}';
        } else {
          statusText = 'Ended';
        }
        break;
      default:
        color = Colors.blue;
        statusText = 'Call';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                callType == 'video' ? 'Video Call' : 'Voice Call',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageMetadata() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Edited indicator
        if (message.isEdited)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              'edited',
              style: TextStyle(
                color: isMe ? Colors.white60 : Colors.grey[500],
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        
        // Timestamp
        Text(
          _formatTimestamp(message.createdAt),
          style: TextStyle(
            color: isMe ? Colors.white60 : Colors.grey[500],
            fontSize: 10,
          ),
        ),
        
        // Message status for sent messages
        if (isMe) ...[
          const SizedBox(width: 4),
          _buildMessageStatus(),
        ],
      ],
    );
  }

  Widget _buildMessageStatus() {
    IconData icon;
    Color color;
    
    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = Colors.white60;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.white60;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.white60;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.blue[300]!;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = Colors.red[300]!;
        break;
    }
    
    return Icon(icon, size: 12, color: color);
  }

  Color _getBubbleColor() {
    if (message.type == MessageType.system) {
      return Colors.transparent;
    }
    return isMe ? AppTheme.primaryColor : Colors.grey[100]!;
  }

  BorderRadius _getBorderRadius() {
    if (message.type == MessageType.system) {
      return BorderRadius.circular(16);
    }
    
    return BorderRadius.circular(18).copyWith(
      bottomRight: isMe ? const Radius.circular(4) : null,
      bottomLeft: !isMe ? const Radius.circular(4) : null,
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  IconData _getDocumentIcon(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file;
    
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('document')) return Icons.description;
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) return Icons.table_chart;
    if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) return Icons.slideshow;
    if (mimeType.contains('zip') || mimeType.contains('rar')) return Icons.archive;
    
    return Icons.insert_drive_file;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showMessageOptions(BuildContext context) {
    final options = <String, String>{};
    
    options['copy'] = 'Copy';
    if (onReply != null) options['reply'] = 'Reply';
    if (onForward != null) options['forward'] = 'Forward';
    if (onEdit != null) options['edit'] = 'Edit';
    if (onDelete != null) options['delete'] = 'Delete';
    options['info'] = 'Info';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ...options.entries.map((entry) => ListTile(
              leading: Icon(_getOptionIcon(entry.key)),
              title: Text(entry.value),
              onTap: () {
                Navigator.pop(context);
                _handleMessageOption(entry.key);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getOptionIcon(String option) {
    switch (option) {
      case 'copy': return Icons.copy;
      case 'reply': return Icons.reply;
      case 'edit': return Icons.edit;
      case 'delete': return Icons.delete;
      case 'forward': return Icons.forward;
      case 'info': return Icons.info;
      default: return Icons.more_horiz;
    }
  }

  void _handleMessageOption(String option) {
    switch (option) {
      case 'copy':
        Clipboard.setData(ClipboardData(text: message.content));
        break;
      case 'reply':
        onReply?.call();
        break;
      case 'forward':
        onForward?.call();
        break;
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
      case 'info':
        // TODO: Show message info
        break;
    }
  }
}