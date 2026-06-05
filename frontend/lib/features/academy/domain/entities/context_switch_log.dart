/// Academy context (학원 컨텍스트).
///
/// Spec: docs/specs/web/academy/context_toggle_spec.md §3.1.
enum AcademyContext {
  /// 학원장 모드 — 콘솔/운영 권한.
  academyOwner,

  /// 강사 모드 — lesson-app 학생 노트/연습 권한.
  teacher;

  /// BE 의 snake_case 값과 매핑.
  String get wireValue => switch (this) {
    AcademyContext.academyOwner => 'academy_owner',
    AcademyContext.teacher => 'teacher',
  };

  static AcademyContext fromWire(String value) => switch (value) {
    'academy_owner' => AcademyContext.academyOwner,
    'teacher' => AcademyContext.teacher,
    _ => throw ArgumentError('Unknown AcademyContext: $value'),
  };
}

/// 컨텍스트 전환 트리거.
///
/// Spec: docs/specs/web/academy/context_toggle_spec.md §3.3.
enum ContextSwitchTrigger {
  /// 학원장이 명시적으로 토글.
  user,

  /// 4시간 만료 후 직전 컨텍스트 복원 (§8.4).
  sessionResume;

  String get wireValue => switch (this) {
    ContextSwitchTrigger.user => 'user',
    ContextSwitchTrigger.sessionResume => 'session_resume',
  };

  static ContextSwitchTrigger fromWire(String value) => switch (value) {
    'user' => ContextSwitchTrigger.user,
    'session_resume' => ContextSwitchTrigger.sessionResume,
    _ => throw ArgumentError('Unknown ContextSwitchTrigger: $value'),
  };
}

/// 학원장 ↔ 강사 모드 전환 audit.
///
/// Spec: docs/specs/web/academy/context_toggle_spec.md §3.3, §9.
///
/// 영구 보존 — 학원 운영 분쟁 증거 + 노트 일시 접근 (R-AO-23) 사전 검증.
/// BE: `ContextSwitchLog` (`backend/app/models/academy_governance.py`).
class ContextSwitchLog {
  const ContextSwitchLog({
    required this.id,
    required this.userId,
    required this.academyId,
    required this.fromContext,
    required this.toContext,
    required this.switchedAt,
    this.ip,
    this.userAgent,
    this.triggeredBy = ContextSwitchTrigger.user,
  });

  final String id;
  final String userId;
  final String academyId;
  final AcademyContext fromContext;
  final AcademyContext toContext;
  final DateTime switchedAt;

  /// 클라이언트 IP (IPv4/IPv6). nullable.
  final String? ip;

  /// 클라이언트 User-Agent. nullable.
  final String? userAgent;

  /// 전환 트리거. 기본 user.
  final ContextSwitchTrigger triggeredBy;

  ContextSwitchLog copyWith({
    String? id,
    String? userId,
    String? academyId,
    AcademyContext? fromContext,
    AcademyContext? toContext,
    DateTime? switchedAt,
    String? ip,
    String? userAgent,
    ContextSwitchTrigger? triggeredBy,
  }) {
    return ContextSwitchLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      academyId: academyId ?? this.academyId,
      fromContext: fromContext ?? this.fromContext,
      toContext: toContext ?? this.toContext,
      switchedAt: switchedAt ?? this.switchedAt,
      ip: ip ?? this.ip,
      userAgent: userAgent ?? this.userAgent,
      triggeredBy: triggeredBy ?? this.triggeredBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContextSwitchLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          academyId == other.academyId &&
          fromContext == other.fromContext &&
          toContext == other.toContext &&
          switchedAt == other.switchedAt &&
          ip == other.ip &&
          userAgent == other.userAgent &&
          triggeredBy == other.triggeredBy;

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    academyId,
    fromContext,
    toContext,
    switchedAt,
    ip,
    userAgent,
    triggeredBy,
  );
}
