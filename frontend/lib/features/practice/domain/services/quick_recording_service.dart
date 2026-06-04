import '../../../../core/constants/practice_defaults.dart';
import '../entities/practice_repertoire.dart';
import '../repositories/practice_repertoire_repository.dart';

/// Result of preparing the default quick-recording destination.
class QuickRecordingTarget {
  const QuickRecordingTarget({required this.repertoire, required this.section});

  final PracticeRepertoire repertoire;
  final PracticeSection section;
}

/// Domain service that ensures a student has a default "무제 > 바로 녹음"
/// repertoire/section pair available for quick recording.
///
/// Spec: `docs/specs/practice/practice_master.md` §4.3.
///
/// Idempotent: calling [ensureDefaultsForStudent] multiple times returns the
/// same repertoire/section. Uniqueness is guaranteed via fixed,
/// per-student composite IDs from [PracticeDefaults].
class QuickRecordingService {
  const QuickRecordingService(this._repository);

  final PracticeRepertoireRepository _repository;

  /// Ensure the default quick-record repertoire and section exist for
  /// [studentId], creating them if necessary.
  ///
  /// Idempotent across repeated calls: a subsequent invocation returns the
  /// existing default pair untouched.
  Future<QuickRecordingTarget> ensureDefaultsForStudent(
    String studentId,
  ) async {
    if (studentId.isEmpty) {
      throw ArgumentError('studentId must not be empty');
    }

    final repertoireId = PracticeDefaults.defaultRepertoireIdFor(studentId);
    final sectionId = PracticeDefaults.defaultQuickRecordSectionIdFor(
      studentId,
    );

    final now = DateTime.now();

    // 1. Repertoire — find or create.
    PracticeRepertoire? repertoire = await _repository.getRepertoire(
      repertoireId,
    );
    repertoire ??= await _repository.createRepertoire(
      PracticeRepertoire(
        id: repertoireId,
        studentId: studentId,
        name: PracticeDefaults.repertoireName,
        startDate: now,
        createdAt: now,
        isDefault: true,
      ),
    );

    // 2. Section — find or create inside repertoire.
    PracticeSection? section = await _repository.getSection(sectionId);
    section ??= await _repository.createSection(
      PracticeSection(
        id: sectionId,
        repertoireId: repertoire.id,
        pieceName: PracticeDefaults.quickRecordSectionName,
        rangeType: SectionRangeType.full,
        startMeasure: 1,
        endMeasure: 1,
        sectionName: PracticeDefaults.quickRecordSectionName,
        isDefault: true,
        createdAt: now,
      ),
    );

    return QuickRecordingTarget(repertoire: repertoire, section: section);
  }
}
