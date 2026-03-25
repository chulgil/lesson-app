import '../../practice_repertoire_repository.dart';
import '../../../features/practice/domain/entities/practice_repertoire.dart';
import '../practice_repository_base.dart';

/// Mixin for repertoire CRUD operations
mixin PracticeRepertoireCrudMixin on PracticeRepositoryBase
    implements PracticeRepertoireRepository {
  @override
  Future<List<PracticeRepertoire>> getRepertoires(String studentId) async {
    await ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    return repertoires[studentId] ?? [];
  }

  @override
  Future<List<PracticeRepertoire>> getRepertoiresForDate(
      String studentId, DateTime date) async {
    await ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    final reps = repertoires[studentId] ?? [];
    return reps.where((r) => r.isActiveForDate(date) && !r.isArchived).toList();
  }

  @override
  Future<PracticeRepertoire?> getRepertoire(String id) async {
    await ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    for (final reps in repertoires.values) {
      try {
        return reps.firstWhere((r) => r.id == id);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  @override
  Future<PracticeRepertoire> createRepertoire(
      PracticeRepertoire repertoire) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    final newRepertoire = PracticeRepertoire(
      id: uuid.v4(),
      studentId: repertoire.studentId,
      name: repertoire.name,
      description: repertoire.description,
      startDate: repertoire.startDate,
      endDate: repertoire.endDate,
      sections: [],
      createdAt: now,
    );
    repertoires.putIfAbsent(repertoire.studentId, () => []);
    repertoires[repertoire.studentId]!.add(newRepertoire);

    // Persist to Hive
    await saveRepertoiresToHive();

    return newRepertoire;
  }

  @override
  Future<PracticeRepertoire> updateRepertoire(
      PracticeRepertoire repertoire) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final reps = repertoires[repertoire.studentId];
    if (reps == null) throw Exception('Student not found');

    final index = reps.indexWhere((r) => r.id == repertoire.id);
    if (index == -1) throw Exception('Repertoire not found');

    final updated = repertoire.copyWith(updatedAt: DateTime.now());
    reps[index] = updated;

    // Persist to Hive
    await saveRepertoiresToHive();

    return updated;
  }

  @override
  Future<void> deleteRepertoire(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (final reps in repertoires.values) {
      reps.removeWhere((r) => r.id == id);
    }

    // Persist to Hive
    await saveRepertoiresToHive();
  }
}
