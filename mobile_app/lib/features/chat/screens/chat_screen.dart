import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart' as perm;

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
  Message? _replyingTo; // Message being replied to
  
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
        replyToId: _replyingTo?.id, // Include reply reference
        attachments: attachments,
      );

      if (response.success) {
        // Clear reply state
        setState(() => _replyingTo = null);
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
                onForward: () => _forwardMessage(message),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview
            if (_replyingTo != null) _buildReplyPreview(),
            
            Row(
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
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: AppTheme.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Replying to ${_replyingTo!.senderName}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _replyingTo!.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _replyingTo = null),
            icon: const Icon(Icons.close, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
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

  void _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (photo != null) {
        await _sendImageMessage(photo);
      }
    } catch (e) {
      print('❌ Take photo error: $e');
      _showError('Failed to take photo: $e');
    }
  }

  void _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _sendImageMessage(image);
      }
    } catch (e) {
      print('❌ Pick image error: $e');
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _sendImageMessage(XFile imageFile) async {
    try {
      setState(() => _isSending = true);
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text('Uploading image...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      // Upload the image
      final file = File(imageFile.path);
      final fileName = path.basename(imageFile.path);
      
      final response = await _chatService.uploadAttachment(
        file: file,
        fileName: fileName,
        fileType: 'image',
      );

      // Hide loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.success && response.data != null) {
        final attachment = response.data!;
        
        // Send message with image attachment
        final messageResponse = await _chatService.sendMessage(
          conversationId: widget.conversationId,
          content: '', // Empty content for image-only message
          type: MessageType.image,
          attachments: [attachment],
        );

        if (messageResponse.success) {
          print('✅ Image message sent successfully');
          _scrollToBottom();
        } else {
          _showError('Failed to send image: ${messageResponse.error}');
        }
      } else {
        _showError('Failed to upload image: ${response.error}');
      }
    } catch (e) {
      print('❌ Send image error: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showError('Failed to send image: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _pickDocument() {
    // Document picker temporarily disabled due to compatibility issues
    // Will be re-enabled in future update
    _showError('Document picker will be available in the next update. You can share images, location, contacts, and schedule sessions for now.');
  }

  void _shareLocation() async {
    try {
      // Check location permission
      final permission = await perm.Permission.location.request();
      if (!permission.isGranted) {
        _showError('Location permission is required');
        return;
      }
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
      
      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Hide loading
      if (mounted) Navigator.pop(context);
      
      // Create location message
      final locationText = 'Location: https://www.google.com/maps?q=${position.latitude},${position.longitude}';
      
      // Send location message
      await _sendMessage(
        content: locationText,
        type: MessageType.text,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location shared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Hide loading if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      print('❌ Share location error: $e');
      _showError('Failed to get location: $e');
    }
  }

  void _shareContact() async {
    try {
      print('🔍 Starting contact share...');
      
      // Request contacts permission (this will show system dialog if not granted)
      print('📱 Requesting contacts permission...');
      final hasPermission = await FlutterContacts.requestPermission();
      print('✅ Permission result: $hasPermission');
      
      if (!hasPermission) {
        print('❌ Permission denied');
        _showError('Contacts permission is required to share contacts');
        
        // Show dialog to open settings
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text('Please grant contacts permission in app settings to share contacts.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        
        if (openSettings == true) {
          await perm.openAppSettings();
        }
        return;
      }
      
      // Show loading while fetching contacts
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
      
      print('📋 Fetching contacts...');
      // Get all contacts with a small delay to ensure permission is processed
      await Future.delayed(const Duration(milliseconds: 300));
      
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      
      print('📋 Found ${contacts.length} contacts');
      
      // Hide loading
      if (mounted) Navigator.pop(context);
      
      if (contacts.isEmpty) {
        _showError('No contacts found on your device');
        return;
      }
      
      // Show contact picker dialog
      if (!mounted) return;
      final selectedContact = await showDialog<Contact>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Contact'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      contact.displayName.isNotEmpty
                          ? contact.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(contact.displayName),
                  subtitle: contact.phones.isNotEmpty
                      ? Text(contact.phones.first.number)
                      : const Text('No phone number'),
                  onTap: () => Navigator.pop(context, contact),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      if (selectedContact != null) {
        print('✅ Contact selected: ${selectedContact.displayName}');
        // Create contact message
        final phoneNumber = selectedContact.phones.isNotEmpty
            ? selectedContact.phones.first.number
            : 'No phone number';
        final contactText = '📇 Contact: ${selectedContact.displayName}\n📞 $phoneNumber';
        
        // Send contact message
        await _sendMessage(
          content: contactText,
          type: MessageType.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact shared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      print('❌ Share contact error: $e');
      print('❌ Error stack trace: ${StackTrace.current}');
      _showError('Failed to share contact: $e');
    }
  }

  void _scheduleSession() async {
    try {
      // Navigate to booking screen with participant info
      Navigator.pop(context); // Close attachment sheet
      
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Schedule Session'),
          content: Text('Would you like to schedule a tutoring session with ${widget.participantName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        // Check user role
        final authProvider = context.read<AuthProvider>();
        final userRole = authProvider.user?.role;
        
        if (userRole == 'student') {
          // Navigate to tutor booking screen
          // Note: You'll need to import the booking screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening booking for ${widget.participantName}...'),
              backgroundColor: Colors.blue,
            ),
          );
          
          // Send booking link message
          await _sendMessage(
            content: '📅 Session booking request sent. Please check your bookings to schedule.',
            type: MessageType.booking,
          );
        } else {
          _showError('Only students can schedule sessions');
        }
      }
    } catch (e) {
      print('❌ Schedule session error: $e');
      _showError('Failed to schedule session: $e');
    }
  }

  void _replyToMessage(Message message) {
    setState(() {
      _replyingTo = message;
    });
    _messageFocusNode.requestFocus();
  }

  void _editMessage(Message message) {
    // TODO: Implement edit functionality
    _showError('Edit message feature coming soon!');
  }

  void _deleteMessage(Message message) {
    // TODO: Implement delete functionality
    _showError('Delete message feature coming soon!');
  }

  void _forwardMessage(Message message) {
    // Show conversation list to select where to forward
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildForwardSheet(message),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'view_profile':
        _viewProfile();
        break;
      case 'search':
        _searchMessages();
        break;
      case 'clear_chat':
        _showClearChatDialog();
        break;
      case 'report':
        _showReportDialog();
        break;
    }
  }
  
  void _viewProfile() {
    // Navigate to profile based on user role
    final authProvider = context.read<AuthProvider>();
    final currentUserRole = authProvider.user?.role;
    
    if (currentUserRole == 'student') {
      // Student viewing tutor profile - use go_router
      context.push('/student/tutor/${widget.participantId}');
    } else if (currentUserRole == 'tutor') {
      // Tutor viewing student profile (show basic info dialog)
      _showStudentInfoDialog();
    }
  }
  
  void _showStudentInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              backgroundImage: widget.participantAvatar != null
                  ? NetworkImage(widget.participantAvatar!)
                  : null,
              child: widget.participantAvatar == null
                  ? Text(
                      widget.participantName.isNotEmpty
                          ? widget.participantName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.participantName,
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (widget.subject != null)
                    Text(
                      widget.subject!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.person, color: AppTheme.primaryColor),
              title: const Text('Student'),
              subtitle: Text(widget.participantName),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(
                _isOnline ? Icons.circle : Icons.circle_outlined,
                color: _isOnline ? Colors.green : Colors.grey,
                size: 16,
              ),
              title: Text(_isOnline ? 'Online' : 'Offline'),
              contentPadding: EdgeInsets.zero,
            ),
            if (widget.subject != null)
              ListTile(
                leading: Icon(Icons.book, color: AppTheme.primaryColor),
                title: const Text('Subject'),
                subtitle: Text(widget.subject!),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _searchMessages() {
    showSearch(
      context: context,
      delegate: MessageSearchDelegate(
        messages: _messages,
        onMessageSelected: (message) {
          // Scroll to the selected message
          final index = _messages.indexOf(message);
          if (index != -1 && _scrollController.hasClients) {
            // Calculate approximate position
            final position = index * 100.0; // Approximate height per message
            _scrollController.animateTo(
              position,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        },
      ),
    );
  }
  
  void _showReportDialog() {
    final reasonController = TextEditingController();
    String selectedReason = 'spam';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.report, color: Colors.red),
              const SizedBox(width: 12),
              const Text('Report User'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report ${widget.participantName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reason for reporting:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  title: const Text('Spam or Scam'),
                  value: 'spam',
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value!),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<String>(
                  title: const Text('Inappropriate Content'),
                  value: 'inappropriate',
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value!),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<String>(
                  title: const Text('Harassment or Bullying'),
                  value: 'harassment',
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value!),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<String>(
                  title: const Text('Fake Profile'),
                  value: 'fake',
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value!),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<String>(
                  title: const Text('Other'),
                  value: 'other',
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value!),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Details (Optional)',
                    hintText: 'Provide more information...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 500,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This report will be sent to our admin team for review.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                reasonController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final details = reasonController.text.trim();
                reasonController.dispose();
                Navigator.pop(context);
                await _submitReport(selectedReason, details);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _submitReport(String reason, String details) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
      
      // Submit report to admin
      final response = await _chatService.reportUser(
        reportedUserId: widget.participantId,
        reportedUserName: widget.participantName,
        reason: reason,
        details: details,
        conversationId: widget.conversationId,
      );
      
      // Hide loading
      if (mounted) Navigator.pop(context);
      
      if (response.success) {
        // Show success message
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  const Text('Report Submitted'),
                ],
              ),
              content: const Text(
                'Thank you for your report. Our admin team will review it and take appropriate action.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        _showError(response.error ?? 'Failed to submit report');
      }
    } catch (e) {
      // Hide loading
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      print('❌ Error submitting report: $e');
      _showError('Failed to submit report. Please try again.');
    }
  }

  Widget _buildForwardSheet(Message message) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Forward message to...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Conversations list
            Expanded(
              child: FutureBuilder<List<Conversation>>(
                future: _loadConversationsForForward(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No conversations available'),
                    );
                  }
                  
                  final conversations = snapshot.data!;
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      // Don't show current conversation
                      if (conversation.id == widget.conversationId) {
                        return const SizedBox.shrink();
                      }
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          backgroundImage: conversation.participantAvatar != null
                              ? NetworkImage(conversation.participantAvatar!)
                              : null,
                          child: conversation.participantAvatar == null
                              ? Text(
                                  conversation.participantName.isNotEmpty
                                      ? conversation.participantName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(conversation.participantName),
                        subtitle: Text(conversation.subject ?? ''),
                        onTap: () => _confirmForward(conversation, message),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<Conversation>> _loadConversationsForForward() async {
    try {
      final response = await _chatService.getConversations(refresh: true);
      if (response.success && response.data != null) {
        return response.data!;
      }
    } catch (e) {
      print('❌ Error loading conversations: $e');
    }
    return [];
  }

  Future<void> _confirmForward(Conversation conversation, Message message) async {
    Navigator.pop(context); // Close forward sheet
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forward Message'),
        content: Text('Forward this message to ${conversation.participantName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Forward'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _performForward(conversation, message);
    }
  }

  Future<void> _performForward(Conversation conversation, Message message) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text('Forwarding message...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Forward the message
      final response = await _chatService.sendMessage(
        conversationId: conversation.id,
        content: message.content,
        type: message.type,
        attachments: message.attachments,
      );
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message forwarded to ${conversation.participantName}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError('Failed to forward message');
      }
    } catch (e) {
      print('❌ Error forwarding message: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showError('Failed to forward message');
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to clear all messages in this conversation? This will only clear messages on your device. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearChat();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _clearChat() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
      
      // Clear chat messages
      final response = await _chatService.clearChat(
        conversationId: widget.conversationId,
      );
      
      // Hide loading
      if (mounted) Navigator.pop(context);
      
      if (response.success) {
        // Clear local messages
        setState(() {
          _messages.clear();
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError(response.error ?? 'Failed to clear chat');
      }
    } catch (e) {
      // Hide loading
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      print('❌ Error clearing chat: $e');
      _showError('Failed to clear chat. Please try again.');
    }
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

// Message Search Delegate
class MessageSearchDelegate extends SearchDelegate<Message?> {
  final List<Message> messages;
  final Function(Message) onMessageSelected;
  
  MessageSearchDelegate({
    required this.messages,
    required this.onMessageSelected,
  });
  
  @override
  String get searchFieldLabel => 'Search messages...';
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.clear),
        ),
    ];
  }
  
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }
  
  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }
  
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }
  
  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Search for messages',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    // Filter messages by query
    final results = messages.where((message) {
      return message.content.toLowerCase().contains(query.toLowerCase()) ||
             message.senderName.toLowerCase().contains(query.toLowerCase());
    }).toList();
    
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No messages found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final message = results[index];
        final highlightedContent = _highlightQuery(message.content, query);
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              message.senderName.isNotEmpty
                  ? message.senderName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            message.senderName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: RichText(
            text: highlightedContent,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            _formatTime(message.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          onTap: () {
            close(context, message);
            onMessageSelected(message);
          },
        );
      },
    );
  }
  
  TextSpan _highlightQuery(String text, String query) {
    if (query.isEmpty) {
      return TextSpan(text: text);
    }
    
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    
    int start = 0;
    int index = lowerText.indexOf(lowerQuery);
    
    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: Colors.yellow.withOpacity(0.5),
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }
    
    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    
    return TextSpan(children: spans);
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}