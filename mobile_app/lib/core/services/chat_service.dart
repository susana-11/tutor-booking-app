import 'api_service.dart';
import 'socket_service.dart';
import '../../features/chat/models/chat_models.dart';
import 'dart:async';
import 'dart:io';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  
  // Stream controllers for real-time updates
  final StreamController<List<Conversation>> _conversationsController = 
      StreamController<List<Conversation>>.broadcast();
  final StreamController<Message> _newMessageController = 
      StreamController<Message>.broadcast();
  final StreamController<TypingIndicator> _typingController = 
      StreamController<TypingIndicator>.broadcast();
  final StreamController<Map<String, bool>> _onlineStatusController = 
      StreamController<Map<String, bool>>.broadcast();

  // Getters for streams
  Stream<List<Conversation>> get conversationsStream => _conversationsController.stream;
  Stream<Message> get newMessageStream => _newMessageController.stream;
  Stream<TypingIndicator> get typingStream => _typingController.stream;
  Stream<Map<String, bool>> get onlineStatusStream => _onlineStatusController.stream;

  // Local cache
  List<Conversation> _conversations = [];
  Map<String, List<Message>> _messagesCache = {};
  Map<String, bool> _onlineUsers = {};
  Set<String> _typingUsers = {};

  void initialize() {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen for new messages
    _socketService.on('new_message', (data) {
      try {
        final message = Message.fromJson(data);
        _handleNewMessage(message);
      } catch (e) {
        print('❌ Error handling new message: $e');
      }
    });

    // Listen for typing indicators
    _socketService.on('user_typing', (data) {
      try {
        final typing = TypingIndicator.fromJson(data);
        if (!_typingController.isClosed) {
          _typingController.add(typing);
        }
        _typingUsers.add(typing.userId);
      } catch (e) {
        print('❌ Error handling typing indicator: $e');
      }
    });

    _socketService.on('user_stopped_typing', (data) {
      try {
        final userId = data['userId'] as String;
        _typingUsers.remove(userId);
      } catch (e) {
        print('❌ Error handling stopped typing: $e');
      }
    });

    // Listen for online status updates
    _socketService.on('user_status_change', (data) {
      try {
        final userId = data['userId'] as String;
        final status = data['status'] as String;
        _onlineUsers[userId] = status == 'online';
        if (!_onlineStatusController.isClosed) {
          _onlineStatusController.add(_onlineUsers);
        }
      } catch (e) {
        print('❌ Error handling status change: $e');
      }
    });

    // Listen for message status updates
    _socketService.on('message_status_update', (data) {
      try {
        final messageId = data['messageId'] as String;
        final status = MessageStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => MessageStatus.sent,
        );
        _updateMessageStatus(messageId, status);
      } catch (e) {
        print('❌ Error handling message status update: $e');
      }
    });

    // Listen for conversation updates
    _socketService.on('conversation_updated', (data) {
      try {
        _refreshConversations();
      } catch (e) {
        print('❌ Error handling conversation update: $e');
      }
    });
  }

  void _handleNewMessage(Message message) {
    // Add to messages cache
    if (_messagesCache.containsKey(message.conversationId)) {
      _messagesCache[message.conversationId]!.add(message);
    }

    // Update conversation with new last message
    final conversationIndex = _conversations.indexWhere(
      (c) => c.id == message.conversationId,
    );
    
    if (conversationIndex != -1) {
      final conversation = _conversations[conversationIndex];
      final updatedConversation = conversation.copyWith(
        lastMessage: message,
        unreadCount: conversation.unreadCount + 1,
        updatedAt: message.createdAt,
      );
      
      _conversations[conversationIndex] = updatedConversation;
      
      // Move to top of list
      _conversations.removeAt(conversationIndex);
      _conversations.insert(0, updatedConversation);
      
      if (!_conversationsController.isClosed) {
        _conversationsController.add(_conversations);
      }
    }

    if (!_newMessageController.isClosed) {
      _newMessageController.add(message);
    }
  }

  void _updateMessageStatus(String messageId, MessageStatus status) {
    for (final messages in _messagesCache.values) {
      final messageIndex = messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        messages[messageIndex] = messages[messageIndex].copyWith(status: status);
        break;
      }
    }
  }

  // Get chat conversations
  Future<ApiResponse<List<Conversation>>> getConversations({
    int page = 1,
    int limit = 20,
    bool refresh = false,
  }) async {
    try {
      print('📨 ChatService.getConversations called: page=$page, refresh=$refresh');
      
      if (!refresh && _conversations.isNotEmpty && page == 1) {
        print('📨 Returning cached conversations: ${_conversations.length}');
        return ApiResponse.success(_conversations);
      }

      print('📨 Fetching conversations from API...');
      final response = await _apiService.get('/chat/conversations', queryParameters: {
        'page': page,
        'limit': limit,
      });

      print('📨 API response: success=${response.success}');
      
      if (response.success && response.data != null) {
        // Handle nested data structure from server
        final dataObj = response.data['data'] ?? response.data;
        final conversationsData = dataObj['conversations'] as List;
        print('📨 Found ${conversationsData.length} conversations in response');
        
        final conversations = conversationsData
            .map((data) => Conversation.fromJson(data))
            .toList();
        
        print('📨 Parsed ${conversations.length} conversation objects');
        
        if (page == 1) {
          _conversations = conversations;
        } else {
          _conversations.addAll(conversations);
        }
        
        if (!_conversationsController.isClosed) {
          _conversationsController.add(_conversations);
        }
        return ApiResponse.success(conversations);
      }
      
      print('❌ API response not successful: ${response.error}');
      return ApiResponse.error(response.error ?? 'Failed to fetch conversations');
    } catch (e) {
      print('❌ getConversations error: $e');
      return ApiResponse.error('Failed to fetch conversations: $e');
    }
  }

  // Get messages for a conversation
  Future<ApiResponse<List<Message>>> getMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
    bool refresh = false,
  }) async {
    try {
      if (!refresh && _messagesCache.containsKey(conversationId) && page == 1) {
        return ApiResponse.success(_messagesCache[conversationId]!);
      }

      final response = await _apiService.get('/chat/conversations/$conversationId/messages', queryParameters: {
        'page': page,
        'limit': limit,
      });

      if (response.success && response.data != null) {
        // Handle nested data structure from server
        final dataObj = response.data['data'] ?? response.data;
        final messagesData = dataObj['messages'] as List;
        final messages = messagesData
            .map((data) => Message.fromJson(data))
            .toList();
        
        if (page == 1) {
          _messagesCache[conversationId] = messages;
        } else {
          _messagesCache[conversationId]?.insertAll(0, messages);
        }
        
        return ApiResponse.success(messages);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch messages');
    } catch (e) {
      return ApiResponse.error('Failed to fetch messages: $e');
    }
  }

  // Send message
  Future<ApiResponse<Message>> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToId,
    List<MessageAttachment> attachments = const [],
  }) async {
    try {
      // Create temporary message for immediate UI update
      final tempMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conversationId,
        senderId: 'current_user', // Will be replaced by actual user ID
        senderName: 'You',
        content: content,
        type: type,
        status: MessageStatus.sending,
        attachments: attachments,
        replyToId: replyToId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to cache immediately for UI responsiveness
      if (_messagesCache.containsKey(conversationId)) {
        _messagesCache[conversationId]!.add(tempMessage);
      }
      _newMessageController.add(tempMessage);

      // Send via socket for real-time delivery
      _socketService.emit('send_message', {
        'conversationId': conversationId,
        'content': content,
        'type': type.name,
        'replyToId': replyToId,
        'attachments': attachments.map((a) => a.toJson()).toList(),
      });

      // Also send via API for persistence
      final response = await _apiService.post('/chat/conversations/$conversationId/messages', data: {
        'content': content,
        'type': type.name,
        'replyToId': replyToId,
        'attachments': attachments.map((a) => a.toJson()).toList(),
      });

      if (response.success && response.data != null) {
        final message = Message.fromJson(response.data);
        
        // Replace temporary message with real one
        if (_messagesCache.containsKey(conversationId)) {
          final messages = _messagesCache[conversationId]!;
          final tempIndex = messages.indexWhere((m) => m.id == tempMessage.id);
          if (tempIndex != -1) {
            messages[tempIndex] = message;
          }
        }
        
        return ApiResponse.success(message);
      }
      
      // Update temp message status to failed
      if (_messagesCache.containsKey(conversationId)) {
        final messages = _messagesCache[conversationId]!;
        final tempIndex = messages.indexWhere((m) => m.id == tempMessage.id);
        if (tempIndex != -1) {
          messages[tempIndex] = tempMessage.copyWith(status: MessageStatus.failed);
        }
      }
      
      return ApiResponse.error(response.error ?? 'Failed to send message');
    } catch (e) {
      return ApiResponse.error('Failed to send message: $e');
    }
  }

  // Create or get conversation
  Future<ApiResponse<Conversation>> createOrGetConversation({
    required String participantId,
    String? subject,
  }) async {
    try {
      final response = await _apiService.post('/chat/conversations', data: {
        'participantId': participantId,
        'subject': subject,
      });

      if (response.success && response.data != null) {
        final conversation = Conversation.fromJson(response.data);
        
        // Add to local cache if not exists
        final existingIndex = _conversations.indexWhere((c) => c.id == conversation.id);
        if (existingIndex == -1) {
          _conversations.insert(0, conversation);
          _conversationsController.add(_conversations);
        }
        
        return ApiResponse.success(conversation);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to create conversation');
    } catch (e) {
      return ApiResponse.error('Failed to create conversation: $e');
    }
  }

  // Mark messages as read
  Future<ApiResponse<void>> markAsRead({
    required String conversationId,
  }) async {
    try {
      final response = await _apiService.put('/chat/conversations/$conversationId/read');

      if (response.success) {
        // Update local conversation
        final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
        if (conversationIndex != -1) {
          _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
            unreadCount: 0,
          );
          _conversationsController.add(_conversations);
        }

        // Emit socket event
        _socketService.emit('mark_messages_read', {
          'conversationId': conversationId,
        });
        
        return ApiResponse.success(null);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to mark as read');
    } catch (e) {
      return ApiResponse.error('Failed to mark as read: $e');
    }
  }

  // Start typing
  void startTyping(String conversationId) {
    _socketService.emit('typing_start', {
      'conversationId': conversationId,
    });
  }

  // Stop typing
  void stopTyping(String conversationId) {
    _socketService.emit('typing_stop', {
      'conversationId': conversationId,
    });
  }

  // Get unread message count
  Future<ApiResponse<int>> getUnreadCount() async {
    try {
      final response = await _apiService.get('/chat/unread-count');

      if (response.success && response.data != null) {
        // Handle nested data structure from server
        final dataObj = response.data['data'] ?? response.data;
        final count = dataObj['count'] ?? 0;
        return ApiResponse.success(count);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch unread count');
    } catch (e) {
      return ApiResponse.error('Failed to fetch unread count: $e');
    }
  }

  // Delete conversation
  Future<ApiResponse<void>> deleteConversation({
    required String conversationId,
  }) async {
    try {
      final response = await _apiService.delete('/chat/conversations/$conversationId');

      if (response.success) {
        // Remove from local cache
        _conversations.removeWhere((c) => c.id == conversationId);
        _messagesCache.remove(conversationId);
        _conversationsController.add(_conversations);
        
        return ApiResponse.success(null);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to delete conversation');
    } catch (e) {
      return ApiResponse.error('Failed to delete conversation: $e');
    }
  }

  // Archive conversation
  Future<ApiResponse<void>> archiveConversation({
    required String conversationId,
  }) async {
    try {
      final response = await _apiService.put('/chat/conversations/$conversationId/archive');

      if (response.success) {
        // Update local conversation
        final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
        if (conversationIndex != -1) {
          _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
            isArchived: true,
          );
          _conversationsController.add(_conversations);
        }
        
        return ApiResponse.success(null);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to archive conversation');
    } catch (e) {
      return ApiResponse.error('Failed to archive conversation: $e');
    }
  }

  // Pin conversation
  Future<ApiResponse<void>> pinConversation({
    required String conversationId,
    required bool isPinned,
  }) async {
    try {
      final response = await _apiService.put('/chat/conversations/$conversationId/pin', data: {
        'isPinned': isPinned,
      });

      if (response.success) {
        // Update local conversation
        final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
        if (conversationIndex != -1) {
          _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
            isPinned: isPinned,
          );
          
          // Re-sort conversations (pinned first)
          _conversations.sort((a, b) {
            if (a.isPinned && !b.isPinned) return -1;
            if (!a.isPinned && b.isPinned) return 1;
            return b.updatedAt.compareTo(a.updatedAt);
          });
          
          _conversationsController.add(_conversations);
        }
        
        return ApiResponse.success(null);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to pin conversation');
    } catch (e) {
      return ApiResponse.error('Failed to pin conversation: $e');
    }
  }

  // Upload attachment
  Future<ApiResponse<MessageAttachment>> uploadAttachment({
    required File file,
    required String fileName,
    required String fileType,
  }) async {
    try {
      final response = await _apiService.uploadFile(
        '/chat/upload',
        file,
        fieldName: 'file',
      );

      if (response.success && response.data != null) {
        final attachment = MessageAttachment.fromJson(response.data);
        return ApiResponse.success(attachment);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to upload attachment');
    } catch (e) {
      return ApiResponse.error('Failed to upload attachment: $e');
    }
  }

  // Search messages
  Future<ApiResponse<List<Message>>> searchMessages({
    required String query,
    String? conversationId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'query': query,
        'page': page,
        'limit': limit,
      };
      
      if (conversationId != null) {
        queryParams['conversationId'] = conversationId;
      }

      final response = await _apiService.get('/chat/search', queryParameters: queryParams);

      if (response.success && response.data != null) {
        // Handle nested data structure from server
        final dataObj = response.data['data'] ?? response.data;
        final messagesData = dataObj['messages'] as List;
        final messages = messagesData
            .map((data) => Message.fromJson(data))
            .toList();
        
        return ApiResponse.success(messages);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to search messages');
    } catch (e) {
      return ApiResponse.error('Failed to search messages: $e');
    }
  }

  // Get online users
  Map<String, bool> getOnlineUsers() {
    return Map.from(_onlineUsers);
  }

  // Check if user is typing
  bool isUserTyping(String userId) {
    return _typingUsers.contains(userId);
  }

  // Refresh conversations
  Future<void> _refreshConversations() async {
    await getConversations(refresh: true);
  }

  // Clear cache
  void clearCache() {
    _conversations.clear();
    _messagesCache.clear();
    _onlineUsers.clear();
    _typingUsers.clear();
  }

  // Dispose
  void dispose() {
    _conversationsController.close();
    _newMessageController.close();
    _typingController.close();
    _onlineStatusController.close();
  }
}