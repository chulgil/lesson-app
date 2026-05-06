import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../../features/profile/domain/entities/teacher.dart';
import '../../../profile/data/repositories/mock_teacher_repository.dart';
import '../../../profile/domain/repositories/teacher_repository.dart';
import '../../data/repositories/remote_teacher_repository.dart';

part 'teacher_providers.g.dart';

// =============================================================================
// Repository Provider
// =============================================================================

/// Teacher repository provider
@Riverpod(keepAlive: true)
TeacherRepository teacherRepository(TeacherRepositoryRef ref) {
  return createRepository<TeacherRepository>(
    ref: ref,
    mock: () => MockTeacherRepository(),
    remote: (api) => RemoteTeacherRepository(api),
  );
}

// =============================================================================
// Query Providers
// =============================================================================

/// All teachers provider
@Riverpod(keepAlive: true)
Future<List<Teacher>> allTeachers(AllTeachersRef ref) async {
  final repository = ref.watch(teacherRepositoryProvider);
  return repository.getAllTeachers();
}

/// Single teacher provider
@Riverpod(keepAlive: true)
Future<Teacher?> teacher(TeacherRef ref, String teacherId) async {
  final repository = ref.watch(teacherRepositoryProvider);
  return repository.getTeacherById(teacherId);
}

/// Featured teachers provider
@Riverpod(keepAlive: true)
Future<List<Teacher>> featuredTeachers(FeaturedTeachersRef ref) async {
  final repository = ref.watch(teacherRepositoryProvider);
  return repository.getFeaturedTeachers();
}

/// Teachers by instrument provider
@Riverpod(keepAlive: true)
Future<List<Teacher>> teachersByInstrument(
  TeachersByInstrumentRef ref,
  String instrument,
) async {
  final repository = ref.watch(teacherRepositoryProvider);
  return repository.getTeachersByInstrument(instrument);
}

/// Filtered teachers provider
@Riverpod(keepAlive: true)
Future<List<Teacher>> filteredTeachers(
  FilteredTeachersRef ref,
  TeacherFilter filter,
) async {
  final repository = ref.watch(teacherRepositoryProvider);
  return repository.searchTeachers(filter);
}

// =============================================================================
// State Providers (for UI state)
// =============================================================================

/// Selected instrument filter
@Riverpod(keepAlive: true)
class SelectedInstrumentFilter extends _$SelectedInstrumentFilter {
  @override
  String? build() => null;
}

/// Search query for teachers
@Riverpod(keepAlive: true)
class TeacherSearchQuery extends _$TeacherSearchQuery {
  @override
  String build() => '';
}

/// Available teachers (filtered by instrument and search)
@Riverpod(keepAlive: true)
Future<List<Teacher>> availableTeachers(AvailableTeachersRef ref) async {
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
    teachers =
        teachers.where((t) {
          return t.name.toLowerCase().contains(searchQuery) ||
              t.instruments.any((i) => i.toLowerCase().contains(searchQuery)) ||
              (t.location?.toLowerCase().contains(searchQuery) ?? false);
        }).toList();
  }

  return teachers;
}
