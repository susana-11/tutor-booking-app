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
                      _buildWeeklyView(isDark),
                      _buildSessionsView(isDark),
                      _buildRequestsView(isDark),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAvailability,
        backgroundColor: isDark ? const Color(0xFF8B9DC3) : const Color(0xFF6B7FA8),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Slot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
          'My Schedule',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        if (_pendingRequests.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _tabController.animateTo(2),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Stack(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: isDark ? Colors.white70 : const Color(0xFF5F6F94),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
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
                            '${_pendingRequests.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
              onTap: _refreshSchedule,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _isRefreshing 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.white70 : const Color(0xFF5F6F94),
                          ),
                        ),
                      )
                    : Icon(
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
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            tabs: [
              const Tab(text: 'Weekly'),
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
                          '${_pendingRequests.length}',
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

  Widget _buildWeeklyView(bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshSchedule,
      color: isDark ? const Color(0xFF8B9DC3) : const Color(0xFF6B7FA8),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Week Navigation Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFE0E0E0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : const Color(0xFF6B7FA8).withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : const Color(0xFF6B7FA8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                        });
                        _loadScheduleData();
                      },
                      icon: Icon(
                        Icons.chevron_left,
                        color: isDark ? Colors.white70 : const Color(0xFF6B7FA8),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _getWeekRange(_selectedDate),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Week ${_getWeekNumber(_selectedDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : const Color(0xFF6B7FA8),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : const Color(0xFF6B7FA8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 7));
                        });
                        _loadScheduleData();
                      },
                      icon: Icon(
                        Icons.chevron_right,
                        color: isDark ? Colors.white70 : const Color(0xFF6B7FA8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingLG),
            
            // Legend
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.03)
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem('Available', const Color(0xFF7FA87F), isDark),
                  _buildLegendItem('Booked', const Color(0xFF6B7FA8), isDark),
                  _buildLegendItem('Unavailable', const Color(0xFF90A4AE), isDark),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingLG),
            
            // Weekly Schedule
            if (_weeklySchedule != null)
              ..._weeklySchedule!.schedule.entries.map((entry) => _buildDaySchedule(entry.key, entry.value, isDark))
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? const Color(0xFF8B9DC3) : const Color(0xFF6B7FA8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil() + 1;
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

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppTheme.spacingXS),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF6B7FA8),
          ),
        ),
      ],
    );
  }

  Widget _buildDaySchedule(String day, List<AvailabilitySlot> slots, bool isDark) {
    final isToday = day == _getDayName(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? (isDark ? const Color(0xFF8B9DC3) : const Color(0xFF6B7FA8))
              : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE0E0E0)),
          width: isToday ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : const Color(0xFF6B7FA8).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isToday
                          ? [const Color(0xFF6B7FA8), const Color(0xFF8B9DC3)]
                          : isDark
                              ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.05)]
                              : [const Color(0xFFF5F7FA), const Color(0xFFECEFF4)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isToday
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF2C3E50)),
                    ),
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7FA87F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7FA87F),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${slots.length} slot${slots.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withOpacity(0.6)
                        : const Color(0xFF6B7FA8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            if (slots.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 20,
                      color: isDark
                          ? Colors.white.withOpacity(0.4)
                          : const Color(0xFF90A4AE),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'No availability set for this day',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : const Color(0xFF90A4AE),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...slots.map((slot) => _buildTimeSlotWidget(slot, isDark)),
          ],
        ),
      ),
    );
  }

  String _getDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  Widget _buildTimeSlotWidget(AvailabilitySlot slot, bool isDark) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String status;
    IconData statusIcon;
    
    if (slot.isBooked) {
      backgroundColor = const Color(0xFF6B7FA8).withOpacity(0.1);
      borderColor = const Color(0xFF6B7FA8);
      textColor = const Color(0xFF6B7FA8);
      status = 'Booked';
      statusIcon = Icons.event_available;
    } else if (slot.isAvailable) {
      backgroundColor = const Color(0xFF7FA87F).withOpacity(0.1);
      borderColor = const Color(0xFF7FA87F);
      textColor = const Color(0xFF7FA87F);
      status = 'Available';
      statusIcon = Icons.check_circle_outline;
    } else {
      backgroundColor = const Color(0xFF90A4AE).withOpacity(0.1);
      borderColor = const Color(0xFF90A4AE);
      textColor = const Color(0xFF90A4AE);
      status = 'Unavailable';
      statusIcon = Icons.block;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              statusIcon,
              color: textColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.timeSlot.displayTime,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF2C3E50),
                  ),
                ),
                if (slot.isBooked && slot.booking != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${slot.booking!.studentName} • ${slot.booking!.subject}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white.withOpacity(0.6)
                          : const Color(0xFF6B7FA8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.white70 : const Color(0xFF6B7FA8),
              size: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              if (slot.isAvailable && !slot.isBooked)
                const PopupMenuItem(
                  value: 'make_unavailable',
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 18),
                      SizedBox(width: 8),
                      Text('Make Unavailable'),
                    ],
                  ),
                ),
              if (!slot.isAvailable)
                const PopupMenuItem(
                  value: 'make_available',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18),
                      SizedBox(width: 8),
                      Text('Make Available'),
                    ],
                  ),
                ),
              if (slot.isBooked) ...[
                const PopupMenuItem(
                  value: 'view_booking',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: 8),
                      Text('View Booking'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'contact_student',
                  child: Row(
                    children: [
                      Icon(Icons.message, size: 18),
                      SizedBox(width: 8),
                      Text('Contact Student'),
                    ],
                  ),
                ),
              ],
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Time Slot'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
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

  void _handleSlotAction(String action, AvailabilitySlot slot) async {
    switch (action) {
      case 'make_unavailable':
        await _makeSlotUnavailable(slot);
        break;
      case 'make_available':
        await _makeSlotAvailable(slot);
        break;
      case 'view_booking':
        _viewBookingDetails(slot);
        break;
      case 'contact_student':
        _contactStudent(slot.booking!);
        break;
      case 'edit':
        await _editTimeSlot(slot);
        break;
      case 'delete':
        await _deleteTimeSlot(slot);
        break;
    }
  }

  Future<void> _makeSlotUnavailable(AvailabilitySlot slot) async {
    try {
      // First attempt without cancelling booking
      final response = await _availabilityService.toggleSlotAvailability(
        slotId: slot.id,
        makeAvailable: false,
        cancelBooking: false,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Slot marked as unavailable')),
        );
        _loadScheduleData();
      } else {
        // Check if it's a pending booking that needs confirmation
        if (response.error?.contains('pending booking') == true) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Pending Booking Exists'),
              content: const Text(
                'This slot has a pending booking request. Do you want to cancel the booking and make the slot unavailable?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Keep Booking'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Cancel Booking', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            // Try again with cancelBooking = true
            final retryResponse = await _availabilityService.toggleSlotAvailability(
              slotId: slot.id,
              makeAvailable: false,
              cancelBooking: true,
            );

            if (retryResponse.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Booking cancelled and slot marked unavailable'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadScheduleData();
            } else {
              throw Exception(retryResponse.error);
            }
          }
        } else if (response.error?.contains('confirmed booking') == true) {
          // Show error for confirmed booking
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cannot Make Unavailable'),
              content: const Text(
                'This slot has a confirmed booking. You cannot make it unavailable.\n\n'
                'To proceed, you must first cancel the booking using the proper cancellation process.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _cancelSession(slot);
                  },
                  child: const Text('Cancel Booking'),
                ),
              ],
            ),
          );
        } else {
          throw Exception(response.error);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to make unavailable: $e')),
      );
    }
  }

  Future<void> _makeSlotAvailable(AvailabilitySlot slot) async {
    try {
      final response = await _availabilityService.toggleSlotAvailability(
        slotId: slot.id,
        makeAvailable: true,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Slot marked as available')),
        );
        _loadScheduleData();
      } else {
        throw Exception(response.error);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to make available: $e')),
      );
    }
  }

  void _viewBookingDetails(AvailabilitySlot slot) {
    // Navigate to booking details
    context.push('/tutor/bookings');
  }

  Future<void> _editTimeSlot(AvailabilitySlot slot) async {
    // Check if slot is booked
    if (slot.isBooked && slot.booking!.status == 'confirmed') {
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Edit Time Slot'),
          content: const Text(
            'This slot has a confirmed booking. You cannot directly edit the time.\n\n'
            'To change the time, use the reschedule request system which requires student approval.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navigate to reschedule request
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Use reschedule request from bookings screen')),
                );
              },
              child: const Text('Go to Bookings'),
            ),
          ],
        ),
      );
      return;
    }

    // Show edit dialog
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
        builder: (context, scrollController) => EditAvailabilitySheet(
          scrollController: scrollController,
          slot: slot,
          onSaved: _loadScheduleData,
        ),
      ),
    );
  }

  Future<void> _deleteTimeSlot(AvailabilitySlot slot) async {
    try {
      // First attempt without cancelling booking
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Time Slot'),
          content: Text(
            'Are you sure you want to delete the ${slot.timeSlot.displayTime} slot?\n\n'
            'This action cannot be undone.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final response = await _availabilityService.deleteAvailabilitySlot(
        slot.id,
        cancelBooking: false,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Time slot deleted')),
        );
        _loadScheduleData();
      } else {
        // Check if it's a pending booking that needs confirmation
        if (response.error?.contains('pending booking') == true) {
          final cancelConfirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Pending Booking Exists'),
              content: const Text(
                'This slot has a pending booking request. Do you want to decline the booking and delete the slot?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Keep Slot'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Decline & Delete', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );

          if (cancelConfirmed == true) {
            // Try again with cancelBooking = true
            final retryResponse = await _availabilityService.deleteAvailabilitySlot(
              slot.id,
              cancelBooking: true,
            );

            if (retryResponse.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Booking declined and slot deleted'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadScheduleData();
            } else {
              throw Exception(retryResponse.error);
            }
          }
        } else if (response.error?.contains('confirmed booking') == true) {
          // Show error for confirmed booking
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cannot Delete Slot'),
              content: const Text(
                'This slot has a confirmed booking. You cannot delete it.\n\n'
                'To proceed, you must first cancel the booking using the proper cancellation process, which may include refund policies based on timing.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _cancelSession(slot);
                  },
                  child: const Text('Cancel Booking'),
                ),
              ],
            ),
          );
        } else {
          throw Exception(response.error);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete slot: $e')),
      );
    }
  }

  Widget _buildSessionsView(bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshSchedule,
      color: isDark ? const Color(0xFF8B9DC3) : const Color(0xFF6B7FA8),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sessions Overview Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF6B7FA8).withOpacity(0.2),
                          const Color(0xFF8B9DC3).withOpacity(0.1),
                        ]
                      : [
                          const Color(0xFF6B7FA8).withOpacity(0.1),
                          const Color(0xFF8B9DC3).withOpacity(0.05),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF6B7FA8).withOpacity(0.3)
                      : const Color(0xFF6B7FA8).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF6B7FA8), const Color(0xFF8B9DC3)]
                            : [const Color(0xFF6B7FA8), const Color(0xFF8B9DC3)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B7FA8).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.event_note,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upcoming Sessions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_upcomingSessions.length} session${_upcomingSessions.length != 1 ? 's' : ''} scheduled',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : const Color(0xFF6B7FA8),
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
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.event_busy_outlined,
                        size: 64,
                        color: isDark
                            ? Colors.white.withOpacity(0.3)
                            : const Color(0xFFB0BEC5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No upcoming sessions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white.withOpacity(0.6)
                            : const Color(0xFF6B7FA8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sessions will appear here once students\nbook your available slots',
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
              )
            else
              ..._upcomingSessions.map((session) => _buildSessionCard(session, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsView(bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshSchedule,
      color: isDark ? const Color(0xFF8B9DC3) : const Color(0xFF6B7FA8),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Requests Overview Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFFFF8E53).withOpacity(0.2),
                          const Color(0xFFFF6B6B).withOpacity(0.1),
                        ]
                      : [
                          const Color(0xFFFF8E53).withOpacity(0.1),
                          const Color(0xFFFF6B6B).withOpacity(0.05),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFFF8E53).withOpacity(0.3)
                      : const Color(0xFFFF8E53).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_pendingRequests.length} pending request${_pendingRequests.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : const Color(0xFF6B7FA8),
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
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: isDark
                            ? Colors.white.withOpacity(0.3)
                            : const Color(0xFFB0BEC5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No pending requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white.withOpacity(0.6)
                            : const Color(0xFF6B7FA8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'New booking requests from students\nwill appear here',
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
              )
            else
              ..._pendingRequests.map((request) => _buildRequestCard(request, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(AvailabilitySlot session, bool isDark) {
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

  Widget _buildRequestCard(BookingRequest request, bool isDark) {
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
  DateTime? _recurringEndDate;
  
  // Session type options
  bool _includeOnline = false;
  bool _includeOffline = false;
  
  // Online session pricing
  final TextEditingController _onlineRateController = TextEditingController(text: '500');
  
  // Offline session details
  final TextEditingController _offlineRateController = TextEditingController(text: '600');
  final TextEditingController _meetingLocationController = TextEditingController();
  final TextEditingController _travelDistanceController = TextEditingController(text: '0');
  final TextEditingController _additionalNotesController = TextEditingController();
  
  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void dispose() {
    _onlineRateController.dispose();
    _offlineRateController.dispose();
    _meetingLocationController.dispose();
    _travelDistanceController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

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
          
          // Recurring End Date (if recurring is enabled)
          if (_recurring) ...[
            const SizedBox(height: AppTheme.spacingMD),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _recurringEndDate ?? DateTime.now().add(const Duration(days: 84)), // 12 weeks
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _recurringEndDate = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Recurring End Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _recurringEndDate != null
                      ? '${_recurringEndDate!.day}/${_recurringEndDate!.month}/${_recurringEndDate!.year}'
                      : 'Select end date (optional)',
                ),
              ),
            ),
          ],
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Session Types Section
          Text(
            'Session Types & Pricing',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            'Select at least one session type',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingMD),
          
          // Online Session Option
          CheckboxListTile(
            title: const Text('Online Session'),
            subtitle: const Text('Video call via the app'),
            value: _includeOnline,
            onChanged: (value) => setState(() => _includeOnline = value ?? false),
            secondary: const Icon(Icons.videocam, color: AppTheme.primaryColor),
          ),
          
          // Online Rate Input
          if (_includeOnline) ...[
            Padding(
              padding: const EdgeInsets.only(left: AppTheme.spacingXL, right: AppTheme.spacingMD),
              child: TextField(
                controller: _onlineRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hourly Rate (ETB)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  helperText: 'Your rate for online sessions',
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMD),
          ],
          
          // Offline Session Option
          CheckboxListTile(
            title: const Text('Offline Session'),
            subtitle: const Text('In-person meeting'),
            value: _includeOffline,
            onChanged: (value) => setState(() => _includeOffline = value ?? false),
            secondary: const Icon(Icons.location_on, color: AppTheme.accentColor),
          ),
          
          // Offline Session Details
          if (_includeOffline) ...[
            Padding(
              padding: const EdgeInsets.only(left: AppTheme.spacingXL, right: AppTheme.spacingMD),
              child: Column(
                children: [
                  TextField(
                    controller: _offlineRateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hourly Rate (ETB)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      helperText: 'Your rate for offline sessions',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  TextField(
                    controller: _meetingLocationController,
                    decoration: const InputDecoration(
                      labelText: 'Meeting Location *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.place),
                      helperText: 'Where will you meet? (5-200 characters)',
                    ),
                    maxLength: 200,
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  TextField(
                    controller: _travelDistanceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Travel Distance (km)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                      helperText: 'Maximum distance you can travel (0-100 km)',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  TextField(
                    controller: _additionalNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                      helperText: 'Any additional information',
                    ),
                    maxLines: 2,
                    maxLength: 500,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMD),
          ],
          
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
      
      // Validate at least one session type is selected
      if (!_includeOnline && !_includeOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one session type (Online or Offline)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Build session types array
      final sessionTypes = <Map<String, dynamic>>[];
      
      // Add online session type
      if (_includeOnline) {
        final onlineRate = double.tryParse(_onlineRateController.text) ?? 0;
        if (onlineRate <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Online hourly rate must be greater than 0'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        sessionTypes.add({
          'type': 'online',
          'hourlyRate': onlineRate,
        });
      }
      
      // Add offline session type
      if (_includeOffline) {
        final offlineRate = double.tryParse(_offlineRateController.text) ?? 0;
        if (offlineRate <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offline hourly rate must be greater than 0'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        final meetingLocation = _meetingLocationController.text.trim();
        if (meetingLocation.isEmpty || meetingLocation.length < 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meeting location must be at least 5 characters'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        final travelDistance = double.tryParse(_travelDistanceController.text) ?? 0;
        if (travelDistance < 0 || travelDistance > 100) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Travel distance must be between 0 and 100 km'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        sessionTypes.add({
          'type': 'offline',
          'hourlyRate': offlineRate,
          'meetingLocation': meetingLocation,
          'travelDistance': travelDistance,
          if (_additionalNotesController.text.trim().isNotEmpty)
            'additionalNotes': _additionalNotesController.text.trim(),
        });
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
        // Calculate end date for recurring availability
        final endDate = _recurringEndDate ?? now.add(const Duration(days: 84)); // Default 12 weeks
        
        // Create multiple slots for recurring availability
        final dates = <DateTime>[];
        DateTime currentDate = targetDate;
        while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
          dates.add(currentDate);
          currentDate = currentDate.add(const Duration(days: 7));
        }
        
        final response = await availabilityService.createBulkAvailability(
          dates: dates,
          startTime: startTimeStr,
          endTime: endTimeStr,
          sessionTypes: sessionTypes,
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
          sessionTypes: sessionTypes,
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