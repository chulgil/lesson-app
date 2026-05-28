import 'package:json_annotation/json_annotation.dart';

part 'note_access_request.g.dart';

/// Status of a note access request
enum NoteAccessStatus {
  /// Access request has been sent, awaiting response
  requested,

  /// User has consented to share their note
  consented,

  /// User has rejected the access request
  rejected,

  /// Previously consented access has been revoked
  revoked,
}

/// Represents a temporary note access request from academy members
@JsonSerializable()
class NoteAccessRequest {
  final String id;

  /// Academy requesting the access
  final String academyId;

  /// Academy name for display
  final String academyName;

  /// Reason for requesting access
  final String reason;

  /// When the access permission expires (UTC)
  final DateTime expiresAt;

  /// Current status of the request
  final NoteAccessStatus status;

  /// User ID who received this request (the one being asked)
  final String recipientUserId;

  /// User ID who initiated the request
  final String requestorUserId;

  /// When this request was created (UTC)
  final DateTime createdAt;

  /// When this request was last updated (UTC)
  final DateTime? updatedAt;

  NoteAccessRequest({
    required this.id,
    required this.academyId,
    required this.academyName,
    required this.reason,
    required this.expiresAt,
    required this.status,
    required this.recipientUserId,
    required this.requestorUserId,
    required this.createdAt,
    this.updatedAt,
  });

  factory NoteAccessRequest.fromJson(Map<String, dynamic> json) =>
      _$NoteAccessRequestFromJson(json);

  Map<String, dynamic> toJson() => _$NoteAccessRequestToJson(this);

  /// Create a copy with modified fields
  NoteAccessRequest copyWith({
    String? id,
    String? academyId,
    String? academyName,
    String? reason,
    DateTime? expiresAt,
    NoteAccessStatus? status,
    String? recipientUserId,
    String? requestorUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteAccessRequest(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      academyName: academyName ?? this.academyName,
      reason: reason ?? this.reason,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      requestorUserId: requestorUserId ?? this.requestorUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Whether this access request is currently active
  bool get isActive => status == NoteAccessStatus.consented && isNotExpired;

  /// Whether the access has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether the access has not expired
  bool get isNotExpired => !isExpired;

  /// Remaining days of access (0 if expired)
  int get remainingDays {
    if (isExpired) return 0;
    return expiresAt.difference(DateTime.now()).inDays;
  }
}
