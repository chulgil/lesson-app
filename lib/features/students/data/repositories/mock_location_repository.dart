import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../domain/entities/lesson_location.dart';
import '../../domain/repositories/location_repository.dart';

/// Mock implementation of LocationRepository for development.
class MockLocationRepository implements LocationRepository {
  final _uuid = const Uuid();
  final List<LessonLocation> _locations = [];
  final _controller = StreamController<List<LessonLocation>>.broadcast();

  MockLocationRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    _locations.addAll([
      // Academy rooms
      LessonLocation(
        id: 'loc_001',
        name: '레슨실 1',
        type: LocationType.academyRoom,
        lessonClassId: 'lc_001', // 행복음악학원
        address: '서울시 강남구 테헤란로 123',
        addressDetail: '3층 301호',
        latitude: 37.5012,
        longitude: 127.0396,
        notes: '주차 1시간 무료, 엘리베이터 이용\n레슨 10분 전 대기실 도착',
        isDefault: true,
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      LessonLocation(
        id: 'loc_002',
        name: '레슨실 2',
        type: LocationType.academyRoom,
        lessonClassId: 'lc_001', // 행복음악학원
        address: '서울시 강남구 테헤란로 123',
        addressDetail: '3층 302호',
        latitude: 37.5012,
        longitude: 127.0396,
        isDefault: false,
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      // Teacher studio (for private lessons)
      LessonLocation(
        id: 'loc_003',
        name: '홈 스튜디오',
        type: LocationType.teacherStudio,
        lessonClassId: 'lc_002', // 개인레슨
        ownerId: 'teacher_1',
        address: '서울시 마포구 연남로 45',
        addressDetail: '102호',
        latitude: 37.5665,
        longitude: 126.9220,
        notes: '연남동 지하철 3번 출구에서 도보 5분\n주차 불가, 대중교통 이용 권장',
        isDefault: true,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      // Online location
      LessonLocation(
        id: 'loc_004',
        name: 'Zoom 레슨',
        type: LocationType.online,
        lessonClassId: 'lc_002', // 개인레슨
        ownerId: 'teacher_1',
        onlinePlatform: 'Zoom',
        onlineLink: 'https://zoom.us/j/1234567890',
        notes: '레슨 시작 10분 전 접속\n화상 카메라 켜고 악기 준비',
        isDefault: false,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      // Arts center academy
      LessonLocation(
        id: 'loc_005',
        name: '연습실 A',
        type: LocationType.academyRoom,
        lessonClassId: 'lc_003', // 예술의전당 아카데미
        address: '서울시 서초구 예술의전당로 123',
        addressDetail: '음악아카데미 2층',
        latitude: 37.4785,
        longitude: 127.0136,
        notes: '예술의전당 주차장 이용 (유료)\n정문에서 음악아카데미 방향 안내 따라가기',
        isDefault: true,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    ]);
  }

  void _notifyListeners() {
    _controller.add(List.unmodifiable(_locations));
  }

  @override
  Future<List<LessonLocation>> getByClassId(String classId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _locations
        .where((l) => l.lessonClassId == classId && l.isActive)
        .toList();
  }

  @override
  Future<List<LessonLocation>> getByOwnerId(String ownerId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _locations
        .where((l) => l.ownerId == ownerId && l.isActive)
        .toList();
  }

  @override
  Future<LessonLocation?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _locations.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<LessonLocation> create(LessonLocation location) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newLocation = location.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    _locations.add(newLocation);
    _notifyListeners();
    return newLocation;
  }

  @override
  Future<LessonLocation> update(LessonLocation location) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _locations.indexWhere((l) => l.id == location.id);
    if (index == -1) {
      throw Exception('LessonLocation not found: ${location.id}');
    }
    final updated = location.copyWith(updatedAt: DateTime.now());
    _locations[index] = updated;
    _notifyListeners();
    return updated;
  }

  @override
  Future<void> setDefault(String id, String classId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Reset all defaults for the class
    for (var i = 0; i < _locations.length; i++) {
      if (_locations[i].lessonClassId == classId) {
        _locations[i] = _locations[i].copyWith(
          isDefault: _locations[i].id == id,
          updatedAt: DateTime.now(),
        );
      }
    }
    _notifyListeners();
  }

  @override
  Future<void> deactivate(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _locations.indexWhere((l) => l.id == id);
    if (index == -1) {
      throw Exception('LessonLocation not found: $id');
    }
    _locations[index] = _locations[index].copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );
    _notifyListeners();
  }

  @override
  Future<void> reactivate(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _locations.indexWhere((l) => l.id == id);
    if (index == -1) {
      throw Exception('LessonLocation not found: $id');
    }
    _locations[index] = _locations[index].copyWith(
      isActive: true,
      updatedAt: DateTime.now(),
    );
    _notifyListeners();
  }

  @override
  Stream<List<LessonLocation>> watchByClassId(String classId) {
    Future.microtask(() async {
      final locations = await getByClassId(classId);
      _controller.add(locations);
    });
    return _controller.stream.map(
      (list) =>
          list.where((l) => l.lessonClassId == classId && l.isActive).toList(),
    );
  }

  @override
  Stream<List<LessonLocation>> watchByOwnerId(String ownerId) {
    Future.microtask(() async {
      final locations = await getByOwnerId(ownerId);
      _controller.add(locations);
    });
    return _controller.stream.map(
      (list) => list.where((l) => l.ownerId == ownerId && l.isActive).toList(),
    );
  }

  void dispose() {
    _controller.close();
  }
}
