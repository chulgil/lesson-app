import 'package:flutter/material.dart';

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
}
