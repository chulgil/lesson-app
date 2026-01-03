import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
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
}

/// Mock implementation for development
class MockPracticeRepertoireRepository implements PracticeRepertoireRepository {
  static const String _recordingsBoxName = 'practice_recordings';

  final _uuid = const Uuid();
  final Map<String, List<PracticeRepertoire>> _repertoires = {};

  Box<PracticeRecording>? _recordingsBox;

  Future<Box<PracticeRecording>> get _practiceRecordingsBox async {
    if (_recordingsBox != null && _recordingsBox!.isOpen) {
      return _recordingsBox!;
    }
    _recordingsBox = await Hive.openBox<PracticeRecording>(_recordingsBoxName);
    debugPrint('PracticeRepertoireRepository: Opened recordings box with ${_recordingsBox!.length} recordings');
    return _recordingsBox!;
  }

  MockPracticeRepertoireRepository() {
    _initMockData();
    _loadPersistedRecordings();
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Student 1 repertoires
    _repertoires['student_1'] = [
      PracticeRepertoire(
        id: 'rep_1',
        studentId: 'student_1',
        name: '스즈키 6권',
        description: '스즈키 바이올린 교본 6권',
        startDate: now.subtract(const Duration(days: 14)),
        endDate: now.add(const Duration(days: 30)), // Active for 30 more days
        sections: [
          PracticeSection(
            id: 'sec_1_1',
            repertoireId: 'rep_1',
            pieceName: '라 폴리아',
            startMeasure: 1,
            endMeasure: 4,
            isCompleted: false,
            isRepeat: true, // Shows every day
            practiceCount: 15,
            totalPracticeSeconds: 2700, // 45 minutes
            dailyStatuses: [
              DailyPracticeStatus(
                id: 'ds_1_1_1',
                sectionId: 'sec_1_1',
                date: yesterday,
                isCompleted: true,
                completedAt: yesterday,
              ),
            ],
            recordings: [
              PracticeRecording(
                id: 'rec_1_1_1',
                sectionId: 'sec_1_1',
                filePath: '/recordings/rec_1_1_1.m4a',
                durationSeconds: 45,
                isRepresentative: true,
                createdAt: now.subtract(const Duration(days: 1)),
              ),
              PracticeRecording(
                id: 'rec_1_1_2',
                sectionId: 'sec_1_1',
                filePath: '/recordings/rec_1_1_2.m4a',
                durationSeconds: 42,
                isRepresentative: false,
                createdAt: now.subtract(const Duration(days: 3)),
              ),
            ],
            createdAt: now.subtract(const Duration(days: 14)),
          ),
          PracticeSection(
            id: 'sec_1_2',
            repertoireId: 'rep_1',
            pieceName: '가보트',
            startMeasure: 1,
            endMeasure: 8,
            isCompleted: false,
            isRepeat: true, // Shows every day
            practiceCount: 8,
            totalPracticeSeconds: 1440, // 24 minutes
            dailyStatuses: [],
            recordings: [
              PracticeRecording(
                id: 'rec_1_2_1',
                sectionId: 'sec_1_2',
                filePath: '/recordings/rec_1_2_1.m4a',
                durationSeconds: 58,
                isRepresentative: true,
                createdAt: now.subtract(const Duration(days: 1)),
              ),
            ],
            createdAt: now.subtract(const Duration(days: 10)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      PracticeRepertoire(
        id: 'rep_2',
        studentId: 'student_1',
        name: '스케일북',
        description: '기초 스케일 연습',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: null, // Ongoing
        sections: [
          PracticeSection(
            id: 'sec_2_1',
            repertoireId: 'rep_2',
            pieceName: 'G장조 스케일',
            startMeasure: 1,
            endMeasure: 4,
            isCompleted: false,
            isRepeat: true,
            practiceCount: 20,
            totalPracticeSeconds: 3600, // 60 minutes
            dailyStatuses: [
              DailyPracticeStatus(
                id: 'ds_2_1_1',
                sectionId: 'sec_2_1',
                date: today,
                isCompleted: true,
                completedAt: now,
              ),
            ],
            recordings: [
              PracticeRecording(
                id: 'rec_2_1_1',
                sectionId: 'sec_2_1',
                filePath: '/recordings/rec_2_1_1.m4a',
                durationSeconds: 72,
                isRepresentative: true,
                createdAt: now.subtract(const Duration(days: 2)),
              ),
            ],
            createdAt: now.subtract(const Duration(days: 21)),
          ),
          PracticeSection(
            id: 'sec_2_2',
            repertoireId: 'rep_2',
            pieceName: 'D장조 스케일',
            startMeasure: 1,
            endMeasure: 4,
            isCompleted: false,
            isRepeat: true,
            practiceCount: 5,
            totalPracticeSeconds: 900, // 15 minutes
            dailyStatuses: [],
            recordings: [],
            createdAt: now.subtract(const Duration(days: 7)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 21)),
      ),
    ];

    // Student 2 repertoires
    _repertoires['student_2'] = [
      PracticeRepertoire(
        id: 'rep_3',
        studentId: 'student_2',
        name: '체르니 100',
        description: '체르니 100번 연습곡',
        startDate: now.subtract(const Duration(days: 10)),
        endDate: null, // Ongoing
        sections: [
          PracticeSection(
            id: 'sec_3_1',
            repertoireId: 'rep_3',
            pieceName: '1번',
            startMeasure: 1,
            endMeasure: 16,
            isCompleted: false,
            isRepeat: false, // Once done, hide
            practiceCount: 12,
            totalPracticeSeconds: 1800, // 30 minutes
            dailyStatuses: [
              DailyPracticeStatus(
                id: 'ds_3_1_1',
                sectionId: 'sec_3_1',
                date: now.subtract(const Duration(days: 3)),
                isCompleted: true,
                completedAt: now.subtract(const Duration(days: 3)),
              ),
            ],
            recordings: [],
            createdAt: now.subtract(const Duration(days: 10)),
          ),
          PracticeSection(
            id: 'sec_3_2',
            repertoireId: 'rep_3',
            pieceName: '2번',
            startMeasure: 1,
            endMeasure: 16,
            isCompleted: false,
            isRepeat: true,
            practiceCount: 4,
            totalPracticeSeconds: 600, // 10 minutes
            dailyStatuses: [],
            recordings: [],
            createdAt: now.subtract(const Duration(days: 5)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ];
  }

  @override
  Future<List<PracticeRepertoire>> getRepertoires(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _repertoires[studentId] ?? [];
  }

  @override
  Future<List<PracticeRepertoire>> getRepertoiresForDate(
      String studentId, DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final repertoires = _repertoires[studentId] ?? [];
    return repertoires.where((r) => r.isActiveForDate(date)).toList();
  }

  @override
  Future<PracticeRepertoire?> getRepertoire(String id) async {
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
    return updated;
  }

  @override
  Future<void> deleteRepertoire(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (final repertoires in _repertoires.values) {
      repertoires.removeWhere((r) => r.id == id);
    }
  }

  @override
  Future<PracticeSection?> getSection(String id) async {
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
      startMeasure: section.startMeasure,
      endMeasure: section.endMeasure,
      sectionName: section.sectionName,
      isCompleted: false,
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

    for (final repertoires in _repertoires.values) {
      for (int i = 0; i < repertoires.length; i++) {
        final repertoire = repertoires[i];
        final sectionIndex =
            repertoire.sections.indexWhere((s) => s.id == sectionId);
        if (sectionIndex != -1) {
          final section = repertoire.sections[sectionIndex];

          // Find existing status for this date
          final existingIndex = section.dailyStatuses.indexWhere(
              (s) => s.dateOnly == dateOnly);

          List<DailyPracticeStatus> updatedStatuses;
          if (existingIndex != -1) {
            // Toggle existing status
            final existing = section.dailyStatuses[existingIndex];
            updatedStatuses = List.from(section.dailyStatuses);
            updatedStatuses[existingIndex] = existing.copyWith(
              isCompleted: !existing.isCompleted,
              completedAt: !existing.isCompleted ? DateTime.now() : null,
            );
          } else {
            // Create new status as completed
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

          final updatedSection = section.copyWith(
            dailyStatuses: updatedStatuses,
            updatedAt: DateTime.now(),
          );
          final updatedSections =
              List<PracticeSection>.from(repertoire.sections);
          updatedSections[sectionIndex] = updatedSection;
          repertoires[i] = repertoire.copyWith(
            sections: updatedSections,
            updatedAt: DateTime.now(),
          );
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
          return updatedSection;
        }
      }
    }
    throw Exception('Section not found');
  }
}
