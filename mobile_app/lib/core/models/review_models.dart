// Review Models for Rating and Review System

class Review {
  final String id;
  final String bookingId;
  final String tutorId;
  final String studentId;
  final int rating;
  final String? review;
  final ReviewCategories? categories;
  final DateTime sessionDate;
  final String subject;
  final bool isVisible;
  final bool isFlagged;
  final String? flagReason;
  final String moderationStatus;
  final List<String> helpful;
  final List<String> notHelpful;
  final TutorResponse? tutorResponse;
  final bool isEdited;
  final DateTime? editedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Populated fields
  final StudentInfo? studentInfo;
  final TutorInfo? tutorInfo;

  Review({
    required this.id,
    required this.bookingId,
    required this.tutorId,
    required this.studentId,
    required this.rating,
    this.review,
    this.categories,
    required this.sessionDate,
    required this.subject,
    this.isVisible = true,
    this.isFlagged = false,
    this.flagReason,
    this.moderationStatus = 'approved',
    this.helpful = const [],
    this.notHelpful = const [],
    this.tutorResponse,
    this.isEdited = false,
    this.editedAt,
    required this.createdAt,
    required this.updatedAt,
    this.studentInfo,
    this.tutorInfo,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      tutorId: json['tutorId'] is String ? json['tutorId'] : json['tutorId']?['_id'] ?? '',
      studentId: json['studentId'] is String ? json['studentId'] : json['studentId']?['_id'] ?? '',
      rating: json['rating'] ?? 0,
      review: json['review'],
      categories: json['categories'] != null 
          ? ReviewCategories.fromJson(json['categories']) 
          : null,
      sessionDate: DateTime.parse(json['sessionDate']),
      subject: json['subject'] ?? '',
      isVisible: json['isVisible'] ?? true,
      isFlagged: json['isFlagged'] ?? false,
      flagReason: json['flagReason'],
      moderationStatus: json['moderationStatus'] ?? 'approved',
      helpful: List<String>.from(json['helpful'] ?? []),
      notHelpful: List<String>.from(json['notHelpful'] ?? []),
      tutorResponse: json['tutorResponse'] != null 
          ? TutorResponse.fromJson(json['tutorResponse']) 
          : null,
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      studentInfo: json['studentId'] is Map 
          ? StudentInfo.fromJson(json['studentId']) 
          : null,
      tutorInfo: json['tutorId'] is Map 
          ? TutorInfo.fromJson(json['tutorId']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'rating': rating,
      'review': review,
      'categories': categories?.toJson(),
    };
  }

  int get helpfulnessScore => helpful.length - notHelpful.length;

  bool canEdit() {
    final hoursSinceCreation = DateTime.now().difference(createdAt).inHours;
    return hoursSinceCreation < 24 && !isEdited;
  }
}

class ReviewCategories {
  final int? communication;
  final int? expertise;
  final int? punctuality;
  final int? helpfulness;

  ReviewCategories({
    this.communication,
    this.expertise,
    this.punctuality,
    this.helpfulness,
  });

  factory ReviewCategories.fromJson(Map<String, dynamic> json) {
    return ReviewCategories(
      communication: json['communication'],
      expertise: json['expertise'],
      punctuality: json['punctuality'],
      helpfulness: json['helpfulness'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (communication != null) 'communication': communication,
      if (expertise != null) 'expertise': expertise,
      if (punctuality != null) 'punctuality': punctuality,
      if (helpfulness != null) 'helpfulness': helpfulness,
    };
  }

  double get average {
    final values = [communication, expertise, punctuality, helpfulness]
        .where((v) => v != null)
        .map((v) => v!)
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

class TutorResponse {
  final String text;
  final DateTime respondedAt;

  TutorResponse({
    required this.text,
    required this.respondedAt,
  });

  factory TutorResponse.fromJson(Map<String, dynamic> json) {
    return TutorResponse(
      text: json['text'] ?? '',
      respondedAt: DateTime.parse(json['respondedAt']),
    );
  }
}

class StudentInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String? profilePicture;

  StudentInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profilePicture: json['profilePicture'],
    );
  }

  String get fullName => '$firstName $lastName';
}

class TutorInfo {
  final String id;
  final UserInfo? userId;

  TutorInfo({
    required this.id,
    this.userId,
  });

  factory TutorInfo.fromJson(Map<String, dynamic> json) {
    return TutorInfo(
      id: json['_id'] ?? '',
      userId: json['userId'] != null ? UserInfo.fromJson(json['userId']) : null,
    );
  }
}

class UserInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String? profilePicture;

  UserInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profilePicture: json['profilePicture'],
    );
  }

  String get fullName => '$firstName $lastName';
}

class RatingStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution;

  RatingStats({
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
  });

  factory RatingStats.fromJson(Map<String, dynamic> json) {
    final dist = json['distribution'] as Map<String, dynamic>? ?? {};
    return RatingStats(
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      distribution: {
        5: dist['5'] ?? 0,
        4: dist['4'] ?? 0,
        3: dist['3'] ?? 0,
        2: dist['2'] ?? 0,
        1: dist['1'] ?? 0,
      },
    );
  }

  int getPercentage(int stars) {
    if (totalReviews == 0) return 0;
    return ((distribution[stars] ?? 0) / totalReviews * 100).round();
  }
}

class ReviewsResponse {
  final List<Review> reviews;
  final RatingStats statistics;
  final Pagination pagination;

  ReviewsResponse({
    required this.reviews,
    required this.statistics,
    required this.pagination,
  });

  factory ReviewsResponse.fromJson(Map<String, dynamic> json) {
    return ReviewsResponse(
      reviews: (json['reviews'] as List?)
          ?.map((r) => Review.fromJson(r))
          .toList() ?? [],
      statistics: RatingStats.fromJson(json['statistics'] ?? {}),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 0,
    );
  }

  bool get hasNextPage => page < pages;
  bool get hasPreviousPage => page > 1;
}
