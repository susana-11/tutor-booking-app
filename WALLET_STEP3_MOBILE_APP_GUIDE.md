# 💰 Wallet System - Step 3: Mobile App Implementation Guide

## Overview
This guide will help you implement the wallet UI in the Flutter mobile app.

## Backend is Ready! ✅
- Wallet API endpoints working
- Booking integration complete
- Escrow system integrated
- Refunds working

## What to Build

### 1. Wallet Service (API Integration)
### 2. Wallet Screens (UI)
### 3. Update Booking Flow
### 4. Update Profile Screens

---

## Part 1: Create Wallet Service

**File**: `mobile_app/lib/core/services/wallet_service.dart`

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage_service.dart';
import 'app_config.dart';

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
      final token = await _storage.getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/wallet/topup'),
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

  // Get wallet transactions
  Future<Map<String, dynamic>> getTransactions({
    String? type,
    int limit = 50,
  }) async {
    try {
      final token = await _storage.getToken();
      var url = '${AppConfig.apiUrl}/wallet/transactions?limit=$limit';
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

  // Pay booking with wallet
  Future<Map<String, dynamic>> payBookingWithWallet(String bookingId) async {
    try {
      final token = await _storage.getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/wallet/pay-booking'),
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
      final token = await _storage.getToken();
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
}
```

---

## Part 2: Create Wallet Screen

**File**: `mobile_app/lib/features/wallet/screens/wallet_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  bool _isLoading = true;
  double _balance = 0.0;
  double _escrowBalance = 0.0;
  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);
    
    // Load balance
    final balanceResult = await _walletService.getWalletBalance();
    if (balanceResult['success']) {
      setState(() {
        _balance = (balanceResult['data']['balance'] ?? 0).toDouble();
        _escrowBalance = (balanceResult['data']['escrowBalance'] ?? 0).toDouble();
      });
    }

    // Load recent transactions
    final transactionsResult = await _walletService.getTransactions(limit: 10);
    if (transactionsResult['success']) {
      setState(() {
        _recentTransactions = List<Map<String, dynamic>>.from(
          transactionsResult['data'] ?? []
        );
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWalletData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    _buildBalanceCard(isDark),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.add_circle,
                            label: 'Add Money',
                            color: Colors.green,
                            onTap: () => context.push('/wallet/add-balance'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.history,
                            label: 'History',
                            color: Colors.blue,
                            onTap: () => context.push('/wallet/transactions'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Recent Transactions
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_recentTransactions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No transactions yet',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._recentTransactions.map((txn) => _buildTransactionItem(txn, isDark)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBalanceCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B46C1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_balance.toStringAsFixed(2)} ETB',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_escrowBalance > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'In Escrow',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${_escrowBalance.toStringAsFixed(2)} ETB',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> txn, bool isDark) {
    final type = txn['type'] ?? '';
    final amount = (txn['amount'] ?? 0).toDouble();
    final isCredit = type.contains('topup') || type.contains('refund') || type.contains('release');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isCredit ? Colors.green : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn['description'] ?? type,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(txn['createdAt']),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}${amount.toStringAsFixed(2)} ETB',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}
```

---

## Part 3: Add Routes

**File**: `mobile_app/lib/core/router/app_router.dart`

Add these routes:

```dart
GoRoute(
  path: '/wallet',
  builder: (context, state) => const WalletScreen(),
),
GoRoute(
  path: '/wallet/add-balance',
  builder: (context, state) => const AddBalanceScreen(),
),
GoRoute(
  path: '/wallet/transactions',
  builder: (context, state) => const TransactionHistoryScreen(),
),
```

---

## Part 4: Update Booking Screen

In `tutor_booking_screen.dart`, add wallet payment option:

```dart
// Add this button after Chapa payment button
ElevatedButton(
  onPressed: () async {
    // Check balance first
    final walletService = WalletService();
    final balanceResult = await walletService.getWalletBalance();
    
    if (balanceResult['success']) {
      final balance = balanceResult['data']['balance'];
      final amount = widget.booking.amount;
      
      if (balance >= amount) {
        // Pay with wallet
        _payWithWallet();
      } else {
        // Show insufficient balance dialog
        _showInsufficientBalanceDialog(balance, amount);
      }
    }
  },
  child: const Text('Pay with Wallet'),
)
```

---

## Quick Implementation Steps

### Day 1: Service & Basic UI (3-4 hours)
1. Create `wallet_service.dart` (1 hour)
2. Create `wallet_screen.dart` (2 hours)
3. Add routes (15 min)
4. Test balance display (30 min)

### Day 2: Add Balance & Transactions (3-4 hours)
1. Create `add_balance_screen.dart` (2 hours)
2. Create `transaction_history_screen.dart` (1 hour)
3. Test top-up flow (1 hour)

### Day 3: Booking Integration (2-3 hours)
1. Update booking screen (1 hour)
2. Add wallet payment button (30 min)
3. Handle insufficient balance (30 min)
4. Test booking with wallet (1 hour)

### Day 4: Polish & Test (2-3 hours)
1. Add loading states (30 min)
2. Add error handling (30 min)
3. Test all flows (1-2 hours)
4. Fix bugs (1 hour)

---

## Testing Checklist

- [ ] Wallet balance displays correctly
- [ ] Top-up redirects to Chapa
- [ ] Top-up updates balance after payment
- [ ] Transaction history shows all transactions
- [ ] Booking payment with wallet works
- [ ] Insufficient balance shows error
- [ ] Escrow balance displays correctly
- [ ] Refunds appear in wallet
- [ ] Withdrawal request works (tutor)

---

## Status

✅ Backend Complete
⏳ Mobile App UI (Next)

**Start with**: Create `wallet_service.dart` and `wallet_screen.dart`

