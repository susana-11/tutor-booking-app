import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../../../core/theme/app_theme.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/call_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_models.dart';
import '../../call/models/call_models.dart';
import '../../call/screens/voice_call_screen.dart';
import '../../call/screens/video_call_screen.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/voice_recorder.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final String? subject;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    this.subject,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  final ChatService _chatService = ChatService();
  final SocketService _socketService = SocketService();
  final CallService _callService = CallService();
  
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  bool _isOnline = false;
  bool _isTyping = false;
  String _typingUser = '';
  bool _isRecording = false;
  bool _isSending = false;
  
  Timer? _typingTimer;
  StreamSubscription? _newMessageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _onlineStatusSubscription;
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  int _currentPage = 1;
  static const int _messagesPerPage = 50;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadMessages();
    _setupRealtimeListeners();
    _markAsRead();
    
    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
    
    // Setup message input listener for typing indicators
    _messageController.addListener(_onMessageChanged);
  }

  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  void _setupRealtimeListeners() {
    // Listen for new messages
    _newMessageSubscription = _chatService.newMessageStream.listen((message) {
      if (message.conversationId == widget.conversationId) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
        _markAsRead();
      }
    });

    // Listen for typing indicators
    _typingSubscription = _chatService.typingStream.listen((typing) {
      if (typing.conversationId == widget.conversationId && 
          typing.userId != context.read<AuthProvider>().user?.id) {
        setState(() {
          _isTyping = true;
          _typingUser = typing.userName;
        });
        
        // Auto-hide typing indicator after 3 seconds
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isTyping = false;
              _typingUser = '';
            });
          }
        });
      }
    });

    // Listen for online status
    _onlineStatusSubscription = _chatService.onlineStatusStream.listen((statusMap) {
      final isOnline = statusMap[widget.participantId] ?? false;
      if (_isOnline != isOnline) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
  }

  Future<void> _loadMessages({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMoreMessages = true;
      });
    }

    try {
      final response = await _chatService.getMessages(
        conversationId: widget.conversationId,
        page: _currentPage,
        limit: _messagesPerPage,
        refresh: refresh,
      );

      if (response.success) {
        setState(() {
          if (refresh) {
            _messages = response.data!;
          } else {
            _messages.insertAll(0, response.data!);
          }
          _hasMoreMessages = response.data!.length == _messagesPerPage;
          _isLoading = false;
          _isLoadingMore = false;
        });

        if (refresh) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      _showError('Failed to load messages: $e');
    }
  }

  void _onScroll() {
    // Load more messages when scrolled to top
    if (_scrollController.position.pixels <= 100 && 
        !_isLoadingMore && 
        _hasMoreMessages) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });
      _loadMessages();
    }

    // Show/hide scroll to bottom FAB
    if (_scrollController.position.pixels > 200) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  void _onMessageChanged() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      _chatService.startTyping(widget.conversationId);
      setState(() => _isTyping = true);
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _chatService.stopTyping(widget.conversationId);
        setState(() => _isTyping = false);
      }
    });
  }

  Future<void> _sendMessage({
    String? content,
    MessageType type = MessageType.text,
    List<MessageAttachment> attachments = const [],
  }) async {
    final messageContent = content ?? _messageController.text.trim();
    if (messageContent.isEmpty && attachments.isEmpty) return;

    // Clear input immediately for better UX
    if (content == null) {
      _messageController.clear();
    }

    // Stop typing indicator
    _chatService.stopTyping(widget.conversationId);
    setState(() => _isTyping = false);

    try {
      final response = await _chatService.sendMessage(
        conversationId: widget.conversationId,
        content: messageContent,
        type: type,
        attachments: attachments,
      );

      if (response.success) {
        _scrollToBottom();
      } else {
        // Log but don't show error - message might still be sent via API
        print('⚠️ Send message response not successful: ${response.error}');
        // Still scroll in case message was added
        _scrollToBottom();
      }
    } catch (e) {
      print('❌ Send message error: $e');
      _showError('Failed to send message. Please check your connection.');
    }
  }

  Future<void> _markAsRead() async {
    try {
      await _chatService.markAsRead(conversationId: widget.conversationId);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessagesList(),
          ),
          
          // Typing Indicator
          if (_isTyping && _typingUser.isNotEmpty)
            TypingIndicatorWidget(userName: _typingUser),
          
          // Message Input
          _buildMessageInput(),
        ],
      ),
      floatingActionButton: _buildScrollToBottomFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 1,
      title: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: widget.participantAvatar != null
                    ? NetworkImage(widget.participantAvatar!)
                    : null,
                child: widget.participantAvatar == null
                    ? Text(
                        widget.participantName.isNotEmpty
                            ? widget.participantName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              // Online indicator
              if (_isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(width: 12),
          
          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.participantName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.subject != null)
                  Text(
                    widget.subject!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.white70,
                    ),
                  )
                else
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Video call
        IconButton(
          onPressed: _makeVideoCall,
          icon: const Icon(Icons.videocam),
          tooltip: 'Video Call',
        ),
        
        // Voice call
        IconButton(
          onPressed: _makeVoiceCall,
          icon: const Icon(Icons.call),
          tooltip: 'Voice Call',
        ),
        
        // More options
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 12),
                  Text('View Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'book_session',
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 20),
                  SizedBox(width: 12),
                  Text('Book Session'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search, size: 20),
                  SizedBox(width: 12),
                  Text('Search Messages'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear_chat',
              child: Row(
                children: [
                  Icon(Icons.clear_all, size: 20),
                  SizedBox(width: 12),
                  Text('Clear Chat'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.report, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Report', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return RefreshIndicator(
      onRefresh: () => _loadMessages(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0 && _isLoadingMore) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final messageIndex = _isLoadingMore ? index - 1 : index;
          final message = _messages[messageIndex];
          final isMe = message.senderId == context.read<AuthProvider>().user?.id;
          
          // Show date separator
          bool showDateSeparator = false;
          if (messageIndex == 0 || 
              !_isSameDay(message.createdAt, _messages[messageIndex - 1].createdAt)) {
            showDateSeparator = true;
          }
          
          return Column(
            children: [
              if (showDateSeparator) _buildDateSeparator(message.createdAt),
              MessageBubble(
                message: message,
                isMe: isMe,
                showAvatar: !isMe,
                onReply: () => _replyToMessage(message),
                onEdit: isMe ? () => _editMessage(message) : null,
                onDelete: isMe ? () => _deleteMessage(message) : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatDateSeparator(date),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    // Show voice recorder when recording
    if (_isRecording) {
      return VoiceRecorder(
        onRecordingComplete: _onRecordingComplete,
        onCancel: _onRecordingCancel,
      );
    }

    // Show normal message input
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            IconButton(
              onPressed: _showAttachmentOptions,
              icon: const Icon(Icons.add),
              color: AppTheme.primaryColor,
            ),
            
            // Message input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Send button
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageController,
              builder: (context, value, child) {
                final hasText = value.text.trim().isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: FloatingActionButton.small(
                    onPressed: hasText ? () => _sendMessage() : _recordVoiceMessage,
                    backgroundColor: AppTheme.primaryColor,
                    elevation: 0,
                    child: Icon(
                      hasText ? Icons.send : Icons.mic,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollToBottomFAB() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton.small(
            onPressed: _scrollToBottom,
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAttachmentOptions() {
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Send Attachment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              padding: const EdgeInsets.all(16),
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo_camera,
                  label: 'Camera',
                  color: Colors.pink,
                  onTap: _takePhoto,
                ),
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: _pickImage,
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  color: Colors.blue,
                  onTap: _pickDocument,
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  label: 'Location',
                  color: Colors.green,
                  onTap: _shareLocation,
                ),
                _buildAttachmentOption(
                  icon: Icons.contact_phone,
                  label: 'Contact',
                  color: Colors.orange,
                  onTap: _shareContact,
                ),
                _buildAttachmentOption(
                  icon: Icons.calendar_today,
                  label: 'Schedule',
                  color: Colors.teal,
                  onTap: _scheduleSession,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
  Future<void> _makeVideoCall() async {
    await _initiateCall(CallType.video);
  }

  Future<void> _makeVoiceCall() async {
    await _initiateCall(CallType.voice);
  }

  Future<void> _initiateCall(CallType callType) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      // Initiate call
      final response = await _callService.initiateCall(
        receiverId: widget.participantId,
        callType: callType,
      );

      // Hide loading
      if (mounted) Navigator.pop(context);

      if (response.success && response.data != null) {
        // Navigate to call screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => callType == CallType.video
                  ? VideoCallScreen(callSession: response.data!)
                  : VoiceCallScreen(callSession: response.data!),
            ),
          );
        }
      } else {
        _showError(response.error ?? 'Failed to initiate call');
      }
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.pop(context);
      print('❌ Error initiating call: $e');
      _showError('Failed to make call');
    }
  }

  void _recordVoiceMessage() {
    setState(() => _isRecording = true);
  }

  void _onRecordingComplete(String audioPath, Duration duration) async {
    setState(() => _isRecording = false);
    
    try {
      // Show loading indicator
      setState(() => _isSending = true);
      
      // Upload the audio file first
      final file = File(audioPath);
      final fileName = path.basename(audioPath);
      
      print('📤 Uploading voice message: $fileName');
      
      final uploadResponse = await _chatService.uploadAttachment(
        file: file,
        fileName: fileName,
        fileType: 'audio',
      );
      
      if (!uploadResponse.success || uploadResponse.data == null) {
        throw Exception(uploadResponse.error ?? 'Failed to upload voice message');
      }
      
      final attachment = uploadResponse.data!;
      print('✅ Voice message uploaded: ${attachment.url}');
      
      // Send the voice message with the uploaded file URL
      await _sendMessage(
        content: 'Voice message',
        type: MessageType.voice,
        attachments: [
          MessageAttachment(
            id: attachment.id,
            type: attachment.type,
            url: attachment.url,
            name: attachment.name,
            size: attachment.size,
            mimeType: attachment.mimeType,
            duration: duration.inSeconds,
          ),
        ],
      );
      
      print('✅ Voice message sent successfully');
      
    } catch (e) {
      print('❌ Error sending voice message: $e');
      _showError('Failed to send voice message: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _onRecordingCancel() {
    setState(() => _isRecording = false);
  }

  void _takePhoto() {
    // TODO: Implement camera
    _showError('Camera feature coming soon!');
  }

  void _pickImage() {
    // TODO: Implement image picker
    _showError('Image picker feature coming soon!');
  }

  void _pickDocument() {
    // TODO: Implement document picker
    _showError('Document picker feature coming soon!');
  }

  void _shareLocation() {
    // TODO: Implement location sharing
    _showError('Location sharing feature coming soon!');
  }

  void _shareContact() {
    // TODO: Implement contact sharing
    _showError('Contact sharing feature coming soon!');
  }

  void _scheduleSession() {
    // TODO: Navigate to booking screen
    _showError('Session scheduling feature coming soon!');
  }

  void _replyToMessage(Message message) {
    // TODO: Implement reply functionality
    _showError('Reply feature coming soon!');
  }

  void _editMessage(Message message) {
    // TODO: Implement edit functionality
    _showError('Edit message feature coming soon!');
  }

  void _deleteMessage(Message message) {
    // TODO: Implement delete functionality
    _showError('Delete message feature coming soon!');
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'view_profile':
        // TODO: Navigate to profile
        _showError('Profile view coming soon!');
        break;
      case 'book_session':
        // TODO: Navigate to booking
        _showError('Session booking coming soon!');
        break;
      case 'search':
        // TODO: Implement search
        _showError('Message search coming soon!');
        break;
      case 'clear_chat':
        _showClearChatDialog();
        break;
      case 'report':
        // TODO: Implement report
        _showError('Report feature coming soon!');
        break;
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear chat
              _showError('Clear chat feature coming soon!');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _typingTimer?.cancel();
    _newMessageSubscription?.cancel();
    _typingSubscription?.cancel();
    _onlineStatusSubscription?.cancel();
    _fabAnimationController.dispose();
    super.dispose();
  }
}