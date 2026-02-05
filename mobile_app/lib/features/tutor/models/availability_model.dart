class SessionTypeInfo {
  final String type; // 'online' or 'offline'
  final double hourlyRate;
  final String? meetingLocation;
  final double? travelDistance;
  final String? additionalNotes;

  const SessionTypeInfo({
    required this.type,
    required this.hourlyRate,
    this.meetingLocation,
    this.travelDistance,
    this.additionalNotes,
  });

  bool get isOnline => type == 'online';
  bool get isOffline => type == 'offline';

  factory SessionTypeInfo.fromJson(Map<String, dynamic> json) {
    return SessionTypeInfo(
      type: json['type'] ?? 'online',
      hourlyRate: (json['hourlyRate'] ?? 0).toDouble(),
      meetingLocation: json['meetingLocation'],
      travelDistance: json['travelDistance'] != null 
          ? (json['travelDistance'] as num).toDouble() 
          : null,
      additionalNotes: json['additionalNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'hourlyRate': hourlyRate,
      if (meetingLocation != null) 'meetingLocation': meetingLocation,
      if (travelDistance != null) 'travelDistance': travelDistance,
      if (additionalNotes != null) 'additionalNotes': additionalNotes,
    };
  }

  SessionTypeInfo copyWith({
    String? type,
    double? hourlyRate,
    String? meetingLocation,
    double? travelDistance,
    String? additionalNotes,
  }) {
    return SessionTypeInfo(
      type: type ?? this.type,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      meetingLocation: meetingLocation ?? this.meetingLocation,
      travelDistance: travelDistance ?? this.travelDistance,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }
}

class AvailabilitySlot {
  final String id;
  final String tutorId;
  final DateTime date;
  final TimeSlot timeSlot;
  final List<SessionTypeInfo> sessionTypes;
  final bool isAvailable;
  final bool isRecurring;
  final String? recurringPattern; // 'weekly', 'daily', etc.
  final BookingInfo? booking;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AvailabilitySlot({
    required this.id,
    required this.tutorId,
    required this.date,
    required this.timeSlot,
    required this.sessionTypes,
    required this.isAvailable,
    this.isRecurring = false,
    this.recurringPattern,
    this.booking,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isBooked => booking != null;
  bool get isPast {
    // Combine date with end time to check if the slot has passed
    final slotDateTime = _getSlotEndDateTime();
    return slotDateTime.isBefore(DateTime.now());
  }
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  bool get isUpcoming {
    // Combine date with start time to check if the slot is upcoming
    final slotDateTime = _getSlotStartDateTime();
    return slotDateTime.isAfter(DateTime.now());
  }

  // Get session types
  bool get hasOnlineSession => sessionTypes.any((st) => st.isOnline);
  bool get hasOfflineSession => sessionTypes.any((st) => st.isOffline);
  bool get hasBothSessionTypes => hasOnlineSession && hasOfflineSession;

  // Get pricing
  double? get onlineRate => sessionTypes.firstWhere(
    (st) => st.isOnline,
    orElse: () => SessionTypeInfo(type: 'online', hourlyRate: 0),
  ).hourlyRate;
  
  double? get offlineRate => sessionTypes.firstWhere(
    (st) => st.isOffline,
    orElse: () => SessionTypeInfo(type: 'offline', hourlyRate: 0),
  ).hourlyRate;

  double get minRate => sessionTypes.map((st) => st.hourlyRate).reduce((a, b) => a < b ? a : b);
  double get maxRate => sessionTypes.map((st) => st.hourlyRate).reduce((a, b) => a > b ? a : b);

  // Helper method to get the full datetime of the slot start
  DateTime _getSlotStartDateTime() {
    final timeParts = timeSlot.startTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  // Helper method to get the full datetime of the slot end
  DateTime _getSlotEndDateTime() {
    final timeParts = timeSlot.endTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      id: json['id'] ?? json['_id'] ?? '',
      tutorId: json['tutorId'] ?? '',
      date: DateTime.parse(json['date']),
      timeSlot: TimeSlot.fromJson(json['timeSlot']),
      sessionTypes: (json['sessionTypes'] as List<dynamic>?)
          ?.map((st) => SessionTypeInfo.fromJson(st))
          .toList() ?? [],
      isAvailable: json['isAvailable'] ?? false,
      isRecurring: json['isRecurring'] ?? false,
      recurringPattern: json['recurringPattern'],
      booking: json['booking'] != null ? BookingInfo.fromJson(json['booking']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tutorId': tutorId,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot.toJson(),
      'sessionTypes': sessionTypes.map((st) => st.toJson()).toList(),
      'isAvailable': isAvailable,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'booking': booking?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AvailabilitySlot copyWith({
    String? id,
    String? tutorId,
    DateTime? date,
    TimeSlot? timeSlot,
    List<SessionTypeInfo>? sessionTypes,
    bool? isAvailable,
    bool? isRecurring,
    String? recurringPattern,
    BookingInfo? booking,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AvailabilitySlot(
      id: id ?? this.id,
      tutorId: tutorId ?? this.tutorId,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      sessionTypes: sessionTypes ?? this.sessionTypes,
      isAvailable: isAvailable ?? this.isAvailable,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      booking: booking ?? this.booking,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TimeSlot {
  final String startTime; // "09:00"
  final String endTime;   // "10:00"
  final int durationMinutes;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
  });

  String get displayTime => '$startTime - $endTime';
  
  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'durationMinutes': durationMinutes,
    };
  }
}

class BookingInfo {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String? studentPhone;
  final String subject;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String sessionType; // 'online' or 'offline'
  final double amount;
  final String? notes;
  final String? meetingLink;
  final DateTime bookedAt;

  const BookingInfo({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    this.studentPhone,
    required this.subject,
    required this.status,
    required this.sessionType,
    required this.amount,
    this.notes,
    this.meetingLink,
    required this.bookedAt,
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isOnline => sessionType == 'online';
  bool get isOffline => sessionType == 'offline';

  factory BookingInfo.fromJson(Map<String, dynamic> json) {
    return BookingInfo(
      id: json['id'] ?? json['_id'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      studentEmail: json['studentEmail'] ?? '',
      studentPhone: json['studentPhone'],
      subject: json['subject'] ?? '',
      status: json['status'] ?? 'pending',
      sessionType: json['sessionType'] ?? 'online',
      amount: (json['amount'] ?? 0).toDouble(),
      notes: json['notes'],
      meetingLink: json['meetingLink'],
      bookedAt: DateTime.parse(json['bookedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'studentPhone': studentPhone,
      'subject': subject,
      'status': status,
      'sessionType': sessionType,
      'amount': amount,
      'notes': notes,
      'meetingLink': meetingLink,
      'bookedAt': bookedAt.toIso8601String(),
    };
  }
}

class WeeklySchedule {
  final Map<String, List<AvailabilitySlot>> schedule;
  final DateTime weekStart;
  final DateTime weekEnd;

  const WeeklySchedule({
    required this.schedule,
    required this.weekStart,
    required this.weekEnd,
  });

  List<AvailabilitySlot> getSlotsForDay(String day) {
    return schedule[day] ?? [];
  }

  List<AvailabilitySlot> get allSlots {
    return schedule.values.expand((slots) => slots).toList();
  }

  List<AvailabilitySlot> get bookedSlots {
    return allSlots.where((slot) => slot.isBooked).toList();
  }

  List<AvailabilitySlot> get availableSlots {
    return allSlots.where((slot) => slot.isAvailable && !slot.isBooked).toList();
  }

  int get totalSlots => allSlots.length;
  int get bookedSlotsCount => bookedSlots.length;
  int get availableSlotsCount => availableSlots.length;

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    final scheduleMap = <String, List<AvailabilitySlot>>{};
    
    if (json['schedule'] != null) {
      (json['schedule'] as Map<String, dynamic>).forEach((day, slots) {
        scheduleMap[day] = (slots as List)
            .map((slot) => AvailabilitySlot.fromJson(slot))
            .toList();
      });
    }

    return WeeklySchedule(
      schedule: scheduleMap,
      weekStart: DateTime.parse(json['weekStart']),
      weekEnd: DateTime.parse(json['weekEnd']),
    );
  }

  Map<String, dynamic> toJson() {
    final scheduleMap = <String, dynamic>{};
    schedule.forEach((day, slots) {
      scheduleMap[day] = slots.map((slot) => slot.toJson()).toList();
    });

    return {
      'schedule': scheduleMap,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
    };
  }
}