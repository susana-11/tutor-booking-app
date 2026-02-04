import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SessionActionButton extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onStartSession;
  final VoidCallback? onJoinSession;

  const SessionActionButton({
    Key? key,
    required this.booking,
    required this.onStartSession,
    this.onJoinSession,
  }) : super(key: key);

  bool _canStartSession() {
    if (booking['status'] != 'confirmed') return false;
    
    // Check if session is already active
    final session = booking['session'];
    if (session != null && session['isActive'] == true) {
      return false; // Can't start if already active
    }
    
    try {
      final sessionDate = DateTime.parse(booking['sessionDate']);
      final startTime = booking['startTime'] as String;
      final parts = startTime.split(':');
      final sessionDateTime = DateTime(
        sessionDate.year,
        sessionDate.month,
        sessionDate.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      
      final now = DateTime.now();
      
      // Can start 5 minutes before
      final canStartFrom = sessionDateTime.subtract(const Duration(minutes: 5));
      
      // Can start up to 15 minutes after
      final canStartUntil = sessionDateTime.add(const Duration(minutes: 15));
      
      return now.isAfter(canStartFrom) && now.isBefore(canStartUntil);
    } catch (e) {
      print('Error checking if can start: $e');
      return false;
    }
  }

  bool _canJoinSession() {
    if (booking['status'] != 'confirmed') return false;
    
    // Check if session is already active
    final session = booking['session'];
    return session != null && session['isActive'] == true;
  }

  String _getTimeUntilSession() {
    try {
      final sessionDate = DateTime.parse(booking['sessionDate']);
      final startTime = booking['startTime'] as String;
      final parts = startTime.split(':');
      final sessionDateTime = DateTime(
        sessionDate.year,
        sessionDate.month,
        sessionDate.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      
      final now = DateTime.now();
      final difference = sessionDateTime.difference(now);
      
      if (difference.isNegative) {
        final minutesLate = difference.inMinutes.abs();
        if (minutesLate <= 15) {
          return 'Session started $minutesLate min ago';
        }
        return 'Session time passed';
      } else if (difference.inDays > 0) {
        return 'In ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return 'In ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
      } else if (difference.inMinutes > 0) {
        return 'In ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
      } else {
        return 'Starting now!';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canStart = _canStartSession();
    final canJoin = _canJoinSession();
    final timeUntil = _getTimeUntilSession();

    // Show Join button if session is already active
    if (canJoin && onJoinSession != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onJoinSession,
            icon: const Icon(Icons.video_call, size: 20),
            label: const Text(
              'Join Session',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: Colors.green,
              ),
              const SizedBox(width: 6),
              Text(
                'Session in progress',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Show Start button if it's time to start
    if (canStart) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onStartSession,
            icon: const Icon(Icons.play_circle_filled, size: 20),
            label: const Text(
              'Start Session',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: Colors.green[700],
              ),
              const SizedBox(width: 4),
              Text(
                timeUntil,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      );
    } else if (booking['status'] == 'confirmed') {
      return Column(
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    timeUntil,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
