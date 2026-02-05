import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../../core/theme/app_theme.dart';
import '../../../core/services/tutor_service.dart';
import '../../../core/services/chat_service.dart';

class TutorSearchScreen extends StatefulWidget {
  const TutorSearchScreen({Key? key}) : super(key: key);

  @override
  State<TutorSearchScreen> createState() => _TutorSearchScreenState();
}

class _TutorSearchScreenState extends State<TutorSearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TutorService _tutorService = TutorService();
  
  List<Map<String, dynamic>> _tutors = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Filters
  String _selectedSubject = 'All Subjects';
  String _selectedGrade = 'All Grades';
  RangeValues _priceRange = const RangeValues(0, 1000);
  String _selectedMode = 'All Modes';
  double _minRating = 0;
  
  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;

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
    _initializeAnimations();
    _loadTutors();
    _searchController.addListener(_onSearchChanged);
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

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController?.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
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

  String _getActiveFiltersText() {
    int activeFilters = 0;
    if (_selectedSubject != 'All Subjects') activeFilters++;
    if (_selectedMode != 'All Modes') activeFilters++;
    if (_minRating > 0) activeFilters++;
    if (_priceRange.start != 0 || _priceRange.end != 1000) activeFilters++;
    
    return activeFilters > 0 ? 'Filters ($activeFilters)' : 'Filters';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(isDark),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Modern Header
                _buildModernHeader(isDark),
                
                // Search and Filters
                _buildSearchSection(isDark),
                
                // Tutors List
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                    child: _buildTutorsList(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildModernHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF6B46C1).withOpacity(0.3),
                  const Color(0xFF805AD5).withOpacity(0.2),
                  const Color(0xFF38B2AC).withOpacity(0.2),
                ]
              : [
                  const Color(0xFF6B46C1),
                  const Color(0xFF805AD5),
                  const Color(0xFF38B2AC),
                ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: isDark ? Colors.amber[300] : Colors.amber[100],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Find Your Tutor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_tutors.length} tutors available',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        children: [
          // Modern Search Bar
          Container(
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
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.textPrimaryColor,
              ),
              decoration: InputDecoration(
                hintText: 'Search by name, subject...',
                hintStyle: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : AppTheme.textDisabledColor,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : AppTheme.primaryColor,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _searchController.clear();
                            _loadTutors();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.clear_rounded,
                              color: isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingMD),
          
          // Filter Button
          Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showFilters,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getActiveFiltersText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Widget _buildTutorsList(bool isDark) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? const Color(0xFF38B2AC) : AppTheme.primaryColor,
          ),
        ),
      );
    }

    if (_hasError) {
      return _buildErrorState(isDark);
    }

    if (_tutors.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: _loadTutors,
      color: isDark ? const Color(0xFF38B2AC) : AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        itemCount: _tutors.length,
        itemBuilder: (context, index) => _buildModernTutorCard(_tutors[index], isDark),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLG),
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loadTutors,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Try Again',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            Text(
              'No tutors found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLG),
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _selectedSubject = 'All Subjects';
                      _selectedMode = 'All Modes';
                      _minRating = 0;
                      _priceRange = const RangeValues(0, 1000);
                    });
                    _loadTutors();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.clear_all_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Clear Filters',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTutorCard(Map<String, dynamic> tutor, bool isDark) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewTutorProfile(tutor),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture with gradient border
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: CircleAvatar(
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
                      ),
                    ),
                    
                    const SizedBox(width: AppTheme.spacingMD),
                    
                    // Tutor Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (subjects.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: subjects.take(2).map((subject) {
                                final subjectName = subject is Map ? subject['name'] : subject.toString();
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    subjectName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star_rounded, size: 16, color: Colors.amber[600]),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                                ),
                              ),
                              Text(
                                ' ($totalReviews)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.5)
                                      : AppTheme.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.work_outline_rounded,
                                size: 14,
                                color: isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : AppTheme.textSecondaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$experience yrs',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.7)
                                      : AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                          if (modeText.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  isOnline ? Icons.laptop_rounded : Icons.location_on_rounded,
                                  size: 14,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.5)
                                      : AppTheme.textSecondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  modeText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.5)
                                        : AppTheme.textSecondaryColor,
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
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                          ).createShader(bounds),
                          child: Text(
                            '\$${hourlyRate.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          'per hour',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white.withOpacity(0.5)
                                : AppTheme.textSecondaryColor,
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
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF38B2AC)
                                : AppTheme.primaryColor,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _messageTutor(tutor),
                            borderRadius: BorderRadius.circular(12),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.message_rounded,
                                    size: 18,
                                    color: isDark
                                        ? const Color(0xFF38B2AC)
                                        : AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Message',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? const Color(0xFF38B2AC)
                                          : AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMD),
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _bookTutor(tutor),
                            borderRadius: BorderRadius.circular(12),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Book',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
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
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Filter Tutors',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
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
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF38B2AC) : AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingLG),
                  
                  // Subject Filter
                  Text(
                    'Subject',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      items: _subjects.map((subject) => DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      )).toList(),
                      onChanged: (value) => setModalState(() => _selectedSubject = value!),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingLG),
                  
                  // Price Range
                  Text(
                    'Price Range (\$${_priceRange.start.round()}-\$${_priceRange.end.round()}/hr)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                    ),
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: isDark ? const Color(0xFF38B2AC) : AppTheme.primaryColor,
                      inactiveTrackColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[300],
                      thumbColor: isDark ? const Color(0xFF38B2AC) : AppTheme.primaryColor,
                      overlayColor: (isDark ? const Color(0xFF38B2AC) : AppTheme.primaryColor).withOpacity(0.2),
                    ),
                    child: RangeSlider(
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
                  ),
                  
                  const SizedBox(height: AppTheme.spacingLG),
                  
                  // Teaching Mode
                  Text(
                    'Teaching Mode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedMode,
                      items: _modes.map((mode) => DropdownMenuItem(
                        value: mode,
                        child: Text(mode),
                      )).toList(),
                      onChanged: (value) => setModalState(() => _selectedMode = value!),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingLG),
                  
                  // Minimum Rating
                  Text(
                    'Minimum Rating: ${_minRating > 0 ? _minRating.toStringAsFixed(1) : 'Any'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                    ),
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: isDark ? const Color(0xFF38B2AC) : AppTheme.primaryColor,
                      inactiveTrackColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[300],
                      thumbColor: isDark ? const Color(0xFF38B2AC) : AppTheme.primaryColor,
                      overlayColor: (isDark ? const Color(0xFF38B2AC) : AppTheme.primaryColor).withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _minRating,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      label: _minRating > 0 ? _minRating.toStringAsFixed(1) : 'Any',
                      onChanged: (value) => setModalState(() => _minRating = value),
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Apply Filters Button
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B46C1), Color(0xFF38B2AC)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {}); // Apply filters
                          Navigator.pop(context);
                          _loadTutors();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Apply Filters',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
    
    String subjectId;
    String subjectName;
    
    if (firstSubject is Map) {
      subjectId = firstSubject['id'] ?? '';
      subjectName = firstSubject['name'] ?? 'General';
    } else {
      subjectId = '';
      subjectName = firstSubject?.toString() ?? 'General';
    }
    
    final userId = tutor['userId'] is Map 
        ? tutor['userId']['_id'] 
        : tutor['userId'];
    
    print('🔍 SEARCH: Booking with userId: $userId (from profile id: ${tutor['id']})');
    
    context.push('/student/book-tutor', extra: {
      'tutorId': userId,
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
}
