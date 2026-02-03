import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/services/call_service.dart';
import '../../../core/services/agora_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/call_models.dart';

class VoiceCallScreen extends StatefulWidget {
  final CallSession callSession;

  const VoiceCallScreen({
    super.key,
    required this.callSession,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final CallService _callService = CallService();
  final AgoraService _agoraService = AgoraService();

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isConnected = false;
  String _callStatus = 'Connecting...';
  Timer? _callTimer;
  int _callDuration = 0;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      // Initialize Agora
      await _agoraService.initialize();

      // Register event handlers
      _agoraService.registerEventHandlers(
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _isConnected = true;
            _callStatus = 'Connected';
          });
          _startCallTimer();
        },
        onUserOffline: (connection, remoteUid, reason) {
          _endCall();
        },
        onLeaveChannel: (connection, stats) {
          Navigator.pop(context);
        },
      );

      // Join channel
      await _agoraService.joinChannel(
        token: widget.callSession.token,
        channelName: widget.callSession.channelName,
        uid: widget.callSession.uid,
        enableVideo: false,
      );

      // Enable speakerphone by default
      await _agoraService.enableSpeakerphone(true);

      setState(() {
        _callStatus = widget.callSession.isIncoming ? 'Incoming call...' : 'Calling...';
      });
    } catch (e) {
      print('❌ Failed to initialize call: $e');
      _showError('Failed to connect call');
      Navigator.pop(context);
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _agoraService.muteLocalAudio(_isMuted);
  }

  Future<void> _toggleSpeaker() async {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    await _agoraService.enableSpeakerphone(_isSpeakerOn);
  }

  Future<void> _endCall() async {
    try {
      _callTimer?.cancel();
      await _agoraService.leaveChannel();
      await _callService.endCall(widget.callSession.callId);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error ending call: $e');
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
        await _endCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48),
                    Text(
                      _isConnected ? _formatDuration(_callDuration) : _callStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Avatar and name
              Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: widget.callSession.participant.avatar != null
                        ? ClipOval(
                            child: Image.network(
                              widget.callSession.participant.avatar!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Text(
                              widget.callSession.participant.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.callSession.participant.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _callStatus,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Call controls
              Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                      label: 'Speaker',
                      onPressed: _toggleSpeaker,
                      isActive: _isSpeakerOn,
                    ),
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: 'Mute',
                      onPressed: _toggleMute,
                      isActive: _isMuted,
                    ),
                    _buildEndCallButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.2),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEndCallButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
          child: IconButton(
            onPressed: _endCall,
            icon: const Icon(Icons.call_end, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'End',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }
}
