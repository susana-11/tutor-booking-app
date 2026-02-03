import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/socket_service.dart';
import '../models/availability_model.dart';
import '../services/availability_service.dart';
import '../../auth/providers/auth_provider.dart';

class TutorScheduleScreen extends StatefulWidget {
  const TutorScheduleScreen({super.key});

  @override
  State<TutorScheduleScreen> createState() => _TutorScheduleScreenState();
}

class _TutorScheduleScreenState extends State<TutorScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  
  final AvailabilityService _availabilityService = AvailabilityService();
  final SocketService _socketService = SocketService();
  
  WeeklySchedule? _weeklySchedule;
  List<AvailabilitySlot> _upcomingSessions = [];
  List<BookingRequest> _pendingRequests = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadScheduleData();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen for new booking requests
    _socketService.on('new_booking_request', (data) {
      print('📅 New booking request received: $data');
      _loadBookingRequests();
      _showBookingRequestNotification(data);
    });

    // Listen for booking responses
    _socketService.on('booking_response', (data) {
      print('📅 Booking response: $data');
      _loadScheduleData();
    });

    // Listen for session updates
    _socketService.on('session_update', (data) {
      print('📅 Session update: $data');
      _loadScheduleData();
    });
  }

  Future<void> _loadScheduleData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get start of current week
      final weekStart = _getWeekStart(_selectedDate);
      
      // Load weekly schedule
      final scheduleResponse = await _availabilityService.getWeeklySchedule(
        weekStart: weekStart,
      );
      
      if (scheduleResponse.success && scheduleResponse.data != null) {
        setState(() {
          _weeklySchedule = scheduleResponse.data!;
        });
      }

      // Load upcoming sessions
      final sessionsResponse = await _availabilityService.getUpcomingSessions();
      if (sessionsResponse.success && sessionsResponse.data != null) {
        setState(() {
          _upcomingSessions = sessionsResponse.data!;
        });
      }

      // Load pending booking requests
      await _loadBookingRequests();

    } catch (e) {
      print('❌ Error loading schedule data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load schedule: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBookingRequests() async {
    try {
      final requestsResponse = await _availabilityService.getBookingRequests();
      if (requestsResponse.success && requestsResponse.data != null) {
        setState(() {
          _pendingRequests = requestsResponse.data!.where((r) => r.isPending).toList();
        });
      }
    } catch (e) {
      print('❌ Error loading booking requests: $e');
    }
  }

  void _showBookingRequestNotification(dynamic data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New booking request from ${data['studentName']}'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _tabController.animateTo(2), // Go to requests tab
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_pendingRequests.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  onPressed: () => _tabController.animateTo(2),
                  icon: const Icon(Icons.notifications),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_pendingRequests.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            onPressed: _refreshSchedule,
            icon: _isRefreshing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(text: 'Weekly View'),
            const Tab(text: 'Sessions'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Requests'),
                  if (_pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingRequests.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWeeklyView(),
                _buildSessionsView(),
                _buildRequestsView(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAvailability,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWeeklyView() {
    return RefreshIndicator(
      onRefresh: _refreshSchedule,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Week Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                    });
                    _loadScheduleData();
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  _getWeekRange(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 7));
                    });
                    _loadScheduleData();
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingLG),
            
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Available', Colors.green),
                _buildLegendItem('Booked', Colors.blue),
                _buildLegendItem('Unavailable', Colors.grey),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingLG),
            
            // Weekly Schedule
            if (_weeklySchedule != null)
              ..._weeklySchedule!.schedule.entries.map((entry) => _buildDaySchedule(entry.key, entry.value))
            else
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        children: [
          // Calendar Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
            child: Column(
              children: [
                Text(
                  'Calendar View',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                Text(
                  'Tap on a date to view or edit availability',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Calendar Grid (Simplified)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 35, // 5 weeks
            itemBuilder: (context, index) {
              final day = index + 1;
              final hasBookings = day % 3 == 0; // Mock data
              final isToday = day == DateTime.now().day;
              
              return GestureDetector(
                onTap: () => _showDayDetails(day),
                child: Container(
                  decoration: BoxDecoration(
                    color: isToday 
                        ? AppTheme.primaryColor 
                        : hasBookings 
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    border: hasBookings 
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.toString(),
                        style: TextStyle(
                          color: isToday ? Colors.white : Colors.black87,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (hasBookings)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isToday ? Colors.white : Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTheme.spacingXS),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDaySchedule(String day, List<AvailabilitySlot> slots) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            if (slots.isEmpty)
              Text(
                'No availability set',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              )
            else
              ...slots.map((slot) => _buildTimeSlotWidget(slot)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotWidget(AvailabilitySlot slot) {
    Color backgroundColor;
    Color textColor;
    String status;
    
    if (slot.isBooked) {
      backgroundColor = Colors.blue.withOpacity(0.1);
      textColor = Colors.blue;
      status = 'Booked';
    } else if (slot.isAvailable) {
      backgroundColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green;
      status = 'Available';
    } else {
      backgroundColor = Colors.grey.withOpacity(0.1);
      textColor = Colors.grey;
      status = 'Unavailable';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.timeSlot.displayTime,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (slot.isBooked && slot.booking != null) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    '${slot.booking!.studentName} • ${slot.booking!.subject}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSM,
              vertical: AppTheme.spacingXS,
            ),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSM),
          PopupMenuButton(
            itemBuilder: (context) => [
              if (slot.isAvailable && !slot.isBooked)
                const PopupMenuItem(
                  value: 'make_unavailable',
                  child: Text('Make Unavailable'),
                ),
              if (!slot.isAvailable)
                const PopupMenuItem(
                  value: 'make_available',
                  child: Text('Make Available'),
                ),
              if (slot.isBooked) ...[
                const PopupMenuItem(
                  value: 'view_booking',
                  child: Text('View Booking'),
                ),
                const PopupMenuItem(
                  value: 'contact_student',
                  child: Text('Contact Student'),
                ),
              ],
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit Time Slot'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
            onSelected: (value) => _handleSlotAction(value, slot),
          ),
        ],
      ),
    );
  }

  String _getWeekRange(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return '${_formatDate(startOfWeek)} - ${_formatDate(endOfWeek)}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  void _addAvailability() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLG)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => AddAvailabilitySheet(
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showDayDetails(int day) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Day $day Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('View and manage availability for this day'),
            const SizedBox(height: AppTheme.spacingMD),
            // Add day-specific content here
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addAvailability();
            },
            child: const Text('Add Availability'),
          ),
        ],
      ),
    );
  }

  void _handleSlotAction(String action, AvailabilitySlot slot) {
    switch (action) {
      case 'make_unavailable':
        // TODO: Update slot availability
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot marked as unavailable')),
        );
        break;
      case 'make_available':
        // TODO: Update slot availability
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot marked as available')),
        );
        break;
      case 'view_booking':
        // TODO: Navigate to booking details
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viewing booking details')),
        );
        break;
      case 'contact_student':
        // TODO: Navigate to chat with student
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening chat with student')),
        );
        break;
      case 'edit':
        _editTimeSlot(slot);
        break;
      case 'delete':
        _deleteTimeSlot(slot);
        break;
    }
  }

  void _editTimeSlot(AvailabilitySlot slot) {
    // TODO: Show edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit time slot functionality coming soon')),
    );
  }

  void _deleteTimeSlot(AvailabilitySlot slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Slot'),
        content: Text('Are you sure you want to delete the ${slot.timeSlot.displayTime} slot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Delete slot
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Time slot deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsView() {
    return RefreshIndicator(
      onRefresh: _refreshSchedule,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sessions Overview
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor.withOpacity(0.1), AppTheme.primaryColor.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMD),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Icon(
                      Icons.schedule,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingLG),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upcoming Sessions',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          '${_upcomingSessions.length} sessions scheduled',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingXL),
            
            // Sessions List
            if (_upcomingSessions.isEmpty)
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingXL),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      ),
                      child: Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLG),
                    Text(
                      'No upcoming sessions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSM),
                    Text(
                      'Sessions will appear here once students book your available slots',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._upcomingSessions.map((session) => _buildSessionCard(session)),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsView() {
    return RefreshIndicator(
      onRefresh: _refreshSchedule,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Requests Overview
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMD),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: Colors.orange,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingLG),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Requests',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          '${_pendingRequests.length} pending requests',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingXL),
            
            // Requests List
            if (_pendingRequests.isEmpty)
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingXL),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      ),
                      child: Icon(
                        Icons.inbox,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLG),
                    Text(
                      'No pending requests',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSM),
                    Text(
                      'New booking requests from students will appear here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._pendingRequests.map((request) => _buildRequestCard(request)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(AvailabilitySlot session) {
    final booking = session.booking!;
    final isToday = session.isToday;
    final isPast = session.isPast;
    
    Color statusColor;
    IconData statusIcon;
    
    switch (booking.status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      elevation: isToday ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: isToday 
            ? BorderSide(color: AppTheme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSM),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.studentName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        booking.subject,
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
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
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: AppTheme.spacingXS),
                        Text(
                          _formatSessionDate(session.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: AppTheme.spacingXS),
                        Text(
                          session.timeSlot.displayTime,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                      Text(
                        '\$${booking.amount.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingMD),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Notes:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      booking.notes!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: AppTheme.spacingMD),
            
            // Action Buttons
            Row(
              children: [
                if (booking.status == 'pending') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _declineSession(session),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptSession(session),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else if (booking.status == 'confirmed' && !isPast) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelSession(session),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  if (booking.meetingLink != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _joinSession(booking.meetingLink!),
                        icon: const Icon(Icons.video_call, size: 16),
                        label: const Text('Join'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markCompleted(session),
                        icon: const Icon(Icons.done, size: 16),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ] else if (booking.status == 'confirmed' && isPast) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markCompleted(session),
                      icon: const Icon(Icons.done, size: 16),
                      label: const Text('Mark Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: AppTheme.spacingSM),
                IconButton(
                  onPressed: () => _contactStudent(booking),
                  icon: const Icon(Icons.message),
                  tooltip: 'Message Student',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(BookingRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: BorderSide(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSM),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.studentName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        request.studentEmail,
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
                  child: Text(
                    'NEW REQUEST',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingMD),
            
            // Request Details
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
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.subject, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: AppTheme.spacingXS),
                            Text(
                              request.subject,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                          Text(
                            '\$${request.amount.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: AppTheme.spacingXS),
                            Text(
                              _formatSessionDate(request.sessionDate),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: AppTheme.spacingXS),
                          Text(
                            request.timeSlot.displayTime,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingMD),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message from Student:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      request.message!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
                    onPressed: () => _declineRequest(request),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red[300]!),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptRequest(request),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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

  String _formatSessionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);
    
    if (sessionDate == today) {
      return 'Today';
    } else if (sessionDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (sessionDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  Future<void> _refreshSchedule() async {
    setState(() => _isRefreshing = true);
    await _loadScheduleData();
    setState(() => _isRefreshing = false);
  }

  // Session Management Methods
  Future<void> _acceptSession(AvailabilitySlot session) async {
    try {
      final response = await _availabilityService.respondToBookingRequest(
        requestId: session.booking!.id,
        response: 'accept',
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session accepted successfully!')),
        );
        _loadScheduleData();
        
        // Emit socket event
        _socketService.emit('booking_response', {
          'requestId': session.booking!.id,
          'response': 'accepted',
          'tutorId': session.tutorId,
          'studentId': session.booking!.studentId,
        });
      } else {
        throw Exception(response.error);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept session: $e')),
      );
    }
  }

  Future<void> _declineSession(AvailabilitySlot session) async {
    final reason = await _showDeclineDialog();
    if (reason == null) return;

    try {
      final response = await _availabilityService.respondToBookingRequest(
        requestId: session.booking!.id,
        response: 'decline',
        message: reason,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session declined')),
        );
        _loadScheduleData();
        
        // Emit socket event
        _socketService.emit('booking_response', {
          'requestId': session.booking!.id,
          'response': 'declined',
          'reason': reason,
          'tutorId': session.tutorId,
          'studentId': session.booking!.studentId,
        });
      } else {
        throw Exception(response.error);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline session: $e')),
      );
    }
  }

  Future<void> _acceptRequest(BookingRequest request) async {
    try {
      final response = await _availabilityService.respondToBookingRequest(
        requestId: request.id,
        response: 'accept',
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request accepted!')),
        );
        _loadScheduleData();
        
        // Emit socket event
        _socketService.emit('booking_response', {
          'requestId': request.id,
          'response': 'accepted',
          'tutorId': context.read<AuthProvider>().user?.id,
          'studentId': request.studentId,
        });
      } else {
        throw Exception(response.error);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept request: $e')),
      );
    }
  }

  Future<void> _declineRequest(BookingRequest request) async {
    final reason = await _showDeclineDialog();
    if (reason == null) return;

    try {
      final response = await _availabilityService.respondToBookingRequest(
        requestId: request.id,
        response: 'decline',
        message: reason,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request declined')),
        );
        _loadScheduleData();
        
        // Emit socket event
        _socketService.emit('booking_response', {
          'requestId': request.id,
          'response': 'declined',
          'reason': reason,
          'tutorId': context.read<AuthProvider>().user?.id,
          'studentId': request.studentId,
        });
      } else {
        throw Exception(response.error);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline request: $e')),
      );
    }
  }

  Future<void> _cancelSession(AvailabilitySlot session) async {
    final reason = await _showCancelDialog();
    if (reason == null) return;

    try {
      final response = await _availabilityService.cancelSession(
        slotId: session.id,
        reason: reason,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session cancelled successfully')),
        );
        _loadScheduleData();
        
        // Emit socket event
        _socketService.emit('session_cancelled', {
          'slotId': session.id,
          'reason': reason,
          'tutorId': session.tutorId,
          'studentId': session.booking!.studentId,
        });
      } else {
        throw Exception(response.error);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel session: $e')),
      );
    }
  }

  Future<void> _markCompleted(AvailabilitySlot session) async {
    final notes = await _showCompletionDialog();
    
    try {
      final response = await _availabilityService.markSessionCompleted(
        slotId: session.id,
        notes: notes,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session marked as completed!')),
        );
        _loadScheduleData();
        
        // Emit socket event
        _socketService.emit('session_completed', {
          'slotId': session.id,
          'notes': notes,
          'tutorId': session.tutorId,
          'studentId': session.booking!.studentId,
        });
      } else {
        throw Exception(response.error);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark session as completed: $e')),
      );
    }
  }

  void _joinSession(String meetingLink) {
    // TODO: Implement meeting link opening
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening meeting: $meetingLink')),
    );
  }

  void _contactStudent(BookingInfo booking) {
    // Navigate to chat with student
    context.push('/tutor/messages', extra: {
      'studentId': booking.studentId,
      'studentName': booking.studentName,
    });
  }

  Future<String?> _showDeclineDialog() async {
    String? reason;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for declining this booking:'),
            const SizedBox(height: AppTheme.spacingMD),
            TextField(
              onChanged: (value) => reason = value,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reason),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Decline', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showCancelDialog() async {
    String? reason;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancelling this session:'),
            const SizedBox(height: AppTheme.spacingMD),
            TextField(
              onChanged: (value) => reason = value,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Session'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reason),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Session', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showCompletionDialog() async {
    String? notes;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add any notes about this session (optional):'),
            const SizedBox(height: AppTheme.spacingMD),
            TextField(
              onChanged: (value) => notes = value,
              decoration: const InputDecoration(
                hintText: 'Session notes...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, notes),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class AddAvailabilitySheet extends StatefulWidget {
  final ScrollController scrollController;

  const AddAvailabilitySheet({super.key, required this.scrollController});

  @override
  State<AddAvailabilitySheet> createState() => _AddAvailabilitySheetState();
}

class _AddAvailabilitySheetState extends State<AddAvailabilitySheet> {
  String _selectedDay = 'Monday';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _recurring = false;
  
  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: ListView(
        controller: widget.scrollController,
        children: [
          Text(
            'Add Availability',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          // Day Selection
          DropdownButtonFormField<String>(
            value: _selectedDay,
            decoration: const InputDecoration(
              labelText: 'Day',
              border: OutlineInputBorder(),
            ),
            items: _days.map((day) => DropdownMenuItem(
              value: day,
              child: Text(day),
            )).toList(),
            onChanged: (value) => setState(() => _selectedDay = value!),
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          // Time Selection
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (time != null) {
                      setState(() => _startTime = time);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_startTime.format(context)),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (time != null) {
                      setState(() => _endTime = time);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_endTime.format(context)),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          // Duration Display
          Builder(
            builder: (context) {
              final startMinutes = _startTime.hour * 60 + _startTime.minute;
              final endMinutes = _endTime.hour * 60 + _endTime.minute;
              final durationMinutes = endMinutes - startMinutes;
              final isValid = durationMinutes >= 15;
              
              return Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: isValid ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(
                    color: isValid ? Colors.green.shade300 : Colors.red.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isValid ? Icons.check_circle : Icons.warning,
                      color: isValid ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    const SizedBox(width: AppTheme.spacingSM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duration: $durationMinutes minutes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isValid ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                          if (!isValid)
                            Text(
                              'Minimum 15 minutes required',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          // Recurring Option
          SwitchListTile(
            title: const Text('Recurring Weekly'),
            subtitle: const Text('Repeat this availability every week'),
            value: _recurring,
            onChanged: (value) => setState(() => _recurring = value),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveAvailability,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveAvailability() async {
    try {
      // Validate that end time is after start time
      final startMinutes = _startTime.hour * 60 + _startTime.minute;
      final endMinutes = _endTime.hour * 60 + _endTime.minute;
      final durationMinutes = endMinutes - startMinutes;
      
      if (durationMinutes <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Validate minimum duration of 15 minutes
      if (durationMinutes < 15) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Time slot must be at least 15 minutes long. Current duration: $durationMinutes minutes.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
      
      // Convert TimeOfDay to string format
      final startTimeStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
      final endTimeStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';
      
      // Calculate the date for the selected day
      final now = DateTime.now();
      final currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday
      final selectedWeekday = _days.indexOf(_selectedDay) + 1; // Convert to 1-based
      final daysToAdd = selectedWeekday - currentWeekday;
      final targetDate = now.add(Duration(days: daysToAdd));
      
      final availabilityService = AvailabilityService();
      
      if (_recurring) {
        // Create multiple slots for recurring availability
        final dates = <DateTime>[];
        for (int i = 0; i < 12; i++) { // Create for next 12 weeks
          dates.add(targetDate.add(Duration(days: i * 7)));
        }
        
        final response = await availabilityService.createBulkAvailability(
          dates: dates,
          startTime: startTimeStr,
          endTime: endTimeStr,
          isRecurring: true,
          recurringPattern: 'weekly',
        );
        
        if (response.success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Created ${response.data!.length} recurring availability slots!')),
          );
        } else {
          throw Exception(response.error);
        }
      } else {
        // Create single slot
        final response = await availabilityService.createAvailabilitySlot(
          date: targetDate,
          startTime: startTimeStr,
          endTime: endTimeStr,
          isRecurring: false,
        );
        
        if (response.success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Availability added successfully!')),
          );
        } else {
          throw Exception(response.error);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save availability: $e')),
      );
    }
  }
}

class EditAvailabilitySheet extends StatefulWidget {
  final ScrollController scrollController;
  final AvailabilitySlot slot;
  final VoidCallback onSaved;

  const EditAvailabilitySheet({
    super.key,
    required this.scrollController,
    required this.slot,
    required this.onSaved,
  });

  @override
  State<EditAvailabilitySheet> createState() => _EditAvailabilitySheetState();
}

class _EditAvailabilitySheetState extends State<EditAvailabilitySheet> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isAvailable;
  late bool _isRecurring;
  
  final AvailabilityService _availabilityService = AvailabilityService();

  @override
  void initState() {
    super.initState();
    
    // Parse existing time
    final startParts = widget.slot.timeSlot.startTime.split(':');
    final endParts = widget.slot.timeSlot.endTime.split(':');
    
    _startTime = TimeOfDay(
      hour: int.parse(startParts[0]),
      minute: int.parse(startParts[1]),
    );
    _endTime = TimeOfDay(
      hour: int.parse(endParts[0]),
      minute: int.parse(endParts[1]),
    );
    
    _isAvailable = widget.slot.isAvailable;
    _isRecurring = widget.slot.isRecurring;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: ListView(
        controller: widget.scrollController,
        children: [
          Text(
            'Edit Availability',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          // Time Selection
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (time != null) {
                      setState(() => _startTime = time);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_startTime.format(context)),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (time != null) {
                      setState(() => _endTime = time);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_endTime.format(context)),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          // Duration Display
          Builder(
            builder: (context) {
              final startMinutes = _startTime.hour * 60 + _startTime.minute;
              final endMinutes = _endTime.hour * 60 + _endTime.minute;
              final durationMinutes = endMinutes - startMinutes;
              final isValid = durationMinutes >= 15;
              
              return Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: isValid ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(
                    color: isValid ? Colors.green.shade300 : Colors.red.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isValid ? Icons.check_circle : Icons.warning,
                      color: isValid ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    const SizedBox(width: AppTheme.spacingSM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duration: $durationMinutes minutes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isValid ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                          if (!isValid)
                            Text(
                              'Minimum 15 minutes required',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          // Availability Toggle
          SwitchListTile(
            title: const Text('Available for Booking'),
            subtitle: const Text('Students can book this time slot'),
            value: _isAvailable,
            onChanged: (value) => setState(() => _isAvailable = value),
          ),
          
          // Recurring Option
          SwitchListTile(
            title: const Text('Recurring Weekly'),
            subtitle: const Text('Repeat this availability every week'),
            value: _isRecurring,
            onChanged: (value) => setState(() => _isRecurring = value),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    try {
      // Validate duration
      final startMinutes = _startTime.hour * 60 + _startTime.minute;
      final endMinutes = _endTime.hour * 60 + _endTime.minute;
      final durationMinutes = endMinutes - startMinutes;
      
      if (durationMinutes <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (durationMinutes < 15) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Time slot must be at least 15 minutes long. Current duration: $durationMinutes minutes.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
      
      final startTimeStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
      final endTimeStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';
      
      final response = await _availabilityService.updateAvailabilitySlot(
        slotId: widget.slot.id,
        startTime: startTimeStr,
        endTime: endTimeStr,
        isAvailable: _isAvailable,
        isRecurring: _isRecurring,
      );

      if (response.success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability updated successfully!')),
        );
        widget.onSaved();
      } else {
        throw Exception(response.error);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update availability: $e')),
      );
    }
  }
}