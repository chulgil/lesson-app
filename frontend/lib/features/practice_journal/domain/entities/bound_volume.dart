import 'package:json_annotation/json_annotation.dart';

part 'bound_volume.g.dart';

/// 완성본(`BoundVolume`) — 곡(레퍼토리)을 끝내면 제본되는 한 권.
///
/// 책등은 로마숫자(VOL. I·II·III)로 렌더된다(presentation `romanOf`).
/// [volumeNo]는 자녀 프로필별 1부터 증가. 표시 변환 getter는 두지 않는다
/// (`flutter-architecture.md` — 도메인 순수성).
@JsonSerializable()
class BoundVolume {
  final String childProfileId;

  /// 완성한 곡(레퍼토리) 식별자. 자녀 프로필 내 중복 제본 방지 키.
  final String pieceId;

  /// 곡(레퍼토리) 이름 — 책등/축하 표시용.
  final String pieceName;

  /// 자녀 프로필별 1부터 증가하는 권 번호(로마 렌더).
  final int volumeNo;

  final DateTime boundDate;

  const BoundVolume({
    required this.childProfileId,
    required this.pieceId,
    required this.pieceName,
    required this.volumeNo,
    required this.boundDate,
  });

  BoundVolume copyWith({
    String? childProfileId,
    String? pieceId,
    String? pieceName,
    int? volumeNo,
    DateTime? boundDate,
  }) => BoundVolume(
    childProfileId: childProfileId ?? this.childProfileId,
    pieceId: pieceId ?? this.pieceId,
    pieceName: pieceName ?? this.pieceName,
    volumeNo: volumeNo ?? this.volumeNo,
    boundDate: boundDate ?? this.boundDate,
  );

  factory BoundVolume.fromJson(Map<String, dynamic> json) =>
      _$BoundVolumeFromJson(json);
  Map<String, dynamic> toJson() => _$BoundVolumeToJson(this);
}
