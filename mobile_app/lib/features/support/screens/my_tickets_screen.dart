import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/support_service.dart';
import '../../../core/models/support_models.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  String? _selectedStatus;
  List<SupportTicket> _tickets = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _statusFilters = [
    {'value': null, 'label': 'All', 'color': Colors.grey},
    {'value': 'open', 'label': 'Open', 'color': Colors.blue},
    {'value': 'in-progress', 'label': 'In Progress', 'color': Colors.orange},
    {'value': 'resolved', 'label': 'Resolved', 'color': Colors.green},
    {'value': 'closed', 'label': 'Closed', 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      apiService.initialize();
      final supportService = SupportService(apiService);
      final tickets = await supportService.getUserTickets(status: _selectedStatus);

      if (mounted) {
        setState(() {
          _tickets = tickets;
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in-progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'technical':
        return Icons.bug_report;
      case 'payment':
        return Icons.payment;
      case 'booking':
        return Icons.calendar_today;
      case 'account':
        return Icons.person;
      case 'general':
        return Icons.help_outline;
      default:
        return Icons.more_horiz;
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
        title: const Text('My Tickets'),
      ),
      body: Column(
        children: [
          // Status Filter
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            color: isDark ? const Color(0xFF16213E) : Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.map((filter) {
                  final isSelected = _selectedStatus == filter['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter['label'] as String),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = filter['value'] as String?;
                        });
                        _loadTickets();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Tickets List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tickets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: AppTheme.spacingMD),
                            Text(
                              'No tickets found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTickets,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppTheme.spacingMD),
                          itemCount: _tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = _tickets[index];
                            return _buildTicketCard(ticket, isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/support/create-ticket');
          _loadTickets();
        },
        backgroundColor: const Color(0xFF0F3460),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Ticket',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      color: isDark ? const Color(0xFF16213E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/support/tickets/${ticket.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryIcon(ticket.category) == Icons.bug_report
                          ? Colors.red.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(ticket.category),
                      size: 20,
                      color: _getCategoryIcon(ticket.category) == Icons.bug_report
                          ? Colors.red
                          : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.subject,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F3460),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ticket #${ticket.id.substring(ticket.id.length - 6)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ticket.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(ticket.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                ticket.description,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? Colors.white.withOpacity(0.7)
                      : const Color(0xFF6B7FA8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(ticket.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flag,
                          size: 12,
                          color: _getPriorityColor(ticket.priority),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ticket.priority.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getPriorityColor(ticket.priority),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Icon(
                    Icons.message_outlined,
                    size: 14,
                    color: Colors.grey.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ticket.messages.length} messages',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(ticket.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.withOpacity(0.7),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
