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
  
  final AvailabilityService _availabilityService = AvailabilityService();
  final SocketService _socketService = SocketService();
  final TextEditingController _notesController = TextEditingController();
  
  List<AvailabilitySlot> _availableSlots = [];
  bool _isLoading = true;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            Tab(text: 'Confirm Booking'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTimeSelectionTab(),
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: AppTheme.spacingMD,
        mainAxisSpacing: AppTheme.spacingMD,
      ),
      itemCount: slotsForDate.length,
      itemBuilder: (context, index) {
        final slot = slotsForDate[index];
        final isSelected = _selectedSlot?.id == slot.id;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSlot = slot;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                slot.timeSlot.displayTime,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
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
                  _buildSummaryRow('Duration', '${_selectedSlot!.timeSlot.durationMinutes} minutes'),
                  
                  const Divider(height: AppTheme.spacingXL),
                  
                  _buildSummaryRow(
                    'Total Amount',
                    '\$${widget.hourlyRate.toStringAsFixed(0)}',
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
                      'Book Session - \$${widget.hourlyRate.toStringAsFixed(0)}',
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

  Future<void> _bookSession() async {
    if (_selectedSlot == null) return;

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

      print('🔍 Creating booking with subject: $subjectIdentifier');

      // Create booking via API
      final bookingService = BookingService();
      final response = await bookingService.createBooking(
        tutorId: widget.tutorId,
        subjectId: subjectIdentifier,
        date: _selectedSlot!.date,
        startTime: _selectedSlot!.timeSlot.startTime,
        endTime: _selectedSlot!.timeSlot.endTime,
        mode: 'online', // Default to online
        message: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (response.success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking request sent! Waiting for tutor confirmation.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate back to bookings screen
          context.pop(); // Go back to previous screen
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