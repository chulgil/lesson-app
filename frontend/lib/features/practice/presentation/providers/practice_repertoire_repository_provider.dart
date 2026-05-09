import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/impl/mock_practice_repertoire_impl.dart';
import '../../data/services/default_repertoire_service.dart';
import '../../domain/repositories/practice_repertoire_repository.dart';

part 'practice_repertoire_repository_provider.g.dart';

/// Practice repertoire repository provider - switches between Mock and Remote.
@Riverpod(keepAlive: true)
PracticeRepertoireRepository practiceRepertoireRepository(Ref ref) {
  return createLocalFallbackRepository<PracticeRepertoireRepository>(
    ref: ref,
    mock: MockPracticeRepertoireRepository.new,
    // Hive 로컬 저장소 의존 (녹음 파일 관리) — Remote 전환 시 파일 동기화 설계 필요
    fallback: MockPracticeRepertoireRepository.new,
  );
}

@Riverpod(keepAlive: true)
Future<void> defaultRepertoireService(Ref ref) async {
  final service = DefaultRepertoireService(
    ref.watch(practiceRepertoireRepositoryProvider),
  );
  await service.ensureDefaultExists();
}
