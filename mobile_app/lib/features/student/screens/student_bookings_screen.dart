import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/widgets/session_action_button.dart';
import '../../auth/providers/auth_provider.dart';

class StudentBookingsScreen extends StatefulWidget {
  const StudentBookingsScreen({Key? key}) : super(key: key);

  @override
  State<StudentBookingsScreen> createState() => _StudentBookingsScreenState();
}

class _StudentBookingsScreenState extends State<StudentBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingService _bookingService = BookingService();
  final PaymentService _paymentService = PaymentService();
  final SessionService _sessionService = SessionService();
  
  List<Map<String, dynamic>> _upcomingBookings = [];
  List<Map<String, dynamic>> _completedBookings = [];
  List<Map<String, dynamic>> _cancelledBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;

      final response = await _bookingService.getBookings();
      
      if (response.success && response.data != null) {
        final allBookings = response.data as List<Map<String, dynamic>>;
        
        setState(() {
          _upcomingBookings = allBookings.where((b) => 
            b['status'] == 'pending' || b['status'] == 'confirmed'
          ).toList();
          
          _completedBookings = allBookings.where((b) => 
            b['status'] == 'completed'
          ).toList();
          
          _cancelledBookings = allBookings.where((b) => 
            b['status'] == 'cancelled'
          ).toList();
          
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startSession(Map<String, dynamic> booking) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Start session
      final response = await _sessionService.startSession(booking['id']);

      // Close loading
      if (mounted) Navigator.pop(context);

      if (response.success && response.data != null) {
        // Navigate to active session screen
        if (mounted) {
          context.push(
            '/active-session/${booking['id']}',
            extra: response.data,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to start session'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _joinSession(Map<String, dynamic> booking) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Join session (same endpoint, server will handle it)
      final response = await _sessionService.startSession(booking['id']);

      // Close loading
      if (mounted) Navigator.pop(context);

      if (response.success && response.data != null) {
        // Navigate to active session screen
        if (mounted) {
          context.push(
            '/active-session/${booking['id']}',
            extra: response.data,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to join session'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingBookings(),
                _buildCompletedBookings(),
                _buildCancelledBookings(),
              ],
            ),
    );
  }

  Widget _buildUpcomingBookings() {
    if (_upcomingBookings.isEmpty) {
      return _buildEmptyState('No upcoming sessions', 'Book a tutor to get started!');
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        itemCount: _upcomingBookings.length,
        itemBuilder: (context, index) => _buildBookingCard(_upcomingBookings[index], true),
      ),
    );
  }

  Widget _buildCompletedBookings() {
    if (_completedBookings.isEmpty) {
      return _buildEmptyState('No completed sessions', 'Your completed sessions will appear here');
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        itemCount: _completedBookings.length,
        itemBuilder: (context, index) => _buildBookingCard(_completedBookings[index], false),
      ),
    );
  }

  Widget _buildCancelledBookings() {
    if (_cancelledBookings.isEmpty) {
      return _buildEmptyState('No cancelled sessions', 'Cancelled sessions will appear here');
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        itemCount: _cancelledBookings.length,
        itemBuilder: (context, index) => _buildBookingCard(_cancelledBookings[index], false),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isUpcoming) {
    final status = booking['status'] as String;
    Color statusColor = _getStatusColor(status);
    final tutorName = booking['tutorName'] ?? 'Unknown Tutor';
    final subject = booking['subject'] ?? 'Unknown Subject';
    final date = booking['sessionDate'] ?? '';
    final startTime = booking['startTime'] ?? '';
    final endTime = booking['endTime'] ?? '';
    final amount = booking['totalAmount'] ?? booking['pricePerHour'] ?? 0;
    final paymentStatus = booking['paymentStatus'] ?? 'pending';
    final meetingLink = booking['meetingLink'];

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with tutor name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tutorName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSM,
                    vertical: AppTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingSM),
            
            // Subject
            Text(
              subject,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingSM),
            
            // Date and Time
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: AppTheme.spacingXS),
                Text(
                  _formatDate(date),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: AppTheme.spacingXS),
                Text(
                  '$startTime - $endTime',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingSM),
            
            // Amount and Payment Status
            Row(
              children: [
                Icon(Icons.payments, size: 16, color: Colors.grey[600]),
                const SizedBox(width: AppTheme.spacingXS),
                Text(
                  'Payment: ${_getPaymentStatusText(paymentStatus)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingMD),
            
            // Action Buttons
            _buildActionButtons(booking, isUpcoming, status, meetingLink),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> booking, bool isUpcoming, String status, String? meetingLink) {
    final paymentStatus = booking['paymentStatus'] ?? booking['payment']?['status'] ?? 'pending';
    
    // Show Pay Now button for pending payment
    if (isUpcoming && paymentStatus == 'pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _payForBooking(booking),
              icon: const Icon(Icons.payment, size: 16),
              label: const Text('Pay Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _cancelSession(booking),
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      );
    }
    
    if (isUpcoming && status == 'confirmed') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Session Action Button (Start/Join Session)
          SessionActionButton(
            booking: booking,
            onStartSession: () => _startSession(booking),
            onJoinSession: () => _joinSession(booking),
          ),
          
          const SizedBox(height: AppTheme.spacingSM),
          
          // Other action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rescheduleSession(booking),
                  icon: const Icon(Icons.schedule, size: 16),
                  label: const Text('Reschedule'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cancelSession(booking),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (!isUpcoming && status == 'completed') {
      // Check if review exists
      final hasReview = booking['hasReview'] == true;
      
      return Row(
        children: [
          if (!hasReview)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _rateSession(booking),
                icon: const Icon(Icons.star, size: 16),
                label: const Text('Write Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          if (hasReview)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingSM),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: AppTheme.spacingXS),
                    Text(
                      'Review Submitted',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _bookAgain(booking),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Book Again'),
            ),
          ),
        ],
      );
    } else if (isUpcoming && status == 'pending') {
      return OutlinedButton.icon(
        onPressed: () => _cancelSession(booking),
        icon: const Icon(Icons.cancel, size: 16),
        label: const Text('Cancel Request'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppTheme.spacingLG),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXL),
          ElevatedButton(
            onPressed: () => context.go('/student/search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Find Tutors'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }

  String _getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _payForBooking(Map<String, dynamic> booking) async {
    try {
      final bookingId = booking['_id'] ?? booking['id'];
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Process payment with WebView
      final result = await _paymentService.processBookingPayment(context, bookingId);
      
      // Close loading
      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        // Payment successful
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Payment successful! Your booking is confirmed.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Refresh bookings
          _loadBookings();
        }
      } else if (result['status'] == 'cancelled') {
        // Payment cancelled
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment was cancelled'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Payment failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Payment failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _joinSession(Map<String, dynamic> booking) {
    final tutorName = booking['tutorName'] ?? 'tutor';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joining session with $tutorName'),
        action: SnackBarAction(
          label: 'Open Link',
          onPressed: () {
            // TODO: Launch meeting link
          },
        ),
      ),
    );
  }

  Future<void> _rescheduleSession(Map<String, dynamic> booking) async {
    final tutorName = booking['tutorName'] ?? 'tutor';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rescheduling session with $tutorName')),
    );
    // TODO: Show reschedule dialog
  }

  Future<void> _cancelSession(Map<String, dynamic> booking) async {
    final tutorName = booking['tutorName'] ?? 'tutor';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Session'),
        content: Text('Are you sure you want to cancel this session with $tutorName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Session'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Session'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final bookingId = booking['_id'] ?? booking['id'];
        final response = await _bookingService.cancelBooking(
          bookingId: bookingId,
          reason: 'Student cancelled',
        );
        
        if (response.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Session cancelled successfully')),
            );
            _loadBookings();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to cancel: ${response.error}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel: $e')),
          );
        }
      }
    }
  }

  Future<void> _rateSession(Map<String, dynamic> booking) async {
    final bookingId = booking['_id'] ?? booking['id'];
    final tutorId = booking['tutorId'];
    
    if (bookingId == null || tutorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to rate this session')),
      );
      return;
    }

    // Navigate to create review screen
    final result = await context.push(
      '/student/create-review',
      extra: {
        'bookingId': bookingId,
        'tutorId': tutorId,
        'tutorName': booking['tutorName'] ?? 'Tutor',
        'subject': booking['subject'] ?? 'Session',
        'sessionDate': booking['sessionDate'],
      },
    );

    // Reload bookings if review was submitted
    if (result == true && mounted) {
      _loadBookings();
    }
  }

  void _bookAgain(Map<String, dynamic> booking) {
    final tutorId = booking['tutorId'];
    if (tutorId != null) {
      context.go('/student/tutor/$tutorId');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
