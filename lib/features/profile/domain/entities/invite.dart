// Invite domain entity
// Moved from lib/models/invite.dart for Clean Architecture

import 'package:flutter/material.dart';

// Re-export shared enums for backward compatibility
export '../../../../core/models/shared_enums.dart'
    show ConnectionStatus, PracticeLevel, ConnectionStatusHelper;

/// Method used to send/receive invitation
enum InviteMethod {
  qrCode,     // QR code scan (in-person)
  urlLink,    // URL link (message/kakao)
  inviteCode, // 6-digit code input
  inAppSearch; // In-app search (teacher only)

  String get label {
    switch (this) {
      case InviteMethod.qrCode:
        return 'QR 코드';
      case InviteMethod.urlLink:
        return 'URL 링크';
      case InviteMethod.inviteCode:
        return '초대 코드';
      case InviteMethod.inAppSearch:
        return '앱 내 검색';
    }
  }

  IconData get icon {
    switch (this) {
      case InviteMethod.qrCode:
        return Icons.qr_code;
      case InviteMethod.urlLink:
        return Icons.link;
      case InviteMethod.inviteCode:
        return Icons.dialpad;
      case InviteMethod.inAppSearch:
        return Icons.search;
    }
  }
}

/// Status of an invite link/code
enum InviteStatus {
  active,   // Valid and can be used
  used,     // Already used (single-use)
  expired,  // Past expiration date
  revoked;  // Manually revoked by creator

  String get label {
    switch (this) {
      case InviteStatus.active:
        return '활성';
      case InviteStatus.used:
        return '사용됨';
      case InviteStatus.expired:
        return '만료됨';
      case InviteStatus.revoked:
        return '취소됨';
    }
  }

  Color get color {
    switch (this) {
      case InviteStatus.active:
        return const Color(0xFF4CAF50); // Green
      case InviteStatus.used:
        return const Color(0xFF9E9E9E); // Grey
      case InviteStatus.expired:
        return const Color(0xFFFF9800); // Orange
      case InviteStatus.revoked:
        return const Color(0xFFE57373); // Red
    }
  }

  bool get isValid => this == InviteStatus.active;
}

/// User role for invitation system
enum InviteUserRole {
  teacher,
  student;

  String get label {
    switch (this) {
      case InviteUserRole.teacher:
        return '선생님';
      case InviteUserRole.student:
        return '학생';
    }
  }

  InviteUserRole get opposite {
    switch (this) {
      case InviteUserRole.teacher:
        return InviteUserRole.student;
      case InviteUserRole.student:
        return InviteUserRole.teacher;
    }
  }
}

/// Invite model - can be created by teacher or student
class Invite {
  final String id;
  final String creatorId;
  final InviteUserRole creatorRole;
  final String inviteCode;       // 6-digit code
  final String inviteUrl;        // Deep link URL
  final String qrCodeData;       // Data for QR code generation
  final InviteStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isSingleUse;        // If true, can only be used once
  final int? maxUses;            // Maximum number of uses (null = unlimited)
  final int useCount;            // Current use count
  final String? note;            // Optional note/label for the invite

  const Invite({
    required this.id,
    required this.creatorId,
    required this.creatorRole,
    required this.inviteCode,
    required this.inviteUrl,
    required this.qrCodeData,
    this.status = InviteStatus.active,
    required this.createdAt,
    required this.expiresAt,
    this.isSingleUse = false,
    this.maxUses,
    this.useCount = 0,
    this.note,
  });

  /// Check if invite is currently valid
  bool get isValid {
    if (status != InviteStatus.active) return false;
    if (DateTime.now().isAfter(expiresAt)) return false;
    if (isSingleUse && useCount > 0) return false;
    if (maxUses != null && useCount >= maxUses!) return false;
    return true;
  }

