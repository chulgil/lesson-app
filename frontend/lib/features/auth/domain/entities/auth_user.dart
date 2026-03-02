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
  final String email;
  final String name;
  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;
  final UserRole? role; // null for new OAuth signups before role selection
  @JsonKey(name: 'auth_provider')
  final String? authProvider;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    this.role,
    this.authProvider,
    this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);

  Map<String, dynamic> toJson() => _$AuthUserToJson(this);
}
