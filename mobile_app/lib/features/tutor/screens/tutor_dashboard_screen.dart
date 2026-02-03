import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/providers/auth_provider.dart';

class TutorDashboardScreen extends StatefulWidget {
  const TutorDashboardScreen({super.key});

  @override
  State<TutorDashboardScreen> createState() => _TutorDashboardScreenState();
}

class _TutorDashboardScreenState extends State<TutorDashboardScreen> {
  final BookingService _bookingService = BookingService();
  final ProfileService _profileService = ProfileService();
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _upcomingSessions = [];
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoadingSessions = true;
  bool _isLoadingActivity = true;
  bool _isLoadingStats = true;
  int _unreadCount = 0;
  
  // Stats
  int _todaysSessions = 0;
  double _thisMonthEarnings = 0.0;
  double _rating = 0.0;
  int _totalStudents = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadUnreadCount();
    
    // Listen to notification count updates
    _notificationService.notificationCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });
  }

  Future<void> _loadUnreadCount() async {
    final count = await _notificationService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadStats(),
      _loadUpcomingSessions(),
      _loadRecentActivity(),
    ]);
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    
    try {
      // Load tutor profile for rating
      final profileResponse = await _profileService.getTutorProfile();
      if (profileResponse.success && profileResponse.data != null) {
        final profile = profileResponse.data!;
        setState(() {
          _rating = (profile['rating'] ?? 0.0).toDouble();
        });
      }
      
      // Load all bookings to calculate stats
      final bookingsResponse = await _bookingService.getBookings();
      if (bookingsResponse.success && bookingsResponse.data != null) {
        final bookings = bookingsResponse.data!;
        
        // Calculate today's sessions
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        _todaysSessions = bookings.where((booking) {
          final sessionDate = DateTime.tryParse(booking['sessionDate'] ?? '');
          if (sessionDate == null) return false;
          final sessionDay = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
          return sessionDay == today && booking['status'] == 'confirmed';
        }).length;
        
        // Calculate this month's earnings
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        _thisMonthEarnings = bookings.where((booking) {
          final sessionDate = DateTime.tryParse(booking['sessionDate'] ?? '');
          if (sessionDate == null) return false;
          return sessionDate.isAfter(firstDayOfMonth) && 
                 booking['status'] == 'completed';
        }).fold(0.0, (sum, booking) {
          final amount = booking['totalAmount'] ?? booking['amount'] ?? 0;
          return sum + (amount is int ? amount.toDouble() : (amount as num).toDouble());
        });
        
        // Calculate total unique students
        final uniqueStudents = <String>{};
        for (var booking in bookings) {
          final studentId = booking['studentId'];
          if (studentId != null) {
            uniqueStudents.add(studentId.toString());
          }
        }
        _totalStudents = uniqueStudents.length;
        
        setState(() {});
      }
    } catch (e) {
      print('Error loading stats: $e');
    } finally {
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadUpcomingSessions() async {
    setState(() => _isLoadingSessions = true);
    
    try {
      // Get confirmed bookings
      final response = await _bookingService.getBookings(status: 'confirmed');
      
      if (response.success && response.data != null) {
        final bookings = response.data!;
        
        // Filter for upcoming sessions (future dates)
        final now = DateTime.now();
        final upcoming = bookings.where((booking) {
          final sessionDate = DateTime.tryParse(booking['sessionDate'] ?? '');
          return sessionDate != null && sessionDate.isAfter(now);
        }).toList();
        
        // Sort by date (earliest first)
        upcoming.sort((a, b) {
          final dateA = DateTime.tryParse(a['sessionDate'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['sessionDate'] ?? '') ?? DateTime.now();
          return dateA.compareTo(dateB);
        });
        
        // Take only first 5
        setState(() {
          _upcomingSessions = upcoming.take(5).toList();
        });
      }
    } catch (e) {
      print('Error loading upcoming sessions: $e');
    } finally {
      setState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _loadRecentActivity() async {
    setState(() => _isLoadingActivity = true);
    
    try {
      // Get all recent bookings (last 10)
      final response = await _bookingService.getBookings();
      
      if (response.success && response.data != null) {
        final bookings = response.data!;
        
        // Convert bookings to activity items
        final activities = <Map<String, dynamic>>[];
        
        for (var booking in bookings.take(10)) {
          final status = booking['status'];
          final studentName = booking['studentName'] ?? 'Student';
          final createdAt = DateTime.tryParse(booking['createdAt'] ?? booking['requestedAt'] ?? '');
          final timeAgo = createdAt != null ? _getTimeAgo(createdAt) : 'Recently';
          
          if (status == 'pending') {
            activities.add({
              'type': 'booking',
              'message': 'New booking request from $studentName',
              'time': timeAgo,
              'icon': Icons.book_online,
              'color': Colors.blue,
              'bookingId': booking['id'],
            });
          } else if (status == 'confirmed') {
            activities.add({
              'type': 'confirmed',
              'message': 'Booking confirmed with $studentName',
              'time': timeAgo,
              'icon': Icons.check_circle,
              'color': Colors.green,
              'bookingId': booking['id'],
            });
          } else if (status == 'completed') {
            activities.add({
              'type': 'completed',
              'message': 'Session completed with $studentName',
              'time': timeAgo,
              'icon': Icons.done_all,
              'color': Colors.teal,
              'bookingId': booking['id'],
            });
          }
        }
        
        setState(() {
          _recentActivity = activities;
        });
      }
    } catch (e) {
      print('Error loading recent activity: $e');
    } finally {
      setState(() => _isLoadingActivity = false);
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} week${difference.inDays > 13 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final sessionDay = DateTime(date.year, date.month, date.day);
    
    if (sessionDay == today) {
      return 'Today';
    } else if (sessionDay == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tutor Dashboard'),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: () => context.push('/tutor-notifications'),
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            _unreadCount > 99 ? '99+' : '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  await authProvider.logout();
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingLG),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        user?.fullName ?? 'Tutor',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSM),
                      Text(
                        'Ready to inspire and teach students today?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingXL),
                
                // Quick Stats
                Row(
                  children: [
                    Expanded(child: _buildStatCard(
                      'Today\'s Sessions', 
                      _isLoadingStats ? '...' : '$_todaysSessions', 
                      Icons.today, 
                      Colors.blue
                    )),
                    const SizedBox(width: AppTheme.spacingMD),
                    Expanded(child: _buildStatCard(
                      'This Month', 
                      _isLoadingStats ? '...' : '\$${_thisMonthEarnings.toStringAsFixed(0)}', 
                      Icons.attach_money, 
                      Colors.green
                    )),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingMD),
                
                Row(
                  children: [
                    Expanded(child: _buildStatCard(
                      'Rating', 
                      _isLoadingStats ? '...' : _rating > 0 ? _rating.toStringAsFixed(1) : 'N/A', 
                      Icons.star, 
                      Colors.amber
                    )),
                    const SizedBox(width: AppTheme.spacingMD),
                    Expanded(child: _buildStatCard(
                      'Total Students', 
                      _isLoadingStats ? '...' : '$_totalStudents', 
                      Icons.people, 
                      Colors.purple
                    )),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingXL),
                
                // Quick Actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingLG),
                
                // Action Cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppTheme.spacingMD,
                  mainAxisSpacing: AppTheme.spacingMD,
                  childAspectRatio: 1.2,
                  children: [
                    _buildActionCard(
                      context,
                      icon: Icons.calendar_today,
                      title: 'My Schedule',
                      subtitle: 'Manage availability',
                      onTap: () => context.push('/tutor-schedule'),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.book_online,
                      title: 'Bookings',
                      subtitle: 'View & manage',
                      onTap: () => context.push('/tutor-bookings'),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.person,
                      title: 'My Profile',
                      subtitle: 'Edit profile',
                      onTap: () => context.push('/tutor-profile'),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.analytics,
                      title: 'Earnings',
                      subtitle: 'Track income',
                      onTap: () => context.push('/tutor-earnings'),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.chat,
                      title: 'Messages',
                      subtitle: 'Chat with students',
                      onTap: () => context.push('/tutor-messages'),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.reviews,
                      title: 'Reviews',
                      subtitle: 'Student feedback',
                      onTap: () => context.push('/tutor-reviews'),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingXL),
                
                // Upcoming Sessions
                Text(
                  'Upcoming Sessions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingLG),
                
                _buildUpcomingSessionsList(),
                
                const SizedBox(height: AppTheme.spacingXL),
                
                // Recent Activity
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingLG),
                
                _buildRecentActivity(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingSM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingSessionsList() {
    if (_isLoadingSessions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingXL),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_upcomingSessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            children: [
              Icon(
                Icons.event_busy,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: AppTheme.spacingMD),
              Text(
                'No upcoming sessions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                'Your confirmed sessions will appear here',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _upcomingSessions.map((session) {
        final sessionDate = DateTime.tryParse(session['sessionDate'] ?? '');
        final studentName = session['studentName'] ?? 'Student';
        final subject = session['subject'] ?? 'Session';
        final startTime = session['startTime'] ?? '';
        final endTime = session['endTime'] ?? '';
        final mode = session['mode'] ?? session['sessionType'] ?? 'Online';
        final status = session['status'] ?? 'confirmed';
        
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                studentName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join(),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(studentName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$subject • $mode'),
                if (sessionDate != null)
                  Text('${_formatDate(sessionDate)} • $startTime - $endTime'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSM,
                vertical: AppTheme.spacingXS,
              ),
              decoration: BoxDecoration(
                color: status == 'confirmed' 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Text(
                status == 'confirmed' ? 'Confirmed' : 'Pending',
                style: TextStyle(
                  color: status == 'confirmed' ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () {
              context.push('/tutor-bookings');
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivity() {
    if (_isLoadingActivity) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingXL),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_recentActivity.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: AppTheme.spacingMD),
              Text(
                'No recent activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                'Your recent bookings and activities will appear here',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recentActivity.map((activity) => ListTile(
        leading: CircleAvatar(
          backgroundColor: (activity['color'] as Color).withOpacity(0.1),
          child: Icon(
            activity['icon'] as IconData,
            color: activity['color'] as Color,
            size: 20,
          ),
        ),
        title: Text(activity['message'] as String),
        subtitle: Text(activity['time'] as String),
        onTap: () {
          // Navigate to bookings screen
          context.push('/tutor-bookings');
        },
      )).toList(),
    );
  }
}