import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/practice_repertoire.dart';

/// Repository for managing practice repertoire data
abstract class PracticeRepertoireRepository {
  // Repertoire methods
  Future<List<PracticeRepertoire>> getRepertoires(String studentId);
  Future<List<PracticeRepertoire>> getRepertoiresForDate(
      String studentId, DateTime date);
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
  Future<PracticeSection> toggleSectionComplete(String sectionId);
  Future<PracticeSection> incrementPracticeCount(
      String sectionId, int practiceSeconds);

  // Daily practice methods
  Future<PracticeSection> toggleDailyCompletion(
      String sectionId, DateTime date);
  Future<PracticeSection> toggleSectionRepeat(String sectionId);

  // Recording methods
  Future<PracticeRecording> createRecording(PracticeRecording recording);
  Future<void> deleteRecording(String id);
  Future<PracticeSection> setRepresentativeRecording(
      String sectionId, String recordingId);

  // Section order methods
  Future<void> updateSectionOrders(
      String repertoireId, List<String> sectionIds);
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
  Future<List<({PracticeRecording recording, PracticeSection? section, PracticeRepertoire? repertoire})>>
      getAllRecordingsWithSectionInfo();

  // Import recording from external file
  Future<PracticeRecording> importRecording(String sourceFilePath, int durationSeconds);

  // Cache management
  Future<void> reloadFromHive();

  // File path repair (for recordings restored from backup with wrong paths)
  Future<int> repairRecordingFilePaths();

  // Diagnostic stats
  Future<Map<String, int>> getRecordingStats();
}

/// Mock implementation for development
class MockPracticeRepertoireRepository implements PracticeRepertoireRepository {
  static const String _recordingsBoxName = 'practice_recordings';
  static const String _repertoiresBoxName = 'practice_repertoires';

  final _uuid = const Uuid();
  final Map<String, List<PracticeRepertoire>> _repertoires = {};

  Box<PracticeRecording>? _recordingsBox;
  Box? _repertoiresBox;
  bool _isInitialized = false;
  Future<void>? _initializationFuture;

  Future<Box<PracticeRecording>> get _practiceRecordingsBox async {
    if (_recordingsBox != null && _recordingsBox!.isOpen) {
      return _recordingsBox!;
    }
    _recordingsBox = await Hive.openBox<PracticeRecording>(_recordingsBoxName);
    debugPrint('PracticeRepertoireRepository: Opened recordings box with ${_recordingsBox!.length} recordings');
    return _recordingsBox!;
  }

  Future<Box> get _practiceRepertoiresBox async {
    if (_repertoiresBox != null && _repertoiresBox!.isOpen) {
      return _repertoiresBox!;
    }
    _repertoiresBox = await Hive.openBox(_repertoiresBoxName);
    debugPrint('PracticeRepertoireRepository: Opened repertoires box with ${_repertoiresBox!.length} entries');
    return _repertoiresBox!;
  }

  MockPracticeRepertoireRepository() {
    _initMockData();
    _initializationFuture = _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    if (_isInitialized) return;
    await _loadPersistedRepertoires();
    await _loadPersistedRecordings();
    _isInitialized = true;
    debugPrint('PracticeRepertoireRepository: Initialization complete');
  }

  /// Ensure initialization is complete before accessing data
  Future<void> _ensureInitialized() async {
    if (!_isInitialized && _initializationFuture != null) {
      await _initializationFuture;
    }
  }

  /// Load persisted repertoires from Hive
  Future<void> _loadPersistedRepertoires() async {
    try {
      final box = await _practiceRepertoiresBox;
      debugPrint('PracticeRepertoireRepository: Loading ${box.length} persisted repertoires');

      for (final key in box.keys) {
        try {
          final jsonString = box.get(key) as String?;
          if (jsonString != null) {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final repertoire = PracticeRepertoire.fromJson(json);
            _repertoires.putIfAbsent(repertoire.studentId, () => []);

            // Check if already exists
            final existingIndex = _repertoires[repertoire.studentId]!
                .indexWhere((r) => r.id == repertoire.id);
            if (existingIndex == -1) {
              _repertoires[repertoire.studentId]!.add(repertoire);
            }
          }
        } catch (e) {
          debugPrint('PracticeRepertoireRepository: Failed to parse repertoire $key: $e');
        }
      }
    } catch (e) {
      debugPrint('PracticeRepertoireRepository: Failed to load persisted repertoires: $e');
    }
  }

  /// Save all repertoires to Hive
  Future<void> _saveRepertoiresToHive() async {
    try {
      final box = await _practiceRepertoiresBox;

      // Collect all repertoire IDs that should exist
      final allRepertoireIds = <String>{};

      for (final repertoires in _repertoires.values) {
        for (final repertoire in repertoires) {
          allRepertoireIds.add(repertoire.id);
          final jsonString = jsonEncode(repertoire.toJson());
          await box.put(repertoire.id, jsonString);
        }
      }

      // Remove deleted repertoires from Hive
      final keysToRemove = <dynamic>[];
      for (final key in box.keys) {
        if (!allRepertoireIds.contains(key)) {
          keysToRemove.add(key);
        }
      }
      for (final key in keysToRemove) {
        await box.delete(key);
      }

      await box.flush();
    } catch (e) {
      debugPrint('PracticeRepertoireRepository: Failed to save repertoires to Hive: $e');
    }
  }

