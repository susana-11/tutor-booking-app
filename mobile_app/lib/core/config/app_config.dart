import 'package:flutter/foundation.dart';

class AppConfig {
  static late AppConfig _instance;
  static AppConfig get instance => _instance;

  // API Configuration
  // Cloud server (Render deployment)
  static const String _baseUrlProd = 'https://tutor-app-backend-wtru.onrender.com/api';
  static const String _baseUrlDev = 'https://tutor-app-backend-wtru.onrender.com/api';
  
  // Local network testing - Uncomment to use local server
  // static const String _baseUrlDev = 'http://192.168.1.5:5000/api';
  // static const String _baseUrlProd = 'http://192.168.1.5:5000/api';
  
  String get baseUrl => kDebugMode ? _baseUrlDev : _baseUrlProd;
  
  // App Information
  static const String appName = 'Tutor Booking App';
  static const String appVersion = '1.0.0';
  
  // Feature Flags
  static const bool enableVideoCall = true;
  static const bool enableChat = true;
  static const bool enablePushNotifications = true;
  static const bool enableLocationServices = true;
  
  // Business Rules
  static const int maxBookingDaysInAdvance = 30;
  static const int minCancellationHours = 24;
  static const int sessionReminderMinutes = 60;
  static const double platformCommissionRate = 0.15; // 15%
  
  // File Upload Limits
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache Duration (in minutes)
  static const int cacheExpiryMinutes = 30;
  
  // Validation Rules
  static const int minPasswordLength = 6;
  static const int maxBioLength = 1000;
  static const int maxMessageLength = 500;
  
  // Payment Configuration
  static const String currency = 'USD';
  static const String currencySymbol = '\$';
  
  // Video Call Configuration
  static const String agoraAppId = '0ad4c02139aa48b28e813b4e9676ea0a';
  
  // Map Configuration
  static const String googleMapsApiKey = 'your_google_maps_api_key';
  
  // Social Media Links
  static const String supportEmail = 'support@tutorbookingapp.com';
  static const String privacyPolicyUrl = 'https://tutorbookingapp.com/privacy';
  static const String termsOfServiceUrl = 'https://tutorbookingapp.com/terms';
  
  static Future<void> initialize() async {
    _instance = AppConfig._internal();
    
    // Initialize any async configuration here
    if (kDebugMode) {
      print('🚀 App initialized in DEBUG mode');
      print('📡 API Base URL: ${_instance.baseUrl}');
    }
  }
  
  AppConfig._internal();
  
  // Environment-specific configurations
  bool get isProduction => !kDebugMode;
  bool get isDevelopment => kDebugMode;
  
  // Logging configuration
  bool get enableLogging => kDebugMode;
  bool get enableCrashReporting => !kDebugMode;
  
  // API Timeouts (in seconds) - Increased for Render free tier wake-up time
  int get connectTimeout => 90;
  int get receiveTimeout => 90;
  int get sendTimeout => 90;
  
  // Retry configuration
  int get maxRetryAttempts => 3;
  int get retryDelaySeconds => 2;
}