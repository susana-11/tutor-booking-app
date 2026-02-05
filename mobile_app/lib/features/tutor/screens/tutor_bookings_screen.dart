import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/widgets/session_action_button.dart';
import '../../../core/widgets/reschedule_request_dialog.dart';
import '../../../core/widgets/reschedule_requests_dialog.dart';

class TutorBookingsScreen extends StatefulWidget {
  const TutorBookingsScreen({super.key});

  @override
  State<TutorBookingsScreen> createState() => _TutorBookingsScreenState();
}

class _TutorBookingsScreenState extends State<TutorBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingService _bookingService = BookingService();
  final SessionService _sessionService = SessionService();
  final SocketService _socketService = SocketService();

  List<Map<String, dynamic>> _pendingBookings = [];
  List<Map<String, dynamic>> _confirmedBookings = [];
  List<Map<String, dynamic>> _completedBookings = [];
  List<Map<String, dynamic>> _cancelledBookings = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBookings();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socketService.on('new_booking_request', (data) {
      _loadBookings(); // Refresh bookings when new request comes in
      _showBookingNotification('New booking request from ${data['studentName']}');
    });

    _socketService.on('booking_response', (data) {
      _loadBookings(); // Refresh bookings when response is sent
    });
  }

  void _showBookingNotification(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blue,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              _tabController.animateTo(0); // Go to pending tab
            },
          ),
        ),
      );
    }
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);

    try {
      // Load all bookings at once
      final response = await _bookingService.getBookings();

      if (response.success && response.data != null) {
        final allBookings = response.data as List<Map<String, dynamic>>;
        
        // Filter bookings by status
        final now = DateTime.now();
        final pendingList = <Map<String, dynamic>>[];
        final confirmedList = <Map<String, dynamic>>[];
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
          if (status == 'pending') {
            // Only show pending if date is in the future or today
            if (sessionDate != null) {
              final sessionDay = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
              final today = DateTime(now.year, now.month, now.day);
              if (sessionDay.isAfter(today) || sessionDay.isAtSameMomentAs(today)) {
                pendingList.add(booking);
              } else {
                // Past date - move to cancelled
                cancelledList.add(booking);
              }
            } else {
              pendingList.add(booking);
            }
          } else if (status == 'confirmed') {
            // Only show confirmed if date is in the future or today
            if (sessionDate != null) {
              final sessionDay = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
              final today = DateTime(now.year, now.month, now.day);
              if (sessionDay.isAfter(today) || sessionDay.isAtSameMomentAs(today)) {
                confirmedList.add(booking);
              } else {
                // Past date but not completed - move to cancelled
                cancelledList.add(booking);
              }
            } else {
              confirmedList.add(booking);
            }
          } else if (status == 'completed') {
            completedList.add(booking);
          } else if (status == 'cancelled' || status == 'declined') {
            cancelledList.add(booking);
          }
        }
        
        // Sort by date
        pendingList.sort((a, b) {
          final dateA = DateTime.tryParse(a['sessionDate'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['sessionDate'] ?? '') ?? DateTime.now();
          return dateA.compareTo(dateB); // Earliest first
        });
        
        confirmedList.sort((a, b) {
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
        
        if (mounted) {
          setState(() {
            _pendingBookings = pendingList;
            _confirmedBookings = confirmedList;
            _completedBookings = completedList;
            _cancelledBookings = cancelledList;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to load bookings')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bookings: $e')),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(isDark),
      body: Stack(
        children: [
          _buildElegantBackground(isDark),
          
          SafeArea(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? const Color(0xFF8B9DC3) : const Color(0xFF6B7FA8),
                      ),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPendingBookings(isDark),
                      _buildConfirmedBookings(isDark),
                      _buildCompletedBookings(isDark),
                      _buildCancelledBookings(isDark),
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
      title: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: isDark 
              ? [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)]
              : [const Color(0xFF5F6F94), const Color(0xFF8B9DC3)],
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
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _loadBookings,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.refresh,
                  color: isDark ? Colors.white70 : const Color(0xFF5F6F94),
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF6B7FA8), const Color(0xFF8B9DC3)]
                    : [const Color(0xFF6B7FA8), const Color(0xFF8B9DC3)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF6B7FA8),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            isScrollable: true,
            tabs: [
              Tab(
                child: Row(
                  children: [
                    const Text('Pending'),
                    if (_pendingBookings.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${_pendingBookings.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Confirmed'),
              const Tab(text: 'Completed'),
              const Tab(text: 'Cancelled'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElegantBackground(bool isDark) {
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
                  const Color(0xFFF5F7FA),
                  const Color(0xFFECEFF4),
                  const Color(0xFFE8EAF6),
                ],
        ),
      ),
    );
  }

  Widget _buildPendingBookings(bool isDark) {
    if (_pendingBookings.isEmpty) {
      return _buildEmptyState('No pending requests', 'New booking requests will appear here', isDark);
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: isDark ? const Color(0xFF8B9DC3) : const Color(0xFF6B7FA8),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        itemCount: _pendingBookings.length,
        itemBuilder: (context, index) => _buildPendingBookingCard(_pendingBookings[index], isDark),
      ),
    );
  }

  Widget _buildConfirmedBookings(bool isDark) {
    if (_confirmedBookings.isEmpty) {
      return _buildEmptyState('No confirmed sessions', 'Confirmed sessions will appear here', isDark);
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: isDark ? const Color(0xFF8B9DC3) : const Color(0xFF6B7FA8),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        itemCount: _confirmedBookings.length,
        itemBuilder: (context, index) => _buildConfirmedBookingCard(_confirmedBookings[index], isDark),
      ),
    );
  }

  Widget _buildCompletedBookings(bool isDark) {
    if (_completedBookings.isEmpty) {
      return _buildEmptyState('No completed sessions', 'Completed sessions will appear here', isDark);
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: isDark ? const Color(0xFF8B9DC3) : const Color(0xFF6B7FA8),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        itemCount: _completedBookings.length,
        itemBuilder: (context, index) => _buildCompletedBookingCard(_completedBookings[index], isDark),
      ),
    );
  }

  Widget _buildCancelledBookings(bool isDark) {
    if (_cancelledBookings.isEmpty) {
      return _buildEmptyState('No cancelled sessions', 'Cancelled sessions will appear here', isDark);
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: isDark ? const Color(0xFF8B9DC3) : const Color(0xFF6B7FA8),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        itemCount: _cancelledBookings.length,
        itemBuilder: (context, index) => _buildCancelledBookingCard(_cancelledBookings[index], isDark),
      ),
    );
  }

  Widget _buildPendingBookingCard(Map<String, dynamic> booking, bool isDark) {
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
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    booking['studentName'].toString().split(' ').map((n) => n[0]).join(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['studentName'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Requested ${booking['requestedAt']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSM,
                    vertical: AppTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingMD),
            
            // Session Details
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.book, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: AppTheme.spacingXS),
                      Text(booking['subject']),
                      const Spacer(),
                      Text(
                        '\$${booking['price']}/hr',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: AppTheme.spacingXS),
                      Text('${booking['date']} • ${booking['time']}'),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  Row(
                    children: [
                      Icon(
                        booking['mode'] == 'Online' ? Icons.video_call : Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: AppTheme.spacingXS),
                      Text(booking['mode']),
                    ],
                  ),
                ],
              ),
            ),
            
            // Student Message
            if (booking['studentMessage'] != null) ...[
              const SizedBox(height: AppTheme.spacingMD),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Message:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      booking['studentMessage'],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: AppTheme.spacingLG),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectBooking(booking),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Decline', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptBooking(booking),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmedBookingCard(Map<String, dynamic> booking, bool isDark) {
    final isToday = booking['date'] == '2026-01-31'; // Mock check
    
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
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    booking['studentName'].toString().split(' ').map((n) => n[0]).join(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['studentName'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        booking['subject'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSM,
                    vertical: AppTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: const Text(
                    'Confirmed',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingMD),
            
            // Session Info
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: AppTheme.spacingXS),
                Text('${booking['date']} • ${booking['time']}'),
                if (isToday) ...[
                  const SizedBox(width: AppTheme.spacingSM),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingXS,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                    ),
                    child: const Text(
                      'TODAY',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingSM),
            
            Row(
              children: [
                Icon(
                  booking['mode'] == 'Online' ? Icons.video_call : Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: AppTheme.spacingXS),
                Expanded(
                  child: Text(
                    booking['mode'] == 'Online' 
                        ? 'Online Session'
                        : booking['location'] ?? 'In-Person',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '\$${booking['price']}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingLG),
            
            // Session Action Button (Start Session)
            SessionActionButton(
              booking: booking,
              onStartSession: () => _startSession(booking),
            ),
            
            const SizedBox(height: AppTheme.spacingSM),
            
            // Other Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactStudent(booking),
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Message', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rescheduleSession(booking),
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('Reschedule', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingSM),
            
            // View reschedule requests button
            OutlinedButton.icon(
              onPressed: () => _viewRescheduleRequests(booking),
              icon: const Icon(Icons.history, size: 16),
              label: const Text('View Reschedule Requests', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedBookingCard(Map<String, dynamic> booking, bool isDark) {
    // Safely extract rating value
    final ratingValue = booking['rating'];
    final int? rating = ratingValue is int 
        ? ratingValue 
        : (ratingValue is double ? ratingValue.toInt() : null);
    
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
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    booking['studentName'].toString().split(' ').map((n) => n[0]).join(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['studentName'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${booking['subject']} • ${booking['date']}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${booking['earnings']}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Earned',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Rating and Review
            if (rating != null) ...[
              const SizedBox(height: AppTheme.spacingMD),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: Colors.amber.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(5, (index) => Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        )),
                        const SizedBox(width: AppTheme.spacingSM),
                        Text(
                          '$rating/5',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (booking['review'] != null) ...[
                      const SizedBox(height: AppTheme.spacingSM),
                      Text(
                        booking['review'],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: AppTheme.spacingMD),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewSessionDetails(booking),
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Details', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactStudent(booking),
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Message', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledBookingCard(Map<String, dynamic> booking, bool isDark) {
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
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  child: Text(
                    booking['studentName'].toString().split(' ').map((n) => n[0]).join(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['studentName'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${booking['subject']} • ${booking['date']}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSM,
                    vertical: AppTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: const Text(
                    'Cancelled',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingMD),
            
            // Cancellation Info
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cancelled by: ${booking['cancelledBy']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (booking['reason'] != null) ...[
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      'Reason: ${booking['reason']}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    'Cancelled ${booking['cancelledAt']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : const Color(0xFFB0BEC5),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLG),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? Colors.white.withOpacity(0.6)
                  : const Color(0xFF6B7FA8),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? Colors.white.withOpacity(0.4)
                  : const Color(0xFF90A4AE),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _acceptBooking(Map<String, dynamic> booking) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Booking'),
        content: Text('Accept the booking request from ${booking['studentName'] ?? booking['student']?['firstName']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final response = await _bookingService.respondToBooking(
                  bookingId: booking['_id'] ?? booking['id'],
                  status: 'accepted',
                );

                if (response.success) {
                  // Send real-time notification
                  _socketService.respondToBooking(
                    studentId: booking['student']?['_id'] ?? booking['studentId'],
                    bookingId: booking['_id'] ?? booking['id'],
                    status: 'accepted',
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking accepted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  _loadBookings(); // Refresh the list
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response.error ?? 'Failed to accept booking')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _rejectBooking(Map<String, dynamic> booking) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Decline the booking request from ${booking['studentName'] ?? booking['student']?['firstName']}?'),
            const SizedBox(height: AppTheme.spacingMD),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Let the student know why...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final response = await _bookingService.respondToBooking(
                  bookingId: booking['_id'] ?? booking['id'],
                  status: 'declined',
                  message: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                );

                if (response.success) {
                  // Send real-time notification
                  _socketService.respondToBooking(
                    studentId: booking['student']?['_id'] ?? booking['studentId'],
                    bookingId: booking['_id'] ?? booking['id'],
                    status: 'declined',
                    message: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking declined')),
                  );
                  
                  _loadBookings(); // Refresh the list
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response.error ?? 'Failed to decline booking')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  // _startSession method already defined at line 110-155

  void _contactStudent(Map<String, dynamic> booking) {
    // TODO: Navigate to chat with student
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening chat with ${booking['studentName'] ?? booking['student']?['firstName']}')),
    );
  }

  void _rescheduleSession(Map<String, dynamic> booking) async {
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

  void _viewSessionDetails(Map<String, dynamic> booking) {
    // TODO: Navigate to session details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing details for session with ${booking['studentName'] ?? booking['student']?['firstName']}')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _socketService.off('new_booking_request');
    _socketService.off('booking_response');
    super.dispose();
  }
}