import 'package:json_annotation/json_annotation.dart';

part 'practice_mark.g.dart';

enum MarkIntensity {
  short,
  full;

  /// full > short. 같은 날 재연습 시 더 강한 강도가 우선.
  bool isStrongerThan(MarkIntensity other) => index > other.index;
}

@JsonSerializable()
class PracticeMark {
  final DateTime date;
  final MarkIntensity intensity;

  const PracticeMark({required this.date, required this.intensity});

  PracticeMark copyWith({DateTime? date, MarkIntensity? intensity}) =>
      PracticeMark(
        date: date ?? this.date,
        intensity: intensity ?? this.intensity,
      );

  factory PracticeMark.fromJson(Map<String, dynamic> json) =>
      _$PracticeMarkFromJson(json);
  Map<String, dynamic> toJson() => _$PracticeMarkToJson(this);
}