  /// Load persisted recordings from Hive and merge with mock sections
  Future<void> _loadPersistedRecordings() async {
    try {
      final box = await _practiceRecordingsBox;
      debugPrint('PracticeRepertoireRepository: Loading ${box.length} persisted recordings');

      for (final recording in box.values) {
        _addRecordingToSection(recording);
      }
    } catch (e) {
      debugPrint('PracticeRepertoireRepository: Failed to load persisted recordings: $e');
    }
  }

  /// Add a recording to the corresponding section in memory
  void _addRecordingToSection(PracticeRecording recording) {
    for (final repertoires in _repertoires.values) {
      for (int i = 0; i < repertoires.length; i++) {
        final repertoire = repertoires[i];
        final sectionIndex = repertoire.sections.indexWhere(
          (s) => s.id == recording.sectionId,
        );
        if (sectionIndex != -1) {
          final section = repertoire.sections[sectionIndex];

          // Check if recording already exists
          if (section.recordings.any((r) => r.id == recording.id)) {
            return;
          }

          final updatedRecordings = List<PracticeRecording>.from(section.recordings)
            ..add(recording);
          final updatedSection = section.copyWith(recordings: updatedRecordings);
          final updatedSections = List<PracticeSection>.from(repertoire.sections);
          updatedSections[sectionIndex] = updatedSection;
          repertoires[i] = repertoire.copyWith(sections: updatedSections);
          debugPrint('PracticeRepertoireRepository: Added persisted recording ${recording.id.substring(0, 8)}... to section ${recording.sectionId}');
          return;
        }
      }
    }
  }

  void _initMockData() {
    // No dummy data - users create their own repertoires and sections
  }

