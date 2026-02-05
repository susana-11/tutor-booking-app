import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../theme/app_theme.dart';

class CancelBookingDialog extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingDetails;
  final VoidCallback onCancelled;

  const CancelBookingDialog({
    super.key,
    required this.bookingId,
    required this.bookingDetails,
    required this.onCancelled,
  });

  @override
  State<CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<CancelBookingDialog> {
  final BookingService _bookingService = BookingService();
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _refundInfo;

  @override
  void initState() {
    super.initState();
    _calculateRefund();
  }

  void _calculateRefund() {
    // Calculate refund based on time until session
    final sessionDate = widget.bookingDetails['sessionDate'];
    final startTime = widget.bookingDetails['startTime'];
    
    if (sessionDate == null || startTime == null) return;

    try {
      final sessionDateTime = DateTime.parse(sessionDate);
      final timeParts = startTime.split(':');
      final sessionWithTime = DateTime(
        sessionDateTime.year,
        sessionDateTime.month,
        sessionDateTime.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      final now = DateTime.now();
      final hoursUntilSession = sessionWithTime.difference(now).inHours;
      final minutesUntilSession = sessionWithTime.difference(now).inMinutes;

      int refundPercentage = 0;
      String refundMessage = '';

      // Refund policy (1 hour for testing)
      if (hoursUntilSession >= 1) {
        refundPercentage = 100;
        refundMessage = 'Full refund (cancelled ${hoursUntilSession}h before session)';
      } else if (minutesUntilSession >= 30) {
        refundPercentage = 50;
        refundMessage = 'Partial refund (cancelled ${minutesUntilSession}min before session)';
      } else if (minutesUntilSession >= 0) {
        refundPercentage = 0;
        refundMessage = 'No refund (less than 30 minutes before session)';
      } else {
        refundPercentage = 0;
        refundMessage = 'Session time has passed';
      }

      final totalAmount = widget.bookingDetails['totalAmount'] ?? 0.0;
      final refundAmount = (totalAmount * refundPercentage) / 100;

      setState(() {
        _refundInfo = {
          'percentage': refundPercentage,
          'amount': refundAmount,
          'message': refundMessage,
          'hoursUntilSession': hoursUntilSession,
          'minutesUntilSession': minutesUntilSession,
        };
      });
    } catch (e) {
      print('Error calculating refund: $e');
    }
  }

  Future<void> _cancelBooking() async {
    if (_reasonController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please provide a reason for cancellation';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _bookingService.cancelBooking(
        bookingId: widget.bookingId,
        reason: _reasonController.text.trim(),
      );

      if (!mounted) return;

      if (response.success) {
        Navigator.pop(context, true); // Return true to indicate success
        widget.onCancelled();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking cancelled successfully. ${_refundInfo?['message'] ?? ''}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to cancel booking';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancel Booking',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'This action cannot be undone',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Refund Information
              if (_refundInfo != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _refundInfo!['percentage'] == 100
                        ? Colors.green.withOpacity(0.1)
                        : _refundInfo!['percentage'] == 50
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _refundInfo!['percentage'] == 100
                          ? Colors.green.withOpacity(0.3)
                          : _refundInfo!['percentage'] == 50
                              ? Colors.orange.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Refund Amount',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${_refundInfo!['percentage']}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _refundInfo!['percentage'] == 100
                                  ? Colors.green[700]
                                  : _refundInfo!['percentage'] == 50
                                      ? Colors.orange[700]
                                      : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ETB ${_refundInfo!['amount'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _refundInfo!['message'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Refund Policy Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cancellation Policy',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 1+ hours before: 100% refund\n'
                        '• 30min - 1hr before: 50% refund\n'
                        '• Less than 30min: No refund',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Reason Input
              Text(
                'Reason for Cancellation',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Please provide a reason...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.grey[800]
                      : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Keep Booking'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _cancelBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Cancel Booking'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
