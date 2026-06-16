import '../entities/bound_volume.dart';
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

  /// 자녀 프로필의 완성본 목록(volumeNo 오름차순).
  Future<List<BoundVolume>> getBoundVolumes(String childProfileId);

  /// 곡(레퍼토리) 완성 → 완성본 제본.
  ///
  /// 멱등: 같은 [pieceId]가 이미 제본되었으면 기존 완성본을 그대로 반환(중복 제본 방지).
  /// 신규면 volumeNo = (자녀 프로필 기존 완성본 수 + 1)로 생성.
  Future<BoundVolume> bindVolume({
    required String childProfileId,
    required String pieceId,
    required String pieceName,
  });
}
