import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Notification preferences
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  
  // Notification types
  bool _bookingNotifications = true;
  bool _messageNotifications = true;
  bool _reviewNotifications = true;
  bool _paymentNotifications = true;
  bool _reminderNotifications = true;
  bool _promotionalNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    
    try {
      final apiService = ApiService();
      final response = await apiService.get('/users/notification-preferences');
      
      if (response.success && response.data != null) {
        final prefs = response.data;
        setState(() {
          _emailNotifications = prefs['emailNotifications'] ?? true;
          _pushNotifications = prefs['pushNotifications'] ?? true;
          _bookingNotifications = prefs['bookingNotifications'] ?? true;
          _messageNotifications = prefs['messageNotifications'] ?? true;
          _reviewNotifications = prefs['reviewNotifications'] ?? true;
          _paymentNotifications = prefs['paymentNotifications'] ?? true;
          _reminderNotifications = prefs['reminderNotifications'] ?? true;
          _promotionalNotifications = prefs['promotionalNotifications'] ?? false;
        });
      }
    } catch (e) {
      print('❌ Failed to load preferences: $e');
      // Use defaults if loading fails
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    
    try {
      final apiService = ApiService();
      final response = await apiService.put('/users/notification-preferences', data: {
        'emailNotifications': _emailNotifications,
        'pushNotifications': _pushNotifications,
        'bookingNotifications': _bookingNotifications,
        'messageNotifications': _messageNotifications,
        'reviewNotifications': _reviewNotifications,
        'paymentNotifications': _paymentNotifications,
        'reminderNotifications': _reminderNotifications,
        'promotionalNotifications': _promotionalNotifications,
      });
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification preferences saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response.message ?? 'Failed to save preferences');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF16213E) : Colors.white,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isDark 
                ? [const Color(0xFF6B7FA8), const Color(0xFF8B9DC3)]
                : [const Color(0xFF0F3460), const Color(0xFF16213E)],
          ).createShader(bounds),
          child: const Text(
            'Notification Preferences',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSaving ? null : _savePreferences,
              child: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
                        ),
                      ),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // General Settings
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF16213E), const Color(0xFF0F3460).withOpacity(0.8)]
                            : [Colors.white, const Color(0xFFF5F7FA)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppTheme.spacingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'General Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F3460),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        SwitchListTile(
                          title: Text(
                            'Email Notifications',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F3460),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Receive notifications via email',
                            style: TextStyle(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.6)
                                  : const Color(0xFF6B7FA8),
                            ),
                          ),
                          value: _emailNotifications,
                          onChanged: (value) => setState(() => _emailNotifications = value),
                          contentPadding: EdgeInsets.zero,
                          activeColor: isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
                        ),
                        SwitchListTile(
                          title: Text(
                            'Push Notifications',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F3460),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Receive push notifications on your device',
                            style: TextStyle(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.6)
                                  : const Color(0xFF6B7FA8),
                            ),
                          ),
                          value: _pushNotifications,
                          onChanged: (value) => setState(() => _pushNotifications = value),
                          contentPadding: EdgeInsets.zero,
                          activeColor: isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Notification Types
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF16213E), const Color(0xFF0F3460).withOpacity(0.8)]
                            : [Colors.white, const Color(0xFFF5F7FA)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppTheme.spacingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Types',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F3460),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        _buildNotificationTypeSwitch(
                          'Booking Notifications',
                          'New bookings, cancellations, and updates',
                          _bookingNotifications,
                          (value) => setState(() => _bookingNotifications = value),
                          isDark,
                        ),
                        _buildNotificationTypeSwitch(
                          'Message Notifications',
                          'New messages from students',
                          _messageNotifications,
                          (value) => setState(() => _messageNotifications = value),
                          isDark,
                        ),
                        _buildNotificationTypeSwitch(
                          'Review Notifications',
                          'New reviews and ratings',
                          _reviewNotifications,
                          (value) => setState(() => _reviewNotifications = value),
                          isDark,
                        ),
                        _buildNotificationTypeSwitch(
                          'Payment Notifications',
                          'Payment confirmations and updates',
                          _paymentNotifications,
                          (value) => setState(() => _paymentNotifications = value),
                          isDark,
                        ),
                        _buildNotificationTypeSwitch(
                          'Reminder Notifications',
                          'Session reminders and upcoming bookings',
                          _reminderNotifications,
                          (value) => setState(() => _reminderNotifications = value),
                          isDark,
                        ),
                        _buildNotificationTypeSwitch(
                          'Promotional Notifications',
                          'Tips, updates, and promotional content',
                          _promotionalNotifications,
                          (value) => setState(() => _promotionalNotifications = value),
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLG),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460)).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
                        ),
                        const SizedBox(width: AppTheme.spacingMD),
                        Expanded(
                          child: Text(
                            'You can customize which notifications you receive. Important notifications like booking confirmations will always be sent.',
                            style: TextStyle(
                              color: isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF0F3460),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationTypeSwitch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F3460),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark 
              ? Colors.white.withOpacity(0.6)
              : const Color(0xFF6B7FA8),
          fontSize: 12,
        ),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeColor: isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
    );
  }
}
