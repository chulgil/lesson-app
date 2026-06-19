import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/features/practice_journal/data/repositories/remote_practice_journal_repository.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/bound_volume.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/endorsement.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/guardian_seal.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_ledger.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_mark.dart';

/// Builds an [ApiClient] backed by a Dio interceptor that captures requests
/// and resolves them with [responseData].
RemotePracticeJournalRepository _repoWith({
  required List<RequestOptions> captured,
  required dynamic responseData,
  int statusCode = 200,
}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        captured.add(options);
        handler.resolve(
          Response(
            requestOptions: options,
            data: responseData,
            statusCode: statusCode,
          ),
        );
      },
    ),
  );
  return RemotePracticeJournalRepository(ApiClient(dio));
}

void main() {
  group('RemotePracticeJournalRepository', () {
    group('getLedger', () {
      test(
        'sends correct query params and deserialises PracticeLedger',
        () async {
          final requests = <RequestOptions>[];
          final repo = _repoWith(
            captured: requests,
            responseData: {
              'child_profile_id': 'c1',
              'year': 2026,
              'month': 6,
              'marks': [],
              'seals': [],
              'endorsements': [],
            },
          );

          final ledger = await repo.getLedger('c1', 2026, 6);

          expect(ledger, isA<PracticeLedger>());
          expect(ledger.childProfileId, 'c1');
          expect(ledger.year, 2026);
          expect(ledger.month, 6);
          expect(requests.single.queryParameters['child_profile_id'], 'c1');
          expect(requests.single.queryParameters['year'], 2026);
        },
      );
    });

    group('upsertMark', () {
      test('POSTs with date string and intensity name', () async {
        final requests = <RequestOptions>[];
        final repo = _repoWith(
          captured: requests,
          responseData: null,
          statusCode: 204,
        );

        await repo.upsertMark(
          'c1',
          DateTime.utc(2026, 6, 15),
          MarkIntensity.full,
        );

        final body = requests.single.data as Map<String, dynamic>;
        expect(body['child_profile_id'], 'c1');
        expect(body['date'], '2026-06-15');
        expect(body['intensity'], 'full');
      });
    });

    group('addGuardianSeal', () {
      test('POSTs seal payload with child_profile_id', () async {
        final requests = <RequestOptions>[];
        final repo = _repoWith(
          captured: requests,
          responseData: null,
          statusCode: 204,
        );

        final seal = GuardianSeal(
          weekStart: DateTime.utc(2026, 6, 9),
          guardianUserId: 'p1',
          cheerNote: '잘했어요',
        );
        await repo.addGuardianSeal('c1', seal);

        final body = requests.single.data as Map<String, dynamic>;
        expect(body['child_profile_id'], 'c1');
        expect(body['guardian_user_id'], 'p1');
      });
    });

    group('addEndorsement', () {
      test(
        'throws ArgumentError for teacher endorsement without assignmentRef',
        () {
          // No Dio call should be made — validation is client-side.
          final repo = _repoWith(captured: [], responseData: null);

          final invalid = Endorsement(
            by: EndorsedBy.teacher,
            date: DateTime.utc(2026, 6, 15),
            authorUserId: 't1',
            note: 'x',
            // assignmentRef missing → invalid
          );

          expect(() => repo.addEndorsement('c1', invalid), throwsArgumentError);
        },
      );

      test('POSTs valid teacher endorsement', () async {
        final requests = <RequestOptions>[];
        final repo = _repoWith(
          captured: requests,
          responseData: null,
          statusCode: 204,
        );

        final valid = Endorsement(
          by: EndorsedBy.teacher,
          date: DateTime.utc(2026, 6, 15),
          authorUserId: 't1',
          assignmentRef: 'assign_42',
          note: 'Good job',
        );
        await repo.addEndorsement('c1', valid);

        final body = requests.single.data as Map<String, dynamic>;
        expect(body['child_profile_id'], 'c1');
        expect(requests.single.path, contains('/endorsements'));
      });
    });

    group('getBoundVolumes', () {
      test('deserialises list of BoundVolume sorted by volumeNo', () async {
        final requests = <RequestOptions>[];
        final repo = _repoWith(
          captured: requests,
          responseData: [
            {
              'child_profile_id': 'c1',
              'piece_id': 'piece_1',
              'piece_name': '바흐 미뉴에트',
              'volume_no': 1,
              'bound_date': '2026-03-12T00:00:00.000Z',
            },
            {
              'child_profile_id': 'c1',
              'piece_id': 'piece_2',
              'piece_name': '작은 별',
              'volume_no': 2,
              'bound_date': '2026-05-02T00:00:00.000Z',
            },
          ],
        );

        final volumes = await repo.getBoundVolumes('c1');

        expect(volumes, hasLength(2));
        expect(volumes.first, isA<BoundVolume>());
        expect(volumes.first.pieceId, 'piece_1');
        expect(volumes[1].volumeNo, 2);
        expect(requests.single.queryParameters['child_profile_id'], 'c1');
      });
    });

    group('bindVolume', () {
      test('POSTs bind request and returns BoundVolume', () async {
        final requests = <RequestOptions>[];
        final repo = _repoWith(
          captured: requests,
          responseData: {
            'child_profile_id': 'c1',
            'piece_id': 'piece_1',
            'piece_name': '바흐 미뉴에트',
            'volume_no': 1,
            'bound_date': '2026-06-15T00:00:00.000Z',
          },
        );

        final volume = await repo.bindVolume(
          childProfileId: 'c1',
          pieceId: 'piece_1',
          pieceName: '바흐 미뉴에트',
        );

        expect(volume, isA<BoundVolume>());
        expect(volume.pieceId, 'piece_1');
        expect(volume.volumeNo, 1);

        final body = requests.single.data as Map<String, dynamic>;
        expect(body['child_profile_id'], 'c1');
        expect(body['piece_id'], 'piece_1');
        expect(body['piece_name'], '바흐 미뉴에트');
      });
    });
  });
}
