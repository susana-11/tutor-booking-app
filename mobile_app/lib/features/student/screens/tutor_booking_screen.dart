import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/booking_service.dart';
import '../../tutor/models/availability_model.dart';
import '../../tutor/services/availability_service.dart';
import '../../auth/providers/auth_provider.dart';

class TutorBookingScreen extends StatefulWidget {
  final String tutorId;
  final String tutorName;
  final String subject;
  final String subjectId;
  final double hourlyRate;

  const TutorBookingScreen({
    super.key,
    required this.tutorId,
    required this.tutorName,
    required this.subject,
    required this.subjectId,
    required this.hourlyRate,
  });

  @override
  State<TutorBookingScreen> createState() => _TutorBookingScreenState();
}

class _TutorBookingScreenState extends State<TutorBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  AvailabilitySlot? _selectedSlot;
  
  // Session type and duration selection
  String? _selectedSessionType; // 'online' or 'offline'
  double _selectedDuration = 1.0; // in hours (1, 1.5, 2)
  String? _selectedMeetingLocation; // for offline sessions
  
  final AvailabilityService _availabilityService = AvailabilityService();
  final SocketService _socketService = SocketService();
  final TextEditingController _notesController = TextEditingController();
  
  List<AvailabilitySlot> _availableSlots = [];
  bool _isLoading = true;
  bool _isBooking = false;
  
  // Duration options
  final List<double> _durationOptions = [1.0, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAvailableSlots();
  }

  Future<void> _loadAvailableSlots() async {
    setState(() => _isLoading = true);
    
    try {
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: 30)); // Next 30 days
      
      print('🔍 Loading slots for tutorId: ${widget.tutorId}');
      print('📅 Date range: $startDate to $endDate');
      
      final response = await _availabilityService.getAvailabilitySlots(
        startDate: startDate,
        endDate: endDate,
        tutorId: widget.tutorId, // Pass the tutorId for students
      );

      print('📥 Response success: ${response.success}');
      print('📥 Response data length: ${response.data?.length ?? 0}');

      if (response.success && response.data != null) {
        print('📊 Total slots received: ${response.data!.length}');
        
        final filteredSlots = response.data!
            .where((slot) => 
                slot.tutorId == widget.tutorId &&
                slot.isAvailable &&
                !slot.isBooked &&
                slot.isUpcoming)
            .toList();
        
        print('✅ Available slots after filtering: ${filteredSlots.length}');
        
        setState(() {
          _availableSlots = filteredSlots;
        });
      } else {
        print('❌ Failed to load slots: ${response.error}');
      }
    } catch (e) {
      print('❌ Error loading available slots: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load available slots: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${widget.tutorName}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Select Time'),
            Tab(text: 'Session Details'),
            Tab(text: 'Confirm'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTimeSelectionTab(),
                _buildSessionDetailsTab(),
                _buildConfirmationTab(),
              ],
            ),
    );
  }

  Widget _buildTimeSelectionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tutor Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      widget.tutorName.split(' ').map((n) => n[0]).join(),
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tutorName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.subject,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          '\$${widget.hourlyRate.toStringAsFixed(0)}/hour',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Date Selection
          Text(
            'Select Date',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingMD),
          
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 14, // Next 2 weeks
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = _selectedDate.day == date.day &&
                    _selectedDate.month == date.month &&
                    _selectedDate.year == date.year;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                      _selectedSlot = null; // Reset selected slot
                    });
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: AppTheme.spacingSM),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getDayName(date),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getMonthName(date),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Available Time Slots
          Text(
            'Available Time Slots',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingMD),
          
          _buildTimeSlots(),
        ],
      ),
    );
  }

  Widget _buildTimeSlots() {
    final slotsForDate = _availableSlots.where((slot) {
      return slot.date.day == _selectedDate.day &&
          slot.date.month == _selectedDate.month &&
          slot.date.year == _selectedDate.year;
    }).toList();

    if (slotsForDate.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Text(
              'No available slots',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              'Please select a different date',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slotsForDate.length,
      itemBuilder: (context, index) {
        final slot = slotsForDate[index];
        final isSelected = _selectedSlot?.id == slot.id;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSlot = slot;
              // Reset session type selection when slot changes
              _selectedSessionType = null;
              _selectedMeetingLocation = null;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacingSM),
                      Text(
                        slot.timeSlot.displayTime,
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingSM),
                  
                  // Session Types Available
                  Wrap(
                    spacing: AppTheme.spacingSM,
                    runSpacing: AppTheme.spacingSM,
                    children: [
                      if (slot.hasOnlineSession)
                        _buildSessionTypeChip(
                          icon: Icons.videocam,
                          label: 'Online',
                          price: slot.onlineRate ?? 0,
                          color: Colors.blue,
                        ),
                      if (slot.hasOfflineSession)
                        _buildSessionTypeChip(
                          icon: Icons.location_on,
                          label: 'Offline',
                          price: slot.offlineRate ?? 0,
                          color: Colors.green,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSessionTypeChip({
    required IconData icon,
    required String label,
    required double price,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSM,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label - ${price.toStringAsFixed(0)} ETB/hr',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDetailsTab() {
    if (_selectedSlot == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Text(
              'Please select a time slot first',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Debug logging
    print('🔍 Session Details Tab - Selected Slot Info:');
    print('  - Has Online: ${_selectedSlot!.hasOnlineSession}');
    print('  - Has Offline: ${_selectedSlot!.hasOfflineSession}');
    print('  - Online Rate: ${_selectedSlot!.onlineRate}');
    print('  - Offline Rate: ${_selectedSlot!.offlineRate}');
    print('  - Session Types Count: ${_selectedSlot!.sessionTypes.length}');
    for (var st in _selectedSlot!.sessionTypes) {
      print('    - Type: ${st.type}, Rate: ${st.hourlyRate}');
    }

    // Check if session types are empty - use fallback
    final hasSessionTypes = _selectedSlot!.sessionTypes.isNotEmpty;
    final bool showOnline = hasSessionTypes ? _selectedSlot!.hasOnlineSession : true;
    final bool showOffline = hasSessionTypes ? _selectedSlot!.hasOfflineSession : true;
    final double onlineRateValue = hasSessionTypes ? (_selectedSlot!.onlineRate ?? widget.hourlyRate) : widget.hourlyRate;
    final double offlineRateValue = hasSessionTypes ? (_selectedSlot!.offlineRate ?? widget.hourlyRate) : widget.hourlyRate;

    if (!hasSessionTypes) {
      print('⚠️ WARNING: No session types found! Using fallback with base rate: ${widget.hourlyRate}');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session Type Selection
          Text(
            'Choose Session Type',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingMD),
          
          if (showOnline)
            _buildSessionTypeCard(
              type: 'online',
              icon: Icons.videocam,
              title: 'Online Session',
              subtitle: 'Video call via the app',
              price: onlineRateValue,
              color: Colors.blue,
            ),
          
          if (showOffline)
            _buildSessionTypeCard(
              type: 'offline',
              icon: Icons.location_on,
              title: 'Offline Session',
              subtitle: 'In-person meeting',
              price: offlineRateValue,
              color: Colors.green,
            ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Duration Selection
          Text(
            'Select Duration',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingMD),
          
          Row(
            children: _durationOptions.map((duration) {
              final isSelected = _selectedDuration == duration;
              final hourlyRate = _getSelectedHourlyRate();
              final totalPrice = hourlyRate * duration;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDuration = duration;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: AppTheme.spacingSM),
                    padding: const EdgeInsets.all(AppTheme.spacingMD),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          duration == 1.0 ? '1 hr' : duration == 1.5 ? '1.5 hrs' : '2 hrs',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${totalPrice.toStringAsFixed(0)} ETB',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          // Meeting Location (for offline sessions)
          if (_selectedSessionType == 'offline') ...[
            const SizedBox(height: AppTheme.spacingXL),
            
            Text(
              'Meeting Location',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingMD),
            
            _buildMeetingLocationCard(
              location: 'studentHome',
              icon: Icons.home,
              title: 'Student Home',
              subtitle: 'Tutor comes to your location',
            ),
            
            _buildMeetingLocationCard(
              location: 'tutorLocation',
              icon: Icons.school,
              title: 'Tutor Location',
              subtitle: _getOfflineSessionLocation(),
            ),
            
            _buildMeetingLocationCard(
              location: 'publicPlace',
              icon: Icons.coffee,
              title: 'Public Place',
              subtitle: 'Meet at a coffee shop or library',
            ),
            
            // Travel Distance Info
            const SizedBox(height: AppTheme.spacingMD),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: AppTheme.spacingSM),
                  Expanded(
                    child: Text(
                      'Tutor can travel up to ${_getTravelDistance()} km',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedSessionType != null &&
                      (_selectedSessionType != 'offline' || _selectedMeetingLocation != null)
                  ? () {
                      _tabController.animateTo(2); // Go to confirmation tab
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLG),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
              child: const Text(
                'Continue to Confirmation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSessionTypeCard({
    required String type,
    required IconData icon,
    required String title,
    required String subtitle,
    required double price,
    required Color color,
  }) {
    final isSelected = _selectedSessionType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSessionType = type;
          if (type == 'online') {
            _selectedMeetingLocation = null; // Reset location for online
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${price.toStringAsFixed(0)} ETB',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isSelected ? color : Colors.black87,
                  ),
                ),
                Text(
                  'per hour',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: AppTheme.spacingSM),
              Icon(Icons.check_circle, color: color, size: 24),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildMeetingLocationCard({
    required String location,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMeetingLocation == location;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMeetingLocation = location;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primaryColor : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }
  
  double _getSelectedHourlyRate() {
    if (_selectedSlot == null || _selectedSessionType == null) return widget.hourlyRate;
    
    // If no session types configured, use base rate
    if (_selectedSlot!.sessionTypes.isEmpty) {
      return widget.hourlyRate;
    }
    
    if (_selectedSessionType == 'online') {
      return _selectedSlot!.onlineRate ?? widget.hourlyRate;
    } else {
      return _selectedSlot!.offlineRate ?? widget.hourlyRate;
    }
  }
  
  String _getOfflineSessionLocation() {
    if (_selectedSlot == null) return 'Location not specified';
    
    // If no session types, return default
    if (_selectedSlot!.sessionTypes.isEmpty) {
      return 'To be discussed with tutor';
    }
    
    final offlineSession = _selectedSlot!.sessionTypes.firstWhere(
      (st) => st.isOffline,
      orElse: () => SessionTypeInfo(type: 'offline', hourlyRate: 0),
    );
    
    return offlineSession.meetingLocation ?? 'To be discussed with tutor';
  }
  
  double _getTravelDistance() {
    if (_selectedSlot == null) return 0;
    
    // If no session types, return default
    if (_selectedSlot!.sessionTypes.isEmpty) {
      return 10; // Default 10km
    }
    
    final offlineSession = _selectedSlot!.sessionTypes.firstWhere(
      (st) => st.isOffline,
      orElse: () => SessionTypeInfo(type: 'offline', hourlyRate: 0),
    );
    
    return offlineSession.travelDistance ?? 10;
  }

  Widget _buildConfirmationTab() {
    if (_selectedSlot == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Text(
              'Please select a time slot',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              'Go back to the previous tab to choose your preferred time',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_selectedSessionType == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Text(
              'Please select session type and duration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              'Go back to Session Details tab to complete your selection',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booking Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingLG),
                  
                  _buildSummaryRow('Tutor', widget.tutorName),
                  _buildSummaryRow('Subject', widget.subject),
                  _buildSummaryRow('Date', _formatDate(_selectedSlot!.date)),
                  _buildSummaryRow('Time', _selectedSlot!.timeSlot.displayTime),
                  _buildSummaryRow('Session Type', _selectedSessionType == 'online' ? 'Online Session' : 'Offline Session'),
                  _buildSummaryRow('Duration', _selectedDuration == 1.0 ? '1 hour' : _selectedDuration == 1.5 ? '1.5 hours' : '2 hours'),
                  if (_selectedSessionType == 'offline' && _selectedMeetingLocation != null)
                    _buildSummaryRow('Location', _getMeetingLocationText()),
                  
                  const Divider(height: AppTheme.spacingXL),
                  
                  _buildSummaryRow('Hourly Rate', '${_getSelectedHourlyRate().toStringAsFixed(0)} ETB'),
                  _buildSummaryRow('Duration', '$_selectedDuration hours'),
                  
                  const Divider(height: AppTheme.spacingLG),
                  
                  _buildSummaryRow(
                    'Total Amount',
                    '${(_getSelectedHourlyRate() * _selectedDuration).toStringAsFixed(0)} ETB',
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Additional Notes
          Text(
            'Additional Notes (Optional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingMD),
          
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Any specific topics or requirements for this session...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Terms and Conditions
          Container(
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
                  'Booking Terms:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                Text(
                  '• Cancellation allowed up to 24 hours before the session\n'
                  '• Payment will be processed after tutor confirmation\n'
                  '• Meeting link will be provided upon confirmation',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Book Now Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isBooking ? null : _bookSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLG),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
              child: _isBooking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Book Session - ${(_getSelectedHourlyRate() * _selectedDuration).toStringAsFixed(0)} ETB',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black87 : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isTotal ? AppTheme.primaryColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _getMeetingLocationText() {
    switch (_selectedMeetingLocation) {
      case 'studentHome':
        return 'Student Home';
      case 'tutorLocation':
        return 'Tutor Location';
      case 'publicPlace':
        return 'Public Place';
      default:
        return 'Not specified';
    }
  }

  Future<void> _bookSession() async {
    if (_selectedSlot == null || _selectedSessionType == null) return;

    setState(() => _isBooking = true);

    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Use subjectId if available, otherwise use subject name as fallback
      final subjectIdentifier = widget.subjectId.isNotEmpty 
          ? widget.subjectId 
          : widget.subject;

      // Calculate total amount
      final hourlyRate = _getSelectedHourlyRate();
      final totalAmount = hourlyRate * _selectedDuration;

      print('🔍 Creating booking with:');
      print('  - Subject: $subjectIdentifier');
      print('  - Session Type: $_selectedSessionType');
      print('  - Duration: $_selectedDuration hours');
      print('  - Hourly Rate: $hourlyRate ETB');
      print('  - Total Amount: $totalAmount ETB');
      if (_selectedSessionType == 'offline') {
        print('  - Meeting Location: $_selectedMeetingLocation');
      }

      // Create booking via API
      final bookingService = BookingService();
      final response = await bookingService.createBooking(
        tutorId: widget.tutorId,
        subjectId: subjectIdentifier,
        date: _selectedSlot!.date,
        startTime: _selectedSlot!.timeSlot.startTime,
        endTime: _selectedSlot!.timeSlot.endTime,
        mode: _selectedSessionType!, // 'online' or 'offline'
        duration: _selectedDuration,
        totalAmount: totalAmount,
        location: _selectedSessionType == 'offline' ? _getMeetingLocationText() : null,
        message: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (response.success) {
        // Booking created successfully - now proceed to payment
        final booking = response.data?['booking'] ?? response.data ?? {};
        final bookingId = booking['_id'] ?? booking['id'];
        
        if (mounted) {
          // Navigate to payment screen with complete booking details
          context.push('/payment', extra: {
            'bookingId': bookingId,
            'bookingDetails': {
              'tutorName': widget.tutorName,
              'subject': widget.subject,
              'date': _formatDate(_selectedSlot!.date),
              'time': '${_selectedSlot!.timeSlot.startTime} - ${_selectedSlot!.timeSlot.endTime}',
              'duration': (_selectedDuration * 60).toInt(), // Convert to minutes
              'sessionType': _selectedSessionType,
              'totalAmount': totalAmount,
              'meetingLocation': _selectedSessionType == 'offline' ? _getMeetingLocationText() : null,
            },
          });
        }
      } else {
        throw Exception(response.error ?? 'Failed to create booking');
      }

    } catch (e) {
      print('❌ Error booking session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book session: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  String _getDayName(DateTime date) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }

  String _getMonthName(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  String _formatDate(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}