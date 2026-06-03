import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../widgets/makeup_credit_card.dart';
import '../widgets/teacher_makeup_credit_section.dart';

/// Makeup credit screen (#432 / Make-up Bank).
///
/// - Student role: balance card + ledger (§9.1).
/// - Teacher role: per-student grant/revoke management (§9.2) — requires
///   [studentId].
///
/// Spec: docs/specs/subscription/makeup_credit_spec.md §9.
class MakeupCreditScreen extends StatelessWidget {
  /// When non-null, render teacher-side management for this student.
  /// When null, render the student-side balance card.
  final String? studentId;

  const MakeupCreditScreen({super.key, this.studentId});

  @override
  Widget build(BuildContext context) {
    final isTeacher = studentId != null;
    return NotebookScreenScaffold(
      appBarTitle: isTeacher
          ? AppStrings.makeupCreditManageTitle
          : AppStrings.makeupCreditTitle,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: [
          if (isTeacher)
            TeacherMakeupCreditSection(studentId: studentId!)
          else
            const MakeupCreditCard(),
        ],
      ),
    );
  }
}
