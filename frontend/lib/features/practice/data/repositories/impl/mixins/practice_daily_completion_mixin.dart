import '../../../../domain/repositories/practice_repertoire_repository.dart';
import '../../../../domain/entities/practice_repertoire.dart';
import '../practice_repository_base.dart';

/// Mixin for daily completion and toggle operations
mixin PracticeDailyCompletionMixin on PracticeRepositoryBase
    implements PracticeRepertoireRepository {
  @override
  Future<PracticeSection> toggleSectionComplete(String sectionId, {DateTime? date}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = date != null
        ? DateTime(date.year, date.month, date.day)
        : today;
    final isToday = targetDate == today;

    for (final reps in repertoires.values) {
      for (int i = 0; i < reps.length; i++) {
        final repertoire = reps[i];
        final sectionIndex =
            repertoire.sections.indexWhere((s) => s.id == sectionId);
        if (sectionIndex != -1) {
          final section = repertoire.sections[sectionIndex];

          // Determine current completion state for target date
          final existingIndex =
              section.dailyStatuses.indexWhere((s) => s.dateOnly == targetDate);
          final isCurrentlyCompleted = existingIndex != -1
              ? section.dailyStatuses[existingIndex].isCompleted
              : false;
          final newIsCompleted = !isCurrentlyCompleted;

          // Update dailyStatuses for the target date
          List<DailyPracticeStatus> updatedStatuses;

          if (existingIndex != -1) {
            updatedStatuses = List.from(section.dailyStatuses);
            updatedStatuses[existingIndex] =
                section.dailyStatuses[existingIndex].copyWith(
              isCompleted: newIsCompleted,
              completedAt: newIsCompleted ? now : null,
            );
          } else if (newIsCompleted) {
            updatedStatuses = [
              ...section.dailyStatuses,
              DailyPracticeStatus(
                id: uuid.v4(),
                sectionId: sectionId,
                date: targetDate,
                isCompleted: true,
                completedAt: now,
              ),
            ];
          } else {
            updatedStatuses = section.dailyStatuses;
          }

          // Only sync isCompleted global flag when toggling today
          final updatedSection = section.copyWith(
            isCompleted: isToday ? newIsCompleted : section.isCompleted,
            completedAt: isToday
                ? (newIsCompleted ? now : null)
                : section.completedAt,
            dailyStatuses: updatedStatuses,
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
  Future<PracticeSection> toggleDailyCompletion(
      String sectionId, DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dateKey = PracticeSection.dateToKey(dateOnly);

    for (final reps in repertoires.values) {
      for (int i = 0; i < reps.length; i++) {
        final repertoire = reps[i];
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
            final newCount =
                (currentCount >= maxCount) ? 0 : currentCount + 1;
            final updatedCounts =
                Map<String, int>.from(section.dailyRepeatCounts);
            if (newCount == 0) {
              updatedCounts.remove(dateKey);
            } else {
              updatedCounts[dateKey] = newCount;
            }

            // Also update dailyStatuses for compatibility
            final existingIndex =
                section.dailyStatuses.indexWhere((s) => s.dateOnly == dateOnly);
            List<DailyPracticeStatus> updatedStatuses;
            final isNowCompleted = newCount >= maxCount;

            if (existingIndex != -1) {
              updatedStatuses = List.from(section.dailyStatuses);
              updatedStatuses[existingIndex] =
                  section.dailyStatuses[existingIndex].copyWith(
                isCompleted: isNowCompleted,
                completedAt: isNowCompleted ? DateTime.now() : null,
              );
            } else if (isNowCompleted) {
              updatedStatuses = [
                ...section.dailyStatuses,
                DailyPracticeStatus(
                  id: uuid.v4(),
                  sectionId: sectionId,
                  date: dateOnly,
                  isCompleted: true,
                  completedAt: DateTime.now(),
                ),
              ];
            } else {
              updatedStatuses = section.dailyStatuses;
            }

            // Sync practiceCount with paw print changes
            int updatedPracticeCount = section.practiceCount;
            if (newCount > currentCount) {
              // Incrementing: add 1 to practiceCount
              updatedPracticeCount += 1;
            } else if (newCount == 0 && currentCount > 0) {
              // Resetting: subtract currentCount from practiceCount
              updatedPracticeCount =
                  (updatedPracticeCount - currentCount).clamp(0, updatedPracticeCount);
            }

            // 🆕 Fix #8: Sync isCompleted if toggling today's date
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final isToday = dateOnly == today;

            updatedSection = section.copyWith(
              dailyRepeatCounts: updatedCounts,
              dailyStatuses: updatedStatuses,
              practiceCount: updatedPracticeCount,
              // 🆕 Sync isCompleted with today's completion status
              isCompleted: isToday ? isNowCompleted : section.isCompleted,
              completedAt: isToday && isNowCompleted ? now : (isToday ? null : section.completedAt),
              updatedAt: DateTime.now(),
            );
          } else {
            // Standard toggle mode (existing behavior)
            final existingIndex =
                section.dailyStatuses.indexWhere((s) => s.dateOnly == dateOnly);

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
                  id: uuid.v4(),
                  sectionId: sectionId,
                  date: dateOnly,
                  isCompleted: true,
                  completedAt: DateTime.now(),
                ),
              ];
            }

            // 🆕 Fix #8: Sync isCompleted if toggling today's date (Standard mode)
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final isToday = dateOnly == today;

            // Determine if today is now completed
            bool? todayCompleted;
            if (isToday) {
              final todayStatus = updatedStatuses.firstWhere(
                (s) => s.dateOnly == today,
                orElse: () => DailyPracticeStatus(
                  id: '',
                  sectionId: sectionId,
                  date: today,
                  isCompleted: false,
                ),
              );
              todayCompleted = todayStatus.isCompleted;
            }

            updatedSection = section.copyWith(
              dailyStatuses: updatedStatuses,
              // 🆕 Sync isCompleted with today's completion status
              isCompleted: isToday ? todayCompleted : section.isCompleted,
              completedAt: isToday && (todayCompleted ?? false) ? now : (isToday ? null : section.completedAt),
              updatedAt: DateTime.now(),
            );
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
  Future<PracticeSection> toggleSectionRepeat(String sectionId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    for (final reps in repertoires.values) {
      for (int i = 0; i < reps.length; i++) {
        final repertoire = reps[i];
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
}
