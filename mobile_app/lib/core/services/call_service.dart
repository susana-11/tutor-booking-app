import 'dart:async';
import 'api_service.dart';
import 'socket_service.dart';
import '../../features/call/models/call_models.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  // Stream controller for incoming calls
  final StreamController<IncomingCall> _incomingCallController =
      StreamController<IncomingCall>.broadcast();

  Stream<IncomingCall> get incomingCallStream => _incomingCallController.stream;

  void initialize() {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen for incoming calls
    _socketService.on('incoming_call', (data) {
      try {
        print('📞 Incoming call received: $data');
        final incomingCall = IncomingCall.fromJson(data);
        if (!_incomingCallController.isClosed) {
          _incomingCallController.add(incomingCall);
        }
      } catch (e) {
        print('❌ Error handling incoming call: $e');
      }
    });

    // Listen for call answered
    _socketService.on('call_answered', (data) {
      print('✅ Call answered: $data');
    });

    // Listen for call rejected
    _socketService.on('call_rejected', (data) {
      print('❌ Call rejected: $data');
    });

    // Listen for call ended
    _socketService.on('call_ended', (data) {
      print('📴 Call ended: $data');
    });
  }

  // Initiate a call
  Future<ApiResponse<CallSession>> initiateCall({
    required String receiverId,
    required CallType callType,
    String? bookingId,
  }) async {
    try {
      print('📞 Initiating ${callType.name} call to $receiverId');

      final response = await _apiService.post('/calls/initiate', data: {
        'receiverId': receiverId,
        'callType': callType.name,
        if (bookingId != null) 'bookingId': bookingId,
      });

      if (response.success && response.data != null) {
        final callSession = CallSession.fromJson(response.data);
        print('✅ Call initiated: ${callSession.callId}');
        return ApiResponse.success(callSession);
      }

      return ApiResponse.error(response.error ?? 'Failed to initiate call');
    } catch (e) {
      print('❌ Initiate call error: $e');
      return ApiResponse.error('Failed to initiate call: $e');
    }
  }

  // Answer a call
  Future<ApiResponse<void>> answerCall(String callId) async {
    try {
      print('✅ Answering call: $callId');

      final response = await _apiService.post('/calls/$callId/answer');

      if (response.success) {
        return ApiResponse.success(null);
      }

      return ApiResponse.error(response.error ?? 'Failed to answer call');
    } catch (e) {
      print('❌ Answer call error: $e');
      return ApiResponse.error('Failed to answer call: $e');
    }
  }

  // Reject a call
  Future<ApiResponse<void>> rejectCall(String callId) async {
    try {
      print('❌ Rejecting call: $callId');

      final response = await _apiService.post('/calls/$callId/reject');

      if (response.success) {
        return ApiResponse.success(null);
      }

      return ApiResponse.error(response.error ?? 'Failed to reject call');
    } catch (e) {
      print('❌ Reject call error: $e');
      return ApiResponse.error('Failed to reject call: $e');
    }
  }

  // End a call
  Future<ApiResponse<Map<String, dynamic>>> endCall(String callId) async {
    try {
      print('📴 Ending call: $callId');

      final response = await _apiService.post('/calls/$callId/end');

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      }

      return ApiResponse.error(response.error ?? 'Failed to end call');
    } catch (e) {
      print('❌ End call error: $e');
      return ApiResponse.error('Failed to end call: $e');
    }
  }

  // Get call history
  Future<ApiResponse<List<CallHistory>>> getCallHistory({
    int page = 1,
    int limit = 20,
    CallType? callType,
    String? status,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (callType != null) 'callType': callType.name,
        if (status != null) 'status': status,
      };

      final response = await _apiService.get(
        '/calls/history',
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final dataObj = response.data['data'] ?? response.data;
        final callsData = dataObj['calls'] as List;
        
        // Get current user ID from storage or auth provider
        final currentUserId = ''; // TODO: Get from auth provider
        
        final calls = callsData
            .map((data) => CallHistory.fromJson(data, currentUserId))
            .toList();

        return ApiResponse.success(calls);
      }

      return ApiResponse.error(response.error ?? 'Failed to fetch call history');
    } catch (e) {
      print('❌ Get call history error: $e');
      return ApiResponse.error('Failed to fetch call history: $e');
    }
  }

  // Get missed calls
  Future<ApiResponse<List<CallHistory>>> getMissedCalls() async {
    try {
      final response = await _apiService.get('/calls/missed');

      if (response.success && response.data != null) {
        final dataObj = response.data['data'] ?? response.data;
        final missedCallsData = dataObj['missedCalls'] as List;
        
        final currentUserId = ''; // TODO: Get from auth provider
        
        final missedCalls = missedCallsData
            .map((data) => CallHistory.fromJson(data, currentUserId))
            .toList();

        return ApiResponse.success(missedCalls);
      }

      return ApiResponse.error(response.error ?? 'Failed to fetch missed calls');
    } catch (e) {
      print('❌ Get missed calls error: $e');
      return ApiResponse.error('Failed to fetch missed calls: $e');
    }
  }

  void dispose() {
    _incomingCallController.close();
  }
}
