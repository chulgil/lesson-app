import '../../domain/entities/bound_volume.dart';
import '../../domain/entities/endorsement.dart';
import '../../domain/entities/guardian_seal.dart';
import '../../domain/entities/practice_ledger.dart';
import '../../domain/entities/practice_mark.dart';
import '../../domain/repositories/practice_journal_repository.dart';

/// Empty stub used in remote mode until the practice-journal API ships (#872).
///
/// Reads return empty ledgers/volumes; mutations are best-effort **no-ops**
/// (#424). The API is not deployed yet, so silently skipping a journal write is
/// correct — throwing `UnsupportedError` instead would propagate into the
/// shared `recordPractice` main path (heatmap + quest, where the journal hook
/// runs before the quest bump) and crash the song-completion archive flow.
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
    // no-op (#424)
  }

  @override
  Future<void> addGuardianSeal(String childProfileId, GuardianSeal seal) async {
    // no-op (#424)
  }

  @override
  Future<void> addEndorsement(
    String childProfileId,
    Endorsement endorsement,
  ) async {
    // no-op (#424)
  }

  @override
  Future<BoundVolume> bindVolume({
    required String childProfileId,
    required String pieceId,
    required String pieceName,
  }) async => BoundVolume(
    // Echo the inputs with placeholder metadata so callers (archive flow) get a
    // valid object instead of an exception. Not persisted in remote mode.
    childProfileId: childProfileId,
    pieceId: pieceId,
    pieceName: pieceName,
    volumeNo: 0,
    boundDate: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}
