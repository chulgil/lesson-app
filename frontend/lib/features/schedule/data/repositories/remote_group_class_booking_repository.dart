import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated_response.dart';
import '../../domain/entities/group_class_booking.dart';
import '../../domain/repositories/group_class_booking_repository.dart';

/// Remote implementation of [GroupClassBookingRepository] using FastAPI backend.
class RemoteGroupClassBookingRepository implements GroupClassBookingRepository {
  final ApiClient _apiClient;

  RemoteGroupClassBookingRepository(this._apiClient);

  // ============================================================
  // CRUD Operations
  // ============================================================

  @override
  Future<List<GroupClassBooking>> getBookingsForSchedule(
    String scheduleId,
  ) async {
    final response = await _apiClient.get(
      '/schedule/group-bookings',
      queryParameters: {'schedule_id': scheduleId},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => GroupClassBooking.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<GroupClassBooking>> getBookingsForStudent(
    String studentId,
  ) async {
    final response = await _apiClient.get(
      '/schedule/group-bookings',
      queryParameters: {'student_id': studentId},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => GroupClassBooking.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<GroupClassBooking?> getBookingById(String bookingId) async {
    final response = await _apiClient.get(
      '/schedule/group-bookings/$bookingId',
    );
    return GroupClassBooking.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<GroupClassBooking?> getBooking(
    String scheduleId,
    String studentId,
  ) async {
    final response = await _apiClient.get(
      '/schedule/group-bookings',
      queryParameters: {
        'schedule_id': scheduleId,
        'student_id': studentId,
        'active': 'true',
      },
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => GroupClassBooking.fromJson(json),
    );
    return paginated.items.isEmpty ? null : paginated.items.first;
  }

  // ============================================================
  // Booking Operations
  // ============================================================

  @override
  Future<GroupClassBooking> createBooking({
    required String scheduleId,
    required String studentId,
    String? subscriptionId,
  }) async {
    final response = await _apiClient.post(
      '/schedule/group-bookings',
      data: {
        'schedule_id': scheduleId,
        'student_id': studentId,
        if (subscriptionId != null) 'subscription_id': subscriptionId,
      },
    );
    return GroupClassBooking.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<GroupClassBooking> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    final response = await _apiClient.patch(
      '/schedule/group-bookings/$bookingId/cancel',
      data: reason != null ? {'reason': reason} : null,
    );
    return GroupClassBooking.fromJson(response.data as Map<String, dynamic>);
  }

  // ============================================================
  // Waitlist Operations
  // ============================================================

  @override
  Future<List<GroupClassBooking>> getWaitlist(String scheduleId) async {
    final response = await _apiClient.get(
      '/schedule/group-bookings',
      queryParameters: {'schedule_id': scheduleId, 'status': 'waitlist'},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => GroupClassBooking.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<int?> getWaitlistPosition(String scheduleId, String studentId) async {
    final booking = await getBooking(scheduleId, studentId);
    return booking?.waitlistPosition;
  }

  @override
  Future<GroupClassBooking?> promoteFromWaitlist(String scheduleId) async {
    final response = await _apiClient.post(
      '/schedule/group-bookings/promote',
      data: {'schedule_id': scheduleId},
    );
    if (response.data == null) return null;
    return GroupClassBooking.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<GroupClassBooking>> autoCancelWaitlist(String scheduleId) async {
    final response = await _apiClient.post(
      '/schedule/group-bookings/auto-cancel-waitlist',
      data: {'schedule_id': scheduleId},
    );
    final items = response.data as List<dynamic>;
    return items
        .map((e) => GroupClassBooking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // Attendance Operations
  // ============================================================

  @override
  Future<GroupClassBooking> markAttendance(
    String bookingId, {
    required bool attended,
  }) async {
    final response = await _apiClient.patch(
      '/schedule/group-bookings/$bookingId/attendance',
      data: {'attended': attended},
    );
    return GroupClassBooking.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<GroupClassBooking>> markBatchAttendance(
    Map<String, bool> bookingAttendance,
  ) async {
    final response = await _apiClient.post(
      '/schedule/group-bookings/batch-attendance',
      data: {
        'attendance':
            bookingAttendance.entries
                .map((e) => {'booking_id': e.key, 'attended': e.value})
                .toList(),
      },
    );
    final items = response.data as List<dynamic>;
    return items
        .map((e) => GroupClassBooking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GroupClassBooking> deductSubscription(String bookingId) async {
    final response = await _apiClient.patch(
      '/schedule/group-bookings/$bookingId/deduct',
    );
    return GroupClassBooking.fromJson(response.data as Map<String, dynamic>);
  }

  // ============================================================
  // Query Operations
  // ============================================================

  @override
  Future<int> getConfirmedCount(String scheduleId) async {
    final bookings = await getBookingsForSchedule(scheduleId);
    return bookings
        .where(
          (b) =>
              b.status == GroupBookingStatus.confirmed ||
              b.status == GroupBookingStatus.attended,
        )
        .length;
  }

  @override
  Future<int> getWaitlistCount(String scheduleId) async {
    final waitlist = await getWaitlist(scheduleId);
    return waitlist.length;
  }

  @override
  Future<bool> hasBooking(String scheduleId, String studentId) async {
    final booking = await getBooking(scheduleId, studentId);
    return booking != null;
  }

  @override
  Future<List<GroupClassBooking>> getActiveBookingsForStudent(
    String studentId,
  ) async {
    final bookings = await getBookingsForStudent(studentId);
    return bookings.where((b) => b.isActive).toList();
  }

  @override
  Future<List<GroupClassBooking>> getUpcomingBookingsForStudent(
    String studentId,
  ) async {
    final response = await _apiClient.get(
      '/schedule/group-bookings',
      queryParameters: {'student_id': studentId, 'upcoming': 'true'},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => GroupClassBooking.fromJson(json),
    );
    return paginated.items;
  }
}
