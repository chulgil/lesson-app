// Backend contract (implemented & mounted — backend/app/api/v1/practice_journal.py,
// prefix /practice-journal; 0629 audit N4 path-drift fixed 2026-07-02):
//
//   GET  /practice-journal/ledger?child_profile_id=&year=&month=  → LedgerResponse
//   POST /practice-journal/marks                → 200 PracticeMarkResponse (student-self)
//   POST /practice-journal/seals                → 200 GuardianSealResponse (guardian;
//        body guardian_user_id is accepted-but-IGNORED — server stamps auth user)
//   POST /practice-journal/endorsements/self    → 201 EndorsementResponse (student-self)
//   POST /practice-journal/endorsements/teacher → 201 EndorsementResponse (teacher;
//        body author_user_id is accepted-but-IGNORED — server stamps auth user)
//   GET  /practice-journal/volumes?child_profile_id=  → List<BoundVolumeResponse>
//   POST /practice-journal/volumes              → 200 BoundVolumeResponse
//        (idempotent — same (child, piece) returns the existing row)
//

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
    // BE splits the route by author role (role-guarded dependencies).
    final path = endorsement.by == EndorsedBy.teacher
        ? '/practice-journal/endorsements/teacher'
        : '/practice-journal/endorsements/self';
    await _apiClient.post(
      path,
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
      '/practice-journal/volumes',
      data: {
        'child_profile_id': childProfileId,
        'piece_id': pieceId,
        'piece_name': pieceName,
      },
    );
    return BoundVolume.fromJson(response.data as Map<String, dynamic>);
  }
}
