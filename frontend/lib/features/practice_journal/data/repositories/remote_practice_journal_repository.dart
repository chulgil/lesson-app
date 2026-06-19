// TODO(#872): Backend endpoints for practice_journal are not yet implemented.
// Assumed contract (to be confirmed with backend team):
//
//   GET  /practice-journal/ledger?child_profile_id=&year=&month=
//        → PracticeLedger JSON (marks, seals, endorsements)
//
//   POST /practice-journal/marks
//        body: { child_profile_id, date: "YYYY-MM-DD", intensity: "short"|"full" }
//        → 204 No Content (upsert semantics — server enforces full > short)
//
//   POST /practice-journal/seals
//        body: { child_profile_id, week_start: "YYYY-MM-DD",
//                guardian_user_id, cheer_note?: string }
//        → 204 No Content (server enforces at-most-one per week)
//
//   POST /practice-journal/endorsements
//        body: { child_profile_id, by: "self"|"teacher", date: "YYYY-MM-DD",
//                author_user_id, assignment_ref?: string, note: string }
//        → 204 No Content (server validates teacher requires assignment_ref)
//
//   GET  /practice-journal/volumes?child_profile_id=
//        → List<BoundVolume> JSON (sorted by volume_no asc)
//
//   POST /practice-journal/volumes/bind
//        body: { child_profile_id, piece_id, piece_name }
//        → BoundVolume JSON (idempotent — returns existing if same piece_id)
//
// All routes require authenticated user; 401/403 propagated as
// UnauthorizedException / ForbiddenException by ErrorInterceptor.

import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/bound_volume.dart';
import '../../domain/entities/endorsement.dart';
import '../../domain/entities/guardian_seal.dart';
import '../../domain/entities/practice_ledger.dart';
import '../../domain/entities/practice_mark.dart';
import '../../domain/repositories/practice_journal_repository.dart';

/// Remote implementation of [PracticeJournalRepository] using FastAPI backend.
///
/// Returns data from the practice-journal REST API.
/// Errors (network, 4xx, 5xx) propagate as [ApiException] subclasses.
class RemotePracticeJournalRepository implements PracticeJournalRepository {
  final ApiClient _apiClient;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  RemotePracticeJournalRepository(this._apiClient);

  @override
  Future<PracticeLedger> getLedger(
    String childProfileId,
    int year,
    int month,
  ) async {
    final response = await _apiClient.get(
      '/practice-journal/ledger',
      queryParameters: {
        'child_profile_id': childProfileId,
        'year': year,
        'month': month,
      },
    );
    return PracticeLedger.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> upsertMark(
    String childProfileId,
    DateTime date,
    MarkIntensity intensity,
  ) async {
    await _apiClient.post(
      '/practice-journal/marks',
      data: {
        'child_profile_id': childProfileId,
        'date': _dateFormat.format(date),
        'intensity': intensity.name, // 'short' | 'full'
      },
    );
  }

  @override
  Future<void> addGuardianSeal(String childProfileId, GuardianSeal seal) async {
    await _apiClient.post(
      '/practice-journal/seals',
      data: {'child_profile_id': childProfileId, ...seal.toJson()},
    );
  }

  @override
  Future<void> addEndorsement(
    String childProfileId,
    Endorsement endorsement,
  ) async {
    if (!endorsement.isValid) {
      throw ArgumentError('Endorsement 무효: teacher=과제참조 필수 / self=참조 없음');
    }
    await _apiClient.post(
      '/practice-journal/endorsements',
      data: {'child_profile_id': childProfileId, ...endorsement.toJson()},
    );
  }

  @override
  Future<List<BoundVolume>> getBoundVolumes(String childProfileId) async {
    final response = await _apiClient.get(
      '/practice-journal/volumes',
      queryParameters: {'child_profile_id': childProfileId},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((json) => BoundVolume.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BoundVolume> bindVolume({
    required String childProfileId,
    required String pieceId,
    required String pieceName,
  }) async {
    final response = await _apiClient.post(
      '/practice-journal/volumes/bind',
      data: {
        'child_profile_id': childProfileId,
        'piece_id': pieceId,
        'piece_name': pieceName,
      },
    );
    return BoundVolume.fromJson(response.data as Map<String, dynamic>);
  }
}
