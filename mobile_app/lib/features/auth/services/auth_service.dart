import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();

  // Register user
  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  }) async {
    try {
      final response = await _apiService.post('/auth/register', data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role.value,
      });

      if (response.success && response.data != null) {
        final userData = response.data['user'] ?? response.data;
        final user = User.fromJson(userData);
        
        return AuthResult.success(
          user: user,
          message: response.message ?? 'Registration successful. Please verify your email.',
          requiresEmailVerification: !user.isEmailVerified,
        );
      } else {
        return AuthResult.failure(response.error ?? 'Registration failed');
      }
    } catch (e) {
      return AuthResult.failure('Registration failed: $e');
    }
  }

  // Verify email with OTP
  Future<AuthResult> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiService.post('/auth/verify-email', data: {
        'email': email,
        'otp': otp,
      });

      if (response.success && response.data != null) {
        final token = response.data['token'];
        final userData = response.data['user'];
        
        if (token != null && userData != null) {
          final user = User.fromJson(userData);
          
          // Store auth data
          await StorageService.setAuthToken(token);
          await StorageService.setUserData(userData);
          
          // Set token in API service
          _apiService.setAuthToken(token);
          
          return AuthResult.success(
            user: user,
            token: token,
            message: response.message ?? 'Email verified successfully',
          );
        }
      }
      
      return AuthResult.failure(response.error ?? 'Email verification failed');
    } catch (e) {
      return AuthResult.failure('Email verification failed: $e');
    }
  }

  // Resend OTP
  Future<AuthResult> resendOTP({required String email}) async {
    try {
      final response = await _apiService.post('/auth/resend-otp', data: {
        'email': email,
      });

      if (response.success) {
        return AuthResult.success(
          message: response.message ?? 'Verification code sent successfully',
        );
      } else {
        return AuthResult.failure(response.error ?? 'Failed to send verification code');
      }
    } catch (e) {
      return AuthResult.failure('Failed to send verification code: $e');
    }
  }

  // Login user
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.success && response.data != null) {
        final token = response.data['token'];
        final userData = response.data['user'];
        
        if (token != null && userData != null) {
          final user = User.fromJson(userData);
          
          // Store auth data
          await StorageService.setAuthToken(token);
          await StorageService.setUserData(userData);
          
          // Set token in API service
          _apiService.setAuthToken(token);
          
          return AuthResult.success(
            user: user,
            token: token,
            message: response.message ?? 'Login successful',
            requiresProfileCompletion: !user.profileCompleted,
          );
        }
      } else {
        // Check if email verification is required
        if (response.statusCode == 403) {
          return AuthResult.failure(
            response.error ?? 'Please verify your email first',
            requiresEmailVerification: true,
          );
        }
        
        return AuthResult.failure(response.error ?? 'Login failed');
      }
      
      return AuthResult.failure('Login failed');
    } catch (e) {
      return AuthResult.failure('Login failed: $e');
    }
  }

  // Logout user
  Future<AuthResult> logout() async {
    try {
      print('🚪 AuthService: Starting logout...');
      
      // Call logout endpoint
      print('🚪 AuthService: Calling logout endpoint...');
      await _apiService.post('/auth/logout');
      
      // Clear local storage
      print('🚪 AuthService: Clearing auth token...');
      await StorageService.clearAuthToken();
      
      print('🚪 AuthService: Clearing user data...');
      await StorageService.clearUserData();
      
      // Clear API service token
      print('🚪 AuthService: Clearing API service token...');
      _apiService.clearAuthToken();
      
      print('🚪 AuthService: Logout completed successfully');
      return AuthResult.success(message: 'Logged out successfully');
    } catch (e) {
      print('🚪 AuthService: Logout API call failed: $e');
      // Even if API call fails, clear local data
      await StorageService.clearAuthToken();
      await StorageService.clearUserData();
      _apiService.clearAuthToken();
      
      print('🚪 AuthService: Local data cleared despite API failure');
      return AuthResult.success(message: 'Logged out successfully');
    }
  }

  // Forgot password
  Future<AuthResult> forgotPassword({required String email}) async {
    try {
      final response = await _apiService.post('/auth/forgot-password', data: {
        'email': email,
      });

      if (response.success) {
        return AuthResult.success(
          message: response.message ?? 'Password reset link sent to your email',
        );
      } else {
        return AuthResult.failure(response.error ?? 'Failed to send password reset link');
      }
    } catch (e) {
      return AuthResult.failure('Failed to send password reset link: $e');
    }
  }

  // Reset password
  Future<AuthResult> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      final response = await _apiService.post('/auth/reset-password', data: {
        'token': token,
        'password': password,
      });

      if (response.success && response.data != null) {
        final authToken = response.data['token'];
        
        if (authToken != null) {
          // Store new auth token
          await StorageService.setAuthToken(authToken);
          _apiService.setAuthToken(authToken);
          
          return AuthResult.success(
            token: authToken,
            message: response.message ?? 'Password reset successful',
          );
        }
      }
      
      return AuthResult.failure(response.error ?? 'Password reset failed');
    } catch (e) {
      return AuthResult.failure('Password reset failed: $e');
    }
  }

  // Change password
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.put('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      if (response.success) {
        return AuthResult.success(
          message: response.message ?? 'Password changed successfully',
        );
      } else {
        return AuthResult.failure(response.error ?? 'Failed to change password');
      }
    } catch (e) {
      return AuthResult.failure('Failed to change password: $e');
    }
  }

  // Get current user profile status
  Future<AuthResult> getProfileStatus() async {
    try {
      final response = await _apiService.get('/auth/profile-status');

      if (response.success && response.data != null) {
        final userData = response.data['user'];
        final profileExists = response.data['profileExists'] ?? false;
        final completionPercentage = response.data['completionPercentage'] ?? 0;
        
        if (userData != null) {
          final user = User.fromJson(userData);
          
          return AuthResult.success(
            user: user,
            message: 'Profile status retrieved successfully',
            requiresProfileCompletion: !profileExists || completionPercentage < 80,
          );
        }
      }
      
      return AuthResult.failure(response.error ?? 'Failed to get profile status');
    } catch (e) {
      return AuthResult.failure('Failed to get profile status: $e');
    }
  }

  // Refresh token
  Future<AuthResult> refreshToken() async {
    try {
      final currentToken = await StorageService.getAuthToken();
      if (currentToken == null) {
        return AuthResult.failure('No token to refresh');
      }

      final response = await _apiService.post('/auth/refresh-token', data: {
        'token': currentToken,
      });

      if (response.success && response.data != null) {
        final newToken = response.data['token'];
        
        if (newToken != null) {
          await StorageService.setAuthToken(newToken);
          _apiService.setAuthToken(newToken);
          
          return AuthResult.success(
            token: newToken,
            message: 'Token refreshed successfully',
          );
        }
      }
      
      return AuthResult.failure(response.error ?? 'Token refresh failed');
    } catch (e) {
      return AuthResult.failure('Token refresh failed: $e');
    }
  }

  // Check if user is authenticated
  Future<AuthResult> checkAuthStatus() async {
    try {
      final token = await StorageService.getAuthToken();
      final userData = await StorageService.getUserData();
      
      if (token != null && userData != null) {
        final user = User.fromJson(userData);
        _apiService.setAuthToken(token);
        
        // Verify token is still valid by getting profile status
        final profileResult = await getProfileStatus();
        if (profileResult.isSuccess) {
          return AuthResult.success(
            user: profileResult.user ?? user,
            token: token,
            message: 'User is authenticated',
            requiresProfileCompletion: profileResult.requiresProfileCompletion,
          );
        } else {
          // Token might be expired, try to refresh
          final refreshResult = await refreshToken();
          if (refreshResult.isSuccess) {
            return AuthResult.success(
              user: user,
              token: refreshResult.token,
              message: 'User is authenticated',
            );
          }
        }
      }
      
      return AuthResult.failure('User is not authenticated');
    } catch (e) {
      return AuthResult.failure('Authentication check failed: $e');
    }
  }
}

// Auth result wrapper
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? token;
  final String? message;
  final String? error;
  final bool requiresEmailVerification;
  final bool requiresProfileCompletion;

  const AuthResult({
    required this.isSuccess,
    this.user,
    this.token,
    this.message,
    this.error,
    this.requiresEmailVerification = false,
    this.requiresProfileCompletion = false,
  });

  factory AuthResult.success({
    User? user,
    String? token,
    String? message,
    bool requiresEmailVerification = false,
    bool requiresProfileCompletion = false,
  }) {
    return AuthResult(
      isSuccess: true,
      user: user,
      token: token,
      message: message,
      requiresEmailVerification: requiresEmailVerification,
      requiresProfileCompletion: requiresProfileCompletion,
    );
  }

  factory AuthResult.failure(
    String error, {
    bool requiresEmailVerification = false,
    bool requiresProfileCompletion = false,
  }) {
    return AuthResult(
      isSuccess: false,
      error: error,
      requiresEmailVerification: requiresEmailVerification,
      requiresProfileCompletion: requiresProfileCompletion,
    );
  }

  @override
  String toString() {
    return 'AuthResult(isSuccess: $isSuccess, user: $user, message: $message, error: $error)';
  }
}