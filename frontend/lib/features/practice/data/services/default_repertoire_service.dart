import '../../../../core/constants/default_ids.dart';
import '../../domain/entities/practice_repertoire.dart';
import '../../domain/repositories/practice_repertoire_repository.dart';

/// Service that ensures the default repertoire and quick-record section exist.
///
/// This is used by the quick recording feature to provide a destination
/// for recordings when the user is not on a specific section screen.
class DefaultRepertoireService {
  const DefaultRepertoireService(this._repository);

  final PracticeRepertoireRepository _repository;

  /// Check if the default repertoire exists; if not, create it with
  /// a default quick-record section.
  Future<void> ensureDefaultExists() async {
    // Check if default repertoire already exists
    final existing = await _repository.getRepertoire(DefaultIds.repertoireId);
    if (existing != null) return;

    // Create default repertoire
    final now = DateTime.now();
    final repertoire = PracticeRepertoire(
      id: DefaultIds.repertoireId,
      studentId: 'default',
      name: DefaultIds.repertoireName,
      startDate: now,
      createdAt: now,
      isDefault: true,
    );
    await _repository.createRepertoire(repertoire);

    // Create default quick-record section inside the repertoire
    final section = PracticeSection(
      id: DefaultIds.quickRecordSectionId,
      repertoireId: DefaultIds.repertoireId,
      pieceName: DefaultIds.quickRecordSectionName,
      rangeType: SectionRangeType.full,
      startMeasure: 1,
      endMeasure: 1,
      sectionName: DefaultIds.quickRecordSectionName,
      isDefault: true,
      createdAt: now,
    );
    await _repository.createSection(section);
  }
}
