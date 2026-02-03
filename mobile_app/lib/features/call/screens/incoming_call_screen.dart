import 'package:flutter/material.dart';
import '../../../core/services/call_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/call_models.dart';
import 'voice_call_screen.dart';
import 'video_call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final IncomingCall incomingCall;

  const IncomingCallScreen({
    super.key,
    required this.incomingCall,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  final CallService _callService = CallService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _answerCall() async {
    try {
      // Answer the call via API
      final response = await _callService.answerCall(widget.incomingCall.callId);

      if (response.success) {
        // Navigate to appropriate call screen
        final callSession = widget.incomingCall.toCallSession();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => widget.incomingCall.callType == CallType.video
                  ? VideoCallScreen(callSession: callSession)
                  : VoiceCallScreen(callSession: callSession),
            ),
          );
        }
      } else {
        _showError(response.error ?? 'Failed to answer call');
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error answering call: $e');
      _showError('Failed to answer call');
      Navigator.pop(context);
    }
  }

  Future<void> _rejectCall() async {
    try {
      await _callService.rejectCall(widget.incomingCall.callId);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error rejecting call: $e');
      if (mounted) {
        Navigator.pop(context);
      }
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
    return WillPopScope(
      onWillPop: () async {
        await _rejectCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryColor,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // Call type indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.incomingCall.callType == CallType.video
                          ? Icons.videocam
                          : Icons.call,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.incomingCall.callType == CallType.video
                          ? 'Incoming Video Call'
                          : 'Incoming Voice Call',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Avatar with animation
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: widget.incomingCall.initiator.avatar != null
                          ? ClipOval(
                              child: Image.network(
                                widget.incomingCall.initiator.avatar!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                widget.incomingCall.initiator.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Caller name
              Text(
                widget.incomingCall.initiator.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Ringing text
              Text(
                'Ringing...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 18,
                ),
              ),

              const Spacer(),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Reject button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          child: IconButton(
                            onPressed: _rejectCall,
                            icon: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Decline',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Answer button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          child: IconButton(
                            onPressed: _answerCall,
                            icon: Icon(
                              widget.incomingCall.callType == CallType.video
                                  ? Icons.videocam
                                  : Icons.call,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Accept',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
