// #415 R4 Phase C — Trial/IAP 응답 JSON 매퍼.
//
// 백엔드 스키마: backend/app/schemas/app_billing.py
// — TrialStartResponse, IapValidateResponse.

import '../../domain/entities/iap_validation_result.dart';
import '../../domain/entities/trial_activation_result.dart';

class TrialActivationDto {
  static TrialActivationResult fromJson(Map<String, dynamic> json) {
    return TrialActivationResult(
      success: _asBool(json['success']) ?? false,
      message: _asString(json, 'message') ?? '',
      planId: _asString(json, 'plan_id') ?? _asString(json, 'planId'),
      expiresAt: _parseDate(json['expires_at'] ?? json['expiresAt']),
    );
  }

  static String? _asString(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  static bool? _asBool(dynamic raw) {
    if (raw is bool) return raw;
    return null;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toUtc();
    }
    return null;
  }
}

class IapValidationDto {
  static IapValidationResult fromJson(Map<String, dynamic> json) {
    return IapValidationResult(
      granted: _asBool(json['success']) ?? false,
      message: _asString(json, 'message') ?? '',
      planId: _asString(json, 'plan_id') ?? _asString(json, 'planId'),
      tier: _asString(json, 'tier'),
      expiresAt: _parseDate(json['expires_at'] ?? json['expiresAt']),
    );
  }

  static String? _asString(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  static bool? _asBool(dynamic raw) {
    if (raw is bool) return raw;
    return null;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toUtc();
    }
    return null;
  }
}
