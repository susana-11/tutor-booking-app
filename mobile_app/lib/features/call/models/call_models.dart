enum CallType { voice, video }

enum CallStatus {
  initiated,
  ringing,
  answered,
  ended,
  missed,
  rejected,
  failed,
  busy
}

class CallSession {
  final String callId;
  final String channelName;
  final String token;
  final int uid;
  final CallType callType;
  final CallParticipant participant;
  final bool isIncoming;

  CallSession({
    required this.callId,
    required this.channelName,
    required this.token,
    required this.uid,
    required this.callType,
    required this.participant,
    this.isIncoming = false,
  });

  factory CallSession.fromJson(Map<String, dynamic> json) {
    return CallSession(
      callId: json['callId'] ?? '',
      channelName: json['channelName'] ?? '',
      token: json['token'] ?? '',
      uid: json['uid'] ?? 0,
      callType: json['callType'] == 'video' ? CallType.video : CallType.voice,
      participant: CallParticipant.fromJson(
        json['receiver'] ?? json['initiator'] ?? {},
      ),
      isIncoming: json['isIncoming'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'channelName': channelName,
      'token': token,
      'uid': uid,
      'callType': callType.name,
      'participant': participant.toJson(),
      'isIncoming': isIncoming,
    };
  }
}

class CallParticipant {
  final String id;
  final String name;
  final String? avatar;

  CallParticipant({
    required this.id,
    required this.name,
    this.avatar,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
    };
  }
}

class IncomingCall {
  final String callId;
  final String channelName;
  final String token;
  final int uid;
  final CallType callType;
  final CallParticipant initiator;

  IncomingCall({
    required this.callId,
    required this.channelName,
    required this.token,
    required this.uid,
    required this.callType,
    required this.initiator,
  });

  factory IncomingCall.fromJson(Map<String, dynamic> json) {
    return IncomingCall(
      callId: json['callId'] ?? '',
      channelName: json['channelName'] ?? '',
      token: json['token'] ?? '',
      uid: json['uid'] ?? 0,
      callType: json['callType'] == 'video' ? CallType.video : CallType.voice,
      initiator: CallParticipant.fromJson(json['initiator'] ?? {}),
    );
  }

  CallSession toCallSession() {
    return CallSession(
      callId: callId,
      channelName: channelName,
      token: token,
      uid: uid,
      callType: callType,
      participant: initiator,
      isIncoming: true,
    );
  }
}

class CallHistory {
  final String id;
  final String callId;
  final CallType callType;
  final CallStatus status;
  final CallParticipant otherParticipant;
  final bool isInitiator;
  final DateTime createdAt;
  final int duration; // in seconds

  CallHistory({
    required this.id,
    required this.callId,
    required this.callType,
    required this.status,
    required this.otherParticipant,
    required this.isInitiator,
    required this.createdAt,
    this.duration = 0,
  });

  factory CallHistory.fromJson(Map<String, dynamic> json, String currentUserId) {
    final isInitiator = json['initiatorId']['_id'] == currentUserId;
    final otherParticipant = isInitiator
        ? json['receiverId']
        : json['initiatorId'];

    return CallHistory(
      id: json['_id'] ?? json['id'] ?? '',
      callId: json['callId'] ?? '',
      callType: json['callType'] == 'video' ? CallType.video : CallType.voice,
      status: _parseStatus(json['status']),
      otherParticipant: CallParticipant(
        id: otherParticipant['_id'] ?? '',
        name: '${otherParticipant['firstName']} ${otherParticipant['lastName']}',
        avatar: otherParticipant['profilePicture'],
      ),
      isInitiator: isInitiator,
      createdAt: DateTime.parse(json['createdAt']),
      duration: json['duration'] ?? 0,
    );
  }

  static CallStatus _parseStatus(String? status) {
    switch (status) {
      case 'initiated':
        return CallStatus.initiated;
      case 'ringing':
        return CallStatus.ringing;
      case 'answered':
        return CallStatus.answered;
      case 'ended':
        return CallStatus.ended;
      case 'missed':
        return CallStatus.missed;
      case 'rejected':
        return CallStatus.rejected;
      case 'failed':
        return CallStatus.failed;
      case 'busy':
        return CallStatus.busy;
      default:
        return CallStatus.ended;
    }
  }

  String get statusText {
    switch (status) {
      case CallStatus.missed:
        return isInitiator ? 'Cancelled' : 'Missed';
      case CallStatus.rejected:
        return isInitiator ? 'Rejected' : 'Declined';
      case CallStatus.ended:
        return isInitiator ? 'Outgoing' : 'Incoming';
      default:
        return status.name;
    }
  }

  String get durationText {
    if (duration == 0) return '';
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes}m ${seconds}s';
  }
}
