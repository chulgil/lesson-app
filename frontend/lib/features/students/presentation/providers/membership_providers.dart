import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_membership_repository.dart';
import '../../data/repositories/remote_membership_repository.dart';
import '../../domain/entities/class_membership.dart';
import '../../domain/repositories/membership_repository.dart';

part 'membership_providers.g.dart';

/// Repository provider for ClassMembership.
@riverpod
MembershipRepository membershipRepository(MembershipRepositoryRef ref) =>
    createRepository<MembershipRepository>(
      ref: ref,
      mock: () => MockMembershipRepository(),
      remote: (api) => RemoteMembershipRepository(api),
    );

/// Get all memberships for a class.
@riverpod
Future<List<ClassMembership>> classMemberships(
  ClassMembershipsRef ref,
  String classId,
) async {
  final repository = ref.watch(membershipRepositoryProvider);
  return repository.getByClassId(classId);
}

/// Get all memberships for a student.
@riverpod
Future<List<ClassMembership>> studentMemberships(
  StudentMembershipsRef ref,
  String studentId,
) async {
  final repository = ref.watch(membershipRepositoryProvider);
  return repository.getByStudentId(studentId);
}

/// Get a single membership by ID.
@riverpod
Future<ClassMembership?> membership(MembershipRef ref, String id) async {
  final repository = ref.watch(membershipRepositoryProvider);
  return repository.getById(id);
}

/// Get active memberships for a student (trial or active status).
@riverpod
Future<List<ClassMembership>> activeStudentMemberships(
  ActiveStudentMembershipsRef ref,
  String studentId,
) async {
  final repository = ref.watch(membershipRepositoryProvider);
  final memberships = await repository.getByStudentId(studentId);
  return memberships.where((m) => m.isEnrolled).toList();
}

/// Sibling read providers over the same membership data. They have no
/// watch-chain to the notifiers below, so every mutation must invalidate
/// them or consumer screens (grouped student list, edit-student link check)
/// keep showing pre-mutation memberships until the provider is recreated.
void _invalidateMembershipReads(Ref ref) {
  ref.invalidate(classMembershipsProvider);
  ref.invalidate(studentMembershipsProvider);
  ref.invalidate(activeStudentMembershipsProvider);
  ref.invalidate(membershipProvider);
}

/// Notifier for managing ClassMembership CRUD operations.
@riverpod
class MembershipNotifier extends _$MembershipNotifier {
  @override
  Future<List<ClassMembership>> build(String classId) async {
    final repository = ref.watch(membershipRepositoryProvider);
    return repository.getByClassId(classId);
  }

  Future<ClassMembership> create(ClassMembership membership) async {
    final repository = ref.read(membershipRepositoryProvider);
    final created = await repository.create(membership);
    ref.invalidateSelf();
    _invalidateMembershipReads(ref);
    return created;
  }

  Future<ClassMembership> updateMembership(ClassMembership membership) async {
    final repository = ref.read(membershipRepositoryProvider);
    final updated = await repository.update(membership);
    ref.invalidateSelf();
    _invalidateMembershipReads(ref);
    return updated;
  }

  Future<void> updateStatus(String id, MembershipStatus status) async {
    final repository = ref.read(membershipRepositoryProvider);
    await repository.updateStatus(id, status);
    ref.invalidateSelf();
    _invalidateMembershipReads(ref);
  }

  Future<void> delete(String id) async {
    final repository = ref.read(membershipRepositoryProvider);
    await repository.delete(id);
    ref.invalidateSelf();
    _invalidateMembershipReads(ref);
  }
}

/// Notifier for managing student's memberships.
@riverpod
class StudentMembershipNotifier extends _$StudentMembershipNotifier {
  @override
  Future<List<ClassMembership>> build(String studentId) async {
    final repository = ref.watch(membershipRepositoryProvider);
    return repository.getByStudentId(studentId);
  }

  Future<ClassMembership> create(ClassMembership membership) async {
    final repository = ref.read(membershipRepositoryProvider);
    final created = await repository.create(membership);
    ref.invalidateSelf();
    _invalidateMembershipReads(ref);
    return created;
  }

  Future<ClassMembership> updateMembership(ClassMembership membership) async {
    final repository = ref.read(membershipRepositoryProvider);
    final updated = await repository.update(membership);
    ref.invalidateSelf();
    _invalidateMembershipReads(ref);
    return updated;
  }

  Future<void> updateStatus(String id, MembershipStatus status) async {
    final repository = ref.read(membershipRepositoryProvider);
    await repository.updateStatus(id, status);
    ref.invalidateSelf();
    _invalidateMembershipReads(ref);
  }
}
