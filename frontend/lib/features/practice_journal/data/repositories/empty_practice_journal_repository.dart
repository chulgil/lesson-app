import '../../domain/entities/bound_volume.dart';
import '../../domain/entities/endorsement.dart';
import '../../domain/entities/guardian_seal.dart';
import '../../domain/entities/practice_ledger.dart';
import '../../domain/entities/practice_mark.dart';
import '../../domain/repositories/practice_journal_repository.dart';

/// Empty stub used in remote mode until the practice-journal API ships (#872).
///
/// Returns empty ledgers/volumes and rejects mutations — real users see an
/// empty journal instead of an infinite spinner from a dead endpoint.
class EmptyPracticeJournalRepository implements PracticeJournalRepository {
  @override
  Future<PracticeLedger> getLedger(
    String childProfileId,
    int year,
    int month,
  ) async => PracticeLedger.empty(
    childProfileId: childProfileId,
    year: year,
    month: month,
  );

  @override
  Future<List<BoundVolume>> getBoundVolumes(String childProfileId) async =>
      const [];

  @override
  Future<void> upsertMark(
    String childProfileId,
    DateTime date,
    MarkIntensity intensity,
  ) async {
    throw UnsupportedError(
      'Practice journal API is not available in remote mode.',
    );
  }

  @override
  Future<void> addGuardianSeal(String childProfileId, GuardianSeal seal) async {
    throw UnsupportedError(
      'Practice journal API is not available in remote mode.',
    );
  }

  @override
  Future<void> addEndorsement(
    String childProfileId,
    Endorsement endorsement,
  ) async {
    throw UnsupportedError(
      'Practice journal API is not available in remote mode.',
    );
  }

  @override
  Future<BoundVolume> bindVolume({
    required String childProfileId,
    required String pieceId,
    required String pieceName,
  }) async {
    throw UnsupportedError(
      'Practice journal API is not available in remote mode.',
    );
  }
}
