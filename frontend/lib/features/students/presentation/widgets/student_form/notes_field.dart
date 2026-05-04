import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import 'student_form_helpers.dart';

/// Notes text field.
class NotesField extends StatelessWidget {
  final TextEditingController controller;

  const NotesField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: studentInputDecoration(
        label: AppStrings.studentNotesLabel,
        hint: AppStrings.studentNotesHint,
        prefixIcon: Icons.note_alt_outlined,
      ),
      maxLines: 4,
      textInputAction: TextInputAction.done,
    );
  }
}
