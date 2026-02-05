import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
            'Help & Support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF6B7FA8), const Color(0xFF8B9DC3)]
                      : [const Color(0xFF0F3460), const Color(0xFF16213E)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.support_agent_rounded,
                    size: 64,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  const Text(
                    'How can we help you?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  Text(
                    'We\'re here to assist you with any questions or issues',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingXL),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F3460),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingLG),
            
            _buildActionCard(
              context,
              icon: Icons.add_circle_outline,
              title: 'Create Support Ticket',
              subtitle: 'Get help from our support team',
              color: Colors.blue,
              onTap: () => context.push('/support/create-ticket'),
              isDark: isDark,
            ),
            
            const SizedBox(height: AppTheme.spacingMD),
            
            _buildActionCard(
              context,
              icon: Icons.history,
              title: 'My Tickets',
              subtitle: 'View your support requests',
              color: Colors.orange,
              onTap: () => context.push('/support/tickets'),
              isDark: isDark,
            ),
            
            const SizedBox(height: AppTheme.spacingMD),
            
            _buildActionCard(
              context,
              icon: Icons.question_answer,
              title: 'FAQs',
              subtitle: 'Find answers to common questions',
              color: Colors.green,
              onTap: () => context.push('/support/faqs'),
              isDark: isDark,
            ),
            
            const SizedBox(height: AppTheme.spacingXL),
            
            // Contact Information
            Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F3460),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingLG),
            
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
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
              child: Column(
                children: [
                  _buildContactItem(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: 'support@tutorapp.com',
                    isDark: isDark,
                  ),
                  const Divider(height: 32),
                  _buildContactItem(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    value: '+251 123 456 789',
                    isDark: isDark,
                  ),
                  const Divider(height: 32),
                  _buildContactItem(
                    icon: Icons.access_time,
                    title: 'Support Hours',
                    value: 'Mon-Fri: 9AM - 6PM',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F3460),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark 
                          ? Colors.white.withOpacity(0.6)
                          : const Color(0xFF6B7FA8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark 
                  ? Colors.white.withOpacity(0.5)
                  : const Color(0xFF6B7FA8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDark ? const Color(0xFF6B7FA8) : const Color(0xFF0F3460),
            size: 20,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark 
                      ? Colors.white.withOpacity(0.6)
                      : const Color(0xFF6B7FA8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F3460),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
