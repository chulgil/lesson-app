// #1178 — contract test for the cancellation-defaults remote repository.
//
// Pins the wire shape against the BE CancellationDefaultsResponse/Update
// schemas (snake_case keys, GET/PUT /settings/cancellation) so an agent
// editing either side alone breaks this test instead of the runtime.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/features/profile/data/repositories/remote_cancellation_defaults_repository.dart';
import 'package:lessonaza/features/profile/domain/entities/cancellation_defaults.dart';
import 'package:mocktail/mocktail.dart';

class FakeApiClient extends Mock implements ApiClient {}

Response<dynamic> _jsonResponse(String path, Map<String, dynamic> data) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: data,
  );
}

Map<String, dynamic> _serverPayload({bool enabled = true, String? message}) {
  return <String, dynamic>{
    'id': 'cd-1',
    'cancellation_deadline_hours': 12,
    'student_compensation_extra_minutes_enabled': enabled,
    'include_extra_minutes_text_on_late_cancel': true,
    'student_compensation_extra_minutes_message': message,
    'notify_owner_on_late_cancel': false,
    'created_at': '2026-07-11T10:00:00Z',
    'updated_at': null,
  };
}

void main() {
  late FakeApiClient apiClient;
  late RemoteCancellationDefaultsRepository repository;

  setUp(() {
    apiClient = FakeApiClient();
    repository = RemoteCancellationDefaultsRepository(apiClient);
  });

  test('GET parses the BE response payload', () async {
    when(() => apiClient.get<dynamic>('/settings/cancellation')).thenAnswer(
      (_) async => _jsonResponse(
        '/settings/cancellation',
        _serverPayload(enabled: false, message: '15분 보너스'),
      ),
    );

    final result = await repository.getCancellationDefaults();

    expect(result.id, 'cd-1');
    expect(result.studentCompensationExtraMinutesEnabled, isFalse);
    expect(result.studentCompensationExtraMinutesMessage, '15분 보너스');
    expect(result.cancellationDeadlineHours, 12);
  });

  test(
    'PUT sends the five policy fields without server-managed keys',
    () async {
      when(
        () => apiClient.put<dynamic>(
          '/settings/cancellation',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => _jsonResponse('/settings/cancellation', _serverPayload()),
      );

      final defaults = CancellationDefaults(
        id: 'cd-1',
        studentCompensationExtraMinutesEnabled: false,
        studentCompensationExtraMinutesMessage: '커스텀 문구',
        createdAt: DateTime.utc(2026, 7, 11),
      );
      await repository.updateCancellationDefaults(defaults);

      final captured =
          verify(
                () => apiClient.put<dynamic>(
                  '/settings/cancellation',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map<String, dynamic>;

      // Exactly the keys CancellationDefaultsUpdate accepts.
      expect(captured.keys.toSet(), {
        'cancellation_deadline_hours',
        'student_compensation_extra_minutes_enabled',
        'include_extra_minutes_text_on_late_cancel',
        'student_compensation_extra_minutes_message',
        'notify_owner_on_late_cancel',
      });
      expect(captured['student_compensation_extra_minutes_enabled'], isFalse);
      expect(captured['student_compensation_extra_minutes_message'], '커스텀 문구');
    },
  );
}
