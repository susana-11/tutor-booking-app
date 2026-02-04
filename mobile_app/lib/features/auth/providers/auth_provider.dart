import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../../core/services/socket_service.dart';

// Router notifier for auth state changes
class AuthRouterNotifier extends ChangeNotifier {
  static final AuthRouterNotifier _instance = AuthRouterNotifier._internal();
  factory AuthRouterNotifier() => _instance;
  AuthRouterNotifier._internal();

  void notify() {
    notifyListeners();
  }
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final AuthRouterNotifier _routerNotifier = AuthRouterNotifier();

  AuthState _state = const AuthState();
  AuthState get state => _state;

  // Getters for easy access
  bool get isAuthenticated => _state.isAuthenticated;
  bool get isLoading => _state.isLoading;
  User? get user => _state.user;
  String? get token => _state.token;
  String? get error => _state.error;
  bool get requiresEmailVerification => _state.requiresEmailVerification;
  bool get requiresProfileCompletion => _state.requiresProfileCompletion;

  // Update state helper
  void _updateState(AuthState newState) {
    _state = newState;
    notifyListeners();
    
    // Notify router to refresh
    _routerNotifier.notify();
  }

  // Clear error
  void clearError() {
    _updateState(_state.clearError());
  }

  // Register user
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  }) async {
    _updateState(_state.setLoading(true));

    try {
      final result = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );

      if (result.isSuccess) {
        _updateState(AuthState(
          isAuthenticated: false,
          isLoading: false,
          user: result.user,
          requiresEmailVerification: result.requiresEmailVerification,
          error: null,
        ));
        return true;
      } else {
        _updateState(_state.setError(result.error ?? 'Registration failed'));
        return false;
      }
    } catch (e) {
      _updateState(_state.setError('Registration failed: $e'));
      return false;
    }
  }

  // Verify email
  Future<bool> verifyEmail({
    required String email,
    required String otp,
  }) async {
    _updateState(_state.setLoading(true));

    try {
      final result = await _authService.verifyEmail(
        email: email,
        otp: otp,
      );

      if (result.isSuccess) {
        _updateState(AuthState(
          isAuthenticated: true,
          isLoading: false,
          user: result.user,
          token: result.token,
          requiresProfileCompletion: result.requiresProfileCompletion,
          error: null,
        ));
        return true;
      } else {
        _updateState(_state.setError(result.error ?? 'Email verification failed'));
        return false;
      }
    } catch (e) {
      _updateState(_state.setError('Email verification failed: $e'));
      return false;
    }
  }

  // Resend OTP
  Future<bool> resendOTP({required String email}) async {
    _updateState(_state.setLoading(true));

    try {
      final result = await _authService.resendOTP(email: email);

      if (result.isSuccess) {
        _updateState(_state.copyWith(isLoading: false, error: null));
        return true;
      } else {
        _updateState(_state.setError(result.error ?? 'Failed to send verification code'));
        return false;
      }
    } catch (e) {
      _updateState(_state.setError('Failed to send verification code: $e'));
      return false;
    }
  }

  // Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _updateState(_state.setLoading(true));

    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        _updateState(AuthState(
          isAuthenticated: true,
          isLoading: false,
          user: result.user,
          token: result.token,
          requiresProfileCompletion: result.requiresProfileCompletion,
          error: null,
        ));
        
        // Reconnect socket after successful login
        try {
          print('🔌 Reconnecting socket after login...');
          final socketService = SocketService();
          await socketService.connect();
          print('🔌 Socket reconnected successfully after login');
        } catch (e) {
          print('❌ Socket reconnection error after login: $e');
          // Don't fail login if socket connection fails
        }
        
        return true;
      } else {
        _updateState(AuthState(
          isAuthenticated: false,
          isLoading: false,
          requiresEmailVerification: result.requiresEmailVerification,
          error: result.error,
        ));
        return false;
      }
    } catch (e) {
      _updateState(_state.setError('Login failed: $e'));
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    print('🚪 Starting logout process...');
    _updateState(_state.setLoading(true));

    try {
      print('🚪 Calling auth service logout...');
      // Call logout endpoint
      await _authService.logout();
      
      print('🚪 Clearing authentication state...');
      // Clear the authentication state
      _updateState(const AuthState());
      
      // Disconnect socket
      try {
        print('🚪 Disconnecting socket...');
        final socketService = SocketService();
        socketService.disconnect();
        print('🚪 Socket disconnected successfully');
      } catch (e) {
        // Ignore socket disconnect errors
        print('Socket disconnect error during logout: $e');
      }
      
      print('🚪 Logout completed successfully');
      
    } catch (e) {
      print('🚪 Logout error occurred: $e');
      // Even if logout fails, clear the state
      _updateState(const AuthState());
      
      // Still try to disconnect socket
      try {
        final socketService = SocketService();
        socketService.disconnect();
      } catch (socketError) {
        // Ignore socket disconnect errors
        print('Socket disconnect error during logout: $socketError');
      }
      
      print('🚪 Logout completed with errors but state cleared');
    }
  }

  // Forgot password
  Future<bool> forgotPassword({required String email}) async {
    _updateState(_state.setLoading(true));

    try {
      final result = await _authService.forgotPassword(email: email);

      if (result.isSuccess) {
        _updateState(_state.copyWith(isLoading: false, error: null));
        return true;
      } else {
        _updateState(_state.setError(result.error ?? 'Failed to send password reset link'));
        return false;
      }
    } catch (e) {
      _updateState(_state.setError('Failed to send password reset link: $e'));
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword({
    required String token,
    required String password,
  }) async {
    _updateState(_state.setLoading(true));

    try {
      final result = await _authService.resetPassword(
        token: token,
        password: password,
      );

      if (result.isSuccess) {
        _updateState(_state.copyWith(
          isLoading: false,
          token: result.token,
          error: null,
        ));
        return true;
      } else {
        _updateState(_state.setError(result.error ?? 'Password reset failed'));
        return false;
      }
    } catch (e) {
      _updateState(_state.setError('Password reset failed: $e'));
      return false;
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _updateState(_state.setLoading(true));

    try {
      final result = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (result.isSuccess) {
        _updateState(_state.copyWith(isLoading: false, error: null));
        return true;
      } else {
        _updateState(_state.setError(result.error ?? 'Failed to change password'));
        return false;
      }
    } catch (e) {
      _updateState(_state.setError('Failed to change password: $e'));
      return false;
    }
  }

  // Check authentication status
  Future<void> checkAuthStatus() async {
    _updateState(_state.setLoading(true));

    try {
      final result = await _authService.checkAuthStatus();

      if (result.isSuccess) {
        _updateState(AuthState(
          isAuthenticated: true,
          isLoading: false,
          user: result.user,
          token: result.token,
          requiresProfileCompletion: result.requiresProfileCompletion,
          error: null,
        ));
      } else {
        _updateState(const AuthState(isLoading: false));
      }
    } catch (e) {
      _updateState(const AuthState(isLoading: false));
    }
  }

  // Update user profile completion status
  void updateProfileCompletion(bool completed) {
    if (_state.user != null) {
      final updatedUser = _state.user!.copyWith(profileCompleted: completed);
      _updateState(_state.copyWith(
        user: updatedUser,
        requiresProfileCompletion: !completed,
      ));
    }
  }

  // Update user data
  void updateUser(User user) {
    _updateState(_state.copyWith(user: user));
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final result = await _authService.refreshToken();

      if (result.isSuccess) {
        _updateState(_state.copyWith(token: result.token));
        return true;
      } else {
        // Token refresh failed, logout user
        await logout();
        return false;
      }
    } catch (e) {
      // Token refresh failed, logout user
      await logout();
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}