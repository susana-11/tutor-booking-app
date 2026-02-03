import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  
  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  Duration get recordingDuration => _recordingDuration;
  
  // Stream controllers
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _playbackPositionController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _playbackDurationController = StreamController<Duration>.broadcast();
  
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<Duration> get playbackPositionStream => _playbackPositionController.stream;
  Stream<Duration> get playbackDurationStream => _playbackDurationController.stream;

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> startRecording() async {
    try {
      // Check permission
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        print('❌ Microphone permission denied');
        return false;
      }

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/voice_message_$timestamp.m4a';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _recordingDuration = Duration.zero;
      
      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration = Duration(seconds: timer.tick);
        if (!_durationController.isClosed) {
          _durationController.add(_recordingDuration);
        }
      });

      print('🎤 Recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      print('❌ Start recording error: $e');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _recorder.stop();
      _isRecording = false;
      _recordingTimer?.cancel();
      _recordingTimer = null;

      print('🎤 Recording stopped: $path');
      print('🎤 Duration: ${_recordingDuration.inSeconds}s');
      
      return path;
    } catch (e) {
      print('❌ Stop recording error: $e');
      return null;
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
        _recordingTimer?.cancel();
        _recordingTimer = null;
        
        // Delete the file
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        
        _currentRecordingPath = null;
        _recordingDuration = Duration.zero;
        print('🎤 Recording cancelled');
      }
    } catch (e) {
      print('❌ Cancel recording error: $e');
    }
  }

  Future<void> playAudio(String path) async {
    try {
      if (_isPlaying) {
        await stopPlayback();
      }

      _isPlaying = true;
      
      // Listen to position updates
      _player.onPositionChanged.listen((position) {
        if (!_playbackPositionController.isClosed) {
          _playbackPositionController.add(position);
        }
      });

      // Listen to duration updates
      _player.onDurationChanged.listen((duration) {
        if (!_playbackDurationController.isClosed) {
          _playbackDurationController.add(duration);
        }
      });

      // Listen to completion
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
      });

      // Determine source type based on path
      if (path.startsWith('http://') || path.startsWith('https://')) {
        // Use URL source for remote files
        await _player.play(UrlSource(path));
        print('🔊 Playing audio from URL: $path');
      } else {
        // Use device file source for local files
        await _player.play(DeviceFileSource(path));
        print('🔊 Playing audio from file: $path');
      }
    } catch (e) {
      print('❌ Play audio error: $e');
      _isPlaying = false;
      rethrow;
    }
  }

  Future<void> pausePlayback() async {
    try {
      await _player.pause();
      _isPlaying = false;
      print('⏸️ Playback paused');
    } catch (e) {
      print('❌ Pause playback error: $e');
    }
  }

  Future<void> resumePlayback() async {
    try {
      await _player.resume();
      _isPlaying = true;
      print('▶️ Playback resumed');
    } catch (e) {
      print('❌ Resume playback error: $e');
    }
  }

  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      _isPlaying = false;
      print('⏹️ Playback stopped');
    } catch (e) {
      print('❌ Stop playback error: $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print('❌ Seek error: $e');
    }
  }

  void dispose() {
    _recordingTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
    _durationController.close();
    _playbackPositionController.close();
    _playbackDurationController.close();
  }
}
