import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../academy/academy.dart';
import 'context_toggle_dialog.dart';

/// Provides a context toggle menu item for profile tab.
///
/// Returns a [_MenuItem] that can be used in profile menu sections.
/// Only shown when user has both R-AO (owner) and R-AT (teacher) roles.
class ContextToggleButton extends ConsumerWidget {
  const ContextToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This widget should be inserted into profile menu where needed
    // Use buildMenuItem() method to get the _MenuItem for profile menu
    return const SizedBox.shrink();
  }

  /// Returns a [_MenuItem] for use in profile menu sections.
  ///
  /// Returns null if user doesn't have both roles.
  // ignore: library_private_types_in_public_api
  static Future<_MenuItem?> buildMenuItem(
    BuildContext context,
    List<AcademyMember> academyMembers,
  ) async {
    // Check if user has both owner and teacher roles
    final hasOwnerRole = academyMembers.any(
      (m) => m.role == AcademyMemberRole.owner,
    );
    final hasTeacherRole = academyMembers.any(
      (m) => m.role == AcademyMemberRole.teacher,
    );

    if (!hasOwnerRole || !hasTeacherRole) {
      return null;
    }

    return _MenuItem(
      icon: Icons.swap_horiz_rounded,
      label: AppStrings.contextToggleButtonLabel,
      subtitle: AppStrings.contextToggleButtonSubtitle,
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => const ContextToggleDialog(),
        );
      },
    );
  }
}

/// Menu item data class for profile menu.
class _MenuItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });
}
