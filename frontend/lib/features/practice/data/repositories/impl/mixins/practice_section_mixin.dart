import '../../../../domain/repositories/practice_repertoire_repository.dart';
import '../../../../domain/entities/practice_repertoire.dart';
import '../practice_repository_base.dart';

/// Mixin for section CRUD operations
mixin PracticeSectionMixin on PracticeRepositoryBase
    implements PracticeRepertoireRepository {
  @override
  Future<PracticeSection?> getSection(String id) async {
    await ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    for (final reps in repertoires.values) {
      for (final repertoire in reps) {
        try {
          return repertoire.sections.firstWhere((s) => s.id == id);
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }

  @override
  Future<PracticeSection> createSection(PracticeSection section) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newSection = PracticeSection(
      id: uuid.v4(),
      repertoireId: section.repertoireId,
      pieceName: section.pieceName,
      rangeType: section.rangeType,
      startMeasure: section.startMeasure,
      endMeasure: section.endMeasure,
      startLine: section.startLine,
      endLine: section.endLine,
      sectionName: section.sectionName,
      isCompleted: false,
      isRepeat: section.isRepeat,
      repeatCount: section.repeatCount,
      startDate: section.startDate,
      endDate: section.endDate,
      practiceCount: 0,
      totalPracticeSeconds: 0,
      recordings: [],
      createdAt: DateTime.now(),
      youtubeUrl: section.youtubeUrl,
      youtubeVideoId: section.youtubeVideoId,
      youtubeStartSeconds: section.youtubeStartSeconds,
      youtubeEndSeconds: section.youtubeEndSeconds,
      teachingResourceIds: section.teachingResourceIds,
      assignedByTeacherId: section.assignedByTeacherId,
      practiceItemId: section.practiceItemId,
    );

    // Find and update the repertoire
    for (final reps in repertoires.values) {
      final repIndex = reps.indexWhere((r) => r.id == section.repertoireId);
      if (repIndex != -1) {
        final repertoire = reps[repIndex];
        final updatedSections = [...repertoire.sections, newSection];
        reps[repIndex] = repertoire.copyWith(
          sections: updatedSections,
          updatedAt: DateTime.now(),
        );

        // Persist to Hive
        await saveRepertoiresToHive();

        return newSection;
      }
    }
    throw Exception('Repertoire not found');
  }

  @override
  Future<PracticeSection> updateSection(PracticeSection section) async {
    await Future.delayed(const Duration(milliseconds: 300));

    for (final reps in repertoires.values) {
      for (int i = 0; i < reps.length; i++) {
        final repertoire = reps[i];
        final sectionIndex =
            repertoire.sections.indexWhere((s) => s.id == section.id);
        if (sectionIndex != -1) {
          final oldSection = repertoire.sections[sectionIndex];

          // Check if repeatCount changed - if so, reset dailyRepeatCounts and practiceCount
          PracticeSection updatedSection;
          if (oldSection.repeatCount != section.repeatCount) {
            // RepeatCount changed - reset daily completion and practice count
            updatedSection = section.copyWith(
              dailyRepeatCounts: {},
              practiceCount: 0,
              updatedAt: DateTime.now(),
            );
          } else {
            updatedSection = section.copyWith(updatedAt: DateTime.now());
          }

          final updatedSections =
              List<PracticeSection>.from(repertoire.sections);
          updatedSections[sectionIndex] = updatedSection;
          reps[i] = repertoire.copyWith(
            sections: updatedSections,
            updatedAt: DateTime.now(),
          );

          // Persist to Hive
          await saveRepertoiresToHive();

          return updatedSection;
        }
      }
    }
    throw Exception('Section not found');
  }

  @override
  Future<void> deleteSection(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    for (final reps in repertoires.values) {
      for (int i = 0; i < reps.length; i++) {
        final repertoire = reps[i];
        final sectionIndex = repertoire.sections.indexWhere((s) => s.id == id);
        if (sectionIndex != -1) {
          final updatedSections =
              List<PracticeSection>.from(repertoire.sections);
          updatedSections.removeAt(sectionIndex);
          reps[i] = repertoire.copyWith(
            sections: updatedSections,
            updatedAt: DateTime.now(),
          );

          // Persist to Hive
          await saveRepertoiresToHive();

          return;
        }
      }
    }
  }

  @override
  Future<PracticeSection> incrementPracticeCount(
      String sectionId, int practiceSeconds) async {
    await Future.delayed(const Duration(milliseconds: 200));

    for (final reps in repertoires.values) {
      for (int i = 0; i < reps.length; i++) {
        final repertoire = reps[i];
        final sectionIndex =
            repertoire.sections.indexWhere((s) => s.id == sectionId);
        if (sectionIndex != -1) {
          final section = repertoire.sections[sectionIndex];
          final updatedSection = section.copyWith(
            practiceCount: section.practiceCount + 1,
            totalPracticeSeconds:
                section.totalPracticeSeconds + practiceSeconds,
            updatedAt: DateTime.now(),
          );
          final updatedSections =
              List<PracticeSection>.from(repertoire.sections);
          updatedSections[sectionIndex] = updatedSection;
          reps[i] = repertoire.copyWith(
            sections: updatedSections,
            updatedAt: DateTime.now(),
          );

          // Persist to Hive
          await saveRepertoiresToHive();

          return updatedSection;
        }
      }
    }
    throw Exception('Section not found');
  }

  @override
  Future<void> updateSectionOrders(
      String repertoireId, List<String> sectionIds) async {
    await Future.delayed(const Duration(milliseconds: 200));

    for (final reps in repertoires.values) {
      final repIndex = reps.indexWhere((r) => r.id == repertoireId);
      if (repIndex != -1) {
        final repertoire = reps[repIndex];
        final updatedSections = <PracticeSection>[];

        for (int i = 0; i < sectionIds.length; i++) {
          final sectionId = sectionIds[i];
          try {
            final section =
                repertoire.sections.firstWhere((s) => s.id == sectionId);
            updatedSections.add(section.copyWith(sortOrder: i));
          } catch (_) {
            continue;
          }
        }

        // Add any sections not in the list (shouldn't happen but safety)
        for (final section in repertoire.sections) {
          if (!sectionIds.contains(section.id)) {
            updatedSections
                .add(section.copyWith(sortOrder: updatedSections.length));
          }
        }

        reps[repIndex] = repertoire.copyWith(
          sections: updatedSections,
          updatedAt: DateTime.now(),
        );

        // Persist to Hive
        await saveRepertoiresToHive();

        return;
      }
    }
    throw Exception('Repertoire not found');
  }

  @override
  Future<PracticeSection> updateLastPracticedAt(String sectionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();

    for (final reps in repertoires.values) {
      for (int i = 0; i < reps.length; i++) {
        final repertoire = reps[i];
        final sectionIndex =
            repertoire.sections.indexWhere((s) => s.id == sectionId);
        if (sectionIndex != -1) {
          final section = repertoire.sections[sectionIndex];
          final updatedSection = section.copyWith(
            lastPracticedAt: now,
            updatedAt: now,
          );
          final updatedSections =
              List<PracticeSection>.from(repertoire.sections);
          updatedSections[sectionIndex] = updatedSection;
          reps[i] = repertoire.copyWith(
            sections: updatedSections,
            updatedAt: now,
          );

          // Persist to Hive
          await saveRepertoiresToHive();

          return updatedSection;
        }
      }
    }
    throw Exception('Section not found');
  }

  @override
  Future<PracticeRepertoire> getOrCreateDefaultRepertoire(
      String studentId) async {
    await ensureInitialized();
    final reps = repertoires[studentId] ?? [];

    // Find existing default repertoire
    for (final rep in reps) {
      if (rep.isDefault && !rep.isArchived) return rep;
    }

    // Create default repertoire if none exists
    final now = DateTime.now();
    final defaultRepertoire = PracticeRepertoire(
      id: uuid.v4(),
      studentId: studentId,
      name: '선생님 과제',
      description: '선생님이 할당한 과제가 자동으로 추가됩니다',
      startDate: now,
      sections: [],
      createdAt: now,
      isDefault: true,
    );
    repertoires.putIfAbsent(studentId, () => []);

    // Re-check after putIfAbsent to prevent race condition duplicates
    final existingDefault = repertoires[studentId]!
        .where((r) => r.isDefault && !r.isArchived)
        .firstOrNull;
    if (existingDefault != null) return existingDefault;

    repertoires[studentId]!.add(defaultRepertoire);
    await saveRepertoiresToHive();
    return defaultRepertoire;
  }

  @override
  Future<PracticeSection> createSectionFromAssignment({
    required String studentId,
    required String pieceName,
    String? sectionName,
    String? youtubeUrl,
    String? youtubeVideoId,
    int? youtubeStartSeconds,
    int? youtubeEndSeconds,
    List<String> teachingResourceIds = const [],
    required String assignedByTeacherId,
    required String practiceItemId,
  }) async {
    final repertoire = await getOrCreateDefaultRepertoire(studentId);

    // Idempotency guard: return existing section if already synced
    final existing = repertoire.sections
        .where((s) => s.practiceItemId == practiceItemId)
        .firstOrNull;
    if (existing != null) return existing;

    // Validate youtubeVideoId format (11-char alphanumeric)
    final validVideoId = youtubeVideoId != null &&
            RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(youtubeVideoId)
        ? youtubeVideoId
        : null;

    final section = PracticeSection(
      id: '',
      repertoireId: repertoire.id,
      pieceName: pieceName,
      rangeType: SectionRangeType.full,
      startMeasure: 1,
      endMeasure: 1,
      sectionName: sectionName,
      isRepeat: true,
      createdAt: DateTime.now(),
      youtubeUrl: validVideoId != null ? youtubeUrl : null,
      youtubeVideoId: validVideoId,
      youtubeStartSeconds: validVideoId != null ? youtubeStartSeconds : null,
      youtubeEndSeconds: validVideoId != null ? youtubeEndSeconds : null,
      teachingResourceIds: teachingResourceIds,
      assignedByTeacherId: assignedByTeacherId,
      practiceItemId: practiceItemId,
    );

    return createSection(section);
  }
}
