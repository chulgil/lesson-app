import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/auth_facade.dart';
import '../../../students/students_facade.dart';

final studentHomeProfileEditStudentProvider =
    FutureProvider.autoDispose<Student?>((ref) {
      final studentId = ref.watch(currentUserIdProvider);
      return ref.watch(studentProvider(studentId).future);
    });

final studentHomeProfileEditImagePathProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, studentId) {
      return ref.watch(studentProfileImageNotifierProvider(studentId).future);
    });

final studentHomeProfileEditActionsProvider =
    Provider.autoDispose<StudentHomeProfileEditActions>((ref) {
      return StudentHomeProfileEditActions(ref);
    });

class StudentHomeProfileEditActions {
  final Ref _ref;

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
