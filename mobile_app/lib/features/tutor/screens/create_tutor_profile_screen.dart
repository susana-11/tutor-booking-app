import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/profile_service.dart';
import '../../auth/providers/auth_provider.dart';

class CreateTutorProfileScreen extends StatefulWidget {
  const CreateTutorProfileScreen({super.key});

  @override
  State<CreateTutorProfileScreen> createState() => _CreateTutorProfileScreenState();
}

class _CreateTutorProfileScreenState extends State<CreateTutorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _educationController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  
  List<String> _selectedSubjects = [];
  List<String> _selectedGrades = [];
  String _teachingMode = 'Both';
  bool _isLoading = false;
  
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tutor Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
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
        child: Form(
          key: _formKey,
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
                      'Welcome to TutorBooking!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSM),
                    Text(
                      'Let\'s set up your tutor profile to start connecting with students.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Bio Section
              Text(
                'Tell Students About Yourself',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingLG),
              
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  hintText: 'Describe your teaching style, experience, and what makes you a great tutor...',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a bio';
                  }
                  if (value.length < 50) {
                    return 'Bio should be at least 50 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Professional Information
              Text(
                'Professional Background',
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
                  hintText: 'e.g., 5 years of tutoring high school mathematics',
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
                  labelText: 'Education Background',
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
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Subjects
              Text(
                'What Subjects Do You Teach?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                'Select all subjects you\'re qualified to teach:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLG),
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
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Grade Levels
              Text(
                'What Grade Levels Do You Teach?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                'Select all grade levels you\'re comfortable teaching:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLG),
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
                  labelText: 'Preferred Teaching Mode',
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
                  hintText: 'e.g., 50',
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
                  if (rate < 10) {
                    return 'Minimum rate is \$10/hour';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Terms and Conditions
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLG),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700], size: 20),
                        const SizedBox(width: AppTheme.spacingSM),
                        Text(
                          'Before You Start',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSM),
                    Text(
                      '• Your profile will be reviewed by our team before going live\n'
                      '• You can update your profile anytime after creation\n'
                      '• Platform fee: 10% of each session payment\n'
                      '• Payments are processed weekly to your bank account',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Create Profile Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLG),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create My Tutor Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingLG),
              
              // Skip for now button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _skipForNow,
                  child: Text(
                    'Skip for now (you can complete this later)',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
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

  void _createProfile() async {
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
      
      final hourlyRate = double.tryParse(_hourlyRateController.text.trim());
      if (hourlyRate == null || hourlyRate <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid hourly rate'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() => _isLoading = true);
      
      try {
        // Create tutor profile via API
        final response = await _profileService.createTutorProfile(
          subjects: _selectedSubjects,
          grades: _selectedGrades,
          hourlyRate: hourlyRate,
          bio: _bioController.text.trim(),
          experience: _experienceController.text.trim(),
          education: _educationController.text.trim(),
          isAvailableOnline: _teachingMode == 'Online' || _teachingMode == 'Both',
          isAvailableInPerson: _teachingMode == 'In-Person' || _teachingMode == 'Both',
        );
        
        if (response.success) {
          // Update auth provider to reflect profile completion
          final authProvider = context.read<AuthProvider>();
          await authProvider.checkAuthStatus(); // This will refresh the user data
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile created successfully! Awaiting admin approval.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to tutor dashboard
          if (context.mounted) {
            context.go('/tutor-dashboard');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to create profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _skipForNow() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Profile Creation?'),
        content: const Text(
          'You can complete your profile later, but students won\'t be able to find or book sessions with you until your profile is complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Setup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Mark profile as completed but incomplete for now
              final authProvider = context.read<AuthProvider>();
              authProvider.updateProfileCompletion(true);
              context.go('/tutor-dashboard');
            },
            child: const Text('Skip for Now'),
          ),
        ],
      ),
    );
  }

  void _completeProfileCreation() async {
    // Update the user's profile completion status
    final authProvider = context.read<AuthProvider>();
    
    // TODO: Call API to update profile completion status
    // For now, we'll simulate this by updating the local state
    authProvider.updateProfileCompletion(true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile created successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navigate to tutor dashboard
    context.go('/tutor-dashboard');
  }

  @override
  void dispose() {
    _bioController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }
}