import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_academy_invite_repository.dart';
import 'package:lessonaza/features/academy/domain/entities/academy.dart';
import 'package:lessonaza/features/academy/domain/repositories/academy_invite_repository.dart';

void main() {
  group('MockAcademyInviteRepository', () {
    late MockAcademyInviteRepository repository;
    late AcademyInvitePreview testPreview;
    const testToken = 'test-invite-token-123';

    setUp(() {
      repository = MockAcademyInviteRepository();
      final academy = Academy(
        id: 'academy-1',
        slug: 'test-academy',
        name: 'Test Academy',
        address: '서울시 강남구',
        ownerUserId: 'user-1',
        createdAt: DateTime.now(),
      );
      testPreview = AcademyInvitePreview(
        token: testToken,
        academy: academy,
        ownerName: '홍길동',
        roles: ['R-AO', 'R-AT'],
      );
    });

    test('getInvitePreview returns preview for valid token', () async {
      repository.addInvitePreview(testToken, testPreview);

      final result = await repository.getInvitePreview(testToken);

      expect(result.token, testToken);
      expect(result.academy.name, 'Test Academy');
      expect(result.ownerName, '홍길동');
      expect(result.roles, ['R-AO', 'R-AT']);
    });

    test('getInvitePreview throws for expired token', () async {
      repository.addInvitePreview(testToken, testPreview);
      repository.expireToken(testToken);

      expect(() => repository.getInvitePreview(testToken), throwsException);
    });

    test('getInvitePreview throws for non-existent token', () async {
      expect(
        () => repository.getInvitePreview('invalid-token'),
        throwsException,
      );
    });

    test('acceptInvite removes token from available previews', () async {
      repository.addInvitePreview(testToken, testPreview);

      await repository.acceptInvite(testToken, publicPageConsent: true);

      expect(() => repository.getInvitePreview(testToken), throwsException);
    });

    test('acceptInvite throws for expired token', () async {
      repository.addInvitePreview(testToken, testPreview);
      repository.expireToken(testToken);

      expect(
        () => repository.acceptInvite(testToken, publicPageConsent: true),
        throwsException,
      );
    });

    test('rejectInvite marks token as rejected', () async {
      repository.addInvitePreview(testToken, testPreview);

      await repository.rejectInvite(testToken);

      expect(repository.wasTokenRejected(testToken), true);
    });

    test('rejectInvite removes token from available previews', () async {
      repository.addInvitePreview(testToken, testPreview);

      await repository.rejectInvite(testToken);

      expect(() => repository.getInvitePreview(testToken), throwsException);
    });

    test('rejectInvite throws for expired token', () async {
      repository.addInvitePreview(testToken, testPreview);
      repository.expireToken(testToken);

      expect(() => repository.rejectInvite(testToken), throwsException);
    });

    test('reset clears all state', () async {
      repository.addInvitePreview(testToken, testPreview);
      repository.expireToken('expired-token');

      repository.reset();

      expect(() => repository.getInvitePreview(testToken), throwsException);
    });
  });
}
