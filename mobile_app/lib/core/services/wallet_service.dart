import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import 'storage_service.dart';

class WalletService {
  final AppConfig _config = AppConfig.instance;
  
  // Get wallet balance
  Future<Map<String, dynamic>> getWalletBalance() async {
    try {
      final token = await StorageService.getAuthToken();
      final response = await http.get(
        Uri.parse('${_config.baseUrl}/wallet/balance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to fetch balance'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Initialize wallet top-up
  Future<Map<String, dynamic>> initializeTopUp(double amount) async {
    try {
      final token = await StorageService.getAuthToken();
      final response = await http.post(
        Uri.parse('${_config.baseUrl}/wallet/topup'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'amount': amount}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to initialize top-up'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Verify wallet top-up
  Future<Map<String, dynamic>> verifyTopUp(String reference) async {
    try {
      final token = await StorageService.getAuthToken();
      final response = await http.get(
        Uri.parse('${_config.baseUrl}/wallet/topup/verify/$reference'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to verify top-up'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Get wallet transactions
  Future<Map<String, dynamic>> getTransactions({
    String? type,
    int limit = 50,
  }) async {
    try {
      final token = await StorageService.getAuthToken();
      var url = '${_config.baseUrl}/wallet/transactions?limit=$limit';
      if (type != null) url += '&type=$type';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to fetch transactions'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Get wallet statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final token = await StorageService.getAuthToken();
      final response = await http.get(
        Uri.parse('${_config.baseUrl}/wallet/statistics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to fetch statistics'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Check sufficient balance
  Future<Map<String, dynamic>> checkBalance(double amount) async {
    try {
      final token = await StorageService.getAuthToken();
      final response = await http.get(
        Uri.parse('${_config.baseUrl}/wallet/check-balance?amount=$amount'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to check balance'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Pay booking with wallet
  Future<Map<String, dynamic>> payBookingWithWallet(String bookingId) async {
    try {
      final token = await StorageService.getAuthToken();
      final response = await http.post(
        Uri.parse('${_config.baseUrl}/wallet/pay-booking'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'bookingId': bookingId}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to process payment',
          'data': data['data']
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Request withdrawal (tutors only)
  Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String accountNumber,
    required String accountName,
    required String bankName,
  }) async {
    try {
      final token = await StorageService.getAuthToken();
      final response = await http.post(
        Uri.parse('${_config.baseUrl}/wallet/withdraw'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': amount,
          'accountNumber': accountNumber,
          'accountName': accountName,
          'bankName': bankName,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to request withdrawal'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Get withdrawal history
  Future<Map<String, dynamic>> getWithdrawals({int limit = 50}) async {
    try {
      final token = await StorageService.getAuthToken();
      final response = await http.get(
        Uri.parse('${_config.baseUrl}/wallet/withdrawals?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to fetch withdrawals'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
}
