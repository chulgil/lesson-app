import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/auth_facade.dart';
import '../../../students/students_facade.dart';

part 'student_home_profile_edit_provider.g.dart';

@riverpod
Future<Student?> studentHomeProfileEditStudent(
  StudentHomeProfileEditStudentRef ref,
) {
  final studentId = ref.watch(currentUserIdProvider);
  return ref.watch(studentProvider(studentId).future);
}

@riverpod
Future<String?> studentHomeProfileEditImagePath(
  StudentHomeProfileEditImagePathRef ref,
  String studentId,
) {
  return ref.watch(studentProfileImageNotifierProvider(studentId).future);
}

@riverpod
StudentHomeProfileEditActions studentHomeProfileEditActions(
  StudentHomeProfileEditActionsRef ref,
) {
  return StudentHomeProfileEditActions(ref);
}

class StudentHomeProfileEditActions {
  final StudentHomeProfileEditActionsRef _ref;

  const StudentHomeProfileEditActions(this._ref);

  Future<Student> updateStudent(Student student) {
    return _ref.read(studentsNotifierProvider.notifier).updateStudent(student);
  }

  String? profileImagePath(String studentId) {
    return _ref
        .read(studentProfileImageNotifierProvider(studentId))
        .valueOrNull;
  }

  Future<void> removeProfileImage(String studentId) {
    return _ref
        .read(studentProfileImageNotifierProvider(studentId).notifier)
        .removeImage();
  }

  Future<bool> pickAndSaveProfileImage(
    String studentId,
    ImageSource source,
    BuildContext context,
  ) {
    return _ref
        .read(studentProfileImageNotifierProvider(studentId).notifier)
        .pickAndSaveImage(source, context);
  }
}
