import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math' as math;

import '../../../core/theme/app_theme.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/change_password_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tutor/screens/notification_preferences_screen.dart';
import '../../support/screens/help_support_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({Key? key}) : super(key: key);

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  
  String _selectedGrade = 'High School (9-12)';
  List<String> _selectedSubjects = [];
  String _preferredMode = 'Both';
  bool _isUploadingImage = false;
  
  AnimationController? _fadeController;
  AnimationController? _floatController;
  Animation<double>? _fadeAnimation;
  
  final List<String> _grades = [
    'Elementary (K-5)',
    'Middle School (6-8)',
    'High School (9-12)',
    'College/University',
  ];
  
  final List<String> _subjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'History',
    'Computer Science',
    'Art',
    'Music',
    'Languages',
  ];
  
  final List<String> _modes = [
    'Online',
    'In-Person',
    'Both',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    // Fade animation
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
    
    // Float animation for decorative elements
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    
    // Start animations
    _fadeController?.forward();
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      // TODO: Load additional profile data from API
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(isDark),
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(isDark),
          
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              child: FadeTransition(
                opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppTheme.spacingMD),
                      
                      // Profile Picture Section
                      _buildModernProfileHeader(isDark),
                      
                      const SizedBox(height: AppTheme.spacingXL),
                      
                      // Personal Information Card
                      _buildModernCard(
                        isDark: isDark,
                        title: 'Personal Information',
                        icon: Icons.person_rounded,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModernTextField(
                                    controller: _firstNameController,
                                    label: 'First Name',
                                    icon: Icons.badge_rounded,
                                    isDark: isDark,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingMD),
                                Expanded(
                                  child: _buildModernTextField(
                                    controller: _lastNameController,
                                    label: 'Last Name',
                                    icon: Icons.badge_rounded,
                                    isDark: isDark,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingLG),
                            _buildModernTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone_rounded,
                              isDark: isDark,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: AppTheme.spacingLG),
                            _buildModernTextField(
                              controller: _bioController,
                              label: 'Bio (Optional)',
                              icon: Icons.edit_note_rounded,
                              isDark: isDark,
                              maxLines: 3,
                              hint: 'Tell us a bit about yourself...',
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacingLG),
                      
                      // Academic Information Card
                      _buildModernCard(
                        isDark: isDark,
                        title: 'Academic Information',
                        icon: Icons.school_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildModernDropdown(
                              value: _selectedGrade,
                              label: 'Current Grade Level',
                              icon: Icons.grade_rounded,
                              items: _grades,
                              isDark: isDark,
                              onChanged: (value) => setState(() => _selectedGrade = value!),
                            ),
                            const SizedBox(height: AppTheme.spacingLG),
                            Text(
                              'Subjects of Interest',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingSM),
                            Wrap(
                              spacing: AppTheme.spacingSM,
                              runSpacing: AppTheme.spacingSM,
                              children: _subjects.map((subject) => _buildModernChip(
                                label: subject,
                                selected: _selectedSubjects.contains(subject),
                                isDark: isDark,
                                onTap: () {
                                  setState(() {
                                    if (_selectedSubjects.contains(subject)) {
                                      _selectedSubjects.remove(subject);
                                    } else {
                                      _selectedSubjects.add(subject);
                                    }
                                  });
                                },
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacingLG),
                      
                      // Learning Preferences Card
                      _buildModernCard(
                        isDark: isDark,
                        title: 'Learning Preferences',
                        icon: Icons.settings_suggest_rounded,
                        child: _buildModernDropdown(
                          value: _preferredMode,
                          label: 'Preferred Learning Mode',
                          icon: Icons.laptop_chromebook_rounded,
                          items: _modes,
                          isDark: isDark,
                          onChanged: (value) => setState(() => _preferredMode = value!),
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacingLG),
                      
                      // Account Settings Card
                      _buildModernCard(
                        isDark: isDark,
                        title: 'Account Settings',
                        icon: Icons.settings_rounded,
                        child: Column(
                          children: [
                            _buildModernThemeToggle(isDark),
                            const SizedBox(height: AppTheme.spacingSM),
                            _buildModernSettingsTile(
                              icon: Icons.notifications_rounded,
                              title: 'Notifications',
                              subtitle: 'Manage your notification preferences',
                              isDark: isDark,
                              onTap: _manageNotifications,
                            ),
                            const SizedBox(height: AppTheme.spacingSM),
                            _buildModernSettingsTile(
                              icon: Icons.lock_rounded,
                              title: 'Change Password',
                              subtitle: 'Update your account password',
                              isDark: isDark,
                              onTap: _changePassword,
                            ),
                            const SizedBox(height: AppTheme.spacingSM),
                            _buildModernSettingsTile(
                              icon: Icons.help_rounded,
                              title: 'Help & Support',
                              subtitle: 'Get help or contact support',
                              isDark: isDark,
                              onTap: _getHelp,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacingXL),
                      
                      // Save Button
                      _buildGradientButton(
                        label: 'Save Profile',
                        icon: Icons.save_rounded,
                        isDark: isDark,
                        onPressed: _saveProfile,
                      ),
                      
                      const SizedBox(height: AppTheme.spacingMD),
                      
                      // Logout Button
                      _buildOutlineButton(
                        label: 'Logout',
                        icon: Icons.logout_rounded,
                        isDark: isDark,
                        onPressed: _logout,
                      ),
                      
                      const SizedBox(height: AppTheme.spacingXL),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(12),
            child: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : AppTheme.textPrimaryColor,
            ),
          ),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
        ).createShader(bounds),
        child: const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark) {
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
                  const Color(0xFFF8F9FA),
                  const Color(0xFFE9ECEF),
                  const Color(0xFFDEE2E6),
                ],
        ),
      ),
    );
  }

  Widget _buildModernProfileHeader(bool isDark) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        final profilePicture = user?.profilePicture;
        
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6B46C1),
                Color(0xFF805AD5),
                Color(0xFF38B2AC),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B46C1).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  // Gradient border
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.white, Colors.white70],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                          ? NetworkImage(profilePicture)
                          : null,
                      onBackgroundImageError: profilePicture != null
                          ? (exception, stackTrace) {
                              print('Error loading profile picture: $exception');
                            }
                          : null,
                      child: _isUploadingImage
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B46C1)),
                            )
                          : (profilePicture == null || profilePicture.isEmpty)
                              ? Text(
                                  user?.fullName.split(' ').map((n) => n[0]).join() ?? 'U',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6B46C1),
                                  ),
                                )
                              : null,
                    ),
                  ),
                  
                  // Camera button
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B46C1).withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isUploadingImage ? null : _changeProfilePicture,
                          borderRadius: BorderRadius.circular(50),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingLG),
              
              Text(
                user?.fullName ?? 'Student',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingSM),
              
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.email_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLG),
          child,
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.textPrimaryColor,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : AppTheme.textDisabledColor,
              ),
              prefixIcon: Icon(
                icon,
                color: isDark ? Colors.white.withOpacity(0.5) : AppTheme.textSecondaryColor,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required bool isDark,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            )).toList(),
            onChanged: onChanged,
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.textPrimaryColor,
            ),
            dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: isDark ? Colors.white.withOpacity(0.5) : AppTheme.textSecondaryColor,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernChip({
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                  )
                : null,
            color: selected
                ? null
                : isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : isDark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : isDark
                          ? Colors.white70
                          : AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : AppTheme.textSecondaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernThemeToggle(bool isDark) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        String currentTheme = 'System';
        IconData themeIcon = Icons.brightness_auto_rounded;
        
        if (themeProvider.themeMode == ThemeMode.light) {
          currentTheme = 'Light';
          themeIcon = Icons.light_mode_rounded;
        } else if (themeProvider.themeMode == ThemeMode.dark) {
          currentTheme = 'Dark';
          themeIcon = Icons.dark_mode_rounded;
        }
        
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showThemeDialog(themeProvider),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        themeIcon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Theme',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentTheme,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : AppTheme.textSecondaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B46C1).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.red,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _isUploadingImage = true);

        final File imageFile = File(pickedFile.path);
        print('📸 Uploading image from: ${pickedFile.path}');
        
        final response = await _profileService.uploadProfilePicture(imageFile);

        print('📸 Upload response: ${response.success}');
        print('📸 Upload data: ${response.data}');
        print('📸 Upload error: ${response.error}');

        if (response.success) {
          // Refresh auth provider to update profile picture
          print('📸 Refreshing auth status...');
          await context.read<AuthProvider>().checkAuthStatus();
          
          // Get updated user
          final updatedUser = context.read<AuthProvider>().user;
          print('📸 Updated user profile picture: ${updatedUser?.profilePicture}');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload: ${response.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('📸 Error picking/uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save profile data to API
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _manageNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationPreferencesScreen(),
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  void _getHelp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HelpSupportScreen(),
      ),
    );
  }

  void _showThemeDialog(ThemeProvider themeProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.palette_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Choose Theme',
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              icon: Icons.light_mode_rounded,
              title: 'Light Mode',
              subtitle: 'Always use light theme',
              isSelected: themeProvider.themeMode == ThemeMode.light,
              isDark: isDark,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              icon: Icons.dark_mode_rounded,
              title: 'Dark Mode',
              subtitle: 'Always use dark theme',
              isSelected: themeProvider.themeMode == ThemeMode.dark,
              isDark: isDark,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              icon: Icons.brightness_auto_rounded,
              title: 'System Default',
              subtitle: 'Follow device settings',
              isSelected: themeProvider.themeMode == ThemeMode.system,
              isDark: isDark,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
              )
            : null,
        color: isSelected
            ? null
            : isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Colors.transparent
              : isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : isDark
                          ? Colors.white70
                          : AppTheme.textPrimaryColor,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : isDark
                                  ? Colors.white
                                  : AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    _floatController?.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}