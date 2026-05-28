import '../entities/auth_user.dart';

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
  /// Switch user context between roles (teacher <-> academy owner).
  Future<ContextSwitchResult> switchContext({required String targetContext});
}
