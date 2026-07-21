import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/practice_repertoire.dart';

/// Base class for practice repository with shared state and Hive helpers
abstract class PracticeRepositoryBase {
  static const String recordingsBoxName = 'practice_recordings';
  static const String repertoiresBoxName = 'practice_repertoires';

  final uuid = const Uuid();
  final Map<String, List<PracticeRepertoire>> repertoires = {};

  Box<PracticeRecording>? recordingsBox;
  Box? repertoiresBox;
  bool isInitialized = false;
  Future<void>? initializationFuture;

  Future<Box<PracticeRecording>> get practiceRecordingsBox async {
    if (recordingsBox != null && recordingsBox!.isOpen) {
      return recordingsBox!;
    }
    recordingsBox = await Hive.openBox<PracticeRecording>(recordingsBoxName);
    return recordingsBox!;
  }

  Future<Box> get practiceRepertoiresBox async {
    if (repertoiresBox != null && repertoiresBox!.isOpen) {
      return repertoiresBox!;
    }
    repertoiresBox = await Hive.openBox(repertoiresBoxName);
    return repertoiresBox!;
  }

  /// Ensure initialization is complete before accessing data
  Future<void> ensureInitialized() async {
    if (!isInitialized && initializationFuture != null) {
      await initializationFuture;
    }
  }

  /// Load persisted repertoires from Hive
  Future<void> loadPersistedRepertoires() async {
    try {
      final box = await practiceRepertoiresBox;

      for (final key in box.keys) {
        try {
          final jsonString = box.get(key) as String?;
          if (jsonString != null) {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final repertoire = PracticeRepertoire.fromJson(json);
            repertoires.putIfAbsent(repertoire.studentId, () => []);

            // Check if already exists
            final existingIndex = repertoires[repertoire.studentId]!
                .indexWhere((r) => r.id == repertoire.id);
            if (existingIndex == -1) {
              repertoires[repertoire.studentId]!.add(repertoire);
            }
          }
        } catch (e) {
          // Ignore parse errors for individual repertoires
        }
      }
    } catch (e) {
      // Ignore errors loading persisted repertoires
    }
  }

  /// Save all repertoires to Hive
  Future<void> saveRepertoiresToHive() async {
    try {
      final box = await practiceRepertoiresBox;

      // Collect all repertoire IDs that should exist
      final allRepertoireIds = <String>{};

      for (final reps in repertoires.values) {
        for (final repertoire in reps) {
          allRepertoireIds.add(repertoire.id);
          final jsonString = jsonEncode(repertoire.toJson());
          await box.put(repertoire.id, jsonString);
        }
      }

      // Orphan-delete removes Hive keys absent from the in-memory map. Skip it
      // until the initial load has populated `repertoires` (isInitialized),
      // otherwise a mutation that runs before ensureInitialized() completes
      // would wipe persisted-but-not-yet-loaded repertoires from Hive.
      if (isInitialized) {
        final keysToRemove = <dynamic>[];
        for (final key in box.keys) {
          if (!allRepertoireIds.contains(key)) {
            keysToRemove.add(key);
          }
        }
        for (final key in keysToRemove) {
          await box.delete(key);
        }
      }

      await box.flush();
    } catch (e) {
      // Ignore errors saving repertoires to Hive
    }
  }

  /// Load persisted recordings from Hive and merge with mock sections
  Future<void> loadPersistedRecordings() async {
    try {
      final box = await practiceRecordingsBox;

      for (final recording in box.values) {
        addRecordingToSection(recording);
      }
    } catch (e) {
      // Ignore errors loading persisted recordings
    }
  }

  /// Add a recording to the corresponding section in memory
  void addRecordingToSection(PracticeRecording recording) {
    for (final reps in repertoires.values) {
      for (int i = 0; i < reps.length; i++) {
        final repertoire = reps[i];
        final sectionIndex = repertoire.sections.indexWhere(
          (s) => s.id == recording.sectionId,
        );
        if (sectionIndex != -1) {
          final section = repertoire.sections[sectionIndex];

          // Check if recording already exists
          if (section.recordings.any((r) => r.id == recording.id)) {
            return;
          }

          final updatedRecordings =
              List<PracticeRecording>.from(section.recordings)..add(recording);
          final updatedSection =
              section.copyWith(recordings: updatedRecordings);
          final updatedSections =
              List<PracticeSection>.from(repertoire.sections);
          updatedSections[sectionIndex] = updatedSection;
          reps[i] = repertoire.copyWith(sections: updatedSections);
          return;
        }
      }
    }
  }
}
