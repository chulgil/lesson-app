import '../../domain/entities/endorsement.dart';
import '../../domain/entities/guardian_seal.dart';
import '../../domain/entities/practice_ledger.dart';
import '../../domain/entities/practice_mark.dart';
import '../../domain/repositories/practice_journal_repository.dart';

class MockPracticeJournalRepository implements PracticeJournalRepository {
  // key: "$childProfileId:$year-$month"
  final Map<String, PracticeLedger> _store = {};
  static const _latency = Duration(milliseconds: 60);

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
}
