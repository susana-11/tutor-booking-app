import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String? _authToken;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.instance.baseUrl,
      connectTimeout: Duration(seconds: AppConfig.instance.connectTimeout),
      receiveTimeout: Duration(seconds: AppConfig.instance.receiveTimeout),
      sendTimeout: Duration(seconds: AppConfig.instance.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Allow self-signed certificates in development
    if (kDebugMode) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          print('🔓 Allowing certificate for $host:$port');
          return true; // Allow all certificates in debug mode
        };
        return client;
      };
    }

    // Add interceptors
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_LoggingInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());
  }

  // Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Clear authentication token
  void clearAuthToken() {
    _authToken = null;
    _dio.options.headers.remove('Authorization');
  }

  // GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      print('🌐 GET Request: ${AppConfig.instance.baseUrl}$endpoint');
      print('🌐 Query params: $queryParameters');
      
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      
      print('✅ GET Response received: ${response.statusCode}');
      return ApiResponse<T>.fromResponse(response);
    } catch (e) {
      print('❌ GET Request failed: $e');
      print('❌ Error type: ${e.runtimeType}');
      return ApiResponse<T>.error(_handleError(e));
    }
  }

  // POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      print('🌐 POST Request: ${AppConfig.instance.baseUrl}$endpoint');
      print('🌐 Data: $data');
      
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      
      print('✅ POST Response received: ${response.statusCode}');
      return ApiResponse<T>.fromResponse(response);
    } catch (e) {
      print('❌ POST Request failed: $e');
      print('❌ Error type: ${e.runtimeType}');
      return ApiResponse<T>.error(_handleError(e));
    }
  }

  // PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse<T>.fromResponse(response);
    } catch (e) {
      return ApiResponse<T>.error(_handleError(e));
    }
  }

  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse<T>.fromResponse(response);
    } catch (e) {
      return ApiResponse<T>.error(_handleError(e));
    }
  }

  // Upload file
  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData();
      
      // Add file
      formData.files.add(MapEntry(
        fieldName,
        await MultipartFile.fromFile(file.path),
      ));
      
      // Add additional data
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      final response = await _dio.post(
        endpoint,
        data: formData,
        onSendProgress: onSendProgress,
      );
      
      return ApiResponse<T>.fromResponse(response);
    } catch (e) {
      return ApiResponse<T>.error(_handleError(e));
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection.';
        
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['message'];
          
          if (statusCode == 401) {
            return 'Authentication failed. Please login again.';
          } else if (statusCode == 403) {
            return 'Access denied. You don\'t have permission to perform this action.';
          } else if (statusCode == 404) {
            return 'Resource not found.';
          } else if (statusCode == 422) {
            return message ?? 'Validation failed.';
          } else if (statusCode == 500) {
            return 'Server error. Please try again later.';
          }
          
          return message ?? 'An error occurred. Please try again.';
        
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return 'No internet connection. Please check your network.';
          }
          return 'An unexpected error occurred.';
        
        default:
          return 'An error occurred. Please try again.';
      }
    }
    
    return 'An unexpected error occurred.';
  }
}

// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {String? message, int? statusCode}) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse<T>(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.fromResponse(Response response) {
    final responseData = response.data;
    
    if (responseData is Map<String, dynamic>) {
      final success = responseData['success'] ?? true;
      final message = responseData['message'];
      final data = responseData['data'];
      
      if (success) {
        return ApiResponse<T>.success(
          data as T,
          message: message,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<T>.error(
          message ?? 'An error occurred',
          statusCode: response.statusCode,
        );
      }
    }
    
    return ApiResponse<T>.success(
      responseData as T,
      statusCode: response.statusCode,
    );
  }
}

// Auth Interceptor
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Add auth token if available
    final token = await StorageService.getAuthToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle token expiration
    if (err.response?.statusCode == 401) {
      // Clear stored token
      await StorageService.clearAuthToken();
      // You might want to navigate to login screen here
    }
    
    handler.next(err);
  }
}

// Logging Interceptor
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('🚀 REQUEST: ${options.method} ${options.uri}');
      if (options.data != null) {
        print('📤 DATA: ${options.data}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('📥 DATA: ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('❌ ERROR: ${err.response?.statusCode} ${err.requestOptions.uri}');
      print('📥 ERROR DATA: ${err.response?.data}');
    }
    handler.next(err);
  }
}

// Error Interceptor
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle specific error cases
    if (err.response?.statusCode == 429) {
      // Rate limiting
      err = err.copyWith(
        message: 'Too many requests. Please try again later.',
      );
    }
    
    handler.next(err);
  }
}