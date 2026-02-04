import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../config/app_config.dart';
import 'storage_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _userId;
  
  // Event callbacks
  final Map<String, List<Function(dynamic)>> _eventCallbacks = {};

  bool get isConnected => _isConnected;
  String? get userId => _userId;

  Future<void> connect() async {
    if (_isConnected) {
      print('ℹ️ Socket already connected');
      return;
    }

    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        print('❌ No auth token found, cannot connect to socket');
        print('❌ User must be logged in to connect to socket');
        return;
      }

      print('✅ Auth token found: ${token.substring(0, 20)}...');

      final serverUrl = AppConfig.instance.baseUrl.replaceAll('/api', '');
      print('🔌 Socket server URL: $serverUrl');
      print('🔌 Attempting to connect to socket server...');
      
      _socket = IO.io(serverUrl, IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .setTimeout(20000)
          .setAuth({
            'token': token,
          })
          .build());

      _setupEventHandlers();
      
      print('🔌 Socket instance created, waiting for connection...');
    } catch (e, stackTrace) {
      print('❌ Socket connection error: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  void _setupEventHandlers() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _isConnected = true;
      print('✅✅✅ Socket connected successfully! ✅✅✅');
      print('🔌 Socket ID: ${_socket!.id}');
      _notifyCallbacks('connect', null);
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('🔌 Socket disconnected');
      _notifyCallbacks('disconnect', null);
    });

    _socket!.onConnectError((error) {
      print('❌❌❌ Socket connection error: $error');
      print('❌ Error type: ${error.runtimeType}');
      print('❌ Error details: ${error.toString()}');
      _notifyCallbacks('connect_error', error);
    });

    _socket!.onError((error) {
      print('❌ Socket error: $error');
      _notifyCallbacks('error', error);
    });

    _socket!.on('connect_timeout', (data) {
      print('⏱️ Socket connection timeout: $data');
    });

    _socket!.on('reconnect', (data) {
      print('🔄 Socket reconnected: $data');
    });

    _socket!.on('reconnect_attempt', (data) {
      print('🔄 Socket reconnection attempt: $data');
    });

    _socket!.on('reconnect_error', (data) {
      print('❌ Socket reconnection error: $data');
    });

    _socket!.on('reconnect_failed', (data) {
      print('❌ Socket reconnection failed: $data');
    });

    // Chat events
    _socket!.on('new_message', (data) {
      print('💬 New message received: $data');
      _notifyCallbacks('new_message', data);
    });

    _socket!.on('user_typing', (data) {
      _notifyCallbacks('user_typing', data);
    });

    _socket!.on('user_stopped_typing', (data) {
      _notifyCallbacks('user_stopped_typing', data);
    });

    // Call events
    _socket!.on('incoming_call', (data) {
      print('📞📞📞 Incoming call received via socket: $data');
      _notifyCallbacks('incoming_call', data);
    });

    _socket!.on('call_answered', (data) {
      print('✅ Call answered via socket: $data');
      _notifyCallbacks('call_answered', data);
    });

    _socket!.on('call_rejected', (data) {
      print('❌ Call rejected via socket: $data');
      _notifyCallbacks('call_rejected', data);
    });

    _socket!.on('call_ended', (data) {
      print('📴 Call ended via socket: $data');
      _notifyCallbacks('call_ended', data);
    });

    // Booking events
    _socket!.on('new_booking_request', (data) {
      print('📅 New booking request: $data');
      _notifyCallbacks('new_booking_request', data);
    });

    _socket!.on('booking_response', (data) {
      print('📅 Booking response: $data');
      _notifyCallbacks('booking_response', data);
    });

    _socket!.on('session_reminder', (data) {
      print('⏰ Session reminder: $data');
      _notifyCallbacks('session_reminder', data);
    });

    // User status events
    _socket!.on('user_status_change', (data) {
      _notifyCallbacks('user_status_change', data);
    });

    // Notification events
    _socket!.on('notification', (data) {
      print('🔔 New notification: $data');
      _notifyCallbacks('notification', data);
    });

    _socket!.on('unread_count', (data) {
      _notifyCallbacks('unread_count', data);
    });

    print('✅ Socket event handlers registered');
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      _userId = null;
      print('🔌 Socket disconnected manually');
    }
  }

  // Event subscription methods
  void on(String event, Function(dynamic) callback) {
    if (!_eventCallbacks.containsKey(event)) {
      _eventCallbacks[event] = [];
    }
    _eventCallbacks[event]!.add(callback);
  }

  void off(String event, [Function(dynamic)? callback]) {
    if (_eventCallbacks.containsKey(event)) {
      if (callback != null) {
        _eventCallbacks[event]!.remove(callback);
      } else {
        _eventCallbacks[event]!.clear();
      }
    }
  }

  void _notifyCallbacks(String event, dynamic data) {
    if (_eventCallbacks.containsKey(event)) {
      // Create a copy of the list to avoid concurrent modification
      final callbacks = List.from(_eventCallbacks[event]!);
      for (final callback in callbacks) {
        try {
          callback(data);
        } catch (e) {
          print('❌ Error in socket callback for $event: $e');
          // Don't rethrow - continue processing other callbacks
        }
      }
    }
  }

  // Chat methods
  void joinChat(String chatId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('join_chat', {'chatId': chatId});
      print('💬 Joined chat: $chatId');
    }
  }

  void leaveChat(String chatId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('leave_chat', {'chatId': chatId});
      print('💬 Left chat: $chatId');
    }
  }

  void sendMessage({
    required String chatId,
    required String message,
    String? recipientId,
  }) {
    if (_isConnected && _socket != null) {
      _socket!.emit('send_message', {
        'chatId': chatId,
        'message': message,
        'recipientId': recipientId,
      });
      print('💬 Message sent to chat: $chatId');
    }
  }

  void startTyping(String chatId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('typing_start', {'chatId': chatId});
    }
    // Silently skip if not connected - not critical
  }

  void stopTyping(String chatId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('typing_stop', {'chatId': chatId});
    }
    // Silently skip if not connected - not critical
  }

  // Booking methods
  void sendBookingRequest({
    required String tutorId,
    required Map<String, dynamic> bookingData,
  }) {
    if (_isConnected && _socket != null) {
      _socket!.emit('booking_request', {
        'tutorId': tutorId,
        'bookingData': bookingData,
      });
      print('📅 Booking request sent to tutor: $tutorId');
    }
  }

  void respondToBooking({
    required String studentId,
    required String bookingId,
    required String status,
    String? message,
  }) {
    if (_isConnected && _socket != null) {
      _socket!.emit('booking_response', {
        'studentId': studentId,
        'bookingId': bookingId,
        'status': status,
        'message': message,
      });
      print('📅 Booking response sent: $status');
    }
  }

  // Notification methods
  void markNotificationAsRead(String notificationId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('mark_notification_read', {
        'notificationId': notificationId,
      });
    }
  }

  void getUnreadCount() {
    if (_isConnected && _socket != null) {
      _socket!.emit('get_unread_count');
    }
  }

  // Generic emit method
  void emit(String event, [dynamic data]) {
    if (_isConnected && _socket != null) {
      _socket!.emit(event, data);
      print('📤 Socket event emitted: $event');
    } else {
      if (kDebugMode) {
        print('ℹ️ Socket not connected, $event will be sent via HTTP');
      }
    }
  }
}