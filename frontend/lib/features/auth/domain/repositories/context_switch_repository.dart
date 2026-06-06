import '../entities/auth_user.dart';

/// A single context the current user can toggle into.
///
/// Mirrors backend `AvailableContext` (academy_context schema):
/// `context`, `academy_id`, `label`, `member_id`, `is_onboarding`,
/// `delegation_active`.
///
/// [context] uses the backend wire values: `academy_owner` or `teacher`.
class AvailableContext {
  final String context;
  final String academyId;
  final String label;
  final String memberId;
  final bool isOnboarding;
  final bool delegationActive;

  const AvailableContext({
    required this.context,
    required this.academyId,
    required this.label,
    required this.memberId,
    this.isOnboarding = false,
    this.delegationActive = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailableContext &&
          runtimeType == other.runtimeType &&
          context == other.context &&
          academyId == other.academyId &&
          label == other.label &&
          memberId == other.memberId &&
          isOnboarding == other.isOnboarding &&
          delegationActive == other.delegationActive;

  @override
  int get hashCode =>
      context.hashCode ^
      academyId.hashCode ^
      label.hashCode ^
      memberId.hashCode ^
      isOnboarding.hashCode ^
      delegationActive.hashCode;
}

/// Current context + the list of contexts the user can toggle into.
///
/// Mirrors backend `ContextResponse` (GET /auth/context).
class ContextInfo {
  final String userId;

  /// Active context wire value (`academy_owner` / `teacher`) or null when
  /// no context has been selected yet.
  final String? activeContext;
  final String? academyId;
  final String? teacherId;
  final List<AvailableContext> availableContexts;

  const ContextInfo({
    required this.userId,
    this.activeContext,
    this.academyId,
    this.teacherId,
    this.availableContexts = const [],
  });

  /// Whether the user can toggle at all (2+ distinct contexts available).
  bool get canToggle => availableContexts.length >= 2;
}

/// Result of context switch operation
class ContextSwitchResult {
  final String activeContext;
  final String redirectUrl;
  final TokenPair tokens;

  const ContextSwitchResult({
    required this.activeContext,
    required this.redirectUrl,
    required this.tokens,
  });

  ContextSwitchResult copyWith({
    String? activeContext,
    String? redirectUrl,
    TokenPair? tokens,
  }) {
    return ContextSwitchResult(
      activeContext: activeContext ?? this.activeContext,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      tokens: tokens ?? this.tokens,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContextSwitchResult &&
          runtimeType == other.runtimeType &&
          activeContext == other.activeContext &&
          redirectUrl == other.redirectUrl &&
          tokens == other.tokens;

  @override
  int get hashCode =>
      activeContext.hashCode ^ redirectUrl.hashCode ^ tokens.hashCode;
}

/// Repository interface for context switching operations.
abstract class ContextSwitchRepository {
  /// Current context + available contexts (GET /auth/context).
  Future<ContextInfo> getContext();

  /// Switch user context between roles (teacher <-> academy owner).
  ///
  /// [targetContext] is the backend wire value (`academy_owner` / `teacher`).
  /// [academyId] scopes the switch to a specific academy; required by the
  /// remote endpoint but optional here for backward compatibility with mock
  /// callers that only pass [targetContext].
  Future<ContextSwitchResult> switchContext({
    required String targetContext,
    String? academyId,
  });
}
