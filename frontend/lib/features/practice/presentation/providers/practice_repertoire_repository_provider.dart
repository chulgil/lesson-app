import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/environment.dart';
import '../../data/repositories/impl/mock_practice_repertoire_impl.dart';
import '../../data/services/default_repertoire_service.dart';
import '../../domain/repositories/practice_repertoire_repository.dart';

part 'practice_repertoire_repository_provider.g.dart';

/// Practice repertoire repository provider - switches between Mock and Remote.
final practiceRepertoireRepositoryProvider =
    Provider<PracticeRepertoireRepository>((ref) {
      if (EnvironmentConfig.useMockData) {
        return MockPracticeRepertoireRepository();
      }
      // Hive 로컬 저장소 의존 (녹음 파일 관리) — Remote 전환 시 파일 동기화 설계 필요
      return MockPracticeRepertoireRepository();
    });

@Riverpod(keepAlive: true)
Future<void> defaultRepertoireService(Ref ref) async {
  final service = DefaultRepertoireService(
    ref.watch(practiceRepertoireRepositoryProvider),
  );
  await service.ensureDefaultExists();
}
