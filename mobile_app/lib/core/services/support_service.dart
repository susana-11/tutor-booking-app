import 'api_service.dart';
import '../models/support_models.dart';

class SupportService {
  final ApiService _apiService;

  SupportService(this._apiService);

  // Create a new support ticket
  Future<SupportTicket> createTicket({
    required String subject,
    required String category,
    required String description,
    String priority = 'medium',
  }) async {
    final response = await _apiService.post('/support/tickets', data: {
      'subject': subject,
      'category': category,
      'description': description,
      'priority': priority,
    });

    if (response.success && response.data != null) {
      return SupportTicket.fromJson(response.data);
    }
    throw Exception(response.message ?? 'Failed to create ticket');
  }

  // Get user's tickets
  Future<List<SupportTicket>> getUserTickets({String? status}) async {
    final queryParams = status != null ? '?status=$status' : '';
    final response = await _apiService.get('/support/tickets$queryParams');

    if (response.success && response.data != null) {
      final tickets = (response.data as List)
          .map((json) => SupportTicket.fromJson(json))
          .toList();
      return tickets;
    }
    throw Exception(response.message ?? 'Failed to fetch tickets');
  }

  // Get single ticket details
  Future<SupportTicket> getTicket(String ticketId) async {
    final response = await _apiService.get('/support/tickets/$ticketId');

    if (response.success && response.data != null) {
      return SupportTicket.fromJson(response.data);
    }
    throw Exception(response.message ?? 'Failed to fetch ticket');
  }

  // Add message to ticket
  Future<SupportTicket> addMessage(String ticketId, String message) async {
    final response = await _apiService.post(
      '/support/tickets/$ticketId/messages',
      data: {'message': message},
    );

    if (response.success && response.data != null) {
      return SupportTicket.fromJson(response.data);
    }
    throw Exception(response.message ?? 'Failed to send message');
  }

  // Rate ticket
  Future<void> rateTicket(String ticketId, int rating, {String? feedback}) async {
    final response = await _apiService.post(
      '/support/tickets/$ticketId/rate',
      data: {
        'rating': rating,
        if (feedback != null) 'feedback': feedback,
      },
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to rate ticket');
    }
  }

  // Get FAQs
  Future<List<FAQ>> getFAQs() async {
    final response = await _apiService.get('/support/faqs');

    if (response.success && response.data != null) {
      final faqs = (response.data as List)
          .map((json) => FAQ.fromJson(json))
          .toList();
      return faqs;
    }
    throw Exception(response.message ?? 'Failed to fetch FAQs');
  }
}
