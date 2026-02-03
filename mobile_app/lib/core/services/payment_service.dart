import 'package:flutter/material.dart';
import 'api_service.dart';
import '../../features/student/screens/payment_webview_screen.dart';

class PaymentService {
  final ApiService _apiService = ApiService();

  // Initialize payment for booking
  Future<Map<String, dynamic>> initializePayment(String bookingId) async {
    try {
      final response = await _apiService.post(
        '/payments/initialize',
        data: {'bookingId': bookingId},
      );

      if (response.success && response.data != null) {
        return {
          'success': true,
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'error': response.error ?? 'Failed to initialize payment',
        };
      }
    } catch (e) {
      print('Initialize payment error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Open Chapa payment page in WebView
  Future<Map<String, dynamic>> openPaymentPage(
    BuildContext context,
    String checkoutUrl,
    String reference,
  ) async {
    try {
      print('🌐 Opening payment WebView: $checkoutUrl');
      
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewScreen(
            checkoutUrl: checkoutUrl,
            reference: reference,
          ),
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        print('✅ Payment result: ${result['status']}');
        return {
          'success': result['status'] == 'success',
          'status': result['status'],
          'reference': result['reference'],
        };
      }

      return {
        'success': false,
        'status': 'cancelled',
        'message': 'Payment was cancelled',
      };
    } catch (e) {
      print('❌ Open payment page error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Verify payment
  Future<Map<String, dynamic>> verifyPayment(String reference) async {
    try {
      final response = await _apiService.get('/payments/verify/$reference');

      if (response.success && response.data != null) {
        return {
          'success': true,
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'error': response.error ?? 'Payment verification failed',
        };
      }
    } catch (e) {
      print('Verify payment error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get payment status for booking
  Future<Map<String, dynamic>> getPaymentStatus(String bookingId) async {
    try {
      final response = await _apiService.get('/payments/status/$bookingId');

      if (response.success && response.data != null) {
        return {
          'success': true,
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'error': response.error ?? 'Failed to get payment status',
        };
      }
    } catch (e) {
      print('Get payment status error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get transaction history
  Future<Map<String, dynamic>> getTransactions({
    String? type,
    String? status,
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiService.get(
        '/payments/transactions',
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        return {
          'success': true,
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'error': response.error ?? 'Failed to get transactions',
        };
      }
    } catch (e) {
      print('Get transactions error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get transaction summary
  Future<Map<String, dynamic>> getTransactionSummary({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _apiService.get(
        '/payments/transactions/summary',
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        return {
          'success': true,
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'error': response.error ?? 'Failed to get transaction summary',
        };
      }
    } catch (e) {
      print('Get transaction summary error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Process payment for booking (complete flow)
  Future<Map<String, dynamic>> processBookingPayment(
    BuildContext context,
    String bookingId,
  ) async {
    try {
      // Step 1: Initialize payment
      final initResult = await initializePayment(bookingId);
      if (initResult['success'] != true) {
        return initResult;
      }

      final checkoutUrl = initResult['data']['checkoutUrl'];
      final reference = initResult['data']['reference'];

      // Step 2: Open payment page in WebView
      final paymentResult = await openPaymentPage(context, checkoutUrl, reference);
      
      if (paymentResult['success'] == true) {
        // Step 3: Verify payment
        final verifyResult = await verifyPayment(reference);
        return verifyResult;
      }

      return paymentResult;
    } catch (e) {
      print('Process booking payment error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
