import 'package:flutter/material.dart';

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
        label: '메모',
        hint: '레슨 시 참고할 내용 (악기 상태, 연습 환경, 특이사항 등)',
        prefixIcon: Icons.note_alt_outlined,
      ),
      maxLines: 4,
      textInputAction: TextInputAction.done,
    );
  }
}
