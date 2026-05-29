// #415 R4 — 백엔드 BillingPlanResponse JSON ↔ AppBillingSnapshot 매퍼.
//
// 백엔드 스키마: backend/app/schemas/app_billing.py BillingPlanResponse.
// snake_case 와 camelCase 양쪽 모두 허용 (다른 백엔드 응답 패턴과 일관).

import '../../domain/entities/app_billing_snapshot.dart';
import '../../domain/entities/billing_plan.dart';
import '../../domain/entities/billing_status.dart';

class AppBillingDto {
  /// JSON map → AppBillingSnapshot.
  ///
  /// 알 수 없는 필드는 안전한 기본값으로 fallback (Free Active).
  static AppBillingSnapshot fromJson(Map<String, dynamic> json) {
    return AppBillingSnapshot(
      id: _asString(json, 'id') ?? '',
      userId: _asString(json, 'user_id') ?? _asString(json, 'userId') ?? '',
      plan: BillingPlan.fromWire(_asString(json, 'tier')),
      status: BillingStatus.fromWire(_asString(json, 'status')),
      startedAt:
          _parseDate(json['started_at'] ?? json['startedAt']) ??
          DateTime.now().toUtc(),
      expiresAt: _parseDate(json['expires_at'] ?? json['expiresAt']),
      source: _asString(json, 'source') ?? 'unknown',
      originalTransactionId:
          _asString(json, 'original_transaction_id') ??
          _asString(json, 'originalTransactionId'),
      trialUsed:
          _asBool(json['trial_used']) ?? _asBool(json['trialUsed']) ?? false,
      lifetimeOfferEndsAt: _parseDate(
        json['lifetime_offer_ends_at'] ?? json['lifetimeOfferEndsAt'],
      ),
    );
  }

  static String? _asString(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  static bool? _asBool(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is String) {
      final v = raw.toLowerCase();
      if (v == 'true') return true;
      if (v == 'false') return false;
    }
    return null;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toUtc();
    }
    return null;
  }
}
