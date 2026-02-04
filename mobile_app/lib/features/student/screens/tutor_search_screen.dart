import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/tutor_service.dart';
import '../../../core/services/chat_service.dart';

class TutorSearchScreen extends StatefulWidget {
  const TutorSearchScreen({Key? key}) : super(key: key);

  @override
  State<TutorSearchScreen> createState() => _TutorSearchScreenState();
}

class _TutorSearchScreenState extends State<TutorSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TutorService _tutorService = TutorService();
  
  List<Map<String, dynamic>> _tutors = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Filters
  String _selectedSubject = 'All Subjects';
  String _selectedGrade = 'All Grades';
  RangeValues _priceRange = const RangeValues(0, 1000); // Changed from 10-100 to 0-1000
  String _selectedMode = 'All Modes';
  double _minRating = 0;

  final List<String> _subjects = [
    'All Subjects',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'History',
    'Computer Science',
    'Geography',
    'Economics',
  ];

  final List<String> _grades = [
    'All Grades',
    'Elementary (K-5)',
    'Middle School (6-8)',
    'High School (9-12)',
    'College/University',
  ];

  final List<String> _modes = [
    'All Modes',
    'Online',
    'In-Person',
  ];

  @override
  void initState() {
    super.initState();
    _loadTutors();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == _searchController.text) {
        _loadTutors();
      }
    });
  }

  Future<void> _loadTutors() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await _tutorService.searchTutors(
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        subject: _selectedSubject != 'All Subjects' ? _selectedSubject : null,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
        teachingMode: _selectedMode != 'All Modes' ? _selectedMode : null,
        minRating: _minRating > 0 ? _minRating : null,
      );

      if (response.success && response.data != null) {
        setState(() {
          _tutors = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = response.error ?? 'Failed to load tutors';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Tutors'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            decoration: BoxDecoration(
              color: Colors.white,
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
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, subject, or keyword...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadTutors();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingMD),
                
                // Filter Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showFilters,
                    icon: const Icon(Icons.filter_list),
                    label: Text(_getActiveFiltersText()),
                  ),
                ),
              ],
            ),
          ),
          
          // Tutors List
          Expanded(
            child: _buildTutorsList(),
          ),
        ],
      ),
    );
  }

  String _getActiveFiltersText() {
    int activeFilters = 0;
    if (_selectedSubject != 'All Subjects') activeFilters++;
    if (_selectedMode != 'All Modes') activeFilters++;
    if (_minRating > 0) activeFilters++;
    if (_priceRange.start != 0 || _priceRange.end != 1000) activeFilters++;
    
    return activeFilters > 0 ? 'Filters ($activeFilters)' : 'Filters';
  }

  Widget _buildTutorsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: AppTheme.spacingLG),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLG),
            ElevatedButton(
              onPressed: _loadTutors,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_tutors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: AppTheme.spacingLG),
            Text(
              'No tutors found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedSubject = 'All Subjects';
                  _selectedMode = 'All Modes';
                  _minRating = 0;
                  _priceRange = const RangeValues(0, 1000);
                });
                _loadTutors();
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTutors,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        itemCount: _tutors.length,
        itemBuilder: (context, index) => _buildTutorCard(_tutors[index]),
      ),
    );
  }

  Widget _buildTutorCard(Map<String, dynamic> tutor) {
    final name = tutor['name'] ?? '${tutor['firstName']} ${tutor['lastName']}';
    final subjects = tutor['subjects'] as List? ?? [];
    final rating = (tutor['rating'] ?? 0).toDouble();
    final hourlyRate = (tutor['hourlyRate'] ?? 0).toDouble();
    final experience = tutor['experience'] ?? 0;
    final totalReviews = tutor['totalReviews'] ?? 0;
    final teachingMode = tutor['teachingMode'] as Map<String, dynamic>? ?? {};
    final isOnline = teachingMode['online'] == true;
    final isInPerson = teachingMode['inPerson'] == true;
    
    String modeText = '';
    if (isOnline && isInPerson) {
      modeText = 'Online & In-Person';
    } else if (isOnline) {
      modeText = 'Online Only';
    } else if (isInPerson) {
      modeText = 'In-Person Only';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: InkWell(
        onTap: () => _viewTutorProfile(tutor),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundImage: tutor['profilePicture'] != null
                        ? NetworkImage(tutor['profilePicture'])
                        : null,
                    child: tutor['profilePicture'] == null
                        ? Text(
                            name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join().toUpperCase(),
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  
                  const SizedBox(width: AppTheme.spacingMD),
                  
                  // Tutor Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        if (subjects.isNotEmpty)
                          Text(
                            subjects.take(2).join(', '),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber[600]),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              ' ($totalReviews)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMD),
                            Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '$experience yrs',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (modeText.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacingXS),
                          Row(
                            children: [
                              Icon(
                                isOnline ? Icons.laptop : Icons.location_on,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                modeText,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${hourlyRate.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'per hour',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingMD),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _messageTutor(tutor),
                      icon: const Icon(Icons.message, size: 18),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _bookTutor(tutor),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Book'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLG)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: AppTheme.spacingLG,
            right: AppTheme.spacingLG,
            top: AppTheme.spacingLG,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingLG,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Tutors',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedSubject = 'All Subjects';
                          _selectedGrade = 'All Grades';
                          _selectedMode = 'All Modes';
                          _minRating = 0;
                          _priceRange = const RangeValues(0, 1000);
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingLG),
                
                // Subject Filter
                Text('Subject', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppTheme.spacingSM),
                DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  items: _subjects.map((subject) => DropdownMenuItem(
                    value: subject,
                    child: Text(subject),
                  )).toList(),
                  onChanged: (value) => setModalState(() => _selectedSubject = value!),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingLG),
                
                // Price Range
                Text(
                  'Price Range (\$${_priceRange.start.round()}-\$${_priceRange.end.round()}/hr)', 
                  style: Theme.of(context).textTheme.titleMedium
                ),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 1000,
                  divisions: 20,
                  labels: RangeLabels(
                    '\$${_priceRange.start.round()}',
                    '\$${_priceRange.end.round()}',
                  ),
                  onChanged: (values) => setModalState(() => _priceRange = values),
                ),
                
                const SizedBox(height: AppTheme.spacingLG),
                
                // Teaching Mode
                Text('Teaching Mode', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppTheme.spacingSM),
                DropdownButtonFormField<String>(
                  value: _selectedMode,
                  items: _modes.map((mode) => DropdownMenuItem(
                    value: mode,
                    child: Text(mode),
                  )).toList(),
                  onChanged: (value) => setModalState(() => _selectedMode = value!),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingLG),
                
                // Minimum Rating
                Text('Minimum Rating', style: Theme.of(context).textTheme.titleMedium),
                Slider(
                  value: _minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  label: _minRating > 0 ? _minRating.toStringAsFixed(1) : 'Any',
                  onChanged: (value) => setModalState(() => _minRating = value),
                ),
                
                const SizedBox(height: AppTheme.spacingXL),
                
                // Apply Filters Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Apply filters
                      Navigator.pop(context);
                      _loadTutors();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewTutorProfile(Map<String, dynamic> tutor) {
    final tutorId = tutor['id'] ?? tutor['userId'];
    if (tutorId != null) {
      context.push('/tutor-detail/$tutorId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to view tutor profile')),
      );
    }
  }

  void _bookTutor(Map<String, dynamic> tutor) {
    final subjects = tutor['subjects'] as List? ?? [];
    final firstSubject = subjects.isNotEmpty ? subjects[0] : null;
    
    // Extract subject ID and name
    String subjectId;
    String subjectName;
    
    if (firstSubject is Map) {
      subjectId = firstSubject['id'] ?? '';
      subjectName = firstSubject['name'] ?? 'General';
    } else {
      // Fallback for old format (just string)
      subjectId = '';
      subjectName = firstSubject?.toString() ?? 'General';
    }
    
    // Extract userId - tutor['id'] is the Profile ID, we need the User ID
    final userId = tutor['userId'] is Map 
        ? tutor['userId']['_id'] 
        : tutor['userId'];
    
    print('🔍 SEARCH: Booking with userId: $userId (from profile id: ${tutor['id']})');
    
    context.push('/student/book-tutor', extra: {
      'tutorId': userId, // Pass User ID, not Profile ID
      'tutorName': tutor['name'] ?? '${tutor['firstName']} ${tutor['lastName']}',
      'subject': subjectName,
      'subjectId': subjectId,
      'hourlyRate': (tutor['hourlyRate'] ?? 0).toDouble(),
    });
  }

  void _messageTutor(Map<String, dynamic> tutor) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final chatService = ChatService();
      final tutorId = tutor['userId'] ?? tutor['id'];
      final subjects = tutor['subjects'] as List? ?? [];
      final subject = subjects.isNotEmpty ? subjects[0] : 'General';
      
      final response = await chatService.createOrGetConversation(
        participantId: tutorId,
        subject: 'Inquiry about $subject tutoring',
      );

      if (mounted) Navigator.pop(context);

      if (response.success && response.data != null) {
        final conversation = response.data!;
        context.push('/chat', extra: {
          'conversationId': conversation.id,
          'participantId': tutorId,
          'participantName': tutor['name'] ?? '${tutor['firstName']} ${tutor['lastName']}',
          'participantAvatar': tutor['profilePicture'],
          'subject': 'Inquiry about $subject tutoring',
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start conversation: ${response.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
