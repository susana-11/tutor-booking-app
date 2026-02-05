import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../../../core/theme/app_theme.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/widgets/session_action_button.dart';
import '../../../core/widgets/reschedule_request_dialog.dart';
import '../../../core/widgets/reschedule_requests_dialog.dart';
import '../../../core/widgets/cancel_booking_dialog.dart';
import '../../auth/providers/auth_provider.dart';

class StudentBookingsScreen extends StatefulWidget {
  const StudentBookingsScreen({Key? key}) : super(key: key);

  @override
  State<StudentBookingsScreen> createState() => _StudentBookingsScreenState();
}

class _StudentBookingsScreenState extends State<StudentBookingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final BookingService _bookingService = BookingService();
  final PaymentService _paymentService = PaymentService();
  final SessionService _sessionService = SessionService();
  
  List<Map<String, dynamic>> _upcomingBookings = [];
  List<Map<String, dynamic>> _completedBookings = [];
  List<Map<String, dynamic>> _cancelledBookings = [];
  bool _isLoading = true;
  
  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAnimations();
    _loadBookings();
  }

  void _initializeAnimations() {
    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeIn,
    ));
    
    // Start animations
    _fadeController?.forward();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await _bookingService.getBookings();
      
      if (response.success && response.data != null) {
        final allBookings = response.data as List<Map<String, dynamic>>;
        
        // Filter bookings by status
        // Upcoming: pending or confirmed bookings with future dates
        final now = DateTime.now();
        final upcomingList = <Map<String, dynamic>>[];
        final completedList = <Map<String, dynamic>>[];
        final cancelledList = <Map<String, dynamic>>[];
        
        for (var booking in allBookings) {
          final status = booking['status'] as String?;
          final sessionDateStr = booking['sessionDate'] as String?;
          
          if (status == null) continue;
          
          // Parse session date
          DateTime? sessionDate;
          if (sessionDateStr != null) {
            try {
              sessionDate = DateTime.parse(sessionDateStr);
            } catch (e) {
              print('Error parsing date: $sessionDateStr');
            }
          }
          
          // Categorize bookings
          if (status == 'completed') {
            completedList.add(booking);
          } else if (status == 'cancelled' || status == 'declined') {
            cancelledList.add(booking);
          } else if (status == 'pending' || status == 'confirmed') {
            // Only show as upcoming if date is in the future or today
            if (sessionDate != null) {
              final sessionDay = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
              final today = DateTime(now.year, now.month, now.day);
              if (sessionDay.isAfter(today) || sessionDay.isAtSameMomentAs(today)) {
                upcomingList.add(booking);
              } else {
                // Past date but not completed - move to cancelled
                cancelledList.add(booking);
              }
            } else {
              // No date, show in upcoming
              upcomingList.add(booking);
            }
          }
        }
        
        // Sort by date (most recent first for upcoming, most recent last for completed)
        upcomingList.sort((a, b) {
          final dateA = DateTime.tryParse(a['sessionDate'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['sessionDate'] ?? '') ?? DateTime.now();
          return dateA.compareTo(dateB); // Earliest first
        });
        
        completedList.sort((a, b) {
          final dateA = DateTime.tryParse(a['sessionDate'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['sessionDate'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA); // Most recent first
        });
        
        cancelledList.sort((a, b) {
          final dateA = DateTime.tryParse(a['sessionDate'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['sessionDate'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA); // Most recent first
        });
        
        setState(() {
          _upcomingBookings = upcomingList;
          _completedBookings = completedList;
          _cancelledBookings = cancelledList;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to load bookings')),
          );
        }
      }
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e')),
        );
      }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(isDark),
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(isDark),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Modern Tab Bar
                _buildModernTabBar(isDark),
                
                // Tab Content
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState(isDark)
                      : FadeTransition(
                          opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildUpcomingBookings(isDark),
                              _buildCompletedBookings(isDark),
                              _buildCancelledBookings(isDark),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(12),
            child: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : AppTheme.textPrimaryColor,
            ),
          ),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
        ).createShader(bounds),
        child: const Text(
          'My Bookings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _loadBookings,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.refresh_rounded,
                  color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                  const Color(0xFF0F3460),
                ]
              : [
                  const Color(0xFFF8F9FA),
                  const Color(0xFFE9ECEF),
                  const Color(0xFFDEE2E6),
                ],
        ),
      ),
    );
  }

  Widget _buildModernTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMD),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B46C1).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark
            ? Colors.white.withOpacity(0.6)
            : AppTheme.textSecondaryColor,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule_rounded, size: 14),
                const SizedBox(width: 4),
                const Flexible(
                  child: Text(
                    'Upcoming',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_upcomingBookings.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_upcomingBookings.length}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 14),
                const SizedBox(width: 4),
                const Flexible(
                  child: Text(
                    'Completed',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_completedBookings.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_completedBookings.length}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cancel_rounded, size: 14),
                const SizedBox(width: 4),
                const Flexible(
                  child: Text(
                    'Cancelled',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_cancelledBookings.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_cancelledBookings.length}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B46C1).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your bookings...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingBookings(bool isDark) {
    if (_upcomingBookings.isEmpty) {
      return _buildEmptyState(
        'No upcoming sessions',
        'Book a tutor to get started!',
        Icons.calendar_today_rounded,
        isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: isDark ? const Color(0xFF38B2AC) : AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        itemCount: _upcomingBookings.length,
        itemBuilder: (context, index) => _buildModernBookingCard(
          _upcomingBookings[index],
          true,
          isDark,
        ),
      ),
    );
  }

  Widget _buildCompletedBookings(bool isDark) {
    if (_completedBookings.isEmpty) {
      return _buildEmptyState(
        'No completed sessions',
        'Your completed sessions will appear here',
        Icons.check_circle_outline_rounded,
        isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: isDark ? const Color(0xFF38B2AC) : AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        itemCount: _completedBookings.length,
        itemBuilder: (context, index) => _buildModernBookingCard(
          _completedBookings[index],
          false,
          isDark,
        ),
      ),
    );
  }

  Widget _buildCancelledBookings(bool isDark) {
    if (_cancelledBookings.isEmpty) {
      return _buildEmptyState(
        'No cancelled sessions',
        'Cancelled sessions will appear here',
        Icons.cancel_outlined,
        isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: isDark ? const Color(0xFF38B2AC) : AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        itemCount: _cancelledBookings.length,
        itemBuilder: (context, index) => _buildModernBookingCard(
          _cancelledBookings[index],
          false,
          isDark,
        ),
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

  Widget _buildEmptyState(String title, String subtitle, IconData icon, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B46C1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withOpacity(0.6)
                  : AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXL),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B46C1).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go('/student/search'),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.search_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Find Tutors',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBookingCard(Map<String, dynamic> booking, bool isUpcoming, bool isDark) {
    final status = booking['status'] as String;
    final statusColor = _getStatusColor(status);
    final tutorName = booking['tutorName'] ?? 'Unknown Tutor';
    final subject = booking['subject'] ?? 'Unknown Subject';
    final date = booking['sessionDate'] ?? '';
    final startTime = booking['startTime'] ?? '';
    final endTime = booking['endTime'] ?? '';
    final amount = booking['totalAmount'] ?? booking['pricePerHour'] ?? 0;
    final paymentStatus = booking['paymentStatus'] ?? 'pending';
    final meetingLink = booking['meetingLink'];

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getStatusGradient(status),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Tutor Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      tutorName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tutorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          subject,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and Time Row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.calendar_today_rounded,
                        label: _formatDate(date),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.access_time_rounded,
                        label: '$startTime - $endTime',
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Payment Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.03)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.payments_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Status',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.6)
                                      : AppTheme.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getPaymentStatusText(paymentStatus),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _getPaymentStatusColor(paymentStatus),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                        ).createShader(bounds),
                        child: Text(
                          '\$${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingMD),
                
                // Action Buttons
                _buildActionButtons(booking, isUpcoming, status, meetingLink),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.textPrimaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getStatusGradient(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return [const Color(0xFF10b981), const Color(0xFF059669)];
      case 'pending':
        return [const Color(0xFFf59e0b), const Color(0xFFd97706)];
      case 'completed':
        return [const Color(0xFF3b82f6), const Color(0xFF2563eb)];
      case 'cancelled':
      case 'declined':
        return [const Color(0xFFef4444), const Color(0xFFdc2626)];
      default:
        return [const Color(0xFF6b7280), const Color(0xFF4b5563)];
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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

  Future<void> _rescheduleSession(Map<String, dynamic> booking) async {
    // Show reschedule request dialog
    showDialog(
      context: context,
      builder: (context) => RescheduleRequestDialog(
        booking: booking,
        onSuccess: _loadBookings,
      ),
    );
  }

  void _viewRescheduleRequests(Map<String, dynamic> booking) {
    // Show reschedule requests dialog
    showDialog(
      context: context,
      builder: (context) => RescheduleRequestsDialog(
        booking: booking,
        onSuccess: _loadBookings,
      ),
    );
  }

  Future<void> _cancelSession(Map<String, dynamic> booking) async {
    // Check if session can be cancelled
    final status = booking['status'];
    final sessionStarted = booking['sessionStartedAt'] != null || 
                          booking['session']?['isActive'] == true ||
                          booking['checkIn']?['bothCheckedIn'] == true;
    
    if (sessionStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot cancel - session has already started'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!['pending', 'confirmed'].contains(status)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot cancel booking with status: $status'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show cancel dialog with refund information
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CancelBookingDialog(
        bookingId: booking['_id'] ?? booking['id'],
        bookingDetails: booking,
        onCancelled: () {
          _loadBookings();
        },
      ),
    );

    if (result == true && mounted) {
      _loadBookings();
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
    _fadeController?.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
