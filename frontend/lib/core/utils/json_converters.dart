// 2026-06-12 — #706 strict 파서 방어 컨버터.
//
// 배경: BE Pydantic 스키마의 `field: T | None = None` 필드를 FE .g.dart 가
// `json['x'] as String` / `DateTime.parse(... as String)` 로 strict 파싱해
// "데이터 0건일 땐 무사, 실데이터부터 throw" 회귀가 발생 (#704 availability).
// BE 가 None 을 보낼 수 있는 필드는 이 컨버터들로 방어한다.
//
// 사용: `@JsonKey(fromJson: dateTimeFromJsonOrNow)` 등 — build_runner 재생성 필요.

/// BE 가 null 을 보낼 수 있는 `created_at` 류 — null 이면 now 로 대체.
///
/// 표시/정렬 용도 필드에 한해 사용 (도메인 판정에 쓰는 시각이면 nullable 화 검토).
DateTime dateTimeFromJsonOrNow(dynamic value) =>
    value == null ? DateTime.now() : DateTime.parse(value as String);

/// BE 가 null 을 보낼 수 있는 문자열 — null 이면 빈 문자열.
String stringFromJsonOrEmpty(dynamic value) => (value as String?) ?? '';
