class BookingModel {
  final String id;
  final String studentId;
  final String tutorId;
  final String tutorName;
  final String? tutorEmail;
  final String? tutorPhone;
  final String? studentName;
  final String? studentEmail;
  final DateTime sessionDate;
  final String startTime;
  final String endTime;
  final int duration;
  final String subject;
  final String sessionType;
  final String? location;
  final String status;
  final double pricePerHour;
  final double totalAmount;
  
  // Payment
  final String paymentStatus;
  final String? paymentMethod;
  final String? paymentIntentId;
  final String? transactionId;
  final DateTime? paidAt;
  
  // Refund
  final double refundAmount;
  final String? refundReason;
  final String refundStatus;
  final DateTime? refundedAt;
  
  // Platform fee
  final double platformFee;
  final double platformFeePercentage;
  final double tutorEarnings;
  
  // Session notes
  final String? studentNotes;
  final String? tutorNotes;
  final String? sessionNotes;
  
  // Meeting info
  final String? meetingLink;
  final String? meetingId;
  
  // Cancellation
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  
  // Rescheduling
  final List<RescheduleRequest> rescheduleRequests;
  final bool isRescheduled;
  
  // Session completion
  final DateTime? completedAt;
  final DateTime? sessionStartedAt;
  final DateTime? sessionEndedAt;
  final int? actualDuration;
  
  // Rating
  final BookingRating? rating;
  
  // Dispute
  final BookingDispute? dispute;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.studentId,
    required this.tutorId,
    required this.tutorName,
    this.tutorEmail,
    this.tutorPhone,
    this.studentName,
    this.studentEmail,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.subject,
    required this.sessionType,
    this.location,
    required this.status,
    required this.pricePerHour,
    required this.totalAmount,
    required this.paymentStatus,
    this.paymentMethod,
    this.paymentIntentId,
    this.transactionId,
    this.paidAt,
    this.refundAmount = 0,
    this.refundReason,
    this.refundStatus = 'none',
    this.refundedAt,
    this.platformFee = 0,
    this.platformFeePercentage = 15,
    this.tutorEarnings = 0,
    this.studentNotes,
    this.tutorNotes,
    this.sessionNotes,
    this.meetingLink,
    this.meetingId,
    this.cancellationReason,
    this.cancelledBy,
    this.cancelledAt,
    this.rescheduleRequests = const [],
    this.isRescheduled = false,
    this.completedAt,
    this.sessionStartedAt,
    this.sessionEndedAt,
    this.actualDuration,
    this.rating,
    this.dispute,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['_id'] ?? json['id'] ?? '',
      studentId: json['studentId']?['_id'] ?? json['studentId'] ?? '',
      tutorId: json['tutorId']?['_id'] ?? json['tutorId'] ?? '',
      tutorName: json['tutorName'] ?? 
                 (json['tutorId'] != null && json['tutorId'] is Map
                     ? '${json['tutorId']['firstName'] ?? ''} ${json['tutorId']['lastName'] ?? ''}'
                     : ''),
      tutorEmail: json['tutorEmail'] ?? json['tutorId']?['email'],
      tutorPhone: json['tutorPhone'] ?? json['tutorId']?['phone'],
      studentName: json['studentName'] ?? 
                   (json['studentId'] != null && json['studentId'] is Map
                       ? '${json['studentId']['firstName'] ?? ''} ${json['studentId']['lastName'] ?? ''}'
                       : ''),
      studentEmail: json['studentEmail'] ?? json['studentId']?['email'],
      sessionDate: DateTime.parse(json['sessionDate']),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      duration: json['duration'] ?? 0,
      subject: json['subject']?['name'] ?? json['subject'] ?? '',
      sessionType: json['sessionType'] ?? 'online',
      location: json['location'],
      status: json['status'] ?? 'pending',
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentStatus: json['paymentStatus'] ?? 'pending',
      paymentMethod: json['paymentMethod'],
      paymentIntentId: json['paymentIntentId'],
      transactionId: json['transactionId'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      refundAmount: (json['refundAmount'] ?? 0).toDouble(),
      refundReason: json['refundReason'],
      refundStatus: json['refundStatus'] ?? 'none',
      refundedAt: json['refundedAt'] != null ? DateTime.parse(json['refundedAt']) : null,
      platformFee: (json['platformFee'] ?? 0).toDouble(),
      platformFeePercentage: (json['platformFeePercentage'] ?? 15).toDouble(),
      tutorEarnings: (json['tutorEarnings'] ?? 0).toDouble(),
      studentNotes: json['notes']?['student'],
      tutorNotes: json['notes']?['tutor'],
      sessionNotes: json['sessionNotes'],
      meetingLink: json['meetingLink'],
      meetingId: json['meetingId'],
      cancellationReason: json['cancellationReason'],
      cancelledBy: json['cancelledBy'],
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
      rescheduleRequests: (json['rescheduleRequests'] as List?)
              ?.map((r) => RescheduleRequest.fromJson(r))
              .toList() ??
          [],
      isRescheduled: json['isRescheduled'] ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      sessionStartedAt: json['sessionStartedAt'] != null ? DateTime.parse(json['sessionStartedAt']) : null,
      sessionEndedAt: json['sessionEndedAt'] != null ? DateTime.parse(json['sessionEndedAt']) : null,
      actualDuration: json['actualDuration'],
      rating: json['rating'] != null ? BookingRating.fromJson(json['rating']) : null,
      dispute: json['dispute'] != null ? BookingDispute.fromJson(json['dispute']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'tutorId': tutorId,
      'sessionDate': sessionDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
      'subject': subject,
      'sessionType': sessionType,
      'location': location,
      'status': status,
      'pricePerHour': pricePerHour,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
    };
  }