  /// Time remaining until expiration
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }

  /// Formatted expiration time
  String get formattedExpiry {
    final remaining = timeRemaining;
    if (remaining == Duration.zero) return '만료됨';
    if (remaining.inDays > 0) return '${remaining.inDays}일 남음';
    if (remaining.inHours > 0) return '${remaining.inHours}시간 남음';
    if (remaining.inMinutes > 0) return '${remaining.inMinutes}분 남음';
    return '곧 만료';
  }

  Invite copyWith({
    String? id,
    String? creatorId,
    InviteUserRole? creatorRole,
    String? inviteCode,
    String? inviteUrl,
    String? qrCodeData,
    InviteStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isSingleUse,
    int? maxUses,
    int? useCount,
    String? note,
  }) {
    return Invite(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorRole: creatorRole ?? this.creatorRole,
      inviteCode: inviteCode ?? this.inviteCode,
      inviteUrl: inviteUrl ?? this.inviteUrl,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isSingleUse: isSingleUse ?? this.isSingleUse,
      maxUses: maxUses ?? this.maxUses,
      useCount: useCount ?? this.useCount,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Invite && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Status of a connection request
enum ConnectionRequestStatus {
  pending,   // Waiting for response
  accepted,  // Connection established
  rejected,  // Declined by target
  cancelled, // Cancelled by requester
  expired;   // Request expired

  String get label {
    switch (this) {
      case ConnectionRequestStatus.pending:
        return '대기중';
      case ConnectionRequestStatus.accepted:
        return '수락됨';
      case ConnectionRequestStatus.rejected:
        return '거절됨';
      case ConnectionRequestStatus.cancelled:
        return '취소됨';
      case ConnectionRequestStatus.expired:
        return '만료됨';
    }
  }

  Color get color {
    switch (this) {
      case ConnectionRequestStatus.pending:
        return const Color(0xFFFF9800); // Orange
      case ConnectionRequestStatus.accepted:
        return const Color(0xFF4CAF50); // Green
      case ConnectionRequestStatus.rejected:
        return const Color(0xFFE57373); // Red
      case ConnectionRequestStatus.cancelled:
        return const Color(0xFF9E9E9E); // Grey
      case ConnectionRequestStatus.expired:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  bool get isPending => this == ConnectionRequestStatus.pending;
  bool get isResolved => this != ConnectionRequestStatus.pending;
}

/// Connection request between teacher and student
class ConnectionRequest {
  final String id;
  final String requesterId;
  final InviteUserRole requesterRole;
  final String? requesterName;
  final String? requesterProfileImage;
  final String targetId;
  final InviteUserRole targetRole;
  final String? targetName;
  final String? targetProfileImage;
  final InviteMethod method;         // How they found each other
  final String? inviteId;            // Related invite (if used QR/URL/code)
  final String? message;             // Optional message from requester
  final ConnectionRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? rejectionReason;     // Reason if rejected
  final DateTime expiresAt;          // Request expires after 7 days

  const ConnectionRequest({
    required this.id,
    required this.requesterId,
    required this.requesterRole,
    this.requesterName,
    this.requesterProfileImage,
    required this.targetId,
    required this.targetRole,
    this.targetName,
    this.targetProfileImage,
    required this.method,
    this.inviteId,
    this.message,
    this.status = ConnectionRequestStatus.pending,
    required this.createdAt,
    this.respondedAt,
    this.rejectionReason,
    required this.expiresAt,
  });

  /// Check if request is still pending and not expired
  bool get isActionable {
    if (status != ConnectionRequestStatus.pending) return false;
    if (DateTime.now().isAfter(expiresAt)) return false;
    return true;
  }

  /// Time remaining until expiration
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }

  ConnectionRequest copyWith({
    String? id,
    String? requesterId,
    InviteUserRole? requesterRole,
    String? requesterName,
    String? requesterProfileImage,
    String? targetId,
    InviteUserRole? targetRole,
    String? targetName,
    String? targetProfileImage,
    InviteMethod? method,
    String? inviteId,
    String? message,
    ConnectionRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? rejectionReason,
    DateTime? expiresAt,
  }) {
    return ConnectionRequest(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      requesterRole: requesterRole ?? this.requesterRole,
      requesterName: requesterName ?? this.requesterName,
      requesterProfileImage:
          requesterProfileImage ?? this.requesterProfileImage,
      targetId: targetId ?? this.targetId,
      targetRole: targetRole ?? this.targetRole,
      targetName: targetName ?? this.targetName,
      targetProfileImage: targetProfileImage ?? this.targetProfileImage,
      method: method ?? this.method,
      inviteId: inviteId ?? this.inviteId,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionRequest &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Established connection between teacher and student
class Connection {
  final String id;
  final String teacherId;
  final String teacherName;
  final String? teacherProfileImage;
  final String studentId;
  final String studentName;
  final String? studentProfileImage;
  final String? connectionRequestId;  // Original request that created this
  final DateTime connectedAt;
  final bool isActive;                 // Can be deactivated without deletion
  final DateTime? deactivatedAt;

  const Connection({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    this.teacherProfileImage,
    required this.studentId,
    required this.studentName,
    this.studentProfileImage,
    this.connectionRequestId,
    required this.connectedAt,
    this.isActive = true,
    this.deactivatedAt,
  });

  Connection copyWith({
    String? id,
    String? teacherId,
    String? teacherName,
    String? teacherProfileImage,
    String? studentId,
    String? studentName,
    String? studentProfileImage,
    String? connectionRequestId,
    DateTime? connectedAt,
    bool? isActive,
    DateTime? deactivatedAt,
  }) {
    return Connection(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      teacherProfileImage: teacherProfileImage ?? this.teacherProfileImage,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentProfileImage: studentProfileImage ?? this.studentProfileImage,
      connectionRequestId: connectionRequestId ?? this.connectionRequestId,
      connectedAt: connectedAt ?? this.connectedAt,
      isActive: isActive ?? this.isActive,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Connection &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ============================================================================
// V2 Models - Mutual Follow System (invite_system_v2.md)
// Note: ConnectionStatus, PracticeLevel, ConnectionStatusHelper are defined in
// lib/core/models/shared_enums.dart and re-exported from this file.
// ============================================================================

/// Follow relationship for V2 mutual follow system
/// Represents one-directional follow (like Instagram)
class Follow {
  final String id;
  final String followerId;      // Who is following
  final InviteUserRole followerRole;
  final String followeeId;      // Who is being followed
  final InviteUserRole followeeRole;
  final DateTime createdAt;

  const Follow({
    required this.id,
    required this.followerId,
    required this.followerRole,
    required this.followeeId,
    required this.followeeRole,
    required this.createdAt,
  });

  Follow copyWith({
    String? id,
    String? followerId,
    InviteUserRole? followerRole,
    String? followeeId,
    InviteUserRole? followeeRole,
    DateTime? createdAt,
  }) {
    return Follow(
      id: id ?? this.id,
      followerId: followerId ?? this.followerId,
      followerRole: followerRole ?? this.followerRole,
      followeeId: followeeId ?? this.followeeId,
      followeeRole: followeeRole ?? this.followeeRole,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Follow && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
