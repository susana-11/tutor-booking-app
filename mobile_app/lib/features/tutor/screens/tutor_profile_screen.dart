import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/tutor_service.dart';
import '../../auth/providers/auth_provider.dart';

class TutorProfileScreen extends StatefulWidget {
  const TutorProfileScreen({super.key});

  @override
  State<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<TutorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _educationController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  
  List<String> _selectedSubjects = [];
  List<String> _selectedGrades = [];
  String _teachingMode = 'Both';
  bool _profileVisible = true;
  bool _acceptingBookings = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  double _actualRating = 0.0;
  int _totalReviews = 0;
  
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
    'Economics',
    'Psychology',
  ];
  
  final List<String> _grades = [
    'Elementary (K-5)',
    'Middle School (6-8)',
    'High School (9-12)',
    'College/University',
    'Adult Education',
  ];
  
  final List<String> _modes = [
    'Online',
    'In-Person',
    'Both',
  ];

  @override
  void initState() {
    super.initState();
    _loadTutorData();
  }

  Future<void> _loadTutorData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
      }

      print('🔄 Loading tutor profile data...');
      
      // Load tutor profile data from API
      final response = await _profileService.getTutorProfile();
      
      print('📋 Profile response: ${response.success}');
      print('📋 Profile data: ${response.data}');
      
      if (response.success && response.data != null) {
        final profile = response.data!;
        
        print('📋 Mapping profile data to form fields...');
        
        setState(() {
          // Basic user info
          if (profile['firstName'] != null) _firstNameController.text = profile['firstName'];
          if (profile['lastName'] != null) _lastNameController.text = profile['lastName'];
          
          // Profile specific data
          _phoneController.text = profile['phone']?.toString() ?? '';
          _bioController.text = profile['bio']?.toString() ?? '';
          _experienceController.text = profile['experience']?.toString() ?? '';
          _educationController.text = profile['education']?.toString() ?? '';
          _hourlyRateController.text = profile['hourlyRate']?.toString() ?? '';
          
          // Subjects and grades
          if (profile['subjects'] is List) {
            _selectedSubjects = List<String>.from(profile['subjects']);
            print('📋 Loaded subjects: $_selectedSubjects');
          }
          
          if (profile['grades'] is List) {
            _selectedGrades = List<String>.from(profile['grades']);
            print('📋 Loaded grades: $_selectedGrades');
          }
          
          // Teaching mode
          final isOnline = profile['isAvailableOnline'] == true;
          final isInPerson = profile['isAvailableInPerson'] == true;
          
          if (isOnline && isInPerson) {
            _teachingMode = 'Both';
          } else if (isOnline) {
            _teachingMode = 'Online';
          } else if (isInPerson) {
            _teachingMode = 'In-Person';
          } else {
            _teachingMode = 'Both'; // Default
          }
          
          print('📋 Teaching mode: $_teachingMode');
          
          // Profile settings
          _profileVisible = profile['isActive'] == true;
          _acceptingBookings = profile['isAvailable'] == true;
          
          // Rating and reviews
          _actualRating = (profile['rating'] ?? 0.0).toDouble();
          _totalReviews = profile['totalReviews'] ?? 0;
        });
        
        print('✅ Profile data loaded successfully');
      } else {
        // Profile doesn't exist yet - this is okay, user can create/update it
        print('📋 Tutor profile not found - user can create one');
      }
    } catch (e) {
      print('❌ Failed to load profile: $e');
      // Don't show error for missing profile - it's expected for new tutors
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadTutorData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Profile',
          ),
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture and Status
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            final user = authProvider.user;
                            final profilePicture = user?.profilePicture;
                            
                            return CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                                  ? NetworkImage(profilePicture)
                                  : null,
                              onBackgroundImageError: profilePicture != null
                                  ? (exception, stackTrace) {
                                      print('Error loading profile picture: $exception');
                                    }
                                  : null,
                              child: _isUploadingImage
                                  ? const CircularProgressIndicator()
                                  : (profilePicture == null || profilePicture.isEmpty)
                                      ? Text(
                                          user?.fullName.split(' ').map((n) => n[0]).join() ?? 'T',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        )
                                      : null,
                            );
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: IconButton(
                              onPressed: _isUploadingImage ? null : _changeProfilePicture,
                              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSM),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        final user = authProvider.user;
                        return Column(
                          children: [
                            Text(
                              user?.email ?? '',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingSM),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.spacingXS),
                                Text(
                                  _totalReviews > 0 
                                      ? '${_actualRating.toStringAsFixed(1)} ($_totalReviews reviews)'
                                      : 'No reviews yet',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Profile Visibility Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Settings',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMD),
                      SwitchListTile(
                        title: const Text('Profile Visible'),
                        subtitle: const Text('Students can find and view your profile'),
                        value: _profileVisible,
                        onChanged: (value) => _toggleProfileVisibility(value),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        title: const Text('Accepting Bookings'),
                        subtitle: const Text('Students can book sessions with you'),
                        value: _acceptingBookings,
                        onChanged: (value) => _toggleAcceptingBookings(value),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Personal Information
              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingLG),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingLG),
              
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: AppTheme.spacingLG),
              
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  hintText: 'Tell students about yourself, your teaching style, and experience...',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a bio';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Professional Information
              Text(
                'Professional Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingLG),
              
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Teaching Experience',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 5 years of tutoring experience',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your teaching experience';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppTheme.spacingLG),
              
              TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(
                  labelText: 'Education',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Master\'s in Mathematics, University Name',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your education background';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppTheme.spacingLG),
              
              // Subjects
              Text(
                'Subjects I Teach',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Wrap(
                spacing: AppTheme.spacingSM,
                runSpacing: AppTheme.spacingSM,
                children: _subjects.map((subject) => FilterChip(
                  label: Text(subject),
                  selected: _selectedSubjects.contains(subject),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSubjects.add(subject);
                      } else {
                        _selectedSubjects.remove(subject);
                      }
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  checkmarkColor: AppTheme.primaryColor,
                )).toList(),
              ),
              
              const SizedBox(height: AppTheme.spacingLG),
              
              // Grade Levels
              Text(
                'Grade Levels I Teach',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Wrap(
                spacing: AppTheme.spacingSM,
                runSpacing: AppTheme.spacingSM,
                children: _grades.map((grade) => FilterChip(
                  label: Text(grade),
                  selected: _selectedGrades.contains(grade),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGrades.add(grade);
                      } else {
                        _selectedGrades.remove(grade);
                      }
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  checkmarkColor: AppTheme.primaryColor,
                )).toList(),
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Teaching Preferences
              Text(
                'Teaching Preferences',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingLG),
              
              DropdownButtonFormField<String>(
                value: _teachingMode,
                decoration: const InputDecoration(
                  labelText: 'Teaching Mode',
                  border: OutlineInputBorder(),
                ),
                items: _modes.map((mode) => DropdownMenuItem(
                  value: mode,
                  child: Text(mode),
                )).toList(),
                onChanged: (value) => setState(() => _teachingMode = value!),
              ),
              
              const SizedBox(height: AppTheme.spacingLG),
              
              TextFormField(
                controller: _hourlyRateController,
                decoration: const InputDecoration(
                  labelText: 'Hourly Rate (\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your hourly rate';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null || rate <= 0) {
                    return 'Please enter a valid rate';
                  }
                  return null;
                },
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
              
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Manage Availability'),
                subtitle: const Text('Set your teaching schedule'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => context.push('/tutor-schedule'),
              ),
              
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('View Analytics'),
                subtitle: const Text('See your performance metrics'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => context.push('/tutor-analytics'),
              ),
              
              ListTile(
                leading: const Icon(Icons.reviews),
                title: const Text('My Reviews'),
                subtitle: const Text('View student feedback'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => context.push('/tutor-reviews'),
              ),
              
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Earnings'),
                subtitle: const Text('Track your income'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => context.push('/tutor-earnings'),
              ),
              
              const SizedBox(height: AppTheme.spacingLG),
              
              // Account Settings
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                subtitle: const Text('Manage your notification preferences'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _manageNotifications,
              ),
              
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Change Password'),
                subtitle: const Text('Update your account password'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _changePassword,
              ),
              
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                subtitle: const Text('Get help or contact support'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _getHelp,
              ),
              
              const SizedBox(height: AppTheme.spacingLG),
              
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                  ),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
            ],
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

  Future<void> _toggleProfileVisibility(bool isActive) async {
    try {
      final tutorService = TutorService();
      final response = await tutorService.toggleProfileVisibility(isActive);
      
      if (response.success) {
        setState(() => _profileVisible = isActive);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isActive 
                  ? 'Profile is now visible to students' 
                  : 'Profile is now hidden from students'
              ),
              backgroundColor: isActive ? Colors.green : Colors.orange,
            ),
          );
        }
      } else {
        // Revert the switch if API call failed
        setState(() => _profileVisible = !isActive);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update visibility: ${response.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Revert the switch if error occurred
      setState(() => _profileVisible = !isActive);
      
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

  Future<void> _toggleAcceptingBookings(bool isAvailable) async {
    try {
      final tutorService = TutorService();
      final response = await tutorService.toggleAcceptingBookings(isAvailable);
      
      if (response.success) {
        setState(() => _acceptingBookings = isAvailable);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAvailable 
                  ? 'Now accepting new bookings' 
                  : 'Not accepting new bookings'
              ),
              backgroundColor: isAvailable ? Colors.green : Colors.orange,
            ),
          );
        }
      } else {
        // Revert the switch if API call failed
        setState(() => _acceptingBookings = !isAvailable);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update availability: ${response.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Revert the switch if error occurred
      setState(() => _acceptingBookings = !isAvailable);
      
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

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSubjects.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one subject'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (_selectedGrades.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one grade level'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() => _isSaving = true);
      
      try {
        // Update basic profile first
        final basicProfileResponse = await _profileService.updateProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phone: _phoneController.text.trim(),
          bio: _bioController.text.trim(),
        );

        if (!basicProfileResponse.success) {
          throw Exception(basicProfileResponse.error ?? 'Failed to update basic profile');
        }

        // Update tutor-specific profile
        final hourlyRate = double.tryParse(_hourlyRateController.text.trim());
        if (hourlyRate == null) {
          throw Exception('Please enter a valid hourly rate');
        }

        // Try to update first, if it fails (profile doesn't exist), create it
        var tutorProfileResponse = await _profileService.updateTutorProfile(
          subjects: _selectedSubjects,
          grades: _selectedGrades,
          hourlyRate: hourlyRate,
          bio: _bioController.text.trim(),
          experience: _experienceController.text.trim(),
          education: _educationController.text.trim(),
          isAvailableOnline: _teachingMode == 'Online' || _teachingMode == 'Both',
          isAvailableInPerson: _teachingMode == 'In-Person' || _teachingMode == 'Both',
        );

        // If update failed because profile doesn't exist, create it
        if (!tutorProfileResponse.success && (tutorProfileResponse.error?.contains('not found') == true || tutorProfileResponse.error?.contains('404') == true)) {
          print('📋 Profile not found, creating new profile...');
          tutorProfileResponse = await _profileService.createTutorProfile(
            subjects: _selectedSubjects,
            grades: _selectedGrades,
            hourlyRate: hourlyRate,
            bio: _bioController.text.trim(),
            experience: _experienceController.text.trim(),
            education: _educationController.text.trim(),
            isAvailableOnline: _teachingMode == 'Online' || _teachingMode == 'Both',
            isAvailableInPerson: _teachingMode == 'In-Person' || _teachingMode == 'Both',
          );
        }

        if (tutorProfileResponse.success) {
          // Update auth provider to reflect profile completion
          final authProvider = context.read<AuthProvider>();
          await authProvider.checkAuthStatus(); // This will refresh the user data
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(tutorProfileResponse.error ?? 'Failed to update tutor profile');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  void _manageNotifications() {
    // TODO: Navigate to notification settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings coming soon!')),
    );
  }

  void _changePassword() {
    // TODO: Navigate to change password screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change password coming soon!')),
    );
  }

  void _getHelp() {
    // TODO: Navigate to help screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help & support coming soon!')),
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }
}