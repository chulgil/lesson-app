import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/teacher.dart';
import '../../../../repositories/teacher_repository.dart';

// =============================================================================
// Repository Provider
// =============================================================================

/// Teacher repository provider
final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return MockTeacherRepository();
});

// =============================================================================
// Query Providers
// =============================================================================

/// All teachers provider
final allTeachersProvider = FutureProvider<List<Teacher>>((ref) async {
  final repository = ref.watch(teacherRepositoryProvider);
  return repository.getAllTeachers();
});

/// Single teacher provider
final teacherProvider =
    FutureProvider.family<Teacher?, String>((ref, teacherId) async {
  final repository = ref.watch(teacherRepositoryProvider);
  return repository.getTeacherById(teacherId);
});

/// Featured teachers provider
final featuredTeachersProvider = FutureProvider<List<Teacher>>((ref) async {
  final repository = ref.watch(teacherRepositoryProvider);
  return repository.getFeaturedTeachers();
});

/// Teachers by instrument provider
final teachersByInstrumentProvider =
    FutureProvider.family<List<Teacher>, String>((ref, instrument) async {
  final repository = ref.watch(teacherRepositoryProvider);
  return repository.getTeachersByInstrument(instrument);
});

/// Filtered teachers provider
final filteredTeachersProvider =
    FutureProvider.family<List<Teacher>, TeacherFilter>((ref, filter) async {
  final repository = ref.watch(teacherRepositoryProvider);
  return repository.searchTeachers(filter);
});

// =============================================================================
// State Providers (for UI state)
// =============================================================================

/// Selected instrument filter
final selectedInstrumentFilterProvider = StateProvider<String?>((ref) => null);

/// Search query for teachers
final teacherSearchQueryProvider = StateProvider<String>((ref) => '');

/// Available teachers (filtered by instrument and search)
final availableTeachersProvider = FutureProvider<List<Teacher>>((ref) async {
  final repository = ref.watch(teacherRepositoryProvider);
  final selectedInstrument = ref.watch(selectedInstrumentFilterProvider);
  final searchQuery = ref.watch(teacherSearchQueryProvider).toLowerCase();

  List<Teacher> teachers;

  if (selectedInstrument != null) {
    teachers = await repository.getTeachersByInstrument(selectedInstrument);
  } else {
    teachers = await repository.searchTeachers(
      const TeacherFilter(onlyAvailable: true),
    );
  }

  // Apply search filter
  if (searchQuery.isNotEmpty) {
    teachers = teachers.where((t) {
      return t.name.toLowerCase().contains(searchQuery) ||
          t.instruments.any((i) => i.toLowerCase().contains(searchQuery)) ||
          (t.location?.toLowerCase().contains(searchQuery) ?? false);
    }).toList();
  }

  return teachers;
});
