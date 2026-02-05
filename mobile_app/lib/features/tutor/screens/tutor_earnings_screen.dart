import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/withdrawal_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/services/earnings_analytics_service.dart';

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
  final EarningsAnalyticsService _analyticsService = EarningsAnalyticsService();

  Map<String, dynamic>? _balance;
  List<dynamic> _transactions = [];
  Map<String, dynamic>? _analytics;
  bool _isLoadingBalance = true;
  bool _isLoadingTransactions = true;
  bool _isLoadingAnalytics = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBalance();
    _loadTransactions();
    _loadAnalytics();
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

  Future<void> _loadAnalytics() async {
    setState(() => _isLoadingAnalytics = true);
    try {
      final result = await _analyticsService.getEarningsAnalytics();
      if (result['success'] == true && mounted) {
        setState(() {
          _analytics = result['data'];
          _isLoadingAnalytics = false;
        });
      } else {
        setState(() => _isLoadingAnalytics = false);
      }
    } catch (e) {
      print('Load analytics error: $e');
      setState(() => _isLoadingAnalytics = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF16213E) : Colors.white,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isDark 
                ? [const Color(0xFF6B7FA8), const Color(0xFF8B9DC3)]
                : [const Color(0xFF0F3460), const Color(0xFF16213E)],
          ).createShader(bounds),
          child: const Text(
            'My Earnings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedPeriod = value),
            itemBuilder: (context) => _periods.map((period) => PopupMenuItem(
              value: period,
              child: Text(period),
            )).toList(),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF6B7FA8).withOpacity(0.2)
                    : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPeriod,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
          labelColor: isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
          unselectedLabelColor: isDark 
              ? Colors.white.withOpacity(0.5)
              : const Color(0xFF6B7FA8).withOpacity(0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
          _buildOverviewTab(isDark),
          _buildTransactionsTab(isDark),
          _buildAnalyticsTab(isDark),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark) {
    if (_isLoadingBalance) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
          ),
        ),
      );
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
                  Icons.account_balance_wallet_rounded,
                  isDark ? const Color(0xFF7FA87F) : Colors.green,
                  'Ready to withdraw',
                  isDark,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: _buildEarningsCard(
                  'Pending',
                  'ETB ${pending.toStringAsFixed(2)}',
                  Icons.pending_rounded,
                  isDark ? const Color(0xFFD4A574) : Colors.orange,
                  'In progress',
                  isDark,
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
                  Icons.trending_up_rounded,
                  isDark ? const Color(0xFF6B7FA8) : Colors.blue,
                  'All time',
                  isDark,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: _buildEarningsCard(
                  'Withdrawn',
                  'ETB ${withdrawn.toStringAsFixed(2)}',
                  Icons.money_off_rounded,
                  isDark ? const Color(0xFF8B7FA8) : Colors.purple,
                  'Total withdrawn',
                  isDark,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingXL),

          // Withdraw Button
          if (available > 0)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF6B7FA8), const Color(0xFF8B9DC3)]
                      : [const Color(0xFF0F3460), const Color(0xFF16213E)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460))
                        .withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _showWithdrawDialog,
                icon: const Icon(Icons.account_balance_rounded),
                label: const Text('Withdraw Funds'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.all(AppTheme.spacingLG),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Earnings Breakdown
          Text(
            'Earnings Breakdown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F3460),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF16213E), const Color(0xFF0F3460).withOpacity(0.8)]
                    : [Colors.white, const Color(0xFFF5F7FA)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Column(
              children: [
                _buildBreakdownItem('Total Earnings', 'ETB ${total.toStringAsFixed(2)}', 
                    isDark ? const Color(0xFF7FA87F) : Colors.green, isDark),
                const Divider(),
                _buildBreakdownItem('Withdrawn', 'ETB ${withdrawn.toStringAsFixed(2)}', 
                    isDark ? Colors.redAccent : Colors.red, isDark),
                const Divider(),
                _buildBreakdownItem('Available Balance', 'ETB ${available.toStringAsFixed(2)}', 
                    isDark ? const Color(0xFF6B7FA8) : Colors.blue, isDark, isTotal: true),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Bank Account Settings
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF16213E), const Color(0xFF0F3460).withOpacity(0.8)]
                    : [Colors.white, const Color(0xFFF5F7FA)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank Account Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F3460),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF6B7FA8).withOpacity(0.3), const Color(0xFF8B9DC3).withOpacity(0.3)]
                            : [const Color(0xFF0F3460).withOpacity(0.1), const Color(0xFF16213E).withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_rounded,
                      color: isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
                    ),
                  ),
                  title: Text(
                    'Bank Account',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F3460),
                    ),
                  ),
                  subtitle: Text(
                    'Manage your bank account',
                    style: TextStyle(
                      color: isDark 
                          ? Colors.white.withOpacity(0.6)
                          : const Color(0xFF6B7FA8),
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
                    size: 16,
                  ),
                  contentPadding: EdgeInsets.zero,
                  onTap: _manageBankAccount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(bool isDark) {
    if (_isLoadingTransactions) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
          ),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF16213E).withOpacity(0.5), const Color(0xFF0F3460).withOpacity(0.3)]
                      : [const Color(0xFFECEFF4), const Color(0xFFE8EAF6)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 64,
                color: isDark 
                    ? const Color(0xFF6B7FA8).withOpacity(0.5)
                    : const Color(0xFF0F3460).withOpacity(0.3),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F3460),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      itemCount: _transactions.length,
      itemBuilder: (context, index) => _buildTransactionCard(_transactions[index], isDark),
    );
  }

  Widget _buildAnalyticsTab(bool isDark) {
    if (_isLoadingAnalytics) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
          ),
        ),
      );
    }

    if (_analytics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: isDark 
                  ? const Color(0xFF6B7FA8).withOpacity(0.5)
                  : const Color(0xFF0F3460).withOpacity(0.3),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            Text(
              'No analytics data available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F3460),
              ),
            ),
          ],
        ),
      );
    }

    final metrics = _analytics!['metrics'] ?? {};
    final subjectPerformance = (_analytics!['subjectPerformance'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Metrics
          Text(
            'Performance Metrics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F3460),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF16213E), const Color(0xFF0F3460).withOpacity(0.8)]
                    : [Colors.white, const Color(0xFFF5F7FA)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Column(
              children: [
                _buildMetricRow('Average Rating', '${metrics['averageRating'] ?? '0.0'}/5', 
                    Icons.star_rounded, Colors.amber, isDark),
                const Divider(),
                _buildMetricRow('Response Rate', metrics['responseRate'] ?? '0%', 
                    Icons.reply_rounded, isDark ? const Color(0xFF7FA87F) : Colors.green, isDark),
                const Divider(),
                _buildMetricRow('Completion Rate', metrics['completionRate'] ?? '0%', 
                    Icons.check_circle_rounded, isDark ? const Color(0xFF6B7FA8) : Colors.blue, isDark),
                const Divider(),
                _buildMetricRow('Repeat Students', metrics['repeatStudentRate'] ?? '0%', 
                    Icons.refresh_rounded, isDark ? const Color(0xFF8B7FA8) : Colors.purple, isDark),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Subject Performance
          if (subjectPerformance.isNotEmpty) ...[
            Text(
              'Subject Performance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F3460),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingLG),
            
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF16213E), const Color(0xFF0F3460).withOpacity(0.8)]
                      : [Colors.white, const Color(0xFFF5F7FA)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Column(
                children: subjectPerformance.take(5).map<Widget>((subject) {
                  final subjectName = subject['subject'] ?? 'Unknown';
                  final sessions = subject['sessions'] ?? 0;
                  final earnings = (subject['earnings'] ?? 0).toDouble();
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSM),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subjectName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F3460),
                                ),
                              ),
                              Text(
                                '$sessions sessions',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark 
                                      ? Colors.white.withOpacity(0.6)
                                      : const Color(0xFF6B7FA8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'ETB ${earnings.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF7FA87F) : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingXL),
          ],
          
          // Summary Stats
          Text(
            'Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F3460),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF16213E), const Color(0xFF0F3460).withOpacity(0.8)]
                    : [Colors.white, const Color(0xFFF5F7FA)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Column(
              children: [
                _buildSummaryRow('Total Sessions', '${metrics['totalSessions'] ?? 0}', isDark),
                const Divider(),
                _buildSummaryRow('Total Students', '${metrics['totalStudents'] ?? 0}', isDark),
                const Divider(),
                _buildSummaryRow('Total Reviews', '${metrics['totalReviews'] ?? 0}', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF0F3460),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(String title, String amount, IconData icon, Color color, String change, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF16213E), const Color(0xFF0F3460).withOpacity(0.8)]
              : [Colors.white, const Color(0xFFF5F7FA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Flexible(
                child: Text(
                  change,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Text(
            amount,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: isDark 
                  ? Colors.white.withOpacity(0.6)
                  : const Color(0xFF6B7FA8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String amount, Color color, bool isDark, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF0F3460),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
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

  Widget _buildTransactionCard(Map<String, dynamic> transaction, bool isDark) {
    final type = transaction['type'] ?? 'payment';
    final amount = (transaction['amount'] ?? 0).toDouble();
    final netAmount = (transaction['netAmount'] ?? amount).toDouble();
    final status = transaction['status'] ?? 'pending';
    final description = transaction['description'] ?? 'Transaction';
    final createdAt = transaction['createdAt'] ?? '';

    Color statusColor = isDark ? const Color(0xFFD4A574) : Colors.orange;
    if (status == 'completed') statusColor = isDark ? const Color(0xFF7FA87F) : Colors.green;
    if (status == 'failed') statusColor = Colors.redAccent;

    IconData icon = Icons.payment_rounded;
    if (type == 'withdrawal') icon = Icons.account_balance_rounded;
    if (type == 'refund') icon = Icons.money_off_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF16213E), const Color(0xFF0F3460).withOpacity(0.8)]
              : [Colors.white, const Color(0xFFF5F7FA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: statusColor, size: 24),
        ),
        title: Text(
          description,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F3460),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${_formatDate(createdAt)} • ${type.toUpperCase()}',
              style: TextStyle(
                fontSize: 12,
                color: isDark 
                    ? Colors.white.withOpacity(0.6)
                    : const Color(0xFF6B7FA8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Status: $status',
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'ETB ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: type == 'withdrawal' 
                    ? (isDark ? Colors.redAccent : Colors.red)
                    : (isDark ? const Color(0xFF7FA87F) : Colors.green),
              ),
            ),
            if (type == 'withdrawal')
              Text(
                'Net: ETB ${netAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark 
                      ? Colors.white.withOpacity(0.5)
                      : const Color(0xFF6B7FA8),
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

  Widget _buildMetricRow(String label, String value, IconData icon, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F3460),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
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