import '../entities/endorsement.dart';
import '../entities/guardian_seal.dart';
import '../entities/practice_ledger.dart';
import '../entities/practice_mark.dart';

abstract class PracticeJournalRepository {
  /// (자녀 프로필, 연, 월) 장부 조회. 없으면 빈 장부.
  Future<PracticeLedger> getLedger(String childProfileId, int year, int month);

  /// 연습 도장 업서트(날짜당 1개, full>short).
  Future<void> upsertMark(
    String childProfileId,
    DateTime date,
    MarkIntensity intensity,
  );

  /// 부모 주간 응원·확인 도장(주당 1개).
  Future<void> addGuardianSeal(String childProfileId, GuardianSeal seal);

  /// 검인(선생님 과제 한정) 또는 자가 검인. 무효(Endorsement.isValid==false) 시 ArgumentError.
  Future<void> addEndorsement(String childProfileId, Endorsement endorsement);
}
