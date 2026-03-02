import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/default_ids.dart';
import '../../domain/entities/practice_repertoire.dart';
import '../../presentation/providers/practice_repertoire_repository_provider.dart';

part 'default_repertoire_service.g.dart';

/// Service that ensures the default repertoire and quick-record section exist.
///
/// This is used by the quick recording feature to provide a destination
/// for recordings when the user is not on a specific section screen.
@Riverpod(keepAlive: true)
class DefaultRepertoireService extends _$DefaultRepertoireService {
  @override
  Future<void> build() async {
    await ensureDefaultExists();
  }

  /// Check if the default repertoire exists; if not, create it with
  /// a default quick-record section.
  Future<void> ensureDefaultExists() async {
    final repository = ref.read(practiceRepertoireRepositoryProvider);

    // Check if default repertoire already exists
    final existing = await repository.getRepertoire(DefaultIds.repertoireId);
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
    await repository.createRepertoire(repertoire);

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
    await repository.createSection(section);
  }
}
