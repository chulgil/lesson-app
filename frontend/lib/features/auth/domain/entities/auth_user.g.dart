// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenPair _$TokenPairFromJson(Map<String, dynamic> json) => TokenPair(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
    );

Map<String, dynamic> _$TokenPairToJson(TokenPair instance) => <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'token_type': instance.tokenType,
    };

AuthUser _$AuthUserFromJson(Map<String, dynamic> json) => AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      profileImageUrl: json['profile_image_url'] as String?,
      role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']),
      authProvider: json['auth_provider'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$AuthUserToJson(AuthUser instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'profile_image_url': instance.profileImageUrl,
      'role': _$UserRoleEnumMap[instance.role],
      'auth_provider': instance.authProvider,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$UserRoleEnumMap = {
  UserRole.teacher: 'teacher',
  UserRole.student: 'student',
  UserRole.parent: 'parent',
};
