import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_academy_repository.dart';
import '../../data/repositories/remote_academy_repository.dart';
import '../../domain/entities/academy.dart';
import '../../domain/entities/academy_member.dart';
import '../../domain/entities/academy_student.dart';
import '../../domain/repositories/academy_repository.dart';

part 'academy_detail_provider.g.dart';

// Provider for AcademyRepository — switches Mock ↔ Remote (#554).
@Riverpod(keepAlive: true)
AcademyRepository academyRepository(Ref ref) =>
    createRepository<AcademyRepository>(
      ref: ref,
      mock: () => MockAcademyRepository(),
      remote: (api) => RemoteAcademyRepository(api),
    );

/// Academy base info by id.
@riverpod
Future<Academy?> academyById(Ref ref, String academyId) {
  return ref.watch(academyRepositoryProvider).getById(academyId);
}

/// Academy members (teacher/owner roster).
@riverpod
Future<List<AcademyMember>> academyMembers(Ref ref, String academyId) {
  return ref.watch(academyRepositoryProvider).listMembers(academyId);
}

/// Academy students. 강사 모드면 백엔드가 본인 매칭 학생만 반환 (AC-M2 §6.2).
@riverpod
Future<List<AcademyStudent>> academyStudents(Ref ref, String academyId) {
  return ref.watch(academyRepositoryProvider).listStudents(academyId);
}
