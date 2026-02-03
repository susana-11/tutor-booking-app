import 'dart:io';
import '../../../core/services/api_service.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final ApiService _apiService = ApiService();

  // Get user profile
  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    try {
      final response = await _apiService.get('/users/profile');

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch profile');
    } catch (e) {
      return ApiResponse.error('Failed to fetch profile: $e');
    }
  }

  // Update basic profile
  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    String? location,
    DateTime? dateOfBirth,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;
      if (phone != null) data['phone'] = phone;
      if (bio != null) data['bio'] = bio;
      if (location != null) data['location'] = location;
      if (dateOfBirth != null) data['dateOfBirth'] = dateOfBirth.toIso8601String();

      final response = await _apiService.put('/users/profile', data: data);

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to update profile');
    } catch (e) {
      return ApiResponse.error('Failed to update profile: $e');
    }
  }

  // Upload profile picture
  Future<ApiResponse<Map<String, dynamic>>> uploadProfilePicture(File imageFile) async {
    try {
      final response = await _apiService.uploadFile(
        '/users/profile/picture',
        imageFile,
        fieldName: 'profilePicture',
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to upload profile picture');
    } catch (e) {
      return ApiResponse.error('Failed to upload profile picture: $e');
    }
  }

  // Create tutor profile
  Future<ApiResponse<Map<String, dynamic>>> createTutorProfile({
    required List<String> subjects,
    required List<String> grades,
    required double hourlyRate,
    required String bio,
    required String experience,
    required String education,
    List<String>? certifications,
    List<String>? languages,
    String? teachingStyle,
    bool? isAvailableOnline,
    bool? isAvailableInPerson,
    String? location,
  }) async {
    try {
      final response = await _apiService.post('/profiles/tutor/profile', data: {
        'subjects': subjects,
        'grades': grades,
        'hourlyRate': hourlyRate,
        'bio': bio,
        'experience': experience,
        'education': education,
        'certifications': certifications,
        'languages': languages,
        'teachingStyle': teachingStyle,
        'isAvailableOnline': isAvailableOnline,
        'isAvailableInPerson': isAvailableInPerson,
        'location': location,
      });

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to create tutor profile');
    } catch (e) {
      return ApiResponse.error('Failed to create tutor profile: $e');
    }
  }

  // Update tutor profile
  Future<ApiResponse<Map<String, dynamic>>> updateTutorProfile({
    List<String>? subjects,
    List<String>? grades,
    double? hourlyRate,
    String? bio,
    String? experience,
    String? education,
    List<String>? certifications,
    List<String>? languages,
    String? teachingStyle,
    bool? isAvailableOnline,
    bool? isAvailableInPerson,
    String? location,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (subjects != null) data['subjects'] = subjects;
      if (grades != null) data['grades'] = grades;
      if (hourlyRate != null) data['hourlyRate'] = hourlyRate;
      if (bio != null) data['bio'] = bio;
      if (experience != null) data['experience'] = experience;
      if (education != null) data['education'] = education;
      if (certifications != null) data['certifications'] = certifications;
      if (languages != null) data['languages'] = languages;
      if (teachingStyle != null) data['teachingStyle'] = teachingStyle;
      if (isAvailableOnline != null) data['isAvailableOnline'] = isAvailableOnline;
      if (isAvailableInPerson != null) data['isAvailableInPerson'] = isAvailableInPerson;
      if (location != null) data['location'] = location;

      final response = await _apiService.put('/profiles/tutor/profile', data: data);

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to update tutor profile');
    } catch (e) {
      return ApiResponse.error('Failed to update tutor profile: $e');
    }
  }

  // Get tutor profile
  Future<ApiResponse<Map<String, dynamic>>> getTutorProfile([String? tutorId]) async {
    try {
      final endpoint = tutorId != null ? '/profiles/tutor/profile/$tutorId' : '/profiles/tutor/profile';
      print('🔄 Calling tutor profile endpoint: $endpoint');
      
      final response = await _apiService.get(endpoint);
      
      print('📋 Tutor profile API response: ${response.success}');
      print('📋 Tutor profile API data: ${response.data}');
      print('📋 Tutor profile API error: ${response.error}');

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch tutor profile');
    } catch (e) {
      print('❌ Tutor profile API exception: $e');
      return ApiResponse.error('Failed to fetch tutor profile: $e');
    }
  }

  // Create student profile
  Future<ApiResponse<Map<String, dynamic>>> createStudentProfile({
    required String grade,
    required List<String> interestedSubjects,
    String? school,
    String? learningGoals,
    String? preferredLearningStyle,
    List<String>? languages,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
  }) async {
    try {
      final response = await _apiService.post('/profiles/student/profile', data: {
        'grade': grade,
        'interestedSubjects': interestedSubjects,
        'school': school,
        'learningGoals': learningGoals,
        'preferredLearningStyle': preferredLearningStyle,
        'languages': languages,
        'parentName': parentName,
        'parentPhone': parentPhone,
        'parentEmail': parentEmail,
      });

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to create student profile');
    } catch (e) {
      return ApiResponse.error('Failed to create student profile: $e');
    }
  }

  // Update student profile
  Future<ApiResponse<Map<String, dynamic>>> updateStudentProfile({
    String? grade,
    List<String>? interestedSubjects,
    String? school,
    String? learningGoals,
    String? preferredLearningStyle,
    List<String>? languages,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (grade != null) data['grade'] = grade;
      if (interestedSubjects != null) data['interestedSubjects'] = interestedSubjects;
      if (school != null) data['school'] = school;
      if (learningGoals != null) data['learningGoals'] = learningGoals;
      if (preferredLearningStyle != null) data['preferredLearningStyle'] = preferredLearningStyle;
      if (languages != null) data['languages'] = languages;
      if (parentName != null) data['parentName'] = parentName;
      if (parentPhone != null) data['parentPhone'] = parentPhone;
      if (parentEmail != null) data['parentEmail'] = parentEmail;

      final response = await _apiService.put('/profiles/student/profile', data: data);

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to update student profile');
    } catch (e) {
      return ApiResponse.error('Failed to update student profile: $e');
    }
  }

  // Get student profile
  Future<ApiResponse<Map<String, dynamic>>> getStudentProfile([String? studentId]) async {
    try {
      final endpoint = studentId != null ? '/profiles/student/profile/$studentId' : '/profiles/student/profile';
      final response = await _apiService.get(endpoint);

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch student profile');
    } catch (e) {
      return ApiResponse.error('Failed to fetch student profile: $e');
    }
  }

  // Search tutors
  Future<ApiResponse<List<Map<String, dynamic>>>> searchTutors({
    String? subject,
    String? grade,
    double? minRate,
    double? maxRate,
    String? location,
    bool? isOnline,
    bool? isInPerson,
    String? sortBy,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (subject != null) queryParams['subject'] = subject;
      if (grade != null) queryParams['grade'] = grade;
      if (minRate != null) queryParams['minRate'] = minRate;
      if (maxRate != null) queryParams['maxRate'] = maxRate;
      if (location != null) queryParams['location'] = location;
      if (isOnline != null) queryParams['isOnline'] = isOnline;
      if (isInPerson != null) queryParams['isInPerson'] = isInPerson;
      if (sortBy != null) queryParams['sortBy'] = sortBy;

      final response = await _apiService.get('/profiles/tutors', queryParameters: queryParams);

      if (response.success && response.data != null) {
        final tutors = List<Map<String, dynamic>>.from(response.data['tutors'] ?? []);
        return ApiResponse.success(tutors);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to search tutors');
    } catch (e) {
      return ApiResponse.error('Failed to search tutors: $e');
    }
  }

  // Toggle tutor visibility
  Future<ApiResponse<Map<String, dynamic>>> toggleVisibility(bool isVisible) async {
    try {
      final response = await _apiService.put('/profiles/tutor/visibility', data: {
        'isActive': isVisible,
      });

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to update visibility');
    } catch (e) {
      return ApiResponse.error('Failed to update visibility: $e');
    }
  }

  // Get subjects
  Future<ApiResponse<List<Map<String, dynamic>>>> getSubjects() async {
    try {
      final response = await _apiService.get('/subjects');

      if (response.success && response.data != null) {
        final subjects = List<Map<String, dynamic>>.from(response.data['subjects'] ?? []);
        return ApiResponse.success(subjects);
      }
      
      return ApiResponse.error(response.error ?? 'Failed to fetch subjects');
    } catch (e) {
      return ApiResponse.error('Failed to fetch subjects: $e');
    }
  }
}