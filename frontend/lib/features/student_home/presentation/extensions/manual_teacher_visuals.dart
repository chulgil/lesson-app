import 'package:flutter/material.dart';

import '../../domain/entities/manual_teacher.dart';

extension ManualTeacherVisuals on ManualTeacher {
  Color get profileColor => Color(profileColorValue);
}
