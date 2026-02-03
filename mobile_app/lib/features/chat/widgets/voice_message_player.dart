import 'package:flutter/material.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_theme.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final bool isSentByMe;
  final Duration? duration;

  const VoiceMessagePlayer({
    Key? key,
    required this.audioUrl,
    required this.isSentByMe,
    this.duration,
  }) : super(key: key);

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final AudioService _audioService = AudioService();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _duration = widget.duration ?? Duration.zero;
    
    // Listen to playback position
    _audioService.playbackPositionStream.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    // Listen to playback duration
    _audioService.playbackDurationStream.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });
  }

  String _getFullAudioUrl() {
    // If URL is already absolute, return as is
    if (widget.audioUrl.startsWith('http://') || widget.audioUrl.startsWith('https://')) {
      return widget.audioUrl;
    }
    
    // Otherwise, prepend the server base URL
    const baseUrl = 'http://10.0.2.2:5000';
    return '$baseUrl${widget.audioUrl}';
  }

  void _togglePlayback() async {
    if (_isPlaying) {
      await _audioService.pausePlayback();
      setState(() => _isPlaying = false);
    } else {
      final fullUrl = _getFullAudioUrl();
      print('🎵 Playing audio from: $fullUrl');
      await _audioService.playAudio(fullUrl);
      setState(() => _isPlaying = true);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isSentByMe
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isSentByMe
                    ? AppTheme.primaryColor
                    : Colors.grey[400],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Waveform/Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isSentByMe
                          ? AppTheme.primaryColor
                          : Colors.grey[600]!,
                    ),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Duration
                Text(
                  _isPlaying
                      ? '${_formatDuration(_position)} / ${_formatDuration(_duration)}'
                      : _formatDuration(_duration),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          // Microphone icon
          Icon(
            Icons.mic,
            size: 20,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_isPlaying) {
      _audioService.stopPlayback();
    }
    super.dispose();
  }
}
