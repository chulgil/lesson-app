// #1114 (INV-4) — logout must drop the previous user's unsent write queue so
// pending mutations never replay under the next login's auth token.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lessonaza/core/auth/token_storage.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/core/sync/data/sync_queue_store.dart';
import 'package:lessonaza/features/auth/domain/repositories/auth_repository.dart';
import 'package:lessonaza/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _FakeTokenStorage extends TokenStorage {
  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {}

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<bool> hasTokens() async => false;

  @override
  Future<void> clearTokens() async {}
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<void> logout() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthNotifier.logout sync queue (INV-4)', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'lessonaza_auth_logout_test_',
      );
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('로그아웃 시 sync_queue 박스를 비운다', () async {
      // Seed an unsent write in the real (default-named) queue box.
      final box = await Hive.openBox<dynamic>(SyncQueueStore.defaultBoxName);
      await box.put('entry_1', {
        'id': 'entry_1',
        'status': 'pending',
        'domain': 'lesson',
      });
      expect(box.isNotEmpty, isTrue);

      final container = ProviderContainer(
        overrides: [
          mockDataModeProvider.overrideWith((ref) => true),
          tokenStorageProvider.overrideWith((ref) => _FakeTokenStorage()),
          authRepositoryProvider.overrideWith((ref) => _FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.logout();

      expect(
        box.isEmpty,
        isTrue,
        reason: '이전 사용자의 미전송 쓰기가 다음 로그인 사용자 토큰으로 재생되면 안 됨',
      );
    });
  });

}
