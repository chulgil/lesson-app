import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/academy_activity_log.dart';
import '../../domain/repositories/academy_activity_repository.dart';
import '../../data/repositories/mock_academy_activity_repository.dart';

part 'academy_activity_provider.g.dart';

// Provider for AcademyActivityRepository (singleton)
@Riverpod(keepAlive: true)
AcademyActivityRepository academyActivityRepository(Ref ref) {
  return MockAcademyActivityRepository();
}

// Provider for listing activity logs by academy and actor
@riverpod
Future<List<AcademyActivityLog>> academyActivityLogs(
  Ref ref,
  String academyId,
  String actorMemberId,
) async {
  final repository = ref.watch(academyActivityRepositoryProvider);
  return repository.listByAcademyAndActor(academyId, actorMemberId);
}
