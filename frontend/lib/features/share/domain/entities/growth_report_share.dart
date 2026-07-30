/// #1217 — 무가입 자녀 성장 리포트 프리뷰 공유 토큰 결과.
///
/// 백엔드 `POST /growth-reports/{studentId}/share` 응답. 서버가 토큰·공유 URL 을
/// 직접 생성하므로 FE 는 URL 복사/공유만 수행한다.
class GrowthReportShare {
  final String token;

  /// 공개 성장 리포트 랜딩 페이지 공유 URL (서버 생성).
  final String url;

  /// 앱 딥링크 (서버 생성).
  final String appDeepLink;

  /// 토큰 만료 시각.
  final DateTime expiresAt;

  const GrowthReportShare({
    required this.token,
    required this.url,
    required this.appDeepLink,
    required this.expiresAt,
  });

  factory GrowthReportShare.fromJson(Map<String, dynamic> json) {
    return GrowthReportShare(
      token: json['token'] as String? ?? '',
      url: json['url'] as String? ?? '',
      appDeepLink: json['app_deep_link'] as String? ?? '',
      expiresAt:
          DateTime.tryParse(json['expires_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
