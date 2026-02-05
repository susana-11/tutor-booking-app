import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/support_service.dart';
import '../../../core/models/support_models.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  List<FAQ> _faqs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;

  final List<String> _categories = [
    'All',
    'General',
    'Account',
    'Booking',
    'Payment',
    'Technical',
  ];

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  Future<void> _loadFAQs() async {
    setState(() => _isLoading = true);

    try {
      final apiService = context.read<ApiService>();
      final supportService = SupportService(apiService);
      final faqs = await supportService.getFAQs();

      if (mounted) {
        setState(() {
          _faqs = faqs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<FAQ> get _filteredFAQs {
    var filtered = _faqs;

    // Filter by category
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filtered = filtered
          .where((faq) =>
              faq.category.toLowerCase() == _selectedCategory!.toLowerCase())
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((faq) =>
              faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              faq.answer.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF16213E) : Colors.white,
        title: const Text('FAQs'),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            color: isDark ? const Color(0xFF16213E) : Colors.white,
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search FAQs...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1A1A2E)
                    : const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
            color: isDark ? const Color(0xFF16213E) : Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category ||
                    (_selectedCategory == null && category == 'All');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category == 'All' ? null : category;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppTheme.spacingMD),

          // FAQs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFAQs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: AppTheme.spacingMD),
                            Text(
                              _faqs.isEmpty
                                  ? 'No FAQs available'
                                  : 'No FAQs found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacingMD),
                        itemCount: _filteredFAQs.length,
                        itemBuilder: (context, index) {
                          final faq = _filteredFAQs[index];
                          return _buildFAQCard(faq, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCard(FAQ faq, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      color: isDark ? const Color(0xFF16213E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(AppTheme.spacingMD),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMD,
            0,
            AppTheme.spacingMD,
            AppTheme.spacingMD,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F3460), Color(0xFF16213E)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.help_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            faq.question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F3460),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              faq.category.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.withOpacity(0.7),
              ),
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A1A2E)
                    : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                faq.answer,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark
                      ? Colors.white.withOpacity(0.8)
                      : const Color(0xFF6B7FA8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
