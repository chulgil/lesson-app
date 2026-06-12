import 'package:json_annotation/json_annotation.dart';

import 'spotlight_type.dart';

part 'spotlight_prompt.g.dart';

/// 스포트라이트 프롬프트 — 학생 축하 overlay 안 1슬롯에 보여지는 권유.
///
/// 스펙 §6.2 / §7.1~§7.4.
/// 저장: Hive `Box<String>` + JSON (key=`{studentId}::{id}`).
@JsonSerializable()
class SpotlightPrompt {
  final String id;
  final String studentId;
  final SpotlightType type;
  final String title;
  final String? videoId;
  final String? ctaRoute;
  final DateTime queuedAt;

  /// 누적 "다음에" 거절 횟수 (§7.3). 5회 → 8주 hide, 6회 → permanent.
  final int declineCount;

  /// cooldown / 8주 hide 종료 시각. null = no cooldown.
  final DateTime? hideUntil;

  /// 영구 hide (학생이 옵션에서 명시적 재활성 시 false 로 — P4 의존).
  final bool permanentlyHidden;

  /// 마지막 노출 시각. eligibility/queue 가 daily/weekly 카운터 도출 시 참조.
  final DateTime? lastShownAt;

  /// teacherRec + 선생님 "필수" 플래그 (§5.2). 큐 우선순위 +10 진입.
  final bool isMandatory;

  const SpotlightPrompt({
    required this.id,
    required this.studentId,
    required this.type,
    required this.title,
    this.videoId,
    this.ctaRoute,
    required this.queuedAt,
    this.declineCount = 0,
    this.hideUntil,
    this.permanentlyHidden = false,
    this.lastShownAt,
    this.isMandatory = false,
  });

  /// 큐 우선순위 (낮을수록 먼저). 스펙 §7.2.
  /// - teacherRec + isMandatory → 0
  /// - teacherRec → 10
  /// - seasonEvent → 20
  /// - routineSuggestion → 30
  int get priority {
    switch (type) {
      case SpotlightType.teacherRec:
        return isMandatory ? 0 : 10;
      case SpotlightType.seasonEvent:
        return 20;
      case SpotlightType.routineSuggestion:
        return 30;
    }
  }

  /// 현 시점에 노출 차단 여부.
  bool isHiddenAt(DateTime now) {
    if (permanentlyHidden) return true;
    final until = hideUntil;
    if (until != null && now.isBefore(until)) return true;
    return false;
  }

  SpotlightPrompt copyWith({
    int? declineCount,
    DateTime? hideUntil,
    bool? permanentlyHidden,
    DateTime? lastShownAt,
    bool? isMandatory,
    bool clearHideUntil = false,
    bool clearLastShownAt = false,
  }) => SpotlightPrompt(
    id: id,
    studentId: studentId,
    type: type,
    title: title,
    videoId: videoId,
    ctaRoute: ctaRoute,
    queuedAt: queuedAt,
    declineCount: declineCount ?? this.declineCount,
    hideUntil: clearHideUntil ? null : (hideUntil ?? this.hideUntil),
    permanentlyHidden: permanentlyHidden ?? this.permanentlyHidden,
    lastShownAt: clearLastShownAt ? null : (lastShownAt ?? this.lastShownAt),
    isMandatory: isMandatory ?? this.isMandatory,
  );

  factory SpotlightPrompt.fromJson(Map<String, dynamic> json) =>
      _$SpotlightPromptFromJson(json);

  Map<String, dynamic> toJson() => _$SpotlightPromptToJson(this);
}
