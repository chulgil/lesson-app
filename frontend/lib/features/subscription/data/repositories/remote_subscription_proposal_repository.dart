import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated_response.dart';
import '../../domain/entities/subscription_proposal.dart';
import '../../domain/repositories/subscription_proposal_repository.dart';

/// Remote implementation of [SubscriptionProposalRepository] using FastAPI backend.
class RemoteSubscriptionProposalRepository
    implements SubscriptionProposalRepository {
  final ApiClient _apiClient;

  RemoteSubscriptionProposalRepository(this._apiClient);

  @override
  Future<List<SubscriptionProposal>> getByTeacher(String teacherId) async {
    final response = await _apiClient.get('/subscriptions-proposals');
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => SubscriptionProposal.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<SubscriptionProposal>> getByStudent(String studentId) async {
    final response = await _apiClient.get(
      '/subscriptions-proposals',
      queryParameters: {'student_id': studentId},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => SubscriptionProposal.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<SubscriptionProposal>> getActiveByTeacher(
    String teacherId,
  ) async {
    final response = await _apiClient.get(
      '/subscriptions-proposals',
      queryParameters: {'status': 'pending'},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => SubscriptionProposal.fromJson(json),
    );
    // Include both pending and paymentNotified
    final pendingItems = paginated.items;

    final paymentNotifiedResponse = await _apiClient.get(
      '/subscriptions-proposals',
      queryParameters: {'status': 'paymentNotified'},
    );
    final paymentNotifiedPaginated = PaginatedResponse.fromJson(
      paymentNotifiedResponse.data as Map<String, dynamic>,
      (json) => SubscriptionProposal.fromJson(json),
    );

    return [...pendingItems, ...paymentNotifiedPaginated.items];
  }

  @override
  Future<List<SubscriptionProposal>> getActiveByStudent(
    String studentId,
  ) async {
    // Fetch pending and paymentNotified proposals for the student
    final pendingResponse = await _apiClient.get(
      '/subscriptions-proposals',
      queryParameters: {'student_id': studentId, 'status': 'pending'},
    );
    final pendingPaginated = PaginatedResponse.fromJson(
      pendingResponse.data as Map<String, dynamic>,
      (json) => SubscriptionProposal.fromJson(json),
    );

    final paymentNotifiedResponse = await _apiClient.get(
      '/subscriptions-proposals',
      queryParameters: {'student_id': studentId, 'status': 'paymentNotified'},
    );
    final paymentNotifiedPaginated = PaginatedResponse.fromJson(
      paymentNotifiedResponse.data as Map<String, dynamic>,
      (json) => SubscriptionProposal.fromJson(json),
    );

    return [...pendingPaginated.items, ...paymentNotifiedPaginated.items];
  }

  @override
  Future<List<SubscriptionProposal>> getPendingByStudent(
    String studentId,
  ) async {
    final response = await _apiClient.get(
      '/subscriptions-proposals',
      queryParameters: {'student_id': studentId, 'status': 'pending'},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => SubscriptionProposal.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<SubscriptionProposal>> getAwaitingConfirmation(
    String teacherId,
  ) async {
    final response = await _apiClient.get(
      '/subscriptions-proposals',
      queryParameters: {'status': 'paymentNotified'},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => SubscriptionProposal.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<SubscriptionProposal?> getById(String id) async {
    final response = await _apiClient.get('/subscriptions-proposals/$id');
    return SubscriptionProposal.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SubscriptionProposal> create(SubscriptionProposal proposal) async {
    final response = await _apiClient.post(
      '/subscriptions-proposals',
      data: proposal.toJson(),
    );
    return SubscriptionProposal.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SubscriptionProposal> notifyPayment(String id) async {
    final response = await _apiClient.patch(
      '/subscriptions-proposals/$id/respond',
      data: {'action': 'notify_payment'},
    );
    return SubscriptionProposal.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SubscriptionProposal> confirmPayment(
    String id,
    String subscriptionId,
  ) async {
    final response = await _apiClient.patch(
      '/subscriptions-proposals/$id/confirm',
      data: {'subscription_id': subscriptionId},
    );
    return SubscriptionProposal.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SubscriptionProposal> reject(String id, String? reason) async {
    final response = await _apiClient.patch(
      '/subscriptions-proposals/$id/respond',
      data: {'action': 'reject', if (reason != null) 'reason': reason},
    );
    return SubscriptionProposal.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SubscriptionProposal> cancel(String id) async {
    final response = await _apiClient.patch(
      '/subscriptions-proposals/$id/respond',
      data: {'action': 'cancel'},
    );
    return SubscriptionProposal.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> expireOldProposals() async {
    await _apiClient.post('/subscriptions-proposals/expire');
  }

  @override
  Future<SubscriptionProposal?> getActiveProposal(
    String teacherId,
    String studentId,
  ) async {
    final response = await _apiClient.get(
      '/subscriptions-proposals',
      queryParameters: {'student_id': studentId, 'status': 'pending'},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => SubscriptionProposal.fromJson(json),
    );
    if (paginated.items.isNotEmpty) return paginated.items.first;

    // Also check paymentNotified status
    final notifiedResponse = await _apiClient.get(
      '/subscriptions-proposals',
      queryParameters: {'student_id': studentId, 'status': 'paymentNotified'},
    );
    final notifiedPaginated = PaginatedResponse.fromJson(
      notifiedResponse.data as Map<String, dynamic>,
      (json) => SubscriptionProposal.fromJson(json),
    );
    return notifiedPaginated.items.isEmpty
        ? null
        : notifiedPaginated.items.first;
  }

  @override
  Future<SubscriptionProposal> selectTemplate(
    String id,
    String templateId,
  ) async {
    final response = await _apiClient.patch(
      '/subscriptions-proposals/$id/respond',
      data: {'action': 'select_template', 'template_id': templateId},
    );
    return SubscriptionProposal.fromJson(response.data as Map<String, dynamic>);
  }
}
