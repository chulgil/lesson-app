import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/mock_practice_journal_repository.dart';
import '../../domain/entities/bound_volume.dart';
import '../../domain/entities/practice_ledger.dart';
import '../../domain/repositories/practice_journal_repository.dart';

part 'practice_journal_provider.g.dart';

@Riverpod(keepAlive: true)
PracticeJournalRepository practiceJournalRepository(
  PracticeJournalRepositoryRef ref,
) => MockPracticeJournalRepository();
// NOTE: Remote 추가 시 createRepository<PracticeJournalRepository>(ref: ref, mock: ..., remote: ...) 로 교체.

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
