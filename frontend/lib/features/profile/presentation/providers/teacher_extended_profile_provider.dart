import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../models/teacher_profile.dart';
import '../../../../providers/auth/user_role_provider.dart';
import '../../../../providers/onboarding/teacher_profile_repository_provider.dart';

part 'teacher_extended_profile_provider.g.dart';

/// Current teacher profile state
@Riverpod(keepAlive: true)
class TeacherExtendedProfile extends _$TeacherExtendedProfile {
  @override
  AsyncValue<TeacherProfile?> build() {
    // Load initial profile
    _loadProfile();
    return const AsyncValue.loading();
  }

  Future<void> _loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);
      final profile = await repo.getProfileByUserId(userId);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadProfile();
  }

  /// Update experience years
  Future<void> updateExperienceYears(int years) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final updated = await repo.updateProfile(
        current.copyWith(experienceYears: years),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update lesson areas
  Future<void> updateLessonAreas(List<String> areas) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final updated = await repo.updateProfile(
        current.copyWith(lessonAreas: areas),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update lesson types
  Future<void> updateLessonTypes(List<LessonType> types) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final updated = await repo.updateProfile(
        current.copyWith(lessonTypes: types),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update fee range
  Future<void> updateFeeRange(FeeRange feeRange) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final updated = await repo.updateProfile(
        current.copyWith(feeRange: feeRange),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Add education record
  Future<void> addEducation(Education education) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final existingList = current.education ?? <Education>[];
      final newList = <Education>[...existingList, education];
      final updated = await repo.updateProfile(
        current.copyWith(education: newList),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update education record at index
  Future<void> updateEducation(int index, Education education) async {
    final current = state.valueOrNull;
    if (current == null || current.education == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final newList = List<Education>.from(current.education!);
      newList[index] = education;
      final updated = await repo.updateProfile(
        current.copyWith(education: newList),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Remove education record at index
  Future<void> removeEducation(int index) async {
    final current = state.valueOrNull;
    if (current == null || current.education == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final newList = List<Education>.from(current.education!);
      newList.removeAt(index);
      final updated = await repo.updateProfile(
        current.copyWith(education: newList),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Add career record
  Future<void> addCareer(Career career) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final existingList = current.career ?? <Career>[];
      final newList = <Career>[...existingList, career];
      final updated = await repo.updateProfile(
        current.copyWith(career: newList),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update career record at index
  Future<void> updateCareer(int index, Career career) async {
    final current = state.valueOrNull;
    if (current == null || current.career == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final newList = List<Career>.from(current.career!);
      newList[index] = career;
      final updated = await repo.updateProfile(
        current.copyWith(career: newList),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Remove career record at index
  Future<void> removeCareer(int index) async {
    final current = state.valueOrNull;
    if (current == null || current.career == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final newList = List<Career>.from(current.career!);
      newList.removeAt(index);
      final updated = await repo.updateProfile(
        current.copyWith(career: newList),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Add certificate
  Future<void> addCertificate(Certificate certificate) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final existingList = current.verification.certificates;
      final newList = <Certificate>[...existingList, certificate];
      final newVerification = current.verification.copyWith(
        certificates: newList,
      );
      final updated = await repo.updateProfile(
        current.copyWith(verification: newVerification),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update certificate by id
  Future<void> updateCertificate(String id, Certificate certificate) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final newList =
          current.verification.certificates.map((c) {
            return c.id == id ? certificate : c;
          }).toList();
      final newVerification = current.verification.copyWith(
        certificates: newList,
      );
      final updated = await repo.updateProfile(
        current.copyWith(verification: newVerification),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Remove certificate by id
  Future<void> removeCertificate(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final newList =
          current.verification.certificates.where((c) => c.id != id).toList();
      final newVerification = current.verification.copyWith(
        certificates: newList,
      );
      final updated = await repo.updateProfile(
        current.copyWith(verification: newVerification),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Get certificate by id
  Certificate? getCertificateById(String id) {
    final current = state.valueOrNull;
    if (current == null) return null;

    try {
      return current.verification.certificates.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Update visibility settings
  Future<void> updateVisibilitySettings(
    ProfileVisibilitySettings settings,
  ) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final updated = await repo.updateProfile(
        current.copyWith(visibilitySettings: settings),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update basic info, teaching style, and specialties in a single call.
  /// Prevents partial save issues when saving from BasicInfoEditScreen.
  Future<void> updateBasicInfoAll({
    required String name,
    required String introduction,
    String? teachingStyle,
    List<String>? specialties,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final updated = await repo.updateProfile(
        current.copyWith(
          name: name,
          introduction: introduction,
          teachingStyle: teachingStyle ?? current.teachingStyle,
          specialties: specialties ?? current.specialties,
        ),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update basic info (name and/or introduction)
  Future<void> updateBasicInfo({String? name, String? introduction}) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final updated = await repo.updateProfile(
        current.copyWith(
          name: name ?? current.name,
          introduction: introduction ?? current.introduction,
        ),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update teaching style
  Future<void> updateTeachingStyle(String style) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final updated = await repo.updateProfile(
        current.copyWith(teachingStyle: style),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update specialties
  Future<void> updateSpecialties(List<String> specialties) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final repo = ref.read(teacherProfileRepositoryProvider);
      final updated = await repo.updateProfile(
        current.copyWith(specialties: specialties),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update searchable setting
  Future<void> updateSearchable(bool isSearchable) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final newSettings = current.visibilitySettings.copyWith(
      isSearchable: isSearchable,
    );
    await updateVisibilitySettings(newSettings);
  }
}
