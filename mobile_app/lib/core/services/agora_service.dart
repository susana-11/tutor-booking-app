import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../config/app_config.dart';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  RtcEngine? _engine;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized && _engine != null) {
      print('✅ Agora already initialized');
      return;
    }

    try {
      print('🚀 Initializing Agora RTC Engine...');
      
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: AppConfig.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _isInitialized = true;
      print('✅ Agora RTC Engine initialized');
    } catch (e) {
      print('❌ Failed to initialize Agora: $e');
      rethrow;
    }
  }

  Future<void> joinChannel({
    required String token,
    required String channelName,
    required int uid,
    bool enableVideo = false,
  }) async {
    if (_engine == null) {
      await initialize();
    }

    try {
      print('📞 Joining channel: $channelName with UID: $uid');

      // Enable audio
      await _engine!.enableAudio();

      if (enableVideo) {
        // Enable video
        await _engine!.enableVideo();
        await _engine!.startPreview();
        print('📹 Video enabled');
      } else {
        await _engine!.disableVideo();
        print('🎤 Audio-only mode');
      }

      // Join channel
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      print('✅ Joined channel successfully');
    } catch (e) {
      print('❌ Failed to join channel: $e');
      rethrow;
    }
  }

  Future<void> leaveChannel() async {
    if (_engine == null) return;

    try {
      print('📴 Leaving channel...');
      await _engine!.leaveChannel();
      print('✅ Left channel');
    } catch (e) {
      print('❌ Failed to leave channel: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_engine == null) return;

    try {
      await _engine!.switchCamera();
      print('📷 Camera switched');
    } catch (e) {
      print('❌ Failed to switch camera: $e');
    }
  }

  Future<void> muteLocalAudio(bool muted) async {
    if (_engine == null) return;

    try {
      await _engine!.muteLocalAudioStream(muted);
      print('🎤 Local audio ${muted ? 'muted' : 'unmuted'}');
    } catch (e) {
      print('❌ Failed to mute/unmute audio: $e');
    }
  }

  Future<void> muteLocalVideo(bool muted) async {
    if (_engine == null) return;

    try {
      await _engine!.muteLocalVideoStream(muted);
      print('📹 Local video ${muted ? 'disabled' : 'enabled'}');
    } catch (e) {
      print('❌ Failed to mute/unmute video: $e');
    }
  }

  Future<void> enableSpeakerphone(bool enabled) async {
    if (_engine == null) return;

    try {
      await _engine!.setEnableSpeakerphone(enabled);
      print('🔊 Speakerphone ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      print('❌ Failed to toggle speakerphone: $e');
    }
  }

  void registerEventHandlers({
    required Function(RtcConnection connection, int remoteUid, int elapsed) onUserJoined,
    required Function(RtcConnection connection, int remoteUid, UserOfflineReasonType reason) onUserOffline,
    required Function(RtcConnection connection, RtcStats stats) onLeaveChannel,
    Function(ErrorCodeType err, String msg)? onError,
  }) {
    if (_engine == null) return;

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          print('✅ Join channel success: ${connection.channelId}');
        },
        onUserJoined: onUserJoined,
        onUserOffline: onUserOffline,
        onLeaveChannel: onLeaveChannel,
        onError: onError ?? (err, msg) {
          print('❌ Agora error: $err - $msg');
        },
        onConnectionStateChanged: (connection, state, reason) {
          print('🔌 Connection state: $state, reason: $reason');
        },
      ),
    );
  }

  RtcEngine? get engine => _engine;

  bool get isInitialized => _isInitialized;

  Future<void> dispose() async {
    if (_engine == null) return;

    try {
      print('🧹 Disposing Agora RTC Engine...');
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
      _isInitialized = false;
      print('✅ Agora RTC Engine disposed');
    } catch (e) {
      print('❌ Failed to dispose Agora: $e');
    }
  }
}
