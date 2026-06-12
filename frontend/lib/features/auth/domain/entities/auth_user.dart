import 'package:json_annotation/json_annotation.dart';

import 'user_role.dart';

part 'auth_user.g.dart';

/// Token pair returned from auth endpoints.
@JsonSerializable()
class TokenPair {
  final String accessToken;
  final String refreshToken;
  @JsonKey(name: 'token_type')
  final String tokenType;

  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) =>
      _$TokenPairFromJson(json);

  Map<String, dynamic> toJson() => _$TokenPairToJson(this);
}

/// Authenticated user info from /auth/me endpoint.
@JsonSerializable()
class AuthUser {
  final String id;

  // #706 — BE UserResponse 는 email/name 이 `str | None = None`. strict
  // `as String` 캐스트가 OAuth 신규 가입 등 null 응답에서 throw 하므로 방어.
  @JsonKey(defaultValue: '')
  final String email;
  @JsonKey(defaultValue: '')
  final String name;
  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;
  final UserRole? role; // null for new OAuth signups before role selection
  @JsonKey(name: 'onboarding_completed')
  final bool onboardingCompleted;
  @JsonKey(name: 'auth_provider')
  final String? authProvider;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  /// 11개 퀘스트 모두 완료 시점. 축하 카드 1회성 보장용 (§13 퀘스트 시스템).
  /// null = 미완료, DateTime = 축하 카드 이미 표시됨.
  @JsonKey(name: 'quest_celebrated_at')
  final DateTime? questCelebratedAt;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    this.role,
    this.onboardingCompleted = false,
    this.authProvider,
    this.createdAt,
    this.questCelebratedAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);

  Map<String, dynamic> toJson() => _$AuthUserToJson(this);
}
