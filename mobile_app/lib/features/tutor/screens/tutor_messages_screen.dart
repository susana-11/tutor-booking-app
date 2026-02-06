import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/chat_service.dart';
import '../../chat/models/chat_models.dart';

class TutorMessagesScreen extends StatefulWidget {
  const TutorMessagesScreen({super.key});

  @override
  State<TutorMessagesScreen> createState() => _TutorMessagesScreenState();
}

class _TutorMessagesScreenState extends State<TutorMessagesScreen> {
  final ChatService _chatService = ChatService();
  List<Conversation> _conversations = [];
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
    _chatService.newMessageStream.listen((message) {
      _loadConversations();
      _loadUnreadCount();
    });
    _chatService.conversationsStream.listen((conversations) {
      if (mounted) {
        setState(() {
          _conversations = conversations;
        });
      }
    });
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      print('🔍 Tutor loading conversations...');
      final response = await _chatService.getConversations(refresh: true);
      print('📨 Tutor conversations response: success=${response.success}, data=${response.data?.length ?? 0}');
      
      if (response.success && response.data != null) {
        print('✅ Tutor got ${response.data!.length} conversations');
        setState(() {
          _conversations = response.data!;
        });
      } else {
        print('❌ Tutor conversations failed: ${response.error}');
      }
    } catch (e) {
      print('❌ Tutor conversations error: $e');
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
      // Silent fail
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: isDark 
                    ? [const Color(0xFF6B7FA8), const Color(0xFF8B9DC3)]
                    : [const Color(0xFF0F3460), const Color(0xFF16213E)],
              ).createShader(bounds),
              child: const Text(
                'Messages',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF6B7FA8), const Color(0xFF8B9DC3)]
                        : [const Color(0xFF0F3460), const Color(0xFF16213E)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460))
                          .withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF6B7FA8).withOpacity(0.2), const Color(0xFF8B9DC3).withOpacity(0.1)]
                    : [const Color(0xFF0F3460).withOpacity(0.1), const Color(0xFF16213E).withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF6B7FA8).withOpacity(0.3)
                    : const Color(0xFF0F3460).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: _loadConversations,
              icon: Icon(
                Icons.refresh_rounded,
                color: isDark ? const Color(0xFF8B9DC3) : const Color(0xFF0F3460),
                size: 22,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
                ),
                strokeWidth: 3,
              ),
            )
          : _conversations.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  color: isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _buildConversationTile(conversation, isDark);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF16213E).withOpacity(0.5),
                        const Color(0xFF0F3460).withOpacity(0.3),
                      ]
                    : [
                        const Color(0xFFECEFF4),
                        const Color(0xFFE8EAF6),
                      ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: isDark 
                  ? const Color(0xFF6B7FA8).withOpacity(0.5)
                  : const Color(0xFF0F3460).withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Messages Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F3460),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Messages from students will appear here',
              style: TextStyle(
                fontSize: 16,
                color: isDark 
                    ? Colors.white.withOpacity(0.6)
                    : const Color(0xFF6B7FA8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation, bool isDark) {
    final hasUnread = conversation.unreadCount > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF16213E),
                  const Color(0xFF0F3460).withOpacity(0.8),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF5F7FA),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: hasUnread
            ? Border.all(
                color: isDark 
                    ? const Color(0xFF6B7FA8).withOpacity(0.5)
                    : const Color(0xFF0F3460).withOpacity(0.2),
                width: 2,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openChat(conversation),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with gradient border
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasUnread
                        ? LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF6B7FA8), const Color(0xFF8B9DC3)]
                                : [const Color(0xFF0F3460), const Color(0xFF16213E)],
                          )
                        : null,
                    boxShadow: hasUnread
                        ? [
                            BoxShadow(
                              color: (isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460))
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: isDark
                        ? const Color(0xFF6B7FA8).withOpacity(0.2)
                        : const Color(0xFFECEFF4),
                    backgroundImage: conversation.participantAvatar != null
                        ? NetworkImage(conversation.participantAvatar!)
                        : null,
                    child: conversation.participantAvatar == null
                        ? Text(
                            conversation.participantName.isNotEmpty
                                ? conversation.participantName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF6B7FA8)
                                  : const Color(0xFF0F3460),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.participantName,
                              style: TextStyle(
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                fontSize: 16,
                                color: isDark ? Colors.white : const Color(0xFF0F3460),
                              ),
                            ),
                          ),
                          if (conversation.lastMessage?.createdAt != null)
                            Text(
                              _formatTime(conversation.lastMessage!.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : const Color(0xFF6B7FA8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.lastMessage?.content ?? 'No messages yet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                color: isDark
                                    ? Colors.white.withOpacity(hasUnread ? 0.9 : 0.6)
                                    : const Color(0xFF6B7FA8).withOpacity(hasUnread ? 1.0 : 0.8),
                              ),
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [const Color(0xFF6B7FA8), const Color(0xFF8B9DC3)]
                                      : [const Color(0xFF0F3460), const Color(0xFF16213E)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460))
                                        .withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                conversation.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  void _openChat(Conversation conversation) {
    context.push('/chat', extra: {
      'conversationId': conversation.id,
      'participantId': conversation.participantId,
      'participantName': conversation.participantName,
      'participantAvatar': conversation.participantAvatar,
      'subject': conversation.subject,
    });
  }

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }
}
