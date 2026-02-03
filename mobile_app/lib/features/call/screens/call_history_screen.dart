import 'package:flutter/material.dart';
import '../../../core/services/call_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/call_models.dart';
import 'voice_call_screen.dart';
import 'video_call_screen.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen>
    with SingleTickerProviderStateMixin {
  final CallService _callService = CallService();
  late TabController _tabController;

  List<CallHistory> _allCalls = [];
  List<CallHistory> _missedCalls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    setState(() => _isLoading = true);

    try {
      // Load all calls
      final allCallsResponse = await _callService.getCallHistory();
      if (allCallsResponse.success) {
        _allCalls = allCallsResponse.data ?? [];
      }

      // Load missed calls
      final missedCallsResponse = await _callService.getMissedCalls();
      if (missedCallsResponse.success) {
        _missedCalls = missedCallsResponse.data ?? [];
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error loading call history: $e');
      setState(() => _isLoading = false);
      _showError('Failed to load call history');
    }
  }

  Future<void> _makeCall(CallHistory callHistory) async {
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
        receiverId: callHistory.otherParticipant.id,
        callType: callHistory.callType,
      );

      // Hide loading
      if (mounted) Navigator.pop(context);

      if (response.success && response.data != null) {
        // Navigate to call screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => callHistory.callType == CallType.video
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
      print('❌ Error making call: $e');
      _showError('Failed to make call');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Calls'),
            Tab(text: 'Missed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCallList(_allCalls),
                _buildCallList(_missedCalls),
              ],
            ),
    );
  }

  Widget _buildCallList(List<CallHistory> calls) {
    if (calls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.call_end,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No calls yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCallHistory,
      child: ListView.builder(
        itemCount: calls.length,
        itemBuilder: (context, index) {
          final call = calls[index];
          return _buildCallItem(call);
        },
      ),
    );
  }

  Widget _buildCallItem(CallHistory call) {
    IconData callIcon;
    Color iconColor;

    // Determine icon and color based on call status
    if (call.status == CallStatus.missed) {
      callIcon = Icons.call_missed;
      iconColor = Colors.red;
    } else if (call.status == CallStatus.rejected) {
      callIcon = Icons.call_missed_outgoing;
      iconColor = Colors.orange;
    } else if (call.isInitiator) {
      callIcon = Icons.call_made;
      iconColor = Colors.green;
    } else {
      callIcon = Icons.call_received;
      iconColor = Colors.blue;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            backgroundImage: call.otherParticipant.avatar != null
                ? NetworkImage(call.otherParticipant.avatar!)
                : null,
            child: call.otherParticipant.avatar == null
                ? Text(
                    call.otherParticipant.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                call.callType == CallType.video
                    ? Icons.videocam
                    : Icons.call,
                size: 14,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
      title: Text(
        call.otherParticipant.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(callIcon, size: 16, color: iconColor),
          const SizedBox(width: 4),
          Text(
            call.statusText,
            style: TextStyle(
              color: iconColor,
              fontSize: 14,
            ),
          ),
          if (call.duration > 0) ...[
            const Text(' • '),
            Text(
              call.durationText,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatCallTime(call.createdAt),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _makeCall(call),
            icon: Icon(
              call.callType == CallType.video
                  ? Icons.videocam
                  : Icons.call,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
      onTap: () => _showCallDetails(call),
    );
  }

  String _formatCallTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showCallDetails(CallHistory call) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                backgroundImage: call.otherParticipant.avatar != null
                    ? NetworkImage(call.otherParticipant.avatar!)
                    : null,
                child: call.otherParticipant.avatar == null
                    ? Text(
                        call.otherParticipant.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                call.otherParticipant.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${call.callType.name.toUpperCase()} • ${call.statusText}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (call.duration > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Duration: ${call.durationText}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.call,
                    label: 'Voice Call',
                    onPressed: () {
                      Navigator.pop(context);
                      _makeCall(CallHistory(
                        id: call.id,
                        callId: call.callId,
                        callType: CallType.voice,
                        status: call.status,
                        otherParticipant: call.otherParticipant,
                        isInitiator: call.isInitiator,
                        createdAt: call.createdAt,
                        duration: call.duration,
                      ));
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.videocam,
                    label: 'Video Call',
                    onPressed: () {
                      Navigator.pop(context);
                      _makeCall(CallHistory(
                        id: call.id,
                        callId: call.callId,
                        callType: CallType.video,
                        status: call.status,
                        otherParticipant: call.otherParticipant,
                        isInitiator: call.isInitiator,
                        createdAt: call.createdAt,
                        duration: call.duration,
                      ));
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.message,
                    label: 'Message',
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Navigate to chat
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: AppTheme.primaryColor),
          ),
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
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
