import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/tutor_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/api_service.dart';

class TutorDetailScreen extends StatefulWidget {
  final String tutorId;

  const TutorDetailScreen({
    Key? key,
    required this.tutorId,
  }) : super(key: key);

  @override
  State<TutorDetailScreen> createState() => _TutorDetailScreenState();
}

class _TutorDetailScreenState extends State<TutorDetailScreen> {
  final TutorService _tutorService = TutorService();
  final ChatService _chatService = ChatService();
  
  Map<String, dynamic>? _tutor;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTutorDetails();
  }

  Future<void> _loadTutorDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _tutorService.getTutorById(widget.tutorId);
      
      if (response.success && response.data != null) {
        setState(() {
          _tutor = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load tutor details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_tutor == null) return;

    try {
      // Create or get conversation
      final response = await _chatService.createOrGetConversation(
        participantId: _tutor!['userId'],
        subject: 'General Discussion',
      );

      if (response.success && response.data != null) {
        if (mounted) {
          context.push('/chat', extra: {
            'conversationId': response.data!.id,
            'participantId': _tutor!['userId'],
            'participantName': _tutor!['name'],
            'participantAvatar': _tutor!['profilePicture'],
            'subject': 'General Discussion',
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start chat: ${response.error}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  void _bookSession() {
    if (_tutor == null) return;
    
    print('🔍 DEBUG: Full tutor data: $_tutor');
    print('🔍 DEBUG: userId field: ${_tutor!['userId']}');
    print('🔍 DEBUG: userId type: ${_tutor!['userId'].runtimeType}');
    
    // Extract the userId from the tutor data
    // The tutor data has userId populated from the backend
    final userId = _tutor!['userId'] is Map 
        ? _tutor!['userId']['_id'] 
        : _tutor!['userId'];
    
    print('🔍 Booking with userId: $userId (from tutorId: ${widget.tutorId})');
    
    // Extract subject information
    final subjects = _tutor!['subjects'] as List<dynamic>? ?? [];
    String subjectName = 'General';
    String subjectId = '';
    
    if (subjects.isNotEmpty) {
      final firstSubject = subjects[0];
      if (firstSubject is Map) {
        // Subject is an object with name field
        subjectName = firstSubject['name'] ?? 'General';
        // Note: The subject object in tutor profile doesn't have _id
        // We'll pass the name and let the backend look it up
        subjectId = ''; // Backend will look up by name
      } else if (firstSubject is String) {
        // Subject is just a string
        subjectName = firstSubject;
      }
    }
    
    print('🔍 Subject: $subjectName, SubjectId: $subjectId');
    
    context.push('/student/book-tutor', extra: {
      'tutorId': userId, // Pass User ID, not Profile ID
      'tutorName': _tutor!['name'] ?? '${_tutor!['userId']['firstName']} ${_tutor!['userId']['lastName']}',
      'subject': subjectName,
      'subjectId': subjectId,
      'hourlyRate': (_tutor!['pricing']?['hourlyRate'] ?? _tutor!['hourlyRate'] ?? 0).toDouble(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTutorDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _tutor == null
                  ? const Center(child: Text('Tutor not found'))
                  : _buildTutorDetails(),
      bottomNavigationBar: _tutor != null ? _buildBottomButtons() : null,
    );
  }

  Widget _buildTutorDetails() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Divider(height: 1),
              _buildAboutSection(),
              const Divider(height: 1),
              _buildSubjectsSection(),
              const Divider(height: 1),
              _buildExperienceSection(),
              const Divider(height: 1),
              _buildEducationSection(),
              const Divider(height: 1),
              _buildStatsSection(),
              const SizedBox(height: 100), // Space for bottom buttons
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
          ),
          child: Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: _tutor!['profilePicture'] != null
                  ? ClipOval(
                      child: Image.network(
                        _tutor!['profilePicture'],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultAvatar(),
                      ),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Text(
      _tutor!['name']?.substring(0, 1).toUpperCase() ?? 'T',
      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tutor!['name'] ?? 'Unknown',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '${_tutor!['rating']?.toStringAsFixed(1) ?? '0.0'} (${_tutor!['totalReviews'] ?? 0} reviews)',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 16),
              Text(
                '${_tutor!['totalSessions'] ?? 0} sessions',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '\$${_tutor!['hourlyRate']?.toStringAsFixed(0) ?? '0'}/hr',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_tutor!['teachingMode']?['online'] == true)
                Chip(
                  label: const Text('Online'),
                  avatar: const Icon(Icons.videocam, size: 16),
                  backgroundColor: Colors.green[50],
                ),
              const SizedBox(width: 8),
              if (_tutor!['teachingMode']?['inPerson'] == true)
                Chip(
                  label: const Text('In-Person'),
                  avatar: const Icon(Icons.person, size: 16),
                  backgroundColor: Colors.blue[50],
                ),
            ],
          ),
          if (!(_tutor!['isAvailable'] ?? true)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Not accepting new bookings',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tutor!['bio'] ?? 'No bio available',
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsSection() {
    final subjects = _tutor!['subjects'] as List<dynamic>? ?? [];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subjects',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subjects.map((subject) {
              return Chip(
                label: Text(subject.toString()),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceSection() {
    final experience = _tutor!['experience'];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Experience',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            experience?.toString() ?? 'No experience information',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationSection() {
    final education = _tutor!['education'];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Education',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            education?.toString() ?? 'No education information',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.school,
                '${_tutor!['totalSessions'] ?? 0}',
                'Sessions',
              ),
              _buildStatItem(
                Icons.star,
                '${_tutor!['rating']?.toStringAsFixed(1) ?? '0.0'}',
                'Rating',
              ),
              _buildStatItem(
                Icons.rate_review,
                '${_tutor!['totalReviews'] ?? 0}',
                'Reviews',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    final isAvailable = _tutor!['isAvailable'] ?? true;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _sendMessage,
                icon: const Icon(Icons.message),
                label: const Text('Message'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isAvailable ? _bookSession : null,
                icon: const Icon(Icons.calendar_today),
                label: Text(isAvailable ? 'Book Session' : 'Not Available'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
