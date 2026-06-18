/// #808 — 레슨 요약 공유 토큰 결과.
///
/// 백엔드 `POST /lesson-summaries/{lessonId}/share` 응답. 서버가 토큰·공유 URL·
/// 공유 텍스트를 직접 생성하므로 FE 는 URL 복사/공유만 수행한다.
class LessonSummaryShare {
  final String token;

  /// 학생 요약 랜딩 페이지 공유 URL (서버 생성).
  final String url;

  /// 앱 딥링크 (서버 생성).
  final String appDeepLink;

  /// 공유용 안내 텍스트 (URL 포함, 서버 생성).
  final String shareText;

  /// 토큰 만료 시각.
  final DateTime expiresAt;

  const LessonSummaryShare({
    required this.token,
    required this.url,
    required this.appDeepLink,
    required this.shareText,
    required this.expiresAt,
  });

  factory LessonSummaryShare.fromJson(Map<String, dynamic> json) {
    return LessonSummaryShare(
      token: json['token'] as String? ?? '',
      url: json['url'] as String? ?? '',
      appDeepLink: json['app_deep_link'] as String? ?? '',
      shareText: json['share_text'] as String? ?? '',
      expiresAt:
          DateTime.tryParse(json['expires_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
