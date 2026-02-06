import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage_service.dart';
import '../config/app_config.dart';

class WalletService {
  final StorageService _storage = StorageService();
  
  // Get wallet balance
  Future<Map<String, dynamic>> getWalletBalance() async {
    try {
      final token = await _storage.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/wallet/balance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 GET Wallet Balance Response: ${response.statusCode}');
      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        print('✅ Wallet balance fetched: ${data['data']}');
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        print('❌ Failed to fetch balance: ${data['message']}');
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to fetch balance'
        };
      }
    } catch (e) {
      print('❌ Wallet balance error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Initialize wallet top-up
  Future<Map<String, dynamic>> initializeTopUp(double amount) async {
    try {
      final token = await _storage.getToken();
      print('🚀 Initializing top-up: $amount ETB');
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/wallet/topup'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'amount': amount}),
      );

      print('🔍 POST Top-up Response: ${response.statusCode}');
      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        print('✅ Top-up initialized: ${data['data']}');
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        print('❌ Failed to initialize top-up: ${data['message']}');
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to initialize top-up'
        };
      }
    } catch (e) {
      print('❌ Top-up initialization error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Verify wallet top-up
  Future<Map<String, dynamic>> verifyTopUp(String reference) async {
    try {
      final token = await _storage.getToken();
      print('🔍 Verifying top-up: $reference');
      
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/wallet/topup/verify/$reference'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 GET Verify Response: ${response.statusCode}');
      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        print('✅ Top-up verified: ${data['data']}');
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        print('❌ Failed to verify top-up: ${data['message']}');
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to verify top-up'
        };
      }
    } catch (e) {
      print('❌ Top-up verification error: $e');
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
      final token = await _storage.getToken();
      var url = '${AppConfig.apiUrl}/wallet/transactions?limit=$limit';
      if (type != null) url += '&type=$type';
      
      print('🔍 Fetching transactions: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 GET Transactions Response: ${response.statusCode}');
      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        print('✅ Transactions fetched: ${data['data'].length} items');
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        print('❌ Failed to fetch transactions: ${data['message']}');
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to fetch transactions'
        };
      }
    } catch (e) {
      print('❌ Transactions fetch error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Get wallet statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final token = await _storage.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/wallet/statistics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 GET Statistics Response: ${response.statusCode}');
      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        print('✅ Statistics fetched');
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
      print('❌ Statistics fetch error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Check sufficient balance
  Future<Map<String, dynamic>> checkBalance(double amount) async {
    try {
      final token = await _storage.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/wallet/check-balance?amount=$amount'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 Check Balance Response: ${response.statusCode}');
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
      print('❌ Check balance error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Pay booking with wallet
  Future<Map<String, dynamic>> payBookingWithWallet(String bookingId) async {
    try {
      final token = await _storage.getToken();
      print('💰 Paying booking with wallet: $bookingId');
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/wallet/pay-booking'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'bookingId': bookingId}),
      );

      print('🔍 POST Pay Booking Response: ${response.statusCode}');
      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        print('✅ Booking paid with wallet');
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        print('❌ Failed to pay booking: ${data['message']}');
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to process payment',
          'data': data['data']
        };
      }
    } catch (e) {
      print('❌ Wallet payment error: $e');
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
      final token = await _storage.getToken();
      print('💸 Requesting withdrawal: $amount ETB');
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/wallet/withdraw'),
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

      print('🔍 POST Withdrawal Response: ${response.statusCode}');
      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        print('✅ Withdrawal requested');
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        print('❌ Failed to request withdrawal: ${data['message']}');
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to request withdrawal'
        };
      }
    } catch (e) {
      print('❌ Withdrawal request error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Get withdrawal history
  Future<Map<String, dynamic>> getWithdrawals({int limit = 50}) async {
    try {
      final token = await _storage.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/wallet/withdrawals?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 GET Withdrawals Response: ${response.statusCode}');
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
      print('❌ Withdrawals fetch error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
}
