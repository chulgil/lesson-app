import 'package:flutter/material.dart';

/// Parent registration status enum
enum ParentStatus {
  pending, // Invitation sent, not yet registered
  active, // Registered and active
  inactive; // Deactivated

  String get label {
    switch (this) {
      case ParentStatus.pending:
        return '초대 대기';
      case ParentStatus.active:
        return '활성';
      case ParentStatus.inactive:
        return '비활성';
    }
  }

  Color get color {
    switch (this) {
      case ParentStatus.pending:
        return const Color(0xFFFF9800); // Orange
      case ParentStatus.active:
        return const Color(0xFF4CAF50); // Green
      case ParentStatus.inactive:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}

/// Invitation source enum (who invited the parent)
enum InvitationSource {
  student, // Invited by student
  teacher; // Invited by teacher

  String get label {
    switch (this) {
      case InvitationSource.student:
        return '학생 초대';
      case InvitationSource.teacher:
        return '선생님 초대';
    }
  }
}

/// Parent model
class Parent {
  final String id;
  final String userId; // User table FK (for auth)
  final String name;
  final String phone;
  final String? email;
  final String? profileImageUrl;
  final Color profileColor;
  final ParentStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Parent({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.email,
    this.profileImageUrl,
    required this.profileColor,
    this.status = ParentStatus.pending,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get first character of name for avatar
  String get initial => name.isNotEmpty ? name[0] : '?';

  /// Check if parent is active
  bool get isActive => status == ParentStatus.active;

  /// Format phone number for display
  String get formattedPhone {
    if (phone.length == 11) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 7)}-${phone.substring(7)}';
    }
    return phone;
  }

  /// Copy with new values
  Parent copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? email,
    String? profileImageUrl,
    Color? profileColor,
    ParentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Parent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profileColor: profileColor ?? this.profileColor,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Parent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Parent invitation model (for tracking invitations)
class ParentInvitation {
  final String id;
  final String studentId;
  final String? teacherId; // null if student invited
  final InvitationSource source;
  final String parentPhone;
  final String? parentEmail;
  final String invitationCode;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime createdAt;

  const ParentInvitation({
    required this.id,
    required this.studentId,
    this.teacherId,
    required this.source,
    required this.parentPhone,
    this.parentEmail,
    required this.invitationCode,
    required this.expiresAt,
    this.isUsed = false,
    required this.createdAt,
  });

  /// Check if invitation is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if invitation is valid (not used and not expired)
  bool get isValid => !isUsed && !isExpired;

  /// Get remaining time until expiration
  Duration get remainingTime => expiresAt.difference(DateTime.now());

  ParentInvitation copyWith({
    String? id,
    String? studentId,
    String? teacherId,
    InvitationSource? source,
    String? parentPhone,
    String? parentEmail,
    String? invitationCode,
    DateTime? expiresAt,
    bool? isUsed,
    DateTime? createdAt,
  }) {
    return ParentInvitation(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      source: source ?? this.source,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      invitationCode: invitationCode ?? this.invitationCode,
      expiresAt: expiresAt ?? this.expiresAt,
      isUsed: isUsed ?? this.isUsed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
