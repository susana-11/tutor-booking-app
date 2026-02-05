import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

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

class _TutorDashboardScreenState extends State<TutorDashboardScreen>
    with SingleTickerProviderStateMixin {
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
  
  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
    _loadUnreadCount();
    
    _notificationService.notificationCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeIn,
    ));
    
    _fadeController?.forward();
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
      final profileResponse = await _profileService.getTutorProfile();
      if (profileResponse.success && profileResponse.data != null) {
        final profile = profileResponse.data!;
        setState(() {
          _rating = (profile['rating'] ?? 0.0).toDouble();
        });
      }
      
      final bookingsResponse = await _bookingService.getBookings();
      if (bookingsResponse.success && bookingsResponse.data != null) {
        final bookings = bookingsResponse.data!;
        
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        _todaysSessions = bookings.where((booking) {
          final sessionDate = DateTime.tryParse(booking['sessionDate'] ?? '');
          if (sessionDate == null) return false;
          final sessionDay = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
          return sessionDay == today && booking['status'] == 'confirmed';
        }).length;
        
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
      // Fetch confirmed bookings
      final response = await _bookingService.getBookings(status: 'confirmed');
      
      if (response.success && response.data != null) {
        final bookings = response.data!;
        
        final now = DateTime.now();
        final upcoming = bookings.where((booking) {
          final sessionDate = DateTime.tryParse(booking['sessionDate'] ?? booking['date'] ?? '');
          if (sessionDate == null) return false;
          
          // Parse start time to get exact session datetime
          final startTime = booking['startTime'] ?? booking['time']?.toString().split(' - ')[0];
          if (startTime != null && startTime.isNotEmpty) {
            try {
              final timeParts = startTime.split(':');
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              final sessionDateTime = DateTime(
                sessionDate.year,
                sessionDate.month,
                sessionDate.day,
                hour,
                minute,
              );
              return sessionDateTime.isAfter(now);
            } catch (e) {
              // If time parsing fails, just check date
              return sessionDate.isAfter(now);
            }
          }
          
          return sessionDate.isAfter(now);
        }).toList();
        
        // Sort by date and time
        upcoming.sort((a, b) {
          final dateA = DateTime.tryParse(a['sessionDate'] ?? a['date'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['sessionDate'] ?? b['date'] ?? '') ?? DateTime.now();
          return dateA.compareTo(dateB);
        });
        
        setState(() {
          _upcomingSessions = upcoming.take(5).toList();
        });
      }
    } catch (e) {
      print('❌ Error loading upcoming sessions: $e');
    } finally {
      setState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _loadRecentActivity() async {
    setState(() => _isLoadingActivity = true);
    
    try {
      final response = await _bookingService.getBookings();
      
      if (response.success && response.data != null) {
        final bookings = response.data!;
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
              'color': const Color(0xFF6B7FA8),
              'bookingId': booking['id'],
            });
          } else if (status == 'confirmed') {
            activities.add({
              'type': 'confirmed',
              'message': 'Booking confirmed with $studentName',
              'time': timeAgo,
              'icon': Icons.check_circle,
              'color': const Color(0xFF7FA87F),
              'bookingId': booking['id'],
            });
          } else if (status == 'completed') {
            activities.add({
              'type': 'completed',
              'message': 'Session completed with $studentName',
              'time': timeAgo,
              'icon': Icons.done_all,
              'color': const Color(0xFF8B9DC3),
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
    // Convert to local time if it's UTC
    final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final now = DateTime.now();
    final difference = now.difference(localDateTime);
    
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _buildModernAppBar(isDark),
          body: Stack(
            children: [
              _buildElegantBackground(isDark),
              
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  color: isDark ? const Color(0xFF8B9DC3) : const Color(0xFF6B7FA8),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppTheme.spacingLG),
                    child: FadeTransition(
                      opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfessionalWelcomeCard(user, isDark),
                          const SizedBox(height: AppTheme.spacingXL),
                          _buildStatsGrid(isDark),
                          const SizedBox(height: AppTheme.spacingXL),
                          _buildSectionHeader('Upcoming Sessions', isDark),
                          const SizedBox(height: AppTheme.spacingLG),
                          _buildUpcomingSessionsList(isDark),
                          const SizedBox(height: AppTheme.spacingXL),
                          _buildSectionHeader('Recent Activity', isDark),
                          const SizedBox(height: AppTheme.spacingLG),
                          _buildRecentActivity(isDark),
                          const SizedBox(height: AppTheme.spacingXL),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildModernBottomNav(context, isDark),
        );
      },
    );
  }

  Widget _buildModernBottomNav(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF1A1A2E).withOpacity(0.95),
                  const Color(0xFF1A1A2E),
                ]
              : [
                  Colors.white.withOpacity(0.95),
                  Colors.white,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF6B7FA8).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isActive: true,
                isDark: isDark,
                onTap: () {},
              ),
              _buildNavItem(
                context: context,
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month_rounded,
                label: 'Schedule',
                isActive: false,
                isDark: isDark,
                onTap: () => context.push('/tutor-schedule'),
              ),
              _buildNavItem(
                context: context,
                icon: Icons.book_outlined,
                activeIcon: Icons.book_rounded,
                label: 'Bookings',
                isActive: false,
                isDark: isDark,
                onTap: () => context.push('/tutor-bookings'),
              ),
              _buildNavItem(
                context: context,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Messages',
                isActive: false,
                isDark: isDark,
                onTap: () => context.push('/tutor-messages'),
              ),
              _buildNavItem(
                context: context,
                icon: Icons.person_outline,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: false,
                isDark: isDark,
                onTap: () => context.push('/tutor-profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeColor = isDark ? const Color(0xFF8B9DC3) : const Color(0xFF6B7FA8);
    final inactiveColor = isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF90A4AE);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? activeColor.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: isActive ? activeColor : inactiveColor,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? activeColor : inactiveColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
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
          'Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/tutor-notifications'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: isDark ? Colors.white70 : const Color(0xFF5F6F94),
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFB39DDB), Color(0xFF9FA8DA)],
                            ),
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
      ],
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

  Widget _buildProfessionalWelcomeCard(user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF5F6F94),
                  const Color(0xFF6B7FA8),
                  const Color(0xFF8B9DC3),
                ]
              : [
                  const Color(0xFFFFFFFF),
                  const Color(0xFFF8F9FA),
                  const Color(0xFFF5F7FA),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : const Color(0xFFE0E0E0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF5F6F94).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : const Color(0xFF6B7FA8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.fullName ?? 'Tutor',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF2C3E50),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : const Color(0xFF8B9DC3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: isDark
                      ? Colors.white70
                      : const Color(0xFF6B7FA8),
                ),
                const SizedBox(width: 6),
                Text(
                  'Ready to inspire students today',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white70
                        : const Color(0xFF6B7FA8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white : const Color(0xFF2C3E50),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard(
          'Today\'s Sessions',
          _isLoadingStats ? '...' : '$_todaysSessions',
          Icons.today_outlined,
          const Color(0xFF6B7FA8),
          isDark,
        ),
        _buildStatCard(
          'This Month',
          _isLoadingStats ? '...' : '\$${_thisMonthEarnings.toStringAsFixed(0)}',
          Icons.attach_money_outlined,
          const Color(0xFF7FA87F),
          isDark,
        ),
        _buildStatCard(
          'Rating',
          _isLoadingStats ? '...' : _rating > 0 ? _rating.toStringAsFixed(1) : 'N/A',
          Icons.star_outline,
          const Color(0xFFD4A574),
          isDark,
        ),
        _buildStatCard(
          'Total Students',
          _isLoadingStats ? '...' : '$_totalStudents',
          Icons.people_outline,
          const Color(0xFF8B9DC3),
          isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color accentColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                : accentColor.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 18,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF2C3E50),
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withOpacity(0.6)
                      : const Color(0xFF6B7FA8),
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildUpcomingSessionsList(bool isDark) {
    if (_isLoadingSessions) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? const Color(0xFF8B9DC3) : const Color(0xFF6B7FA8),
            ),
          ),
        ),
      );
    }

    if (_upcomingSessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
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
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : const Color(0xFFB0BEC5),
            ),
            const SizedBox(height: 16),
            Text(
              'No upcoming sessions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : const Color(0xFF6B7FA8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your confirmed sessions will appear here',
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
      );
    }

    return Column(
      children: _upcomingSessions.map((session) {
        final sessionDate = DateTime.tryParse(session['sessionDate'] ?? session['date'] ?? '');
        final studentName = session['studentName'] ?? 'Student';
        
        // Handle subject - can be string or object with name field
        String subject = 'Session';
        if (session['subject'] is String) {
          subject = session['subject'];
        } else if (session['subject'] is Map && session['subject']['name'] != null) {
          subject = session['subject']['name'];
        }
        
        // Handle time - can be in different formats
        String startTime = '';
        String endTime = '';
        if (session['startTime'] != null) {
          startTime = session['startTime'];
          endTime = session['endTime'] ?? '';
        } else if (session['time'] != null) {
          final timeParts = session['time'].toString().split(' - ');
          startTime = timeParts.isNotEmpty ? timeParts[0] : '';
          endTime = timeParts.length > 1 ? timeParts[1] : '';
        }
        
        final mode = session['mode'] ?? session['sessionType'] ?? 'Online';
        final displayMode = mode == 'online' || mode == 'Online' ? 'Online' : 'In-Person';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6B7FA8).withOpacity(0.2),
                      const Color(0xFF8B9DC3).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    studentName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF6B7FA8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$subject • $displayMode',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withOpacity(0.6)
                            : const Color(0xFF6B7FA8),
                      ),
                    ),
                    if (sessionDate != null && startTime.isNotEmpty)
                      Text(
                        '${_formatDate(sessionDate)} • $startTime${endTime.isNotEmpty ? ' - $endTime' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.5)
                              : const Color(0xFF90A4AE),
                        ),
                      )
                    else if (sessionDate != null)
                      Text(
                        _formatDate(sessionDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.5)
                              : const Color(0xFF90A4AE),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7FA87F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Confirmed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7FA87F),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivity(bool isDark) {
    if (_isLoadingActivity) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? const Color(0xFF8B9DC3) : const Color(0xFF6B7FA8),
            ),
          ),
        ),
      );
    }

    if (_recentActivity.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
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
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : const Color(0xFFB0BEC5),
            ),
            const SizedBox(height: 16),
            Text(
              'No recent activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : const Color(0xFF6B7FA8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your recent bookings will appear here',
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
      );
    }

    return Column(
      children: _recentActivity.map((activity) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                    : (activity['color'] as Color).withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (activity['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  activity['icon'] as IconData,
                  color: activity['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['message'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity['time'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : const Color(0xFF90A4AE),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    super.dispose();
  }
}
