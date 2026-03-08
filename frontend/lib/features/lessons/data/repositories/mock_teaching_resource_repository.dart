import 'package:uuid/uuid.dart';

import '../../domain/entities/teaching_resource.dart';
import '../../domain/repositories/teaching_resource_repository.dart';

/// Mock implementation of TeachingResourceRepository for development
class MockTeachingResourceRepository implements TeachingResourceRepository {
  final _uuid = const Uuid();
  final List<TeachingResource> _resources = [];

  MockTeachingResourceRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    _resources.addAll([
      // YouTube resources
      TeachingResource(
        id: 'tr_001',
        teacherId: 'teacher_1',
        type: TeachingResourceType.youtube,
        title: '힐러리 한 - 바흐 파르티타 2번 샤콘느',
        description: '보잉 방향 전환이 매끄러운 구간을 잘 관찰하세요.',
        youtubeUrl: 'https://www.youtube.com/watch?v=QEhVW1sXOmM',
        youtubeVideoId: 'QEhVW1sXOmM',
        youtubeThumbnail: 'https://img.youtube.com/vi/QEhVW1sXOmM/mqdefault.jpg',
        youtubeStartSeconds: 92,
        youtubeEndSeconds: 155,
        instrument: '바이올린',
        tags: ['바흐', '보잉', '파르티타'],
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      TeachingResource(
        id: 'tr_002',
        teacherId: 'teacher_1',
        type: TeachingResourceType.youtube,
        title: '스즈키 2권 미뉴엣 시범 연주',
        description: '템포와 다이나믹 변화에 집중해서 들어보세요.',
        youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        youtubeVideoId: 'dQw4w9WgXcQ',
        youtubeThumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
        instrument: '바이올린',
        tags: ['스즈키', '미뉴엣', '기초'],
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      TeachingResource(
        id: 'tr_003',
        teacherId: 'teacher_1',
        type: TeachingResourceType.youtube,
        title: 'G Major 3옥타브 음계 - 정확한 포지션 이동',
        description: '3포지션에서 5포지션으로 이동할 때 엄지 위치를 주의하세요.',
        youtubeUrl: 'https://www.youtube.com/watch?v=example123',
        youtubeVideoId: 'example123',
        youtubeThumbnail: 'https://img.youtube.com/vi/example123/mqdefault.jpg',
        youtubeStartSeconds: 45,
        instrument: '바이올린',
        tags: ['음계', '포지션', '테크닉'],
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      TeachingResource(
        id: 'tr_004',
        teacherId: 'teacher_1',
        type: TeachingResourceType.youtube,
        title: '비발디 A단조 협주곡 1악장 카덴차',
        youtubeUrl: 'https://www.youtube.com/watch?v=vivaldi_amn',
        youtubeVideoId: 'vivaldi_amn',
        youtubeThumbnail: 'https://img.youtube.com/vi/vivaldi_amn/mqdefault.jpg',
        youtubeStartSeconds: 180,
        youtubeEndSeconds: 240,
        instrument: '바이올린',
        tags: ['비발디', '카덴차', '협주곡'],
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      // teacher_2 resource
      TeachingResource(
        id: 'tr_005',
        teacherId: 'teacher_2',
        type: TeachingResourceType.youtube,
        title: '첼로 기초 보잉 테크닉',
        description: '활 압력 조절에 집중하세요.',
        youtubeUrl: 'https://www.youtube.com/watch?v=cello_bow01',
        youtubeVideoId: 'cello_bow01',
        youtubeThumbnail: 'https://img.youtube.com/vi/cello_bow01/mqdefault.jpg',
        instrument: '첼로',
        tags: ['첼로', '보잉', '기초'],
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ]);
  }

  @override
  Future<List<TeachingResource>> getByTeacherId(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _resources
        .where((r) => r.teacherId == teacherId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<TeachingResource>> getByIds(List<String> ids) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _resources.where((r) => ids.contains(r.id)).toList();
  }

  @override
  Future<TeachingResource?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _resources.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TeachingResource> create(TeachingResource resource) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newResource = resource.copyWith(
      id: resource.id.isEmpty ? _uuid.v4() : resource.id,
      createdAt: DateTime.now(),
    );
    _resources.add(newResource);
    return newResource;
  }

  @override
  Future<TeachingResource> update(TeachingResource resource) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _resources.indexWhere((r) => r.id == resource.id);
    if (index == -1) {
      throw Exception('Teaching resource not found');
    }
    final updated = resource.copyWith(updatedAt: DateTime.now());
    _resources[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _resources.removeWhere((r) => r.id == id);
  }
}
