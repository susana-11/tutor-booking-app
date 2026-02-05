import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/widgets/custom_button.dart';
import 'payment_webview_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingDetails;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.bookingDetails,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final tutorName = widget.bookingDetails['tutorName'] ?? 'Tutor';
    final subject = widget.bookingDetails['subject'] ?? 'Subject';
    final date = widget.bookingDetails['date'] ?? '';
    final time = widget.bookingDetails['time'] ?? '';
    final duration = widget.bookingDetails['duration'] ?? 60;
    final sessionType = widget.bookingDetails['sessionType'] ?? 'online';
    final amount = widget.bookingDetails['totalAmount'] ?? 0.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Complete Payment'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing payment...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Summary',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(
                          context,
                          Icons.person_outline,
                          'Tutor',
                          tutorName,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          Icons.book_outlined,
                          'Subject',
                          subject,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          Icons.calendar_today_outlined,
                          'Date',
                          date,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          Icons.access_time_outlined,
                          'Time',
                          time,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          Icons.timer_outlined,
                          'Duration',
                          '$duration minutes',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          sessionType == 'online'
                              ? Icons.videocam_outlined
                              : Icons.location_on_outlined,
                          'Session Type',
                          sessionType == 'online' ? 'Online' : 'In-Person',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Amount Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'ETB ${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Payment will be held securely until session completion. You have 10 minutes after the session to file a dispute if needed.',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Pay Button
                  CustomButton(
                    text: 'Pay with Chapa',
                    onPressed: _initializePayment,
                    isLoading: _isLoading,
                    icon: Icons.payment,
                  ),
                  const SizedBox(height: 16),

                  // Cancel Button
                  CustomButton(
                    text: 'Cancel Booking',
                    onPressed: () => _showCancelDialog(),
                    variant: ButtonVariant.outlined,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _initializePayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _paymentService.initializePayment(widget.bookingId);

      if (!mounted) return;

      if (response['success'] == true) {
        final checkoutUrl = response['data']['checkoutUrl'];
        final reference = response['data']['reference'];

        // Navigate to WebView
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(
              checkoutUrl: checkoutUrl,
              reference: reference,
            ),
          ),
        );

        if (!mounted) return;

        if (result != null) {
          await _handlePaymentResult(result);
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to initialize payment';
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

  Future<void> _handlePaymentResult(Map<String, dynamic> result) async {
    final status = result['status'];
    final reference = result['reference'];

    if (status == 'success') {
      // Show loading while verifying
      setState(() {
        _isLoading = true;
      });

      try {
        // Verify payment
        final verifyResponse = await _paymentService.verifyPayment(reference);

        if (!mounted) return;

        if (verifyResponse['success'] == true) {
          // Payment successful
          _showSuccessDialog();
        } else {
          setState(() {
            _errorMessage = 'Payment verification failed. Please contact support.';
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to verify payment: ${e.toString()}';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (status == 'cancelled') {
      setState(() {
        _errorMessage = 'Payment was cancelled. Please try again.';
      });
    } else {
      setState(() {
        _errorMessage = 'Payment failed. Please try again.';
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your booking has been confirmed. The tutor will be notified.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.go('/student-bookings'); // Navigate to bookings
            },
            child: const Text('View Bookings'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.go('/student-bookings'); // Navigate back
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
