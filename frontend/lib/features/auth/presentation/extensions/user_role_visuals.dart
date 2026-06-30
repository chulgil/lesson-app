import 'package:flutter/material.dart';

import '../../../../core/router/app_routes.dart';
import '../../domain/entities/user_role.dart';

extension UserRoleVisuals on UserRole {
  String get label {
    switch (this) {
      case UserRole.teacher:
        return '선생님';
      case UserRole.student:
        return '학생';
      case UserRole.parent:
        return '학부모';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.teacher:
        return Icons.school;
      case UserRole.student:
        return Icons.music_note;
      case UserRole.parent:
        return Icons.family_restroom;
    }
  }

  String get homeRoute {
    switch (this) {
      case UserRole.teacher:
        return '/home';
      case UserRole.student:
        return '/student-home';
      case UserRole.parent:
        return '/parent-home';
    }
  }

  /// Onboarding route entered after this role is chosen at sign-up.
  ///
  /// SSOT for role -> onboarding entry, extracted from RoleSelectScreen so the
  /// multi-discipline gate (#977) and the discipline-selection step share one
  /// mapping. Byte-identical to the previous inline switch.
  String get onboardingRoute {
    switch (this) {
      case UserRole.teacher:
        return AppRoutes.teacherProfileSetup;
      case UserRole.student:
        // 임시 안전망 — 만 14세 검증용 통신사 본인인증(PASS) 통합 전까지
        // 학생 직접 가입은 차단 화면으로 안내한다.
        // 정책: phone_verification_policy.md §3.2.
        // PASS 통합 시 학생용 전화인증 화면 라우트로 교체.
        return AppRoutes.studentSignupBlocked;
      case UserRole.parent:
        return AppRoutes.parentInviteCode;
    }
  }
}
