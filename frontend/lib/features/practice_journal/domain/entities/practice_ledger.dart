import 'package:json_annotation/json_annotation.dart';

import 'endorsement.dart';
import 'guardian_seal.dart';
import 'practice_mark.dart';

part 'practice_ledger.g.dart';

@JsonSerializable(explicitToJson: true)
class PracticeLedger {
  final String childProfileId;
  final int year;
  final int month;
  final List<PracticeMark> marks;
  final List<GuardianSeal> seals;
  final List<Endorsement> endorsements;

  const PracticeLedger({
    required this.childProfileId,
    required this.year,
    required this.month,
    this.marks = const [],
    this.seals = const [],
    this.endorsements = const [],
  });

  factory PracticeLedger.empty({
    required String childProfileId,
    required int year,
    required int month,
  }) =>
      PracticeLedger(childProfileId: childProfileId, year: year, month: month);

  int get markCount => marks.length;

  static DateTime _dayUtc(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  /// (날짜)당 1개. 같은 날이면 더 강한 강도로 갱신(immutable — 새 리스트 반환).
  PracticeLedger upsertMark(DateTime date, MarkIntensity intensity) {
    final day = _dayUtc(date);
    final idx = marks.indexWhere((m) => _dayUtc(m.date) == day);
    final next = [...marks];
    if (idx == -1) {
      next.add(PracticeMark(date: day, intensity: intensity));
    } else if (intensity.isStrongerThan(next[idx].intensity)) {
      next[idx] = next[idx].copyWith(intensity: intensity);
    }
    return copyWith(marks: next);
  }

  PracticeLedger copyWith({
    List<PracticeMark>? marks,
    List<GuardianSeal>? seals,
    List<Endorsement>? endorsements,
  }) => PracticeLedger(
    childProfileId: childProfileId,
    year: year,
    month: month,
    marks: marks ?? this.marks,
    seals: seals ?? this.seals,
    endorsements: endorsements ?? this.endorsements,
  );

  factory PracticeLedger.fromJson(Map<String, dynamic> json) =>
      _$PracticeLedgerFromJson(json);
  Map<String, dynamic> toJson() => _$PracticeLedgerToJson(this);
}
