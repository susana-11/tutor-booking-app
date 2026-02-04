import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/dashboard_service.dart';
import '../../auth/providers/auth_provider.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final NotificationService _notificationService = NotificationService();
  final DashboardService _dashboardService = DashboardService();
  
  int _unreadCount = 0;
  List<Map<String, dynamic>> _upcomingSessions = [];
  List<Map<String, dynamic>> _recentActivity = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

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
    setState(() => _isLoading = true);
    
    try {
      final response = await _dashboardService.getStudentDashboard();
      
      if (response.success && response.data != null) {
        final data = response.data!['data'] ?? response.data;
        
        setState(() {
          _upcomingSessions = List<Map<String, dynamic>>.from(data['upcomingSessions'] ?? []);
          _recentActivity = List<Map<String, dynamic>>.from(data['recentActivity'] ?? []);
          _stats = Map<String, dynamic>.from(data['stats'] ?? {});
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
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
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getActivityIcon(String iconName) {
    switch (iconName) {
      case 'check_circle':
        return Icons.check_circle;
      case 'done_all':
        return Icons.done_all;
      case 'cancel':
        return Icons.cancel;
      case 'schedule':
        return Icons.schedule;
      case 'notifications':
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String colorName) {
    switch (colorName) {
      case 'green':
        return Colors.green;
      case 'teal':
        return Colors.teal;
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Student Dashboard'),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _unreadCount > 99 ? '99+' : '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
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
                        user?.fullName ?? 'Student',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSM),
                      Text(
                        'Ready to find your perfect tutor?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
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
                  childAspectRatio: 1.2, // Adjusted for better proportions
                  children: [
                    _buildActionCard(
                      context,
                      icon: Icons.search,
                      title: 'Find Tutors',
                      subtitle: 'Browse tutors',
                      onTap: () {
                        context.push('/tutor-search');
                      },
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.calendar_today,
                      title: 'My Bookings',
                      subtitle: 'View sessions',
                      onTap: () {
                        context.push('/student-bookings');
                      },
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.person,
                      title: 'My Profile',
                      subtitle: 'Update info',
                      onTap: () {
                        context.push('/student-profile');
                      },
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.chat,
                      title: 'Messages',
                      subtitle: 'Chat with tutors',
                      onTap: () {
                        context.push('/student-messages');
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingXL),
                
                // Upcoming Sessions Section
                if (_upcomingSessions.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upcoming Sessions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/student-bookings'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  ...(_upcomingSessions.map((session) => _buildSessionCard(session))),
                  const SizedBox(height: AppTheme.spacingXL),
                ],
                
                // Recent Activity Section
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingLG),
                
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _recentActivity.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppTheme.spacingLG),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
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
                                  'Start by finding a tutor to begin your learning journey!',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppTheme.spacingMD),
                                ElevatedButton(
                                  onPressed: () => context.push('/tutor-search'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Find Tutors'),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: _recentActivity.map((activity) => _buildActivityItem(activity)).toList(),
                          ),
                
                const SizedBox(height: AppTheme.spacingXL),
                
                // Debug Info (Development only)
                if (user != null) ...[
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
                          'User Info (Debug)',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSM),
                        Text('Email: ${user.email}', style: TextStyle(color: Colors.blue[700])),
                        Text('Role: ${user.role.displayName}', style: TextStyle(color: Colors.blue[700])),
                        Text('Email Verified: ${user.isEmailVerified}', style: TextStyle(color: Colors.blue[700])),
                        Text('Profile Completed: ${user.profileCompleted}', style: TextStyle(color: Colors.blue[700])),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final sessionDate = DateTime.tryParse(session['sessionDate'] ?? '');
    final dateStr = sessionDate != null ? _formatDate(sessionDate) : 'TBD';
    final timeStr = '${session['startTime']} - ${session['endTime']}';
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: session['tutorPhoto'] != null 
              ? NetworkImage(session['tutorPhoto'])
              : null,
          child: session['tutorPhoto'] == null 
              ? Text(session['tutorName']?.substring(0, 1) ?? 'T')
              : null,
        ),
        title: Text(
          session['tutorName'] ?? 'Tutor',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session['subject'] ?? 'Session'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
        trailing: session['status'] == 'pending'
            ? Chip(
                label: const Text('Pending', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.orange[100],
              )
            : null,
        onTap: () {
          context.push('/student-bookings');
        },
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final time = DateTime.tryParse(activity['time'] ?? '');
    final timeAgo = time != null ? _getTimeAgo(time) : '';
    final icon = _getActivityIcon(activity['icon'] ?? 'info');
    final color = _getActivityColor(activity['color'] ?? 'grey');
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        activity['message'] ?? '',
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        timeAgo,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      dense: true,
    );
  }
}