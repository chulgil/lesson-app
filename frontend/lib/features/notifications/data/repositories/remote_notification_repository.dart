import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated_response.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Remote implementation of [NotificationRepository] using FastAPI backend.
class RemoteNotificationRepository implements NotificationRepository {
  final ApiClient _apiClient;

  RemoteNotificationRepository(this._apiClient);

  @override
  Future<List<AppNotification>> getNotifications() async {
    final response = await _apiClient.get('/notifications');
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => _notificationFromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<void> markAsRead(String id) async {
    await _apiClient.patch('/notifications/$id/read');
  }

  @override
  Future<void> markAllAsRead() async {
    await _apiClient.patch('/notifications/read-all');
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get('/notifications/unread-count');
    final data = response.data as Map<String, dynamic>;
    return data['count'] as int;
  }

  @override
  Future<void> delete(String id) async {
    await _apiClient.delete('/notifications/$id');
  }

  // --- Manual JSON helpers (AppNotification doesn't have @JsonSerializable) ---

  AppNotification _notificationFromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: _parseNotificationType(json['type'] as String?),
      priority: _parseNotificationPriority(json['priority'] as String?),
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      scheduledAt:
          json['scheduled_at'] != null
              ? DateTime.parse(json['scheduled_at'] as String)
              : null,
      sentAt:
          json['sent_at'] != null
              ? DateTime.parse(json['sent_at'] as String)
              : null,
      readAt:
          json['read_at'] != null
              ? DateTime.parse(json['read_at'] as String)
              : null,
      isPush: json['is_push'] as bool? ?? true,
      isInApp: json['is_in_app'] as bool? ?? true,
      actionUrl: json['action_url'] as String?,
      actionLabel: json['action_label'] as String?,
    );
  }

  NotificationType _parseNotificationType(String? value) {
    if (value == null) return NotificationType.lessonReminder;
    try {
      return NotificationType.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return NotificationType.lessonReminder;
    }
  }

  NotificationPriority _parseNotificationPriority(String? value) {
    if (value == null) return NotificationPriority.normal;
    try {
      return NotificationPriority.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return NotificationPriority.normal;
    }
  }
}
