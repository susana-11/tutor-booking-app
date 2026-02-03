import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _authTokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _themePreferenceKey = 'theme_preference';
  static const String _languagePreferenceKey = 'language_preference';
  static const String _notificationSettingsKey = 'notification_settings';
  static const String _cachePrefix = 'cache_';

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Auth Token (Secure Storage)
  static Future<void> setAuthToken(String token) async {
    await _secureStorage.write(key: _authTokenKey, value: token);
  }

  static Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _authTokenKey);
  }

  static Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: _authTokenKey);
  }

  // User Data (Secure Storage)
  static Future<void> setUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _secureStorage.write(key: _userDataKey, value: jsonString);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final jsonString = await _secureStorage.read(key: _userDataKey);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> clearUserData() async {
    await _secureStorage.delete(key: _userDataKey);
  }

  // Onboarding Status
  static Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_onboardingCompletedKey, completed);
  }

  static bool getOnboardingCompleted() {
    return _prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  // Theme Preference
  static Future<void> setThemePreference(String theme) async {
    await _prefs.setString(_themePreferenceKey, theme);
  }

  static String getThemePreference() {
    return _prefs.getString(_themePreferenceKey) ?? 'system';
  }

  // Language Preference
  static Future<void> setLanguagePreference(String language) async {
    await _prefs.setString(_languagePreferenceKey, language);
  }

  static String getLanguagePreference() {
    return _prefs.getString(_languagePreferenceKey) ?? 'en';
  }

  // Notification Settings
  static Future<void> setNotificationSettings(Map<String, dynamic> settings) async {
    final jsonString = jsonEncode(settings);
    await _prefs.setString(_notificationSettingsKey, jsonString);
  }

  static Map<String, dynamic> getNotificationSettings() {
    final jsonString = _prefs.getString(_notificationSettingsKey);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return {
      'bookingReminders': true,
      'chatMessages': true,
      'sessionUpdates': true,
      'promotions': false,
    };
  }

  // Generic String Storage
  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  // Generic Int Storage
  static Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // Generic Bool Storage
  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // Generic Double Storage
  static Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  static double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  // Generic List Storage
  static Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  static List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  // JSON Object Storage
  static Future<void> setJsonObject(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    await _prefs.setString(key, jsonString);
  }

  static Map<String, dynamic>? getJsonObject(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }

  // Cache Management
  static Future<void> setCacheData(String key, Map<String, dynamic> data, {Duration? expiry}) async {
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': expiry?.inMilliseconds,
    };
    
    final jsonString = jsonEncode(cacheData);
    await _prefs.setString('$_cachePrefix$key', jsonString);
  }

  static Map<String, dynamic>? getCacheData(String key) {
    final jsonString = _prefs.getString('$_cachePrefix$key');
    if (jsonString != null) {
      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final expiry = cacheData['expiry'] as int?;
      
      // Check if cache is expired
      if (expiry != null) {
        final expiryTime = timestamp + expiry;
        if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
          // Cache expired, remove it
          clearCacheData(key);
          return null;
        }
      }
      
      return cacheData['data'] as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> clearCacheData(String key) async {
    await _prefs.remove('$_cachePrefix$key');
  }

  static Future<void> clearAllCache() async {
    final keys = _prefs.getKeys();
    final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix));
    
    for (final key in cacheKeys) {
      await _prefs.remove(key);
    }
  }

  // Remove specific key
  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  // Clear all data (logout)
  static Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs.clear();
  }

  // Check if key exists
  static bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  // Get all keys
  static Set<String> getAllKeys() {
    return _prefs.getKeys();
  }
}