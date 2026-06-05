import 'billing_enums.dart';

/// 강사별 정산 모드 override (학원 기본값과 다른 강사만).
///
/// Spec: docs/specs/web/academy/billing_settlement.md §6.5.
/// BE: backend/app/models/academy_billing.py AcademyTeacherPayoutOverride.
///
/// 정책 변경 시 새 행 + 이전 행의 [effectiveUntil] 설정 (히스토리 보존).
/// 한 강사가 [effectiveFrom, effectiveUntil) 기간 동안 1개 행만 활성.
class AcademyTeacherPayoutOverride {
  AcademyTeacherPayoutOverride({
    required this.id,
    required this.academyId,
    required this.teacherMemberId,
    required this.distributionType,
    required this.effectiveFrom,
    required this.createdAt,
    Map<String, dynamic>? distributionConfig,
    this.effectiveUntil,
    this.note,
  }) : distributionConfig = Map.unmodifiable(distributionConfig ?? const {}) {
    if (effectiveUntil != null && !effectiveUntil!.isAfter(effectiveFrom)) {
      throw ArgumentError('effectiveUntil must be after effectiveFrom');
    }
  }

  final String id;
  final String academyId;
  final String teacherMemberId;
  final TeacherDistributionType distributionType;

  /// 배분 모드별 추가 config (예: `{"hourly_rate": 60000}`).
  final Map<String, dynamic> distributionConfig;

  /// 본 override 가 적용되기 시작하는 날짜 (inclusive).
  final DateTime effectiveFrom;

  /// 적용 종료일 (exclusive). null = 현재 유효.
  final DateTime? effectiveUntil;

  /// 학원장 메모 (사유 등).
  final String? note;

  final DateTime createdAt;

  /// 현재 유효 여부 (효력 기간이 [asOf] 를 포함하는지).
  bool isActiveAt(DateTime asOf) {
    if (asOf.isBefore(effectiveFrom)) return false;
    if (effectiveUntil != null && !asOf.isBefore(effectiveUntil!)) {
      return false;
    }
    return true;
  }

  /// 종료일이 설정되지 않은 = 현재 활성.
  bool get isOpen => effectiveUntil == null;

  AcademyTeacherPayoutOverride copyWith({
    String? id,
    String? academyId,
    String? teacherMemberId,
    TeacherDistributionType? distributionType,
    Map<String, dynamic>? distributionConfig,
    DateTime? effectiveFrom,
    DateTime? effectiveUntil,
    String? note,
    DateTime? createdAt,
  }) {
    return AcademyTeacherPayoutOverride(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      teacherMemberId: teacherMemberId ?? this.teacherMemberId,
      distributionType: distributionType ?? this.distributionType,
      distributionConfig: distributionConfig ?? this.distributionConfig,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveUntil: effectiveUntil ?? this.effectiveUntil,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AcademyTeacherPayoutOverride) return false;
    if (!_mapEquals(distributionConfig, other.distributionConfig)) return false;
    return id == other.id &&
        academyId == other.academyId &&
        teacherMemberId == other.teacherMemberId &&
        distributionType == other.distributionType &&
        effectiveFrom == other.effectiveFrom &&
        effectiveUntil == other.effectiveUntil &&
        note == other.note &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    academyId,
    teacherMemberId,
    distributionType,
    distributionConfig.length,
    effectiveFrom,
    effectiveUntil,
    note,
    createdAt,
  );

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
