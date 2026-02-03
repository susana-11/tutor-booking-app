import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/withdrawal_service.dart';
import '../../../core/services/payment_service.dart';

class TutorEarningsScreen extends StatefulWidget {
  const TutorEarningsScreen({super.key});

  @override
  State<TutorEarningsScreen> createState() => _TutorEarningsScreenState();
}

class _TutorEarningsScreenState extends State<TutorEarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';
  
  final List<String> _periods = [
    'This Week',
    'This Month',
    'Last Month',
    'This Year',
    'All Time',
  ];

  final WithdrawalService _withdrawalService = WithdrawalService();
  final PaymentService _paymentService = PaymentService();

  Map<String, dynamic>? _balance;
  List<dynamic> _transactions = [];
  bool _isLoadingBalance = true;
  bool _isLoadingTransactions = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBalance();
    _loadTransactions();
  }

  Future<void> _loadBalance() async {
    setState(() => _isLoadingBalance = true);
    try {
      final result = await _withdrawalService.getBalance();
      if (result['success'] == true && mounted) {
        setState(() {
          _balance = result['data'];
          _isLoadingBalance = false;
        });
      } else {
        setState(() => _isLoadingBalance = false);
      }
    } catch (e) {
      print('Load balance error: $e');
      setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoadingTransactions = true);
    try {
      final result = await _paymentService.getTransactions(limit: 50);
      if (result['success'] == true && mounted) {
        setState(() {
          _transactions = result['data'] ?? [];
          _isLoadingTransactions = false;
        });
      } else {
        setState(() => _isLoadingTransactions = false);
      }
    } catch (e) {
      print('Load transactions error: $e');
      setState(() => _isLoadingTransactions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedPeriod = value),
            itemBuilder: (context) => _periods.map((period) => PopupMenuItem(
              value: period,
              child: Text(period),
            )).toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedPeriod),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Transactions'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTransactionsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoadingBalance) {
      return const Center(child: CircularProgressIndicator());
    }

    final available = (_balance?['available'] ?? 0).toDouble();
    final pending = (_balance?['pending'] ?? 0).toDouble();
    final total = (_balance?['total'] ?? 0).toDouble();
    final withdrawn = (_balance?['withdrawn'] ?? 0).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildEarningsCard(
                  'Available',
                  'ETB ${available.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  Colors.green,
                  'Ready to withdraw',
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: _buildEarningsCard(
                  'Pending',
                  'ETB ${pending.toStringAsFixed(2)}',
                  Icons.pending,
                  Colors.orange,
                  'In progress',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingMD),
          
          Row(
            children: [
              Expanded(
                child: _buildEarningsCard(
                  'Total Earned',
                  'ETB ${total.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.blue,
                  'All time',
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: _buildEarningsCard(
                  'Withdrawn',
                  'ETB ${withdrawn.toStringAsFixed(2)}',
                  Icons.money_off,
                  Colors.purple,
                  'Total withdrawn',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingXL),

          // Withdraw Button
          if (available > 0)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showWithdrawDialog,
                icon: const Icon(Icons.account_balance),
                label: const Text('Withdraw Funds'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(AppTheme.spacingLG),
                ),
              ),
            ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Earnings Breakdown
          Text(
            'Earnings Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Column(
                children: [
                  _buildBreakdownItem('Total Earnings', 'ETB ${total.toStringAsFixed(2)}', Colors.green),
                  const Divider(),
                  _buildBreakdownItem('Withdrawn', 'ETB ${withdrawn.toStringAsFixed(2)}', Colors.red),
                  const Divider(),
                  _buildBreakdownItem('Available Balance', 'ETB ${available.toStringAsFixed(2)}', Colors.blue, isTotal: true),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Bank Account Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bank Account Settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  ListTile(
                    leading: const Icon(Icons.account_balance),
                    title: const Text('Bank Account'),
                    subtitle: const Text('Manage your bank account'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    contentPadding: EdgeInsets.zero,
                    onTap: _manageBankAccount,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    if (_isLoadingTransactions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: AppTheme.spacingMD),
            Text(
              'No transactions yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      itemCount: _transactions.length,
      itemBuilder: (context, index) => _buildTransactionCard(_transactions[index]),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Metrics
          Text(
            'Performance Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Column(
                children: [
                  _buildMetricRow('Average Rating', '4.8/5', Icons.star, Colors.amber),
                  const Divider(),
                  _buildMetricRow('Response Rate', '95%', Icons.reply, Colors.green),
                  const Divider(),
                  _buildMetricRow('Completion Rate', '98%', Icons.check_circle, Colors.blue),
                  const Divider(),
                  _buildMetricRow('Repeat Students', '67%', Icons.refresh, Colors.purple),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Subject Performance (Placeholder)
          Text(
            'Subject Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Center(
                child: Text(
                  'Subject performance analytics coming soon',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Monthly Trends
          Text(
            'Monthly Trends',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Column(
                children: [
                  Text(
                    'Earnings Growth',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLG),
                  // Placeholder for chart
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: const Center(
                      child: Text('Chart will be implemented here'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(String title, String amount, IconData icon, Color color, String change) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Flexible(
                  child: Text(
                    change,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              amount,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String amount, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: payment['status'] == 'Completed' 
              ? Colors.green.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          child: Icon(
            payment['status'] == 'Completed' ? Icons.check : Icons.pending,
            color: payment['status'] == 'Completed' ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(payment['description']),
        subtitle: Text('${payment['date']} • ${payment['method']}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              payment['amount'],
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              payment['status'],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: payment['status'] == 'Completed' ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? 'payment';
    final amount = (transaction['amount'] ?? 0).toDouble();
    final netAmount = (transaction['netAmount'] ?? amount).toDouble();
    final status = transaction['status'] ?? 'pending';
    final description = transaction['description'] ?? 'Transaction';
    final createdAt = transaction['createdAt'] ?? '';

    Color statusColor = Colors.orange;
    if (status == 'completed') statusColor = Colors.green;
    if (status == 'failed') statusColor = Colors.red;

    IconData icon = Icons.payment;
    if (type == 'withdrawal') icon = Icons.account_balance;
    if (type == 'refund') icon = Icons.money_off;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(icon, color: statusColor),
        ),
        title: Text(description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_formatDate(createdAt)} • ${type.toUpperCase()}'),
            Text('Status: $status', style: TextStyle(color: statusColor)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'ETB ${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: type == 'withdrawal' ? Colors.red : Colors.green,
              ),
            ),
            if (type == 'withdrawal')
              Text(
                'Net: ETB ${netAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildMetricRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSM),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _manageBankAccount() {
    showDialog(
      context: context,
      builder: (context) => _BankAccountDialog(
        withdrawalService: _withdrawalService,
        onSaved: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bank account updated successfully')),
          );
        },
      ),
    );
  }

  void _showWithdrawDialog() {
    if (_balance == null) return;

    final available = (_balance!['available'] ?? 0).toDouble();
    if (available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No funds available for withdrawal')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _WithdrawDialog(
        availableBalance: available,
        withdrawalService: _withdrawalService,
        onSuccess: () {
          _loadBalance();
          _loadTransactions();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Withdrawal request submitted successfully')),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Withdraw Dialog Widget
class _WithdrawDialog extends StatefulWidget {
  final double availableBalance;
  final WithdrawalService withdrawalService;
  final VoidCallback onSuccess;

  const _WithdrawDialog({
    required this.availableBalance,
    required this.withdrawalService,
    required this.onSuccess,
  });

  @override
  State<_WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<_WithdrawDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isProcessing = false;
  Map<String, dynamic>? _fees;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _calculateFees() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _fees = null);
      return;
    }

    final result = await widget.withdrawalService.getWithdrawalFees(amount);
    if (result['success'] == true && mounted) {
      setState(() => _fees = result['data']);
    }
  }

  Future<void> _processWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    final amount = double.parse(_amountController.text);
    final result = await widget.withdrawalService.requestWithdrawal(amount);

    setState(() => _isProcessing = false);

    if (result['success'] == true && mounted) {
      Navigator.pop(context);
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Withdrawal failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Withdraw Funds'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available: ETB ${widget.availableBalance.toStringAsFixed(2)}'),
            const SizedBox(height: AppTheme.spacingMD),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'ETB ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter valid amount';
                }
                if (amount > widget.availableBalance) {
                  return 'Insufficient balance';
                }
                if (amount < 100) {
                  return 'Minimum withdrawal is ETB 100';
                }
                return null;
              },
              onChanged: (_) => _calculateFees(),
            ),
            if (_fees != null) ...[
              const SizedBox(height: AppTheme.spacingMD),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount:'),
                        Text('ETB ${_fees!['amount'].toStringAsFixed(2)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Platform Fee (${_fees!['platformFeePercentage']}%):'),
                        Text('-ETB ${_fees!['platformFee'].toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('You will receive:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          'ETB ${_fees!['netAmount'].toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processWithdrawal,
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Withdraw'),
        ),
      ],
    );
  }
}

// Bank Account Dialog Widget
class _BankAccountDialog extends StatefulWidget {
  final WithdrawalService withdrawalService;
  final VoidCallback onSaved;

  const _BankAccountDialog({
    required this.withdrawalService,
    required this.onSaved,
  });

  @override
  State<_BankAccountDialog> createState() => _BankAccountDialogState();
}

class _BankAccountDialogState extends State<_BankAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBankAccount();
  }

  Future<void> _loadBankAccount() async {
    final result = await widget.withdrawalService.getBankAccount();
    if (result['success'] == true && mounted) {
      final data = result['data'];
      _accountNumberController.text = data['accountNumber'] ?? '';
      _accountNameController.text = data['accountName'] ?? '';
      _bankNameController.text = data['bankName'] ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveBankAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final result = await widget.withdrawalService.updateBankAccount(
      accountNumber: _accountNumberController.text,
      accountName: _accountNameController.text,
      bankName: _bankNameController.text,
    );

    setState(() => _isSaving = false);

    if (result['success'] == true && mounted) {
      Navigator.pop(context);
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to save bank account')),
      );
    }
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: const Text('Bank Account'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMD),
              TextFormField(
                controller: _accountNameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMD),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter bank name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveBankAccount,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}