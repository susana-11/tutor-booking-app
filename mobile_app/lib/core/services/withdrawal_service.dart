import 'api_service.dart';

class WithdrawalService {
  final ApiService _apiService = ApiService();

  // Request withdrawal
  Future<Map<String, dynamic>> requestWithdrawal(double amount) async {
    try {
      final response = await _apiService.post(
        '/withdrawals/request',
        data: {'amount': amount},
      );

      if (response.success && response.data != null) {
        return {
          'success': true,
          'data': response.data,
          'message': response.message,
        };
      } else {
        return {
          'success': false,
          'error': response.error ?? 'Failed to request withdrawal',
        };
      }
    } catch (e) {
      print('Request withdrawal error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get withdrawal history
  Future<Map<String, dynamic>> getWithdrawals({
    String? status,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiService.get(
        '/withdrawals',
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
          'error': response.error ?? 'Failed to get withdrawals',
        };
      }
    } catch (e) {
      print('Get withdrawals error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get tutor balance
  Future<Map<String, dynamic>> getBalance() async {
    try {
      final response = await _apiService.get('/withdrawals/balance');

      if (response.success && response.data != null) {
        return {
          'success': true,
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'error': response.error ?? 'Failed to get balance',
        };
      }
    } catch (e) {
      print('Get balance error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update bank account
  Future<Map<String, dynamic>> updateBankAccount({
    required String accountNumber,
    required String accountName,
    required String bankName,
  }) async {
    try {
      final response = await _apiService.put(
        '/withdrawals/bank-account',
        data: {
          'accountNumber': accountNumber,
          'accountName': accountName,
          'bankName': bankName,
        },
      );

      if (response.success && response.data != null) {
        return {
          'success': true,
          'data': response.data,
          'message': response.message,
        };
      } else {
        return {
          'success': false,
          'error': response.error ?? 'Failed to update bank account',
        };
      }
    } catch (e) {
      print('Update bank account error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get bank account
  Future<Map<String, dynamic>> getBankAccount() async {
    try {
      final response = await _apiService.get('/withdrawals/bank-account');

      if (response.success && response.data != null) {
        return {
          'success': true,
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'error': response.error ?? 'Bank account not set up',
        };
      }
    } catch (e) {
      print('Get bank account error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get withdrawal fees calculation
  Future<Map<String, dynamic>> getWithdrawalFees(double amount) async {
    try {
      final response = await _apiService.get(
        '/withdrawals/fees',
        queryParameters: {'amount': amount.toString()},
      );

      if (response.success && response.data != null) {
        return {
          'success': true,
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'error': response.error ?? 'Failed to calculate fees',
        };
      }
    } catch (e) {
      print('Get withdrawal fees error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
