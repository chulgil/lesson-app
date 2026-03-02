import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated_response.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_usage.dart';
import '../../domain/repositories/subscription_repository.dart';

/// Remote implementation of [SubscriptionRepository] using FastAPI backend.
class RemoteSubscriptionRepository implements SubscriptionRepository {
  final ApiClient _apiClient;

  RemoteSubscriptionRepository(this._apiClient);

  @override
  Future<List<Subscription>> getByStudentId(String studentId) async {
    final response = await _apiClient.get(
      '/subscriptions',
      queryParameters: {'student_id': studentId},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Subscription.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<Subscription?> getActiveByMembershipId(String membershipId) async {
    final response = await _apiClient.get(
      '/subscriptions',
      queryParameters: {'membership_id': membershipId, 'status': 'active'},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Subscription.fromJson(json),
    );
    return paginated.items.isEmpty ? null : paginated.items.first;
  }

  @override
  Future<Subscription?> getById(String id) async {
    final response = await _apiClient.get('/subscriptions/$id');
    return Subscription.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Subscription> create(Subscription subscription) async {
    final response = await _apiClient.post(
      '/subscriptions',
      data: subscription.toJson(),
    );
    return Subscription.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Subscription> update(Subscription subscription) async {
    final response = await _apiClient.put(
      '/subscriptions/${subscription.id}',
      data: subscription.toJson(),
    );
    return Subscription.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Subscription> useLesson(
    String id, {
    String? lessonId,
    String? teacherName,
    String? instrument,
  }) async {
    final response = await _apiClient.patch(
      '/subscriptions/$id/use-lesson',
      data: {
        if (lessonId != null) 'lesson_id': lessonId,
        if (teacherName != null) 'teacher_name': teacherName,
        if (instrument != null) 'instrument': instrument,
      },
    );
    return Subscription.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Subscription> useReschedule(String id) async {
    final response = await _apiClient.patch(
      '/subscriptions/$id/use-reschedule',
    );
    return Subscription.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> updateStatus(String id, SubscriptionStatus status) async {
    await _apiClient.patch(
      '/subscriptions/$id/status',
      data: {'status': status.name},
    );
  }

  @override
  Future<List<Subscription>> getExpiringSoon() async {
    final response = await _apiClient.get(
      '/subscriptions',
      queryParameters: {'status': 'expiringSoon'},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Subscription.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<Subscription>> getByTeacherId(String teacherId) async {
    final response = await _apiClient.get(
      '/subscriptions',
      queryParameters: {'teacher_id': teacherId},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Subscription.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Stream<List<Subscription>> watchByStudentId(String studentId) {
    // Remote implementation uses polling or WebSocket in the future.
    // For now, return a single-emission stream from the future.
    return Stream.fromFuture(getByStudentId(studentId));
  }

  @override
  Stream<Subscription?> watchActiveByMembershipId(String membershipId) {
    return Stream.fromFuture(getActiveByMembershipId(membershipId));
  }

  // ═══════════════════════════════════════════════════════════════════
  // Payment
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<Subscription>> getUnpaidSubscriptions(String teacherId) async {
    final response = await _apiClient.get(
      '/subscriptions',
      queryParameters: {'teacher_id': teacherId, 'payment_confirmed': 'false'},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Subscription.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<Subscription> confirmPayment(
    String id, {
    SubscriptionPaymentMethod? paymentMethod,
  }) async {
    final response = await _apiClient.patch(
      '/subscriptions/$id/confirm-payment',
      data: {if (paymentMethod != null) 'payment_method': paymentMethod.name},
    );
    return Subscription.fromJson(response.data as Map<String, dynamic>);
  }

  // ═══════════════════════════════════════════════════════════════════
  // Usage History
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<SubscriptionUsage>> getUsageHistory(String subscriptionId) async {
    final response = await _apiClient.get(
      '/subscriptions/$subscriptionId/usage',
    );
    final items = response.data['items'] as List<dynamic>;
    return items
        .map((e) => SubscriptionUsage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SubscriptionUsage> addUsage(SubscriptionUsage usage) async {
    final response = await _apiClient.post(
      '/subscriptions/${usage.subscriptionId}/usage',
      data: usage.toJson(),
    );
    return SubscriptionUsage.fromJson(response.data as Map<String, dynamic>);
  }
}
