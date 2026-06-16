import 'entities/teacher_profile.dart';

/// Normalize bank account list to ensure correct default status.
///
/// Rules:
/// - empty: return empty
/// - 1 account: mark as default=true
/// - 2+: exactly one default (preferredDefaultId if given & present,
///   else keep existing, else first)
///
/// Always returns new list (immutable).
List<BankAccount> normalizeBankAccountDefaults(
  List<BankAccount> accounts, {
  String? preferredDefaultId,
}) {
  // Empty list
  if (accounts.isEmpty) return [];

  // Single account: always default
  if (accounts.length == 1) {
    return [accounts[0].copyWith(isDefault: true)];
  }

  // Multiple accounts: ensure exactly one default
  // Prefer: preferredDefaultId > existing default > first
  String? defaultId;

  // 1. Check if preferredDefaultId exists
  if (preferredDefaultId != null &&
      accounts.any((a) => a.id == preferredDefaultId)) {
    defaultId = preferredDefaultId;
  } else {
    // 2. Check for existing default
    final existing = accounts.firstWhereOrNull((a) => a.isDefault);
    if (existing != null) {
      defaultId = existing.id;
    } else {
      // 3. Fallback to first
      defaultId = accounts[0].id;
    }
  }

  // Rebuild list with correct defaults
  return accounts
      .map((a) => a.copyWith(isDefault: a.id == defaultId))
      .toList();
}

extension _FirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (_) {
      return null;
    }
  }
}
