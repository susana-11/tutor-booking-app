class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String category;
  final String priority;
  final String status;
  final String description;
  final List<TicketMessage> messages;
  final String? assignedTo;
  final int? rating;
  final String? feedback;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    required this.description,
    required this.messages,
    this.assignedTo,
    this.rating,
    this.feedback,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      subject: json['subject'] ?? '',
      category: json['category'] ?? '',
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'open',
      description: json['description'] ?? '',
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => TicketMessage.fromJson(m))
              .toList() ??
          [],
      assignedTo: json['assignedTo'],
      rating: json['rating'],
      feedback: json['feedback'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'subject': subject,
      'category': category,
      'priority': priority,
      'status': status,
      'description': description,
      'messages': messages.map((m) => m.toJson()).toList(),
      'assignedTo': assignedTo,
      'rating': rating,
      'feedback': feedback,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class TicketMessage {
  final String sender;
  final String senderRole;
  final String message;
  final DateTime timestamp;

  TicketMessage({
    required this.sender,
    required this.senderRole,
    required this.message,
    required this.timestamp,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      sender: json['sender'] ?? '',
      senderRole: json['senderRole'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'senderRole': senderRole,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class FAQ {
  final String id;
  final String question;
  final String answer;
  final String category;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['_id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      category: json['category'] ?? '',
    );
  }
}
