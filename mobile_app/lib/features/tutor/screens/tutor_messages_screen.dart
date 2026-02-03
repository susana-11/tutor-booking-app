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

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final response = await _chatService.getConversations(refresh: true);
      if (response.success && response.data != null) {
        setState(() {
          _conversations = response.data!;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(child: Text('No messages yet'))
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = _conversations[index];
                    return ListTile(
                      title: Text(conversation.participantName),
                      subtitle: Text(conversation.lastMessage?.content ?? ''),
                      onTap: () {
                        context.push('/chat', extra: {
                          'conversationId': conversation.id,
                          'participantId': conversation.participantId,
                          'participantName': conversation.participantName,
                        });
                      },
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }
}
