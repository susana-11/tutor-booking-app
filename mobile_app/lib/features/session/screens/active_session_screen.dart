import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/session_timer.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/agora_service.dart';

class ActiveSessionScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> sessionData;

  const ActiveSessionScreen({
    Key? key,
    required this.bookingId,
    required this.sessionData,
  }) : super(key: key);

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  final SessionService _sessionService = SessionService();
  final AgoraService _agoraService = AgoraService();
  bool _isEnding = false;
  final TextEditingController _notesController = TextEditingController();
  
  // Video/Audio controls
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  int? _remoteUid;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndInitialize();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _agoraService.leaveChannel();
    _agoraService.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionsAndInitialize() async {
    try {
      print('🔐 Requesting permissions...');
      
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

      print('📷 Camera: $cameraGranted, 🎤 Mic: $micGranted');

      if (cameraGranted && micGranted) {
        await _initializeSession();
      } else {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Camera and microphone permissions are required';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please grant camera and microphone permissions'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Permission error: $e');
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to request permissions: $e';
      });
    }
  }

  Future<void> _initializeSession() async {
    final channelName = widget.sessionData['channelName'] as String;
    final token = widget.sessionData['token'] as String;
    final uid = widget.sessionData['uid'] as int;

    try {
      print('🎥 Initializing Agora...');
      print('📺 Channel: $channelName, UID: $uid');
      
      // Initialize Agora
      await _agoraService.initialize();
      print('✅ Agora initialized');
      
      // Register event handlers BEFORE joining
      _agoraService.registerEventHandlers(
        onUserJoined: (connection, remoteUid, elapsed) {
          print('👤 Remote user joined: $remoteUid');
          if (mounted) {
            setState(() {
              _remoteUid = remoteUid;
            });
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          print('👤 Remote user left: $remoteUid');
          if (mounted) {
            setState(() {
              _remoteUid = null;
            });
          }
        },
        onLeaveChannel: (connection, stats) {
          print('📴 Left channel');
          if (mounted) {
            setState(() {
              _remoteUid = null;
            });
          }
        },
        onError: (err, msg) {
          print('❌ Agora error: $err - $msg');
        },
      );
      print('✅ Event handlers registered');
      
      // Join channel
      await _agoraService.joinChannel(
        token: token,
        channelName: channelName,
        uid: uid,
        enableVideo: true,
      );
      print('✅ Joined channel');
      
      // Enable speakerphone
      await _agoraService.enableSpeakerphone(true);
      print('✅ Speakerphone enabled');
      
      setState(() {
        _isInitializing = false;
        _isSpeakerOn = true;
      });
      
    } catch (e) {
      print('❌ Session initialization error: $e');
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to join session: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join session: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  // Toggle microphone
  Future<void> _toggleMute() async {
    try {
      setState(() {
        _isMuted = !_isMuted;
      });
      await _agoraService.muteLocalAudio(_isMuted);
      print('🎤 Mute: $_isMuted');
    } catch (e) {
      print('❌ Toggle mute error: $e');
    }
  }
  
  // Toggle camera
  Future<void> _toggleVideo() async {
    try {
      setState(() {
        _isVideoOff = !_isVideoOff;
      });
      await _agoraService.muteLocalVideo(_isVideoOff);
      print('📹 Video off: $_isVideoOff');
    } catch (e) {
      print('❌ Toggle video error: $e');
    }
  }
  
  // Switch camera
  Future<void> _switchCamera() async {
    try {
      await _agoraService.switchCamera();
      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });
      print('📷 Camera switched to: ${_isFrontCamera ? "front" : "back"}');
    } catch (e) {
      print('❌ Switch camera error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to switch camera: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  
  // Toggle speaker
  Future<void> _toggleSpeaker() async {
    try {
      setState(() {
        _isSpeakerOn = !_isSpeakerOn;
      });
      await _agoraService.enableSpeakerphone(_isSpeakerOn);
      print('🔊 Speaker: $_isSpeakerOn');
    } catch (e) {
      print('❌ Toggle speaker error: $e');
    }
  }

  Future<void> _endSession() async {
    // Show notes dialog first
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => _SessionNotesDialog(
        initialNotes: _notesController.text,
      ),
    );
    
    if (notes == null) return; // User cancelled
    
    setState(() => _isEnding = true);

    try {
      print('🔴 Ending session...');
      
      // End session on backend FIRST
      final response = await _sessionService.endSession(
        widget.bookingId,
        sessionNotes: notes.trim().isEmpty ? null : notes.trim(),
      );

      if (response.success) {
        print('✅ Session ended on server');
        
        // Then leave Agora channel
        await _agoraService.leaveChannel();
        print('✅ Left Agora channel');
        
        if (mounted) {
          // Show completion dialog
          await _showCompletionDialog();
        }
      } else {
        print('❌ Failed to end session: ${response.error}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to end session'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error ending session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnding = false);
      }
    }
  }

  Future<void> _showCompletionDialog() async {
    // Close the dialog and navigate back
    if (!mounted) return;
    
    // Pop the session screen first
    Navigator.of(context).pop();
    
    // Small delay to ensure navigation completes
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    // Show completion dialog
    final shouldRate = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Text('Session Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your session has ended successfully.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Payment Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Payment will be released to the tutor in 24 hours.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Would you like to rate this session?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
    
    if (!mounted) return;
    
    if (shouldRate == true) {
      // Extract booking details from session data
      final otherParty = widget.sessionData['otherParty'] as Map<String, dynamic>?;
      final subject = widget.sessionData['subject'] as String? ?? 'Session';
      
      // Navigate to review screen with booking details
      context.push(
        '/create-review/${widget.bookingId}',
        extra: {
          'bookingDetails': {
            'tutorName': otherParty?['name'] ?? 'Tutor',
            'subject': subject,
            'bookingId': widget.bookingId,
          },
        },
      );
    }
  }

  void _onTimeUp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session time is up!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      ),
    );

    // Auto-end session
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _endSession();
      }
    });
  }

  void _onWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏰ 5 minutes remaining in session'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.sessionData['duration'] as int? ?? 60;
    final startTime = widget.sessionData['sessionStartedAt'] != null
        ? DateTime.parse(widget.sessionData['sessionStartedAt'] as String)
        : DateTime.now();
    final otherParty = widget.sessionData['otherParty'] as Map<String, dynamic>?;

    // Show loading or error state
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Initializing video session...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 64),
                SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Session?'),
            content: const Text(
              'Are you sure you want to leave? The session will continue running.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Video Views
              _buildVideoViews(),
              
              // Top Bar with Timer
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              otherParty?['name'] ?? 'Session',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            CompactSessionTimer(
                              durationMinutes: duration,
                              startTime: startTime,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom Controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Call Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: _isMuted ? Icons.mic_off : Icons.mic,
                            label: _isMuted ? 'Unmute' : 'Mute',
                            onPressed: _toggleMute,
                            isActive: !_isMuted,
                          ),
                          _buildControlButton(
                            icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                            label: _isVideoOff ? 'Camera Off' : 'Camera On',
                            onPressed: _toggleVideo,
                            isActive: !_isVideoOff,
                          ),
                          _buildControlButton(
                            icon: Icons.flip_camera_ios,
                            label: 'Flip',
                            onPressed: _switchCamera,
                            isActive: true,
                          ),
                          _buildControlButton(
                            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                            label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                            onPressed: _toggleSpeaker,
                            isActive: _isSpeakerOn,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // End Session Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isEnding ? null : _endSession,
                          icon: _isEnding
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.call_end),
                          label: Text(_isEnding ? 'Ending...' : 'End Session'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build video views
  Widget _buildVideoViews() {
    if (_agoraService.engine == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
    return Stack(
      children: [
        // Remote video (full screen)
        _remoteUid != null
            ? AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _agoraService.engine!,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(
                    channelId: widget.sessionData['channelName'] as String,
                  ),
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[800],
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Waiting for other participant...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
        
        // Local video (small preview in corner)
        if (!_isVideoOff)
          Positioned(
            top: 80,
            right: 16,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _agoraService.engine!,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  // Build control button
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.2) : Colors.red.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
            iconSize: 28,
          ),
        ),
        const SizedBox(height: 4),
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
}

// Session Notes Dialog
class _SessionNotesDialog extends StatefulWidget {
  final String initialNotes;

  const _SessionNotesDialog({
    Key? key,
    required this.initialNotes,
  }) : super(key: key);

  @override
  State<_SessionNotesDialog> createState() => _SessionNotesDialogState();
}

class _SessionNotesDialogState extends State<_SessionNotesDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('End Session'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Are you sure you want to end this session?',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          const Text(
            'Session Notes (Optional)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Add notes about this session...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('End Session'),
        ),
      ],
    );
  }
}
