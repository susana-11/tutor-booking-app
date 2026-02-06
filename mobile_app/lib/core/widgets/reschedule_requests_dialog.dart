import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../services/booking_service.dart';
import '../services/storage_service.dart';

class RescheduleRequestsDialog extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onSuccess;

  const RescheduleRequestsDialog({
    Key? key,
    required this.booking,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<RescheduleRequestsDialog> createState() => _RescheduleRequestsDialogState();
}

class _RescheduleRequestsDialogState extends State<RescheduleRequestsDialog> {
  final BookingService _bookingService = BookingService();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadRequests();
  }

  Future<void> _loadCurrentUser() async {
    final user = await StorageService.getUserData();
    if (user != null && mounted) {
      setState(() {
        _currentUserId = user['_id'] ?? user['id'];
      });
    }
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    
    try {
      final bookingId = widget.booking['_id'] ?? widget.booking['id'];
      final response = await _bookingService.getRescheduleRequests(bookingId);
      
      if (response.success && response.data != null) {
        setState(() {
          _requests = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to load requests')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _respondToRequest(Map<String, dynamic> request, String response) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final bookingId = widget.booking['_id'] ?? widget.booking['id'];
      final requestId = request['_id'];
      
      final apiResponse = await _bookingService.respondToRescheduleRequest(
        bookingId: bookingId,
        requestId: requestId,
        response: response,
      );

      if (mounted) Navigator.pop(context); // Close loading

      if (apiResponse.success) {
        if (mounted) {
          Navigator.pop(context); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response == 'accept'
                    ? '✅ Reschedule request accepted'
                    : 'Reschedule request declined',
              ),
              backgroundColor: response == 'accept' ? Colors.green : Colors.orange,
            ),
          );
          widget.onSuccess();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(apiResponse.error ?? 'Failed to respond'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Expanded(
                    child: Text(
                      'Reschedule Requests',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppTheme.spacingLG),
                          itemCount: _requests.length,
                          separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingMD),
                          itemBuilder: (context, index) => _buildRequestCard(_requests[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Text(
              'No Reschedule Requests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              'There are no reschedule requests for this booking',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] as String;
    final isPending = status == 'pending';
    final isAccepted = status == 'accepted';
    final isRejected = status == 'rejected';
    
    // Check if current user is the requester
    final requestedBy = request['requestedBy']?.toString();
    final isRequester = requestedBy != null && requestedBy == _currentUserId;
    
    // Only show accept/reject buttons if:
    // 1. Request is pending
    // 2. Current user is NOT the requester
    final canRespond = isPending && !isRequester;
    
    Color statusColor = isPending
        ? Colors.orange
        : isAccepted
            ? Colors.green
            : Colors.red;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Row(
              children: [
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
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(request['requestedAt']),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingMD),
            
            // New date/time
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requested New Time',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: AppTheme.spacingXS),
                      Text(
                        _formatDate(request['newDate']),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: AppTheme.spacingXS),
                      Text(
                        '${request['newStartTime']} - ${request['newEndTime']}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Reason
            if (request['reason'] != null && request['reason'].toString().isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingMD),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reason:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      request['reason'],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            
            // Action buttons (only for pending requests where current user is NOT the requester)
            if (canRespond) ...[
              const SizedBox(height: AppTheme.spacingMD),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _respondToRequest(request, 'reject'),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _respondToRequest(request, 'accept'),
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
            
            // Show "Waiting for response" message if current user is the requester
            if (isPending && isRequester) ...[
              const SizedBox(height: AppTheme.spacingMD),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSM),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 16,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    Expanded(
                      child: Text(
                        'Waiting for the other party to respond',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Response info (for accepted/rejected requests)
            if (!isPending && request['respondedAt'] != null) ...[
              const SizedBox(height: AppTheme.spacingMD),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSM),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAccepted ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    Expanded(
                      child: Text(
                        '${isAccepted ? 'Accepted' : 'Declined'} on ${_formatDateTime(request['respondedAt'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMMM d, y').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, y • h:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
