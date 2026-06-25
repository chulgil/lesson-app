import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/empty_practice_journal_repository.dart';
import '../../data/repositories/mock_practice_journal_repository.dart';
import '../../domain/entities/bound_volume.dart';
import '../../domain/entities/practice_ledger.dart';
import '../../domain/repositories/practice_journal_repository.dart';

part 'practice_journal_provider.g.dart';

// #872: 백엔드 practice-journal 엔드포인트 미구현. remote 모드에서 Remote 레포가
// 죽은 엔드포인트를 호출하면 연습장 카드가 무한로딩으로 멈춘다. 백엔드가 나오기
// 전까지 fallback stub(빈 장부)으로 전환 — 다른 미구현 기능과 동일 패턴.
@Riverpod(keepAlive: true)
PracticeJournalRepository practiceJournalRepository(
  PracticeJournalRepositoryRef ref,
) => createLocalFallbackRepository<PracticeJournalRepository>(
  ref: ref,
  mock: () => MockPracticeJournalRepository(),
  fallback: () => EmptyPracticeJournalRepository(),
);

@riverpod
Future<PracticeLedger> practiceLedger(
  PracticeLedgerRef ref, {
  required String childProfileId,
  required int year,
  required int month,
}) async {
  final repo = ref.watch(practiceJournalRepositoryProvider);
  return repo.getLedger(childProfileId, year, month);
}

/// 자녀 프로필의 완성본 목록(책장). 곡 완성(제본) 후 invalidate 로 갱신.
@riverpod
Future<List<BoundVolume>> boundVolumes(
  BoundVolumesRef ref,
  String childProfileId,
) async {
  final repo = ref.watch(practiceJournalRepositoryProvider);
  return repo.getBoundVolumes(childProfileId);
}
