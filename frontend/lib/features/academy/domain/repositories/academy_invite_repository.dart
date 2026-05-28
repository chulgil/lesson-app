import '../entities/academy.dart';

/// Academy invite repository interface
abstract class AcademyInviteRepository {
  /// Get invite preview by token (GET /academy/invites/:token/preview)
  /// Throws exception if token is invalid or expired
  Future<AcademyInvitePreview> getInvitePreview(String token);

  /// Accept academy invite (POST /academy/invites/:token/accept)
  /// Throws exception if token is invalid or expired
  Future<void> acceptInvite(String token, {required bool publicPageConsent});

  /// Reject academy invite (POST /academy/invites/:token/reject)
  /// Throws exception if token is invalid or expired
  Future<void> rejectInvite(String token, {String? reason});
}

/// Academy invite preview DTO
class AcademyInvitePreview {
  final String token;
  final Academy academy;
  final String ownerName;
  final List<String> roles;

  const AcademyInvitePreview({
    required this.token,
    required this.academy,
    required this.ownerName,
    required this.roles,
  });

  AcademyInvitePreview copyWith({
    String? token,
    Academy? academy,
    String? ownerName,
    List<String>? roles,
  }) {
    return AcademyInvitePreview(
      token: token ?? this.token,
      academy: academy ?? this.academy,
      ownerName: ownerName ?? this.ownerName,
      roles: roles ?? this.roles,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademyInvitePreview &&
          runtimeType == other.runtimeType &&
          token == other.token &&
          academy == other.academy &&
          ownerName == other.ownerName &&
          roles == other.roles;

  @override
  int get hashCode =>
      token.hashCode ^ academy.hashCode ^ ownerName.hashCode ^ roles.hashCode;
}
