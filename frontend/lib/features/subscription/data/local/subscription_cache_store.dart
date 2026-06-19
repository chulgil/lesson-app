import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_usage.dart';

/// Hive-backed read-through cache for [Subscription] and [SubscriptionUsage].
///
/// Uses [Box<String>] + JSON serialisation — no TypeAdapter required.
///
/// Key structure:
///   `student:<id>`       → getByStudentId(id)
///   `membership:<id>`    → getActiveByMembershipId(id) — nullable
///   `sub:<id>`           → getById(id) — nullable
///   `expiring_soon`      → getExpiringSoon()
///   `expired`            → getExpired()
///   `teacher:<id>`       → getByTeacherId(id)
///   `unpaid:<id>`        → getUnpaidSubscriptions(teacherId)
///   `usage:<id>`         → getUsageHistory(subscriptionId)
///
/// Each entry is a JSON object:
/// ```json
/// { "cachedAt": "<iso>", "data": [...] }
/// ```
class SubscriptionCacheStore {
  SubscriptionCacheStore({required Box<String> box}) : _box = box;

  static const String boxName = 'subscription_cache_v1';

  final Box<String> _box;

  // --------------------------------------------------------------------------
  // Write helpers
  // --------------------------------------------------------------------------

  Future<void> putSubscriptions(
    String key,
    List<Subscription> subscriptions,
  ) async {
    final payload = jsonEncode({
      'cachedAt': DateTime.now().toUtc().toIso8601String(),
      'data': subscriptions.map((s) => s.toJson()).toList(),
    });
    await _box.put(key, payload);
  }

  Future<void> putSubscription(String key, Subscription? subscription) async {
    final payload = jsonEncode({
      'cachedAt': DateTime.now().toUtc().toIso8601String(),
      'data': subscription?.toJson(),
    });
    await _box.put(key, payload);
  }

  Future<void> putUsageHistory(
    String key,
    List<SubscriptionUsage> usages,
  ) async {
    final payload = jsonEncode({
      'cachedAt': DateTime.now().toUtc().toIso8601String(),
      'data': usages.map((u) => u.toJson()).toList(),
    });
    await _box.put(key, payload);
  }

  // --------------------------------------------------------------------------
  // Read helpers
  // --------------------------------------------------------------------------

  List<Subscription>? getSubscriptions(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final dataList = map['data'] as List<dynamic>?;
      if (dataList == null) return null;
      return dataList
          .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Subscription? getSubscription(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final data = map['data'];
      if (data == null) return null;
      return Subscription.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  List<SubscriptionUsage>? getUsageHistory(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final dataList = map['data'] as List<dynamic>?;
      if (dataList == null) return null;
      return dataList
          .map((e) => SubscriptionUsage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Key builders
  // --------------------------------------------------------------------------

  static String keyStudent(String studentId) => 'student:$studentId';
  static String keyMembership(String membershipId) =>
      'membership:$membershipId';
  static String keySub(String subscriptionId) => 'sub:$subscriptionId';
  static String keyExpiringSoon() => 'expiring_soon';
  static String keyExpired() => 'expired';
  static String keyTeacher(String teacherId) => 'teacher:$teacherId';
  static String keyUnpaid(String teacherId) => 'unpaid:$teacherId';
  static String keyUsage(String subscriptionId) => 'usage:$subscriptionId';
}
