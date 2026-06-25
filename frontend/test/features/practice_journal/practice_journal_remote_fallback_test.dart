import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/features/practice_journal/data/repositories/empty_practice_journal_repository.dart';
import 'package:lessonaza/features/practice_journal/presentation/providers/practice_journal_provider.dart';

void main() {
  // #872: practice_journal 백엔드 엔드포인트 미구현. remote 모드(소셜 로그인)에서
  // Remote 레포가 죽은 엔드포인트를 호출하면 연습장 카드가 무한로딩으로 멈춘다.
  // fallback stub 으로 전환해 네트워크 호출 없이 빈 상태로 정착해야 한다.
  group('practice_journal remote fallback', () {
    test('remote 모드: 레포는 EmptyPracticeJournalRepository (죽은 엔드포인트 미호출)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // social login → remote mode
      container.read(dataModeProvider.notifier).setMockMode(false);

      final repo = container.read(practiceJournalRepositoryProvider);
      expect(repo, isA<EmptyPracticeJournalRepository>());
    });

    test('remote 모드: getLedger 가 네트워크 없이 빈 장부로 즉시 정착', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(dataModeProvider.notifier).setMockMode(false);

      final repo = container.read(practiceJournalRepositoryProvider);
      final ledger = await repo.getLedger('any-id', 2026, 6);

      expect(ledger.marks, isEmpty);
      expect(ledger.seals, isEmpty);
      expect(ledger.endorsements, isEmpty);

      final volumes = await repo.getBoundVolumes('any-id');
      expect(volumes, isEmpty);
    });
  });
}
