import '../practice_repertoire_repository.dart';
import 'practice_repository_base.dart';
import 'mixins/practice_repertoire_crud_mixin.dart';
import 'mixins/practice_section_mixin.dart';
import 'mixins/practice_daily_completion_mixin.dart';
import 'mixins/practice_recording_mixin.dart';
import 'mixins/practice_archive_mixin.dart';
import 'mixins/practice_orphan_mixin.dart';

/// Mock implementation of PracticeRepertoireRepository
///
/// This implementation uses Hive for persistence and combines
/// multiple mixins for different functionality areas:
/// - [PracticeRepertoireCrudMixin]: Repertoire CRUD operations
/// - [PracticeSectionMixin]: Section CRUD and ordering operations
/// - [PracticeDailyCompletionMixin]: Daily completion and toggle operations
/// - [PracticeRecordingMixin]: Recording management operations
/// - [PracticeArchiveMixin]: Archive/restore operations
/// - [PracticeOrphanMixin]: Orphan recording and utility operations
class MockPracticeRepertoireRepository extends PracticeRepositoryBase
    with
        PracticeRepertoireCrudMixin,
        PracticeSectionMixin,
        PracticeDailyCompletionMixin,
        PracticeRecordingMixin,
        PracticeArchiveMixin,
        PracticeOrphanMixin
    implements PracticeRepertoireRepository {
  MockPracticeRepertoireRepository() {
    _initMockData();
    initializationFuture = _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    if (isInitialized) return;
    await loadPersistedRepertoires();
    await loadPersistedRecordings();
    isInitialized = true;
  }

  void _initMockData() {
    // No dummy data - users create their own repertoires and sections
  }
}
