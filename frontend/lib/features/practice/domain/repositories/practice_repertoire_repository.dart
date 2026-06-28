import '../entities/practice_repertoire.dart';

/// Repository for managing practice repertoire data
abstract class PracticeRepertoireRepository {
  // Repertoire methods
  Future<List<PracticeRepertoire>> getRepertoires(String studentId);
  Future<List<PracticeRepertoire>> getRepertoiresForDate(
    String studentId,
    DateTime date,
  );
  Future<PracticeRepertoire?> getRepertoire(String id);
  Future<PracticeRepertoire> createRepertoire(PracticeRepertoire repertoire);
  Future<PracticeRepertoire> updateRepertoire(PracticeRepertoire repertoire);
  Future<void> deleteRepertoire(String id);

  // Archive methods
  Future<List<PracticeRepertoire>> getActiveRepertoires(String studentId);
  Future<List<PracticeRepertoire>> getArchivedRepertoires(String studentId);
  Future<PracticeRepertoire> archiveRepertoire(String id);
  Future<PracticeRepertoire> restoreRepertoire(String id);
  Future<void> permanentlyDeleteRepertoire(String id);

  // Section methods
  Future<PracticeSection?> getSection(String id);
  Future<PracticeSection> createSection(PracticeSection section);
  Future<PracticeSection> updateSection(PracticeSection section);
  Future<void> deleteSection(String id);
  Future<PracticeSection> toggleSectionComplete(
    String sectionId, {
    DateTime? date,
  });
  Future<PracticeSection> incrementPracticeCount(
    String sectionId,
    int practiceSeconds,
  );

  // Daily practice methods
  Future<PracticeSection> toggleDailyCompletion(
    String sectionId,
    DateTime date,
  );
  Future<PracticeSection> toggleSectionRepeat(String sectionId);

  // Recording methods
  Future<PracticeRecording> createRecording(PracticeRecording recording);
  Future<void> deleteRecording(String id);
  Future<PracticeSection> setRepresentativeRecording(
    String sectionId,
    String recordingId,
  );

  // Section order methods
  Future<void> updateSectionOrders(
    String repertoireId,
    List<String> sectionIds,
  );
  Future<PracticeSection> updateLastPracticedAt(String sectionId);

  // Orphan recording methods
  Future<List<PracticeRecording>> getOrphanedRecordings();
  Future<void> reassignRecording(String recordingId, String newSectionId);
  Future<List<({PracticeRepertoire repertoire, PracticeSection section})>>
  getAllSectionsWithRepertoire(String studentId);

  // Get all sections from all users (for orphan recording assignment)
  Future<List<({PracticeRepertoire repertoire, PracticeSection section})>>
  getAllSectionsForAssignment();

  // Get all recordings with their section and repertoire info
  Future<
    List<
      ({
        PracticeRecording recording,
        PracticeSection? section,
        PracticeRepertoire? repertoire,
      })
    >
  >
  getAllRecordingsWithSectionInfo();

  // Import recording from external file
  Future<PracticeRecording> importRecording(
    String sourceFilePath,
    int durationSeconds,
  );

  // Assignment integration (teacher → student repertoire)
  Future<PracticeRepertoire> getOrCreateDefaultRepertoire(String studentId);

  // Cache management
  Future<void> reloadFromHive();

  // File path repair (for recordings restored from backup with wrong paths)
  Future<int> repairRecordingFilePaths();

  // Diagnostic stats
  Future<Map<String, int>> getRecordingStats();
}
