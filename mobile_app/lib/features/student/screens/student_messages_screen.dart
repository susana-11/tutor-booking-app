import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/chat_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/models/chat_models.dart';

class StudentMessagesScreen extends StatefulWidget {
  const StudentMessagesScreen({Key? key}) : super(key: key);

  @override
  State<StudentMessagesScreen> createState() => _StudentMessagesScreenState();
}

class _StudentMessagesScreenState extends State<StudentMessagesScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Conversation> _conversations = [];
  List<Conversation> _filteredConversations = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _loadConversations();
    _loadUnreadCount();
  }

  void _initializeChat() {
    _chatService.initialize();
    
    // Listen for new messages
    _chatService.newMessageStream.listen((message) {
      _loadConversations();
      _loadUnreadCount();
    });
    
    // Listen for conversation updates
    _chatService.conversationsStream.listen((conversations) {
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _filterConversations(_searchController.text);
        });
      }
    });
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _chatService.getConversations(refresh: true);
      if (response.success && response.data != null) {
        setState(() {
          _conversations = response.data!;
          _filterConversations(_searchController.text);
        });
      } else {
        print('Failed to load conversations: ${response.error}');
      }
    } catch (e) {
      print('Error loading conversations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load conversations: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await _chatService.getUnreadCount();
      if (response.success && response.data != null) {
        setState(() {
          _unreadCount = response.data!;
        });
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  void _filterConversations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = _conversations;
      } else {
        _filteredConversations = _conversations.where((conversation) {
          return conversation.participantName.toLowerCase().contains(query.toLowerCase()) ||
                 (conversation.subject?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 (conversation.lastMessage?.content.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Messages'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadConversations,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _filterConversations,
            ),
          ),
          
          // Conversations List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredConversations.isEmpty 
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: ListView.builder(
                          itemCount: _filteredConversations.length,
                          itemBuilder: (context, index) => _buildConversationTile(_filteredConversations[index]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewConversation,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLG,
        vertical: AppTheme.spacingSM,
      ),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            backgroundImage: conversation.participantAvatar != null 
                ? NetworkImage(conversation.participantAvatar!)
                : null,
            child: conversation.participantAvatar == null
                ? Text(
                    conversation.participantName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          if (conversation.isOnline)
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
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.participantName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: conversation.unreadCount > 0 
                    ? FontWeight.bold 
                    : FontWeight.normal,
              ),
            ),
          ),
          if (conversation.lastMessage != null)
            Text(
              _formatTime(conversation.lastMessage!.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conversation.subject != null) ...[
            Text(
              conversation.subject!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            conversation.lastMessage?.content ?? 'No messages yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: conversation.unreadCount > 0 
                  ? Colors.black87 
                  : Colors.grey[600],
              fontWeight: conversation.unreadCount > 0 
                  ? FontWeight.w500 
                  : FontWeight.normal,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: conversation.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: () => _openConversation(conversation),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppTheme.spacingLG),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            'Start chatting with your tutors to get help and stay connected!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXL),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Find Tutors'),
          ),
        ],
      ),
    );
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

  void _openConversation(Conversation conversation) {
    context.push('/chat', extra: {
      'conversationId': conversation.id,
      'participantId': conversation.participantId,
      'participantName': conversation.participantName,
      'participantAvatar': conversation.participantAvatar,
      'subject': conversation.subject,
    });
  }

  void _startNewConversation() {
    // Navigate to tutor search to find tutors to chat with
    context.push('/tutor-search');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _chatService.dispose();
    super.dispose();
  }
}