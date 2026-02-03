class AvailabilitySlot {
  final String id;
  final String tutorId;
  final DateTime date;
  final TimeSlot timeSlot;
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
    required this.amount,
    this.notes,
    this.meetingLink,
    required this.bookedAt,
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  factory BookingInfo.fromJson(Map<String, dynamic> json) {
    return BookingInfo(
      id: json['id'] ?? json['_id'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      studentEmail: json['studentEmail'] ?? '',
      studentPhone: json['studentPhone'],
      subject: json['subject'] ?? '',
      status: json['status'] ?? 'pending',
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