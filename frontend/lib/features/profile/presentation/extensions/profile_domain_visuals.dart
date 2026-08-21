import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/invite.dart';
import '../../domain/entities/teacher_student_relation.dart';

Color _colorForKey(String key) {
  switch (key) {
    case 'paperAccent':
      return AppColors.paperAccent;
    case 'paperOk':
      return AppColors.paperOk;
    case 'inkTertiary':
      return AppColors.inkTertiary;
    case 'ink':
      return AppColors.ink;
    default:
      return AppColors.paperAccent;
  }
}

IconData _iconForKey(String key) {
  switch (key) {
    case 'qrCode':
      return Icons.qr_code;
    case 'link':
      return Icons.link;
    case 'dialpad':
      return Icons.dialpad;
    case 'search':
      return Icons.search;
    case 'musicNote':
      return Icons.music_note;
    case 'calendarToday':
      return Icons.calendar_today;
    case 'addCircleOutline':
      return Icons.add_circle_outline;
    default:
      return Icons.info_outline;
  }
}

extension InviteMethodVisuals on InviteMethod {
  String get label {
    switch (this) {
      case InviteMethod.qrCode:
        return AppStrings.qrCodeSectionTitle;
      case InviteMethod.urlLink:
        return 'URL 링크';
      case InviteMethod.inviteCode:
        return AppStrings.inviteCodeSectionTitle;
      case InviteMethod.inAppSearch:
        return '앱 내 검색';
    }
  }

  String get iconKey {
    switch (this) {
      case InviteMethod.qrCode:
        return 'qrCode';
      case InviteMethod.urlLink:
        return 'link';
      case InviteMethod.inviteCode:
        return 'dialpad';
      case InviteMethod.inAppSearch:
        return 'search';
    }
  }

  IconData get icon => _iconForKey(iconKey);
}

extension InviteStatusVisuals on InviteStatus {
  String get label {
    switch (this) {
      case InviteStatus.active:
        return '활성';
      case InviteStatus.used:
        return '사용됨';
      case InviteStatus.expired:
        return AppStrings.expired;
      case InviteStatus.revoked:
        return AppStrings.proposalStatusCancelled;
    }
  }

  String get colorKey {
    switch (this) {
      case InviteStatus.active:
        return 'paperOk';
      case InviteStatus.used:
        return 'inkTertiary';
      case InviteStatus.expired:
        return 'paperAccent';
      case InviteStatus.revoked:
        return 'paperAccent';
    }
  }

  Color get color => _colorForKey(colorKey);
}

extension InviteUserRoleVisuals on InviteUserRole {
  String get label {
    switch (this) {
      case InviteUserRole.teacher:
        return AppStrings.teacher;
      case InviteUserRole.student:
        return AppStrings.student;
    }
  }
}

extension InviteTargetRoleVisuals on InviteTargetRole {
  /// Card title in the creation selector, and the badge text shown on the
  /// generated invite/QR view and invite history rows.
  String get label {
    switch (this) {
      case InviteTargetRole.teacher:
        return AppStrings.inviteTargetRoleTeacherLabel;
      case InviteTargetRole.student:
        return AppStrings.inviteTargetRoleStudentLabel;
      case InviteTargetRole.parent:
        return AppStrings.inviteTargetRoleParentLabel;
    }
  }

  /// Bare role noun for guide sentences ("학생에게 …" / "학부모에게 …") —
  /// distinct from [label] which is the badge/card form ("학생용").
  String get guideNoun {
    switch (this) {
      case InviteTargetRole.teacher:
        return AppStrings.teacher;
      case InviteTargetRole.student:
        return AppStrings.student;
      case InviteTargetRole.parent:
        return AppStrings.parent;
    }
  }

  /// Card description in the creation selector only.
  String get description {
    switch (this) {
      case InviteTargetRole.teacher:
        return AppStrings.inviteTargetRoleTeacherDesc;
      case InviteTargetRole.student:
        return AppStrings.inviteTargetRoleStudentDesc;
      case InviteTargetRole.parent:
        return AppStrings.inviteTargetRoleParentDesc;
    }
  }

  IconData get icon {
    switch (this) {
      case InviteTargetRole.teacher:
        return Icons.school_rounded;
      case InviteTargetRole.student:
        return Icons.music_note_rounded;
      case InviteTargetRole.parent:
        return Icons.family_restroom_rounded;
    }
  }
}

extension InviteVisuals on Invite {
  String get formattedExpiry {
    final remaining = timeRemaining;
    if (remaining == Duration.zero) return AppStrings.expired;
    if (remaining.inDays > 0) return '${remaining.inDays}일 남음';
    if (remaining.inHours > 0) return '${remaining.inHours}시간 남음';
    if (remaining.inMinutes > 0) return '${remaining.inMinutes}분 남음';
    return AppStrings.expiresVerySoon;
  }
}

extension ConnectionRequestStatusVisuals on ConnectionRequestStatus {
  String get label {
    switch (this) {
      case ConnectionRequestStatus.pending:
        return AppStrings.tabPending;
      case ConnectionRequestStatus.accepted:
        return '수락됨';
      case ConnectionRequestStatus.rejected:
        return '거절됨';
      case ConnectionRequestStatus.cancelled:
        return AppStrings.proposalStatusCancelled;
      case ConnectionRequestStatus.expired:
        return AppStrings.expired;
    }
  }

  String get colorKey {
    switch (this) {
      case ConnectionRequestStatus.pending:
        return 'paperAccent';
      case ConnectionRequestStatus.accepted:
        return 'paperOk';
      case ConnectionRequestStatus.rejected:
        return 'paperAccent';
      case ConnectionRequestStatus.cancelled:
        return 'inkTertiary';
      case ConnectionRequestStatus.expired:
        return 'inkTertiary';
    }
  }

  Color get color => _colorForKey(colorKey);
}

extension RelationLessonTypeVisuals on RelationLessonType {
  String get label {
    switch (this) {
      case RelationLessonType.trial:
        return '체험 레슨';
      case RelationLessonType.regular:
        return '정기 레슨';
      case RelationLessonType.oneTime:
        return '1회 추가 레슨';
    }
  }

  String get description {
    switch (this) {
      case RelationLessonType.trial:
        return '첫 만남을 위한 1회 레슨';
      case RelationLessonType.regular:
        return '매주 고정 시간 레슨';
      case RelationLessonType.oneTime:
        return '단발성 추가 레슨';
    }
  }

  String get iconKey {
    switch (this) {
      case RelationLessonType.trial:
        return 'musicNote';
      case RelationLessonType.regular:
        return 'calendarToday';
      case RelationLessonType.oneTime:
        return 'addCircleOutline';
    }
  }

  String get colorKey {
    switch (this) {
      case RelationLessonType.trial:
        return 'ink';
      case RelationLessonType.regular:
        return 'paperAccent';
      case RelationLessonType.oneTime:
        return 'paperAccent';
    }
  }

  IconData get icon => _iconForKey(iconKey);
  Color get color => _colorForKey(colorKey);
}

extension RelationStatusVisuals on RelationStatus {
  String get label {
    switch (this) {
      case RelationStatus.none:
        return '처음 만남';
      case RelationStatus.active:
        return '정규레슨 진행중';
      case RelationStatus.inactive:
        return '이전 레슨 이력';
    }
  }

  String get colorKey {
    switch (this) {
      case RelationStatus.none:
        return 'ink';
      case RelationStatus.active:
        return 'paperOk';
      case RelationStatus.inactive:
        return 'inkTertiary';
    }
  }
}

extension TeacherStudentRelationVisuals on TeacherStudentRelation {
  String get statusLabel => status.label;
  String get statusColorKey => status.colorKey;
  Color get statusColor => _colorForKey(statusColorKey);
}
