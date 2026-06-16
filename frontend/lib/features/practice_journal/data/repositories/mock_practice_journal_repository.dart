import '../../domain/entities/bound_volume.dart';
import '../../domain/entities/endorsement.dart';
import '../../domain/entities/guardian_seal.dart';
import '../../domain/entities/practice_ledger.dart';
import '../../domain/entities/practice_mark.dart';
import '../../domain/repositories/practice_journal_repository.dart';

class MockPracticeJournalRepository implements PracticeJournalRepository {
  // key: "$childProfileId:$year-$month"
  final Map<String, PracticeLedger> _store = {};
  // key: childProfileId → 완성본 목록(제본 순서 = volumeNo 순서).
  final Map<String, List<BoundVolume>> _volumes = {};
  static const _latency = Duration(milliseconds: 60);

  MockPracticeJournalRepository() {
    _seedVolumes();
  }

  /// 데모용 완성본 시드(주요 데모 학생 프로필). pieceId 는 시드 전용으로
  /// 실제 레퍼토리 id 와 충돌하지 않게 prefix 를 둔다.
  void _seedVolumes() {
    _volumes['student_1'] = [
      BoundVolume(
        childProfileId: 'student_1',
        pieceId: 'seed-vol-bach-minuet',
        pieceName: '바흐 미뉴에트',
        volumeNo: 1,
        boundDate: DateTime.utc(2026, 3, 12),
      ),
      BoundVolume(
        childProfileId: 'student_1',
        pieceId: 'seed-vol-twinkle',
        pieceName: '작은 별 변주곡',
        volumeNo: 2,
        boundDate: DateTime.utc(2026, 5, 2),
      ),
    ];
    _volumes['student_2'] = [
      BoundVolume(
        childProfileId: 'student_2',
        pieceId: 'seed-vol-canon',
        pieceName: '파헬벨 캐논',
        volumeNo: 1,
        boundDate: DateTime.utc(2026, 4, 20),
      ),
    ];
  }

  String _key(String c, int y, int m) => '$c:$y-$m';

  PracticeLedger _ledgerFor(String c, int y, int m) =>
      _store[_key(c, y, m)] ??
      PracticeLedger.empty(childProfileId: c, year: y, month: m);

  @override
  Future<PracticeLedger> getLedger(String c, int year, int month) async {
    await Future.delayed(_latency);
    return _ledgerFor(c, year, month);
  }

  @override
  Future<void> upsertMark(
    String c,
    DateTime date,
    MarkIntensity intensity,
  ) async {
    await Future.delayed(_latency);
    final l = _ledgerFor(c, date.year, date.month).upsertMark(date, intensity);
    _store[_key(c, date.year, date.month)] = l;
  }

  @override
  Future<void> addGuardianSeal(String c, GuardianSeal seal) async {
    await Future.delayed(_latency);
    final l = _ledgerFor(c, seal.weekStart.year, seal.weekStart.month);
    final ws = DateTime.utc(
      seal.weekStart.year,
      seal.weekStart.month,
      seal.weekStart.day,
    );
    final exists = l.seals.any(
      (s) =>
          DateTime.utc(s.weekStart.year, s.weekStart.month, s.weekStart.day) ==
          ws,
    );
    if (exists) return; // 주당 1개
    _store[_key(c, seal.weekStart.year, seal.weekStart.month)] = l.copyWith(
      seals: [...l.seals, seal],
    );
  }

  @override
  Future<void> addEndorsement(String c, Endorsement e) async {
    await Future.delayed(_latency);
    if (!e.isValid) {
      throw ArgumentError('Endorsement 무효: teacher=과제참조 필수 / self=참조 없음');
    }
    final l = _ledgerFor(c, e.date.year, e.date.month);
    _store[_key(c, e.date.year, e.date.month)] = l.copyWith(
      endorsements: [...l.endorsements, e],
    );
  }

  @override
  Future<List<BoundVolume>> getBoundVolumes(String childProfileId) async {
    await Future.delayed(_latency);
    final list = [...(_volumes[childProfileId] ?? const <BoundVolume>[])];
    list.sort((a, b) => a.volumeNo.compareTo(b.volumeNo));
    return list;
  }

  @override
  Future<BoundVolume> bindVolume({
    required String childProfileId,
    required String pieceId,
    required String pieceName,
  }) async {
    await Future.delayed(_latency);
    final existing = _volumes.putIfAbsent(childProfileId, () => []);
    // 멱등: 같은 곡은 한 번만 제본.
    final already = existing.where((v) => v.pieceId == pieceId);
    if (already.isNotEmpty) return already.first;

    final volume = BoundVolume(
      childProfileId: childProfileId,
      pieceId: pieceId,
      pieceName: pieceName,
      volumeNo: existing.length + 1,
      boundDate: DateTime.now(),
    );
    existing.add(volume);
    return volume;
  }
}
