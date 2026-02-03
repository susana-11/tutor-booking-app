import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_theme.dart';

class VoiceRecorder extends StatefulWidget {
  final Function(String audioPath, Duration duration) onRecordingComplete;
  final VoidCallback onCancel;

  const VoiceRecorder({
    Key? key,
    required this.onRecordingComplete,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> with SingleTickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  Duration _duration = Duration.zero;
  late AnimationController _animationController;
  StreamSubscription? _durationSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _startRecording();
  }

  Future<void> _startRecording() async {
    final started = await _audioService.startRecording();
    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start recording. Please check microphone permission.')),
        );
        widget.onCancel();
      }
      return;
    }

    // Listen to duration updates
    _durationSubscription = _audioService.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
      
      // Auto-stop after 5 minutes
      if (duration.inMinutes >= 5) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    final path = await _audioService.stopRecording();
    _durationSubscription?.cancel();
    
    if (path != null && mounted) {
      widget.onRecordingComplete(path, _duration);
    }
  }

  Future<void> _cancelRecording() async {
    await _audioService.cancelRecording();
    _durationSubscription?.cancel();
    widget.onCancel();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cancel button
            IconButton(
              onPressed: _cancelRecording,
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Cancel',
            ),
            
            const SizedBox(width: 8),
            
            // Recording indicator
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.5 + (_animationController.value * 0.5)),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
            
            const SizedBox(width: 12),
            
            // Duration
            Text(
              _formatDuration(_duration),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const Spacer(),
            
            // Waveform animation
            Row(
              children: List.generate(5, (index) {
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final delay = index * 0.2;
                    final value = (_animationController.value + delay) % 1.0;
                    final height = 10 + (value * 20);
                    
                    return Container(
                      width: 3,
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                );
              }),
            ),
            
            const Spacer(),
            
            // Send button
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _stopRecording,
                icon: const Icon(Icons.send, color: Colors.white),
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _durationSubscription?.cancel();
    super.dispose();
  }
}
