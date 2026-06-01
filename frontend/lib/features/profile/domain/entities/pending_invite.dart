/// 초대 대기 항목 — #5 D-G3 Phase 2.
///
/// 백엔드 `GET /api/v1/invites/pending` 응답을 1:1 매핑.
/// 선생님이 보낸 초대 중 학생이 아직 가입하지 않은 active 초대만 노출.
class PendingInvite {
  const PendingInvite({
    required this.inviteId,
    required this.inviteCode,
    required this.daysSinceSent,
    required this.expiresAt,
    required this.resentCount,
    required this.canResend,
    this.lastResentAt,
    this.note,
  });

  final String inviteId;
  final String inviteCode;
  final int daysSinceSent;
  final DateTime expiresAt;
  final int resentCount;
  final DateTime? lastResentAt;
  final bool canResend;
  final String? note;

  factory PendingInvite.fromJson(Map<String, dynamic> json) {
    return PendingInvite(
      inviteId: json['invite_id'] as String,
      inviteCode: json['invite_code'] as String? ?? '',
      daysSinceSent: (json['days_since_sent'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      resentCount: (json['resent_count'] as num?)?.toInt() ?? 0,
      lastResentAt: json['last_resent_at'] != null
          ? DateTime.parse(json['last_resent_at'] as String)
          : null,
      canResend: json['can_resend'] as bool? ?? true,
      note: json['note'] as String?,
    );
  }

  /// D+5 이상 — 만료 임박 (7일 window)
  bool get isImminent => daysSinceSent >= 5;

  /// D+3 ~ D+4 — 재발송 권장 구간
  bool get isUrgent => daysSinceSent >= 3 && daysSinceSent < 5;
}
