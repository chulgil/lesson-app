import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/environment.dart';
import '../../data/repositories/mock_location_repository.dart';
import '../../domain/entities/lesson_location.dart';
import '../../domain/repositories/location_repository.dart';

part 'location_providers.g.dart';

/// Repository provider for LessonLocation.
@riverpod
LocationRepository locationRepository(LocationRepositoryRef ref) {
  if (EnvironmentConfig.useMockData) {
    return MockLocationRepository();
  }
  // Backend API 미구현 — 레슨 장소 엔드포인트 필요
  return MockLocationRepository();
}

/// Get all locations for a class.
@riverpod
Future<List<LessonLocation>> classLocations(
  ClassLocationsRef ref,
  String classId,
) async {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.getByClassId(classId);
}

/// Get all locations owned by a teacher.
@riverpod
Future<List<LessonLocation>> teacherLocations(
  TeacherLocationsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.getByOwnerId(teacherId);
}

/// Get a single location by ID.
@riverpod
Future<LessonLocation?> location(LocationRef ref, String id) async {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.getById(id);
}

/// Get the default location for a class.
@riverpod
Future<LessonLocation?> defaultClassLocation(
  DefaultClassLocationRef ref,
  String classId,
) async {
  final repository = ref.watch(locationRepositoryProvider);
  final locations = await repository.getByClassId(classId);
  try {
    return locations.firstWhere((l) => l.isDefault);
  } catch (_) {
    return locations.isNotEmpty ? locations.first : null;
  }
}

/// Notifier for managing LessonLocation CRUD operations for a class.
@riverpod
class LocationNotifier extends _$LocationNotifier {
  late final String _classId;

  @override
  Future<List<LessonLocation>> build(String classId) async {
    _classId = classId;
    final repository = ref.watch(locationRepositoryProvider);
    return repository.getByClassId(classId);
  }

  Future<LessonLocation> createLocation(LessonLocation location) async {
    final repository = ref.read(locationRepositoryProvider);
    final created = await repository.create(location);
    ref.invalidateSelf();
    return created;
  }

  Future<LessonLocation> updateLocation(LessonLocation location) async {
    final repository = ref.read(locationRepositoryProvider);
    final updated = await repository.update(location);
    ref.invalidateSelf();
    return updated;
  }

  Future<void> setDefault(String id) async {
    final repository = ref.read(locationRepositoryProvider);
    await repository.setDefault(id, _classId);
    ref.invalidateSelf();
  }

  Future<void> deactivate(String id) async {
    final repository = ref.read(locationRepositoryProvider);
    await repository.deactivate(id);
    ref.invalidateSelf();
  }

  Future<void> reactivate(String id) async {
    final repository = ref.read(locationRepositoryProvider);
    await repository.reactivate(id);
    ref.invalidateSelf();
  }
}

/// Notifier for managing teacher's owned locations.
@riverpod
class TeacherLocationNotifier extends _$TeacherLocationNotifier {
  @override
  Future<List<LessonLocation>> build(String teacherId) async {
    final repository = ref.watch(locationRepositoryProvider);
    return repository.getByOwnerId(teacherId);
  }

  Future<LessonLocation> createLocation(LessonLocation location) async {
    final repository = ref.read(locationRepositoryProvider);
    final created = await repository.create(location);
    ref.invalidateSelf();
    return created;
  }

  Future<LessonLocation> updateLocation(LessonLocation location) async {
    final repository = ref.read(locationRepositoryProvider);
    final updated = await repository.update(location);
    ref.invalidateSelf();
    return updated;
  }

  Future<void> deactivate(String id) async {
    final repository = ref.read(locationRepositoryProvider);
    await repository.deactivate(id);
    ref.invalidateSelf();
  }
}