  bool get canBeCancelled {
    if (!['pending', 'confirmed'].contains(status)) return false;
    
    final now = DateTime.now();
    final sessionDateTime = DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
      int.parse(startTime.split(':')[0]),
      int.parse(startTime.split(':')[1]),
    );
    
    final hoursUntilSession = sessionDateTime.difference(now).inHours;
    return hoursUntilSession >= 24;
  }

  bool get canBeRescheduled {
    if (!['pending', 'confirmed'].contains(status)) return false;
    
    final now = DateTime.now();
    final sessionDateTime = DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
      int.parse(startTime.split(':')[0]),
      int.parse(startTime.split(':')[1]),
    );
    
    final hoursUntilSession = sessionDateTime.difference(now).inHours;
    return hoursUntilSession >= 48;
  }

  bool get canBeRated {
    return status == 'completed' && rating?.studentRating == null;
  }

  bool get isUpcoming {
    final now = DateTime.now();
    final sessionDateTime = DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
      int.parse(startTime.split(':')[0]),
      int.parse(startTime.split(':')[1]),
    );
    
    return sessionDateTime.isAfter(now) && ['confirmed', 'pending'].contains(status);
  }
}

class RescheduleRequest {
  final String id;
  final String requestedBy;
  final DateTime requestedAt;
  final DateTime newDate;
  final String newStartTime;
  final String newEndTime;
  final String reason;
  final String status;
  final DateTime? respondedAt;

  RescheduleRequest({
    required this.id,
    required this.requestedBy,
    required this.requestedAt,
    required this.newDate,
    required this.newStartTime,
    required this.newEndTime,
    required this.reason,
    required this.status,
    this.respondedAt,
  });

  factory RescheduleRequest.fromJson(Map<String, dynamic> json) {
    return RescheduleRequest(
      id: json['_id'] ?? '',
      requestedBy: json['requestedBy'] ?? '',
      requestedAt: DateTime.parse(json['requestedAt']),
      newDate: DateTime.parse(json['newDate']),
      newStartTime: json['newStartTime'] ?? '',
      newEndTime: json['newEndTime'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
    );
  }
}

class BookingRating {
  final RatingDetail? studentRating;
  final RatingDetail? tutorRating;

  BookingRating({
    this.studentRating,
    this.tutorRating,
  });

  factory BookingRating.fromJson(Map<String, dynamic> json) {
    return BookingRating(
      studentRating: json['studentRating'] != null 
          ? RatingDetail.fromJson(json['studentRating']) 
          : null,
      tutorRating: json['tutorRating'] != null 
          ? RatingDetail.fromJson(json['tutorRating']) 
          : null,
    );
  }
}

class RatingDetail {
  final double score;
  final String? review;
  final DateTime ratedAt;

  RatingDetail({
    required this.score,
    this.review,
    required this.ratedAt,
  });

  factory RatingDetail.fromJson(Map<String, dynamic> json) {
    return RatingDetail(
      score: (json['score'] ?? 0).toDouble(),
      review: json['review'],
      ratedAt: DateTime.parse(json['ratedAt']),
    );
  }
}

class BookingDispute {
  final bool isDisputed;
  final String? disputedBy;
  final String? disputeReason;
  final String? disputeDescription;
  final DateTime? disputedAt;
  final String? disputeStatus;
  final String? resolution;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  BookingDispute({
    required this.isDisputed,
    this.disputedBy,
    this.disputeReason,
    this.disputeDescription,
    this.disputedAt,
    this.disputeStatus,
    this.resolution,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory BookingDispute.fromJson(Map<String, dynamic> json) {
    return BookingDispute(
      isDisputed: json['isDisputed'] ?? false,
      disputedBy: json['disputedBy'],
      disputeReason: json['disputeReason'],
      disputeDescription: json['disputeDescription'],
      disputedAt: json['disputedAt'] != null ? DateTime.parse(json['disputedAt']) : null,
      disputeStatus: json['disputeStatus'],
      resolution: json['resolution'],
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      resolvedBy: json['resolvedBy'],
    );
  }
}
