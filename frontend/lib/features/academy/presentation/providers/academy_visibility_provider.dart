import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repositories/academy_visibility_repository.dart';
import '../../data/repositories/mock_academy_visibility_repository.dart';

part 'academy_visibility_provider.g.dart';

// Provider for AcademyVisibilityRepository (singleton)
@Riverpod(keepAlive: true)
AcademyVisibilityRepository academyVisibilityRepository(Ref ref) {
  return MockAcademyVisibilityRepository();
}

// Provider for listing teacher's academies
@riverpod
Future<List<TeacherAcademyMembership>> teacherAcademies(
  Ref ref,
  String teacherId,
) async {
  final repository = ref.watch(academyVisibilityRepositoryProvider);
  return repository.listTeacherAcademies(teacherId);
}

// Provider for updating teacher's academy visibility
class AcademyVisibilityNotifier extends AsyncNotifier<void> {
  late final AcademyVisibilityRepository _repository;

  @override
  Future<void> build() async {
    _repository = ref.watch(academyVisibilityRepositoryProvider);
  }

  Future<void> updateConsent(
    String academyId,
    String teacherId,
    bool consent,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateTeacherAcademyConsent(
        academyId,
        teacherId,
        consent,
      );
      // Invalidate the teacherAcademies provider to refresh
      ref.invalidate(teacherAcademiesProvider(teacherId));
    });
  }
}

@Riverpod(keepAlive: true)
AsyncNotifier<void> academyVisibilityNotifier(Ref ref) {
  return AcademyVisibilityNotifier();
}
