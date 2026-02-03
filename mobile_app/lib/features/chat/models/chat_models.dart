class Conversation {
  final String id;
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final String participantRole; // 'student' or 'tutor'
  final String? subject;
  final Message? lastMessage;
  final int unreadCount;
  final bool isOnline;
  final bool isArchived;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    required this.participantRole,
    this.subject,
    this.lastMessage,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isArchived = false,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? json['_id'] ?? '',
      participantId: json['participantId'] ?? '',
      participantName: json['participantName'] ?? '',
      participantAvatar: json['participantAvatar'],
      participantRole: json['participantRole'] ?? '',
      subject: json['subject'],
      lastMessage: json['lastMessage'] != null 
          ? Message.fromJson(json['lastMessage']) 
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      isArchived: json['isArchived'] ?? false,
      isPinned: json['isPinned'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantId': participantId,
      'participantName': participantName,
      'participantAvatar': participantAvatar,
      'participantRole': participantRole,
      'subject': subject,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'isOnline': isOnline,
      'isArchived': isArchived,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Conversation copyWith({
    String? id,
    String? participantId,
    String? participantName,
    String? participantAvatar,
    String? participantRole,
    String? subject,
    Message? lastMessage,
    int? unreadCount,
    bool? isOnline,
    bool? isArchived,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantAvatar: participantAvatar ?? this.participantAvatar,
      participantRole: participantRole ?? this.participantRole,
      subject: subject ?? this.subject,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final List<MessageAttachment> attachments;
  final String? replyToId;
  final Message? replyTo;
  final bool isEdited;
  final DateTime? editedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? callData; // Call information

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.attachments = const [],
    this.replyToId,
    this.replyTo,
    this.isEdited = false,
    this.editedAt,
    required this.createdAt,
    required this.updatedAt,
    this.callData,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? json['_id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      attachments: (json['attachments'] as List?)
          ?.map((a) => MessageAttachment.fromJson(a))
          .toList() ?? [],
      replyToId: json['replyToId'],
      replyTo: json['replyTo'] != null 
          ? Message.fromJson(json['replyTo']) 
          : null,
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null 
          ? DateTime.parse(json['editedAt']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      callData: json['callData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.name,
      'status': status.name,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'replyToId': replyToId,
      'replyTo': replyTo?.toJson(),
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    MessageStatus? status,
    List<MessageAttachment>? attachments,
    String? replyToId,
    Message? replyTo,
    bool? isEdited,
    DateTime? editedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      replyToId: replyToId ?? this.replyToId,
      replyTo: replyTo ?? this.replyTo,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MessageAttachment {
  final String id;
  final String name;
  final String url;
  final String type; // 'image', 'document', 'audio', 'video', 'voice'
  final int size;
  final String? mimeType;
  final String? thumbnail;
  final int? duration; // Duration in seconds for audio/voice messages

  const MessageAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
    this.mimeType,
    this.thumbnail,
    this.duration,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      type: json['type'] ?? '',
      size: json['size'] ?? 0,
      mimeType: json['mimeType'],
      thumbnail: json['thumbnail'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final json = {
      'name': name,
      'url': url,
      'type': type,
      'size': size,
      'mimeType': mimeType,
      'thumbnail': thumbnail,
      'duration': duration,
    };
    
    // Only include id if explicitly requested (for responses from server)
    if (includeId && id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }
}

class TypingIndicator {
  final String userId;
  final String userName;
  final String conversationId;
  final DateTime timestamp;

  const TypingIndicator({
    required this.userId,
    required this.userName,
    required this.conversationId,
    required this.timestamp,
  });

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      conversationId: json['conversationId'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'conversationId': conversationId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum MessageType {
  text,
  image,
  document,
  audio,
  video,
  voice,
  system,
  booking,
  payment,
  call,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class ChatNotification {
  final String id;
  final String title;
  final String body;
  final String conversationId;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final bool isRead;

  const ChatNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatNotification.fromJson(Map<String, dynamic> json) {
    return ChatNotification(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}