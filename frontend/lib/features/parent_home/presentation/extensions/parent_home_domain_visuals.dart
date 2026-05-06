import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/child_profile.dart';
import '../../domain/entities/parent.dart';
import '../../domain/entities/parent_child_relation.dart';
import '../../domain/entities/parent_notification_settings.dart';
import '../../domain/entities/user_profile.dart';

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
    case 'profileBlue':
      return AppColors.profileBlue;
    case 'profilePink':
      return AppColors.profilePink;
    case 'profileGreen':
      return AppColors.profileGreen;
    default:
      return AppColors.paperAccent;
  }
}

String parentHomeColorKeyForColor(Color color) {
  if (color == AppColors.paperAccent) return 'paperAccent';
  if (color == AppColors.paperOk) return 'paperOk';
  if (color == AppColors.inkTertiary) return 'inkTertiary';
  if (color == AppColors.ink) return 'ink';
  if (color == AppColors.profileBlue) return 'profileBlue';
  if (color == AppColors.profilePink) return 'profilePink';
  if (color == AppColors.profileGreen) return 'profileGreen';
  return 'paperAccent';
}

IconData _iconForKey(String key) {
  switch (key) {
    case 'familyRestroom':
      return Icons.family_restroom;
    case 'school':
      return Icons.school;
    case 'childCare':
      return Icons.child_care;
    case 'link':
      return Icons.link;
    case 'hourglassEmpty':
      return Icons.hourglass_empty;
    case 'linkOff':
      return Icons.link_off;
    case 'piano':
      return Icons.piano;
    case 'musicNote':
      return Icons.music_note;
    default:
      return Icons.music_note;
  }
}

extension ParentStatusVisuals on ParentStatus {
  String get label {
    switch (this) {
      case ParentStatus.pending:
        return AppStrings.parentHomeParentStatusPending;
      case ParentStatus.active:
        return AppStrings.parentHomeParentStatusActive;
      case ParentStatus.inactive:
        return AppStrings.parentHomeParentStatusInactive;
    }
  }

  Color get color {
    switch (this) {
      case ParentStatus.pending:
        return AppColors.paperAccent;
      case ParentStatus.active:
        return AppColors.paperOk;
      case ParentStatus.inactive:
        return AppColors.inkTertiary;
    }
  }
}

extension ParentPermissionVisuals on ParentPermission {
  String get label {
    switch (this) {
      case ParentPermission.viewOnly:
        return AppStrings.parentHomePermissionViewOnly;
      case ParentPermission.managePayments:
        return AppStrings.parentHomePermissionManagePayments;
      case ParentPermission.manageLessons:
        return AppStrings.parentHomePermissionManageLessons;
      case ParentPermission.fullAccess:
        return AppStrings.parentHomePermissionFullAccess;
    }
  }
}

extension InvitationSourceVisuals on InvitationSource {
  String get label {
    switch (this) {
      case InvitationSource.student:
        return AppStrings.parentHomeInvitationSourceStudent;
      case InvitationSource.teacher:
        return AppStrings.parentHomeInvitationSourceTeacher;
    }
  }
}

extension ParentChildRelationStatusVisuals on ParentChildRelationStatus {
  String get label {
    switch (this) {
      case ParentChildRelationStatus.pending:
        return AppStrings.parentHomeRelationStatusPending;
      case ParentChildRelationStatus.active:
        return AppStrings.parentHomeRelationStatusActive;
      case ParentChildRelationStatus.inactive:
        return AppStrings.parentHomeRelationStatusInactive;
    }
  }
}

extension NotificationCategoryVisuals on NotificationCategory {
  String get label {
    switch (this) {
      case NotificationCategory.payment:
        return AppStrings.parentHomeNotificationCategoryPayment;
      case NotificationCategory.lesson:
        return AppStrings.parentHomeNotificationCategoryLesson;
      case NotificationCategory.assignment:
        return AppStrings.parentHomeNotificationCategoryAssignment;
      case NotificationCategory.practice:
        return AppStrings.parentHomeNotificationCategoryPractice;
      case NotificationCategory.communication:
        return AppStrings.parentHomeNotificationCategoryCommunication;
      case NotificationCategory.report:
        return AppStrings.parentHomeNotificationCategoryReport;
    }
  }

  String get icon {
    switch (this) {
      case NotificationCategory.payment:
        return '💰';
      case NotificationCategory.lesson:
        return '📅';
      case NotificationCategory.assignment:
        return '📝';
      case NotificationCategory.practice:
        return '🔥';
      case NotificationCategory.communication:
        return '💬';
      case NotificationCategory.report:
        return '📊';
    }
  }
}

extension NotificationItemVisuals on NotificationItem {
  String get label => type.label;

  String get suffix {
    if (isRequired) return AppStrings.parentHomeNotificationRequiredSuffix;
    if (isRecommended) {
      return AppStrings.parentHomeNotificationRecommendedSuffix;
    }
    return '';
  }
}

extension NotificationSettingTypeVisuals on NotificationSettingType {
  String get label {
    switch (this) {
      case NotificationSettingType.paymentRequest:
        return AppStrings.parentHomeNotificationPaymentRequest;
      case NotificationSettingType.paymentComplete:
        return AppStrings.parentHomeNotificationPaymentComplete;
      case NotificationSettingType.paymentDueSoon:
        return AppStrings.parentHomeNotificationPaymentDueSoon;
      case NotificationSettingType.lessonChange:
        return AppStrings.parentHomeNotificationLessonChange;
      case NotificationSettingType.lessonCancel:
        return AppStrings.parentHomeNotificationLessonCancel;
      case NotificationSettingType.lessonStart:
        return AppStrings.parentHomeNotificationLessonStart;
      case NotificationSettingType.lessonEnd:
        return AppStrings.parentHomeNotificationLessonEnd;
      case NotificationSettingType.newAssignment:
        return AppStrings.parentHomeNotificationNewAssignment;
      case NotificationSettingType.assignmentIncomplete:
        return AppStrings.parentHomeNotificationAssignmentIncomplete;
      case NotificationSettingType.practiceComplete:
        return AppStrings.parentHomeNotificationPracticeComplete;
      case NotificationSettingType.streakAchievement:
        return AppStrings.parentHomeNotificationStreakAchievement;
      case NotificationSettingType.teacherMessage:
        return AppStrings.parentHomeNotificationTeacherMessage;
      case NotificationSettingType.lessonNoteUpdate:
        return AppStrings.parentHomeNotificationLessonNoteUpdate;
      case NotificationSettingType.weeklyReport:
        return AppStrings.parentHomeNotificationWeeklyReport;
      case NotificationSettingType.monthlyReport:
        return AppStrings.parentHomeNotificationMonthlyReport;
    }
  }
}

extension ParentVisuals on Parent {
  Color get profileColor => _colorForKey(profileColorKey);
}

extension ProfileTypeVisuals on ProfileType {
  String get label {
    switch (this) {
      case ProfileType.parent:
        return AppStrings.parentHomeProfileTypeParent;
      case ProfileType.student:
        return AppStrings.parentHomeProfileTypeStudent;
      case ProfileType.child:
        return AppStrings.parentHomeProfileTypeChild;
    }
  }

  IconData get icon {
    switch (this) {
      case ProfileType.parent:
        return Icons.family_restroom;
      case ProfileType.student:
        return Icons.school;
      case ProfileType.child:
        return Icons.child_care;
    }
  }

  Color get color {
    switch (this) {
      case ProfileType.parent:
        return AppColors.paperAccent;
      case ProfileType.student:
        return AppColors.paperOk;
      case ProfileType.child:
        return AppColors.paperAccent;
    }
  }
}

extension ChildConnectionStatusVisuals on ChildConnectionStatus {
  String get label {
    switch (this) {
      case ChildConnectionStatus.connected:
        return AppStrings.parentHomeChildConnectionConnected;
      case ChildConnectionStatus.pending:
        return AppStrings.parentHomeChildConnectionPending;
      case ChildConnectionStatus.unconnected:
        return AppStrings.parentHomeChildConnectionUnconnected;
    }
  }

  Color get color {
    switch (this) {
      case ChildConnectionStatus.connected:
        return AppColors.paperOk;
      case ChildConnectionStatus.pending:
        return AppColors.paperAccent;
      case ChildConnectionStatus.unconnected:
        return AppColors.inkTertiary;
    }
  }

  IconData get icon {
    switch (this) {
      case ChildConnectionStatus.connected:
        return Icons.link;
      case ChildConnectionStatus.pending:
        return Icons.hourglass_empty;
      case ChildConnectionStatus.unconnected:
        return Icons.link_off;
    }
  }
}

extension ChildProfileStatusVisuals on ChildProfileStatus {
  String get label {
    switch (this) {
      case ChildProfileStatus.active:
        return AppStrings.parentHomeChildStatusActive;
      case ChildProfileStatus.inactive:
        return AppStrings.parentHomeChildStatusInactive;
    }
  }
}

extension ChildProfileVisuals on ChildProfile {
  Color get profileColor => _colorForKey(profileColorKey);
  IconData get instrumentIcon => _iconForKey(instrumentIconKey);
}