  @override
  Future<List<PracticeRepertoire>> getRepertoires(String studentId) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    return _repertoires[studentId] ?? [];
  }

  @override
  Future<List<PracticeRepertoire>> getRepertoiresForDate(
      String studentId, DateTime date) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    final repertoires = _repertoires[studentId] ?? [];
    return repertoires.where((r) => r.isActiveForDate(date) && !r.isArchived).toList();
  }

  @override
  Future<PracticeRepertoire?> getRepertoire(String id) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    for (final repertoires in _repertoires.values) {
      try {
        return repertoires.firstWhere((r) => r.id == id);
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
      id: _uuid.v4(),
      studentId: repertoire.studentId,
      name: repertoire.name,
      description: repertoire.description,
      startDate: repertoire.startDate,
      endDate: repertoire.endDate,
      sections: [],
      createdAt: now,
    );
    _repertoires.putIfAbsent(repertoire.studentId, () => []);
    _repertoires[repertoire.studentId]!.add(newRepertoire);

    // Persist to Hive
    await _saveRepertoiresToHive();

    return newRepertoire;
  }

  @override
  Future<PracticeRepertoire> updateRepertoire(
      PracticeRepertoire repertoire) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final repertoires = _repertoires[repertoire.studentId];
    if (repertoires == null) throw Exception('Student not found');

    final index = repertoires.indexWhere((r) => r.id == repertoire.id);
    if (index == -1) throw Exception('Repertoire not found');

    final updated = repertoire.copyWith(updatedAt: DateTime.now());
    repertoires[index] = updated;

    // Persist to Hive
    await _saveRepertoiresToHive();

    return updated;
  }

  @override
  Future<void> deleteRepertoire(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (final repertoires in _repertoires.values) {
      repertoires.removeWhere((r) => r.id == id);
    }

    // Persist to Hive
    await _saveRepertoiresToHive();
  }

  @override
  Future<PracticeSection?> getSection(String id) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    for (final repertoires in _repertoires.values) {
      for (final repertoire in repertoires) {
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
      id: _uuid.v4(),
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
    );

    // Find and update the repertoire
    for (final repertoires in _repertoires.values) {
      final repIndex =
          repertoires.indexWhere((r) => r.id == section.repertoireId);
      if (repIndex != -1) {
        final repertoire = repertoires[repIndex];
        final updatedSections = [...repertoire.sections, newSection];
        repertoires[repIndex] = repertoire.copyWith(
          sections: updatedSections,
          updatedAt: DateTime.now(),
        );

        // Persist to Hive
        await _saveRepertoiresToHive();

        return newSection;
      }
    }
    throw Exception('Repertoire not found');
  }

  @override
  Future<PracticeSection> updateSection(PracticeSection section) async {
    await Future.delayed(const Duration(milliseconds: 300));

    for (final repertoires in _repertoires.values) {
      for (int i = 0; i < repertoires.length; i++) {
        final repertoire = repertoires[i];
        final sectionIndex =
            repertoire.sections.indexWhere((s) => s.id == section.id);
        if (sectionIndex != -1) {
          final updatedSection = section.copyWith(updatedAt: DateTime.now());
          final updatedSections = List<PracticeSection>.from(repertoire.sections);
          updatedSections[sectionIndex] = updatedSection;
          repertoires[i] = repertoire.copyWith(
            sections: updatedSections,
            updatedAt: DateTime.now(),
          );

          // Persist to Hive
          await _saveRepertoiresToHive();

          return updatedSection;
        }
      }
    }
    throw Exception('Section not found');
  }

  @override
  Future<void> deleteSection(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    for (final repertoires in _repertoires.values) {
      for (int i = 0; i < repertoires.length; i++) {
        final repertoire = repertoires[i];
        final sectionIndex = repertoire.sections.indexWhere((s) => s.id == id);
        if (sectionIndex != -1) {
          final updatedSections = List<PracticeSection>.from(repertoire.sections);
          updatedSections.removeAt(sectionIndex);
          repertoires[i] = repertoire.copyWith(
            sections: updatedSections,
            updatedAt: DateTime.now(),
          );

          // Persist to Hive
          await _saveRepertoiresToHive();

          return;
        }
      }
    }
  }

  @override
  Future<PracticeSection> toggleSectionComplete(String sectionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final repertoires in _repertoires.values) {
      for (int i = 0; i < repertoires.length; i++) {
        final repertoire = repertoires[i];
        final sectionIndex =
            repertoire.sections.indexWhere((s) => s.id == sectionId);
        if (sectionIndex != -1) {
          final section = repertoire.sections[sectionIndex];
          final newIsCompleted = !section.isCompleted;

          // Also update today's dailyStatus to sync with isCompleted
          List<DailyPracticeStatus> updatedStatuses;
          final existingIndex = section.dailyStatuses.indexWhere(
              (s) => s.dateOnly == today);

          if (existingIndex != -1) {
            // Update existing status for today
            updatedStatuses = List.from(section.dailyStatuses);
            updatedStatuses[existingIndex] = section.dailyStatuses[existingIndex].copyWith(
              isCompleted: newIsCompleted,
              completedAt: newIsCompleted ? now : null,
            );
          } else if (newIsCompleted) {
            // Create new completed status for today
            updatedStatuses = [
              ...section.dailyStatuses,
              DailyPracticeStatus(
                id: _uuid.v4(),
                sectionId: sectionId,
                date: today,
                isCompleted: true,
                completedAt: now,
              ),
            ];
          } else {
            // Not completing and no existing status - keep as is
            updatedStatuses = section.dailyStatuses;
          }

          final updatedSection = section.copyWith(
            isCompleted: newIsCompleted,
            completedAt: newIsCompleted ? now : null,
            dailyStatuses: updatedStatuses,
            updatedAt: now,
          );
          final updatedSections = List<PracticeSection>.from(repertoire.sections);
          updatedSections[sectionIndex] = updatedSection;
          repertoires[i] = repertoire.copyWith(
            sections: updatedSections,
            updatedAt: now,
          );

          // Persist to Hive
          await _saveRepertoiresToHive();

          return updatedSection;
        }
      }
    }
    throw Exception('Section not found');
  }

  @override
  Future<PracticeSection> incrementPracticeCount(
      String sectionId, int practiceSeconds) async {
    await Future.delayed(const Duration(milliseconds: 200));

    for (final repertoires in _repertoires.values) {
      for (int i = 0; i < repertoires.length; i++) {
        final repertoire = repertoires[i];
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
          final updatedSections = List<PracticeSection>.from(repertoire.sections);
          updatedSections[sectionIndex] = updatedSection;
          repertoires[i] = repertoire.copyWith(
            sections: updatedSections,
            updatedAt: DateTime.now(),
          );

          // Persist to Hive
          await _saveRepertoiresToHive();

          return updatedSection;
        }
      }
    }
    throw Exception('Section not found');
  }

  @override
  Future<PracticeSection> toggleDailyCompletion(
      String sectionId, DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dateKey = PracticeSection.dateToKey(dateOnly);

    for (final repertoires in _repertoires.values) {
      for (int i = 0; i < repertoires.length; i++) {
        final repertoire = repertoires[i];
        final sectionIndex =
            repertoire.sections.indexWhere((s) => s.id == sectionId);
        if (sectionIndex != -1) {
          final section = repertoire.sections[sectionIndex];

          PracticeSection updatedSection;

          // Handle N회 반복 mode
          if (section.hasRepeatCount) {
            final currentCount = section.getRepeatCompletedCount(dateOnly);
            final maxCount = section.repeatCount!;

            // Increment count (cycle: 0 -> 1 -> 2 -> ... -> max -> 0)
            final newCount = (currentCount >= maxCount) ? 0 : currentCount + 1;
            final updatedCounts = Map<String, int>.from(section.dailyRepeatCounts);
            if (newCount == 0) {
              updatedCounts.remove(dateKey);
            } else {
              updatedCounts[dateKey] = newCount;
            }

            // Also update dailyStatuses for compatibility
            final existingIndex = section.dailyStatuses.indexWhere(
                (s) => s.dateOnly == dateOnly);
            List<DailyPracticeStatus> updatedStatuses;
            final isNowCompleted = newCount >= maxCount;

            if (existingIndex != -1) {
              updatedStatuses = List.from(section.dailyStatuses);
              updatedStatuses[existingIndex] = section.dailyStatuses[existingIndex].copyWith(
                isCompleted: isNowCompleted,
                completedAt: isNowCompleted ? DateTime.now() : null,
              );
            } else if (isNowCompleted) {
              updatedStatuses = [
                ...section.dailyStatuses,
                DailyPracticeStatus(
                  id: _uuid.v4(),
                  sectionId: sectionId,
                  date: dateOnly,
                  isCompleted: true,
                  completedAt: DateTime.now(),
                ),
              ];
            } else {
              updatedStatuses = section.dailyStatuses;
            }

            updatedSection = section.copyWith(
              dailyRepeatCounts: updatedCounts,
              dailyStatuses: updatedStatuses,
              updatedAt: DateTime.now(),
            );
          } else {
            // Standard toggle mode (existing behavior)
            final existingIndex = section.dailyStatuses.indexWhere(
                (s) => s.dateOnly == dateOnly);

            List<DailyPracticeStatus> updatedStatuses;
            if (existingIndex != -1) {
              final existing = section.dailyStatuses[existingIndex];
              updatedStatuses = List.from(section.dailyStatuses);
              updatedStatuses[existingIndex] = existing.copyWith(
                isCompleted: !existing.isCompleted,
                completedAt: !existing.isCompleted ? DateTime.now() : null,
              );
            } else {
              updatedStatuses = [
                ...section.dailyStatuses,
                DailyPracticeStatus(
                  id: _uuid.v4(),
                  sectionId: sectionId,
                  date: dateOnly,
                  isCompleted: true,
                  completedAt: DateTime.now(),
                ),
              ];
            }

            updatedSection = section.copyWith(
              dailyStatuses: updatedStatuses,
              updatedAt: DateTime.now(),
            );
          }

          final updatedSections =
              List<PracticeSection>.from(repertoire.sections);
          updatedSections[sectionIndex] = updatedSection;
          repertoires[i] = repertoire.copyWith(
            sections: updatedSections,
            updatedAt: DateTime.now(),
          );

          // Persist to Hive
          await _saveRepertoiresToHive();

          return updatedSection;
        }
      }
    }
    throw Exception('Section not found');
  }

  @override
  Future<PracticeSection> toggleSectionRepeat(String sectionId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    for (final repertoires in _repertoires.values) {
      for (int i = 0; i < repertoires.length; i++) {
        final repertoire = repertoires[i];
        final sectionIndex =
            repertoire.sections.indexWhere((s) => s.id == sectionId);
        if (sectionIndex != -1) {
          final section = repertoire.sections[sectionIndex];
          final updatedSection = section.copyWith(
            isRepeat: !section.isRepeat,
            updatedAt: DateTime.now(),
          );
          final updatedSections =
              List<PracticeSection>.from(repertoire.sections);
          updatedSections[sectionIndex] = updatedSection;
          repertoires[i] = repertoire.copyWith(
            sections: updatedSections,
            updatedAt: DateTime.now(),
          );

          // Persist to Hive
          await _saveRepertoiresToHive();

          return updatedSection;
        }
      }
    }
    throw Exception('Section not found');
  }

  @override
  Future<PracticeRecording> createRecording(PracticeRecording recording) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newRecording = PracticeRecording(
      id: _uuid.v4(),
      sectionId: recording.sectionId,
      filePath: recording.filePath,
      durationSeconds: recording.durationSeconds,
      bpm: recording.bpm,
      isRepresentative: recording.isRepresentative,
      createdAt: DateTime.now(),
    );

    // Save to Hive for persistence
    try {
      final box = await _practiceRecordingsBox;
      await box.put(newRecording.id, newRecording);
      await box.flush();
      debugPrint('=== PracticeRepertoireRepository: Recording saved to Hive ===');
      debugPrint('  ID: ${newRecording.id}');
      debugPrint('  sectionId: ${newRecording.sectionId}');
      debugPrint('  filePath: ${newRecording.filePath}');
      debugPrint('  Box length: ${box.length}');
      debugPrint('=== Recording persisted successfully ===');
    } catch (e) {
      debugPrint('PracticeRepertoireRepository: Failed to persist recording: $e');
    }

    // Find and update the section in memory
    for (final repertoires in _repertoires.values) {
      for (int i = 0; i < repertoires.length; i++) {
        final repertoire = repertoires[i];
        final sectionIndex =
            repertoire.sections.indexWhere((s) => s.id == recording.sectionId);
        if (sectionIndex != -1) {
          final section = repertoire.sections[sectionIndex];

          // If this is marked as representative, unmark others
          List<PracticeRecording> updatedRecordings;
          if (newRecording.isRepresentative) {
            updatedRecordings = section.recordings
                .map((r) => r.copyWith(isRepresentative: false))
                .toList();
          } else {
            updatedRecordings = List.from(section.recordings);
          }
          updatedRecordings.add(newRecording);

          final updatedSection = section.copyWith(
            recordings: updatedRecordings,
            updatedAt: DateTime.now(),
          );
          final updatedSections = List<PracticeSection>.from(repertoire.sections);
          updatedSections[sectionIndex] = updatedSection;
          repertoires[i] = repertoire.copyWith(
            sections: updatedSections,
            updatedAt: DateTime.now(),
          );

          // Persist to Hive
          await _saveRepertoiresToHive();

          return newRecording;
        }
      }
    }
    throw Exception('Section not found');
  }

  @override
  Future<void> deleteRecording(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Get file path before deleting from Hive
    String? filePath;
    try {
      final box = await _practiceRecordingsBox;
      final recording = box.get(id);
      if (recording != null) {
        filePath = recording.filePath;
      }
    } catch (e) {
      debugPrint('PracticeRepertoireRepository: Failed to get recording for file deletion: $e');
    }

    // Delete actual audio file and trim metadata
    if (filePath != null) {
      try {
        final audioFile = File(filePath);
        if (await audioFile.exists()) {
          await audioFile.delete();
          debugPrint('PracticeRepertoireRepository: Deleted audio file: $filePath');
        }
        // Also delete .trim metadata file if exists
        final trimFile = File('$filePath.trim');
        if (await trimFile.exists()) {
          await trimFile.delete();
          debugPrint('PracticeRepertoireRepository: Deleted trim file: $filePath.trim');
        }
      } catch (e) {
        debugPrint('PracticeRepertoireRepository: Failed to delete audio file: $e');
      }
    }

    // Delete from Hive
    try {
      final box = await _practiceRecordingsBox;
      await box.delete(id);
      await box.flush();
      debugPrint('PracticeRepertoireRepository: Deleted recording $id from Hive (flushed)');
    } catch (e) {
      debugPrint('PracticeRepertoireRepository: Failed to delete recording from Hive: $e');
    }

    // Delete from memory
    for (final repertoires in _repertoires.values) {
      for (int i = 0; i < repertoires.length; i++) {
        final repertoire = repertoires[i];
        for (int j = 0; j < repertoire.sections.length; j++) {
          final section = repertoire.sections[j];
          final recordingIndex =
              section.recordings.indexWhere((r) => r.id == id);
          if (recordingIndex != -1) {
            final deletedRecording = section.recordings[recordingIndex];
            final wasRepresentative = deletedRecording.isRepresentative;

            var updatedRecordings =
                List<PracticeRecording>.from(section.recordings);
            updatedRecordings.removeAt(recordingIndex);

            // Auto-select newest recording as representative if deleted was representative
            if (wasRepresentative && updatedRecordings.isNotEmpty) {
              // Sort by createdAt descending and set newest as representative
              updatedRecordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              final newestId = updatedRecordings.first.id;
              updatedRecordings = updatedRecordings
                  .map((r) => r.copyWith(isRepresentative: r.id == newestId))
                  .toList();
              debugPrint('PracticeRepertoireRepository: Auto-set recording ${newestId.substring(0, 8)}... as representative');
            }

            final updatedSection = section.copyWith(
              recordings: updatedRecordings,
              updatedAt: DateTime.now(),
            );
            final updatedSections =
                List<PracticeSection>.from(repertoire.sections);
            updatedSections[j] = updatedSection;
            repertoires[i] = repertoire.copyWith(
              sections: updatedSections,
              updatedAt: DateTime.now(),
            );

            // Persist to Hive
            await _saveRepertoiresToHive();

            return;
          }
        }
      }
    }
  }

  @override
  Future<PracticeSection> setRepresentativeRecording(
      String sectionId, String recordingId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    for (final repertoires in _repertoires.values) {
      for (int i = 0; i < repertoires.length; i++) {
        final repertoire = repertoires[i];
        final sectionIndex =
            repertoire.sections.indexWhere((s) => s.id == sectionId);
        if (sectionIndex != -1) {
          final section = repertoire.sections[sectionIndex];
          final updatedRecordings = section.recordings
              .map((r) => r.copyWith(isRepresentative: r.id == recordingId))
              .toList();
          final updatedSection = section.copyWith(
            recordings: updatedRecordings,
            updatedAt: DateTime.now(),
          );
          final updatedSections = List<PracticeSection>.from(repertoire.sections);
          updatedSections[sectionIndex] = updatedSection;
          repertoires[i] = repertoire.copyWith(
            sections: updatedSections,
            updatedAt: DateTime.now(),
          );

          // Persist to Hive
          await _saveRepertoiresToHive();

          return updatedSection;
        }
      }
    }
    throw Exception('Section not found');
  }

  // Archive methods implementation
  @override
  Future<List<PracticeRepertoire>> getActiveRepertoires(String studentId) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    final repertoires = _repertoires[studentId] ?? [];
    return repertoires.where((r) => !r.isArchived).toList();
  }

  @override
  Future<List<PracticeRepertoire>> getArchivedRepertoires(String studentId) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    final repertoires = _repertoires[studentId] ?? [];
    return repertoires.where((r) => r.isArchived).toList();
  }

  @override
  Future<PracticeRepertoire> archiveRepertoire(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();

    for (final repertoires in _repertoires.values) {
      final index = repertoires.indexWhere((r) => r.id == id);
      if (index != -1) {
        final updated = repertoires[index].copyWith(
          isArchived: true,
          archivedAt: now,
          updatedAt: now,
        );
        repertoires[index] = updated;

        // Persist to Hive
        await _saveRepertoiresToHive();

        return updated;
      }
    }
    throw Exception('Repertoire not found');
  }

  @override
  Future<PracticeRepertoire> restoreRepertoire(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();

    for (final repertoires in _repertoires.values) {
      final index = repertoires.indexWhere((r) => r.id == id);
      if (index != -1) {
        final updated = repertoires[index].copyWith(
          isArchived: false,
          updatedAt: now,
        );
        // Clear archivedAt by recreating
        final cleared = PracticeRepertoire(
          id: updated.id,
          studentId: updated.studentId,
          name: updated.name,
          description: updated.description,
          startDate: updated.startDate,
          endDate: updated.endDate,
          sections: updated.sections,
          createdAt: updated.createdAt,
          updatedAt: now,
          isArchived: false,
          archivedAt: null,
        );
        repertoires[index] = cleared;

        // Persist to Hive
        await _saveRepertoiresToHive();

        return cleared;
      }
    }
    throw Exception('Repertoire not found');
  }

  @override
  Future<void> permanentlyDeleteRepertoire(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    for (final repertoires in _repertoires.values) {
      final index = repertoires.indexWhere((r) => r.id == id);
      if (index != -1) {
        // Delete all recordings associated with this repertoire
        final repertoire = repertoires[index];
        for (final section in repertoire.sections) {
          for (final recording in section.recordings) {
            try {
              final audioFile = File(recording.filePath);
              if (await audioFile.exists()) {
                await audioFile.delete();
              }
              final trimFile = File('${recording.filePath}.trim');
              if (await trimFile.exists()) {
                await trimFile.delete();
              }
              // Delete from Hive
              final box = await _practiceRecordingsBox;
              await box.delete(recording.id);
            } catch (e) {
              debugPrint('Failed to delete recording file: $e');
            }
          }
        }
        repertoires.removeAt(index);

        // Persist to Hive
        await _saveRepertoiresToHive();

        return;
      }
    }
  }

  // Section order methods implementation
  @override
  Future<void> updateSectionOrders(
      String repertoireId, List<String> sectionIds) async {
    await Future.delayed(const Duration(milliseconds: 200));

    for (final repertoires in _repertoires.values) {
      final repIndex = repertoires.indexWhere((r) => r.id == repertoireId);
      if (repIndex != -1) {
        final repertoire = repertoires[repIndex];
        final updatedSections = <PracticeSection>[];

        for (int i = 0; i < sectionIds.length; i++) {
          final sectionId = sectionIds[i];
          try {
            final section = repertoire.sections.firstWhere((s) => s.id == sectionId);
            updatedSections.add(section.copyWith(sortOrder: i));
          } catch (_) {
            continue;
          }
        }

        // Add any sections not in the list (shouldn't happen but safety)
        for (final section in repertoire.sections) {
          if (!sectionIds.contains(section.id)) {
            updatedSections.add(section.copyWith(sortOrder: updatedSections.length));
          }
        }

        repertoires[repIndex] = repertoire.copyWith(
          sections: updatedSections,
          updatedAt: DateTime.now(),
        );

        // Persist to Hive
        await _saveRepertoiresToHive();

        return;
      }
    }
    throw Exception('Repertoire not found');
  }

  @override
  Future<PracticeSection> updateLastPracticedAt(String sectionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();

    for (final repertoires in _repertoires.values) {
      for (int i = 0; i < repertoires.length; i++) {
        final repertoire = repertoires[i];
        final sectionIndex =
            repertoire.sections.indexWhere((s) => s.id == sectionId);
        if (sectionIndex != -1) {
          final section = repertoire.sections[sectionIndex];
          final updatedSection = section.copyWith(
            lastPracticedAt: now,
            updatedAt: now,
          );
          final updatedSections = List<PracticeSection>.from(repertoire.sections);
          updatedSections[sectionIndex] = updatedSection;
          repertoires[i] = repertoire.copyWith(
            sections: updatedSections,
            updatedAt: now,
          );

          // Persist to Hive
          await _saveRepertoiresToHive();

          return updatedSection;
        }
      }
    }
    throw Exception('Section not found');
  }

  // Orphan recording methods implementation
  @override
  Future<List<PracticeRecording>> getOrphanedRecordings() async {
    await _ensureInitialized();

    // First, try to repair file paths
    await repairRecordingFilePaths();

    // Get all existing section IDs
    final existingSectionIds = <String>{};
    int totalRepertoires = 0;
    for (final repertoires in _repertoires.values) {
      totalRepertoires += repertoires.length;
      for (final repertoire in repertoires) {
        for (final section in repertoire.sections) {
          existingSectionIds.add(section.id);
        }
      }
    }

    debugPrint('PracticeRepertoireRepository: Loaded $totalRepertoires repertoires with ${existingSectionIds.length} sections');

    // Find recordings whose sectionId doesn't match any existing section
    // Include ALL orphans regardless of file existence (user can decide to delete if file missing)
    final orphanedRecordings = <PracticeRecording>[];
    int totalRecordings = 0;
    try {
      final box = await _practiceRecordingsBox;
      totalRecordings = box.length;
      debugPrint('PracticeRepertoireRepository: Total recordings in Hive: $totalRecordings');

      for (final recording in box.values) {
        final hasMatchingSection = existingSectionIds.contains(recording.sectionId);
        if (!hasMatchingSection) {
          orphanedRecordings.add(recording);
          final audioFile = File(recording.filePath);
          final fileExists = await audioFile.exists();
          debugPrint('PracticeRepertoireRepository: Orphan found - sectionId: ${recording.sectionId}, fileExists: $fileExists');
        }
      }
    } catch (e) {
      debugPrint('PracticeRepertoireRepository: Failed to get orphaned recordings: $e');
    }

    // Sort by creation date (newest first)
    orphanedRecordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    debugPrint('PracticeRepertoireRepository: Found ${orphanedRecordings.length} orphaned recordings');

    return orphanedRecordings;
  }

  @override
  Future<void> reassignRecording(String recordingId, String newSectionId) async {
    await _ensureInitialized();

    // Get the recording from Hive
    final box = await _practiceRecordingsBox;
    final recording = box.get(recordingId);
    if (recording == null) {
      throw Exception('Recording not found');
    }

    // Create updated recording with new sectionId
    final updatedRecording = PracticeRecording(
      id: recording.id,
      sectionId: newSectionId,
      filePath: recording.filePath,
      durationSeconds: recording.durationSeconds,
      bpm: recording.bpm,
      isRepresentative: false, // Reset representative status
      createdAt: recording.createdAt,
    );

    // Update in Hive
    await box.put(recordingId, updatedRecording);
    await box.flush();

    // Add to section in memory
    for (final repertoires in _repertoires.values) {
      for (int i = 0; i < repertoires.length; i++) {
        final repertoire = repertoires[i];
        final sectionIndex =
            repertoire.sections.indexWhere((s) => s.id == newSectionId);
        if (sectionIndex != -1) {
          final section = repertoire.sections[sectionIndex];
          final updatedRecordings = List<PracticeRecording>.from(section.recordings)
            ..add(updatedRecording);
          final updatedSection = section.copyWith(
            recordings: updatedRecordings,
            updatedAt: DateTime.now(),
          );
          final updatedSections = List<PracticeSection>.from(repertoire.sections);
          updatedSections[sectionIndex] = updatedSection;
          repertoires[i] = repertoire.copyWith(
            sections: updatedSections,
            updatedAt: DateTime.now(),
          );

          // Persist to Hive
          await _saveRepertoiresToHive();

          debugPrint('PracticeRepertoireRepository: Reassigned recording $recordingId to section $newSectionId');
          return;
        }
      }
    }
    throw Exception('Section not found');
  }

  @override
  Future<List<({PracticeRepertoire repertoire, PracticeSection section})>>
      getAllSectionsWithRepertoire(String studentId) async {
    await _ensureInitialized();

    final result = <({PracticeRepertoire repertoire, PracticeSection section})>[];
    final repertoires = _repertoires[studentId] ?? [];

    for (final repertoire in repertoires) {
      if (repertoire.isArchived) continue; // Skip archived repertoires
      for (final section in repertoire.sections) {
        result.add((repertoire: repertoire, section: section));
      }
    }

    return result;
  }

  @override
  Future<List<({PracticeRepertoire repertoire, PracticeSection section})>>
      getAllSectionsForAssignment() async {
    await _ensureInitialized();

    final result = <({PracticeRepertoire repertoire, PracticeSection section})>[];

    // Iterate through all users' repertoires
    for (final repertoires in _repertoires.values) {
      for (final repertoire in repertoires) {
        if (repertoire.isArchived) continue; // Skip archived repertoires
        for (final section in repertoire.sections) {
          result.add((repertoire: repertoire, section: section));
        }
      }
    }

    debugPrint('getAllSectionsForAssignment: Found ${result.length} sections from ${_repertoires.keys.length} users');
    return result;
  }

  @override
  Future<List<({PracticeRecording recording, PracticeSection? section, PracticeRepertoire? repertoire})>>
      getAllRecordingsWithSectionInfo() async {
    await _ensureInitialized();

    final box = await _practiceRecordingsBox;
    final allRecordings = box.values.toList();

    // Build a map of sectionId -> (section, repertoire) for quick lookup
    final sectionMap = <String, ({PracticeSection section, PracticeRepertoire repertoire})>{};
    for (final repertoires in _repertoires.values) {
      for (final repertoire in repertoires) {
        for (final section in repertoire.sections) {
          sectionMap[section.id] = (section: section, repertoire: repertoire);
        }
      }
    }

    // Build result with section info
    final result = <({PracticeRecording recording, PracticeSection? section, PracticeRepertoire? repertoire})>[];
    for (final recording in allRecordings) {
      final sectionInfo = sectionMap[recording.sectionId];
      result.add((
        recording: recording,
        section: sectionInfo?.section,
        repertoire: sectionInfo?.repertoire,
      ));
    }

    // Sort by createdAt descending (newest first)
    result.sort((a, b) => b.recording.createdAt.compareTo(a.recording.createdAt));

    debugPrint('getAllRecordingsWithSectionInfo: Found ${result.length} recordings');
    return result;
  }

  @override
  Future<void> reloadFromHive() async {
    debugPrint('PracticeRepertoireRepository: Reloading from Hive...');

    // Clear in-memory cache
    _repertoires.clear();
    _isInitialized = false;

    // Reload from Hive
    await _loadPersistedRepertoires();
    await _loadPersistedRecordings();
    _isInitialized = true;

    debugPrint('PracticeRepertoireRepository: Reload complete. Repertoires: ${_repertoires.values.expand((r) => r).length}');
  }

  @override
  Future<int> repairRecordingFilePaths() async {
    await _ensureInitialized();

    final box = await _practiceRecordingsBox;
    final docsDir = await getApplicationDocumentsDirectory();
    final currentDocsPath = docsDir.path;
    int repairedCount = 0;

    debugPrint('PracticeRepertoireRepository: Repairing file paths...');
    debugPrint('PracticeRepertoireRepository: Current docs path: $currentDocsPath');

    for (final recording in box.values.toList()) {
      final originalPath = recording.filePath;

      // Check if path needs repair (points to different app container)
      if (!originalPath.startsWith(currentDocsPath)) {
        // Find 'recordings/' in the path and rebuild
        final recordingsIndex = originalPath.indexOf('recordings/');
        if (recordingsIndex != -1) {
          final relativePath = originalPath.substring(recordingsIndex);
          final newPath = '$currentDocsPath/$relativePath';

          // Check if file exists at new path
          final newFile = File(newPath);
          if (await newFile.exists()) {
            // Update recording with correct path
            final updatedRecording = PracticeRecording(
              id: recording.id,
              sectionId: recording.sectionId,
              filePath: newPath,
              durationSeconds: recording.durationSeconds,
              bpm: recording.bpm,
              isRepresentative: recording.isRepresentative,
              createdAt: recording.createdAt,
            );
            await box.put(recording.id, updatedRecording);
            repairedCount++;
            debugPrint('PracticeRepertoireRepository: Repaired path for ${recording.id.substring(0, 8)}...');
          } else {
            debugPrint('PracticeRepertoireRepository: File not found at new path: $newPath');
          }
        }
      }
    }

    if (repairedCount > 0) {
      await box.flush();
      // Reload to update in-memory cache
      await reloadFromHive();
    }

    debugPrint('PracticeRepertoireRepository: Repaired $repairedCount recording paths');
    return repairedCount;
  }

  @override
  Future<Map<String, int>> getRecordingStats() async {
    await _ensureInitialized();

    // Count total sections
    int totalSections = 0;
    for (final repertoires in _repertoires.values) {
      for (final repertoire in repertoires) {
        totalSections += repertoire.sections.length;
      }
    }

    // Count total recordings in Hive
    final box = await _practiceRecordingsBox;
    final totalRecordings = box.length;

    // Count recordings with files that exist
    int recordingsWithFiles = 0;
    int recordingsWithMissingFiles = 0;
    for (final recording in box.values) {
      final file = File(recording.filePath);
      if (await file.exists()) {
        recordingsWithFiles++;
      } else {
        recordingsWithMissingFiles++;
        debugPrint('Stats: Missing file - ${recording.filePath}');
      }
    }

    return {
      'totalRecordings': totalRecordings,
      'totalSections': totalSections,
      'recordingsWithFiles': recordingsWithFiles,
      'recordingsWithMissingFiles': recordingsWithMissingFiles,
    };
  }

  @override
  Future<PracticeRecording> importRecording(String sourceFilePath, int durationSeconds) async {
    await _ensureInitialized();

    // Create 'imported' directory for imported recordings
    final appDir = await getApplicationDocumentsDirectory();
    final importedDir = Directory('${appDir.path}/recordings/imported');
    if (!await importedDir.exists()) {
      await importedDir.create(recursive: true);
    }

    // Copy file to app's recordings directory
    final sourceFile = File(sourceFilePath);
    final extension = sourceFilePath.split('.').last;
    final newFileName = '${_uuid.v4()}.$extension';
    final newFilePath = '${importedDir.path}/$newFileName';

    await sourceFile.copy(newFilePath);
    debugPrint('PracticeRepertoireRepository: Copied file to $newFilePath');

    // Create new recording entry with 'imported' as sectionId (will be orphaned)
    final newRecording = PracticeRecording(
      id: _uuid.v4(),
      sectionId: 'imported_${DateTime.now().millisecondsSinceEpoch}', // Unique orphan ID
      filePath: newFilePath,
      durationSeconds: durationSeconds,
      bpm: null,
      isRepresentative: false,
      createdAt: DateTime.now(),
    );

    // Save to Hive
    final box = await _practiceRecordingsBox;
    await box.put(newRecording.id, newRecording);
    await box.flush();
    debugPrint('PracticeRepertoireRepository: Imported recording saved with id: ${newRecording.id}');

    return newRecording;
  }
}
