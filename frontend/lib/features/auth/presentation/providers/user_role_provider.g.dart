// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_role_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentUserRoleHash() => r'7b375133759728d30f8ec2ee7a426734bf4b63b7';

/// Current user role state provider.
///
/// In mock mode: notifier state (for debug role switching).
/// In remote mode: derived from AuthNotifier state.
///
/// Copied from [currentUserRole].
@ProviderFor(currentUserRole)
final currentUserRoleProvider = Provider<UserRole>.internal(
  currentUserRole,
  name: r'currentUserRoleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserRoleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentUserRoleRef = ProviderRef<UserRole>;
String _$currentUserRoleStateHandleHash() =>
    r'15d3bb2139a3c7f83a7423eab2d1d15e301d2956';

/// See also [currentUserRoleStateHandle].
@ProviderFor(currentUserRoleStateHandle)
final currentUserRoleStateHandleProvider =
    Provider<CurrentUserRoleStateHandle>.internal(
  currentUserRoleStateHandle,
  name: r'currentUserRoleStateHandleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserRoleStateHandleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentUserRoleStateHandleRef = ProviderRef<CurrentUserRoleStateHandle>;
String _$currentUserIdHash() => r'54acdde57b5f270677d25087fe2d50b4470665a8';

/// Current user ID based on role.
///
/// In mock mode: returns mock IDs.
/// In remote mode: returns actual user ID from auth state.
///
/// Copied from [currentUserId].
@ProviderFor(currentUserId)
final currentUserIdProvider = Provider<String>.internal(
  currentUserId,
  name: r'currentUserIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentUserIdRef = ProviderRef<String>;
String _$mockStudentsHash() => r'beab4898c58e57e692da666d2bbf8ca04ce9abfb';

/// Available mock students for testing
///
/// Copied from [mockStudents].
@ProviderFor(mockStudents)
final mockStudentsProvider = Provider<List<MockStudentInfo>>.internal(
  mockStudents,
  name: r'mockStudentsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$mockStudentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MockStudentsRef = ProviderRef<List<MockStudentInfo>>;
String _$currentUserRoleControllerHash() =>
    r'eaf62f1d1e834baa0035bf2d4071fbf37451211d';

/// See also [CurrentUserRoleController].
@ProviderFor(CurrentUserRoleController)
final currentUserRoleControllerProvider =
    NotifierProvider<CurrentUserRoleController, UserRole>.internal(
  CurrentUserRoleController.new,
  name: r'currentUserRoleControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserRoleControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentUserRoleController = Notifier<UserRole>;
String _$selectedMockStudentHash() =>
    r'f715241897ec54a1abc58e00629f3dd1b328bc2f';

/// Currently selected mock student (for student role testing)
///
/// Copied from [SelectedMockStudent].
@ProviderFor(SelectedMockStudent)
final selectedMockStudentProvider =
    NotifierProvider<SelectedMockStudent, MockStudentInfo>.internal(
  SelectedMockStudent.new,
  name: r'selectedMockStudentProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedMockStudentHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedMockStudent = Notifier<MockStudentInfo>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
