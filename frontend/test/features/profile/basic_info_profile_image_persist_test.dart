// #1144 회귀: 선생님 프로필 사진 저장 미반영.
//
// basic_info_edit 의 저장(updateBasicInfoAll)이 사진을 파라미터로 받지 않아
// 엔티티 TeacherProfile.profileImage 가 계속 null 로 남았다. 그 결과 preview·
// 완성도 게이지·타 화면이 등록한 사진을 반영하지 못했다(사진은 별도
// profileImageNotifierProvider 디스크에만 저장). 사진 SSOT 부재.
//
// 수정: updateBasicInfoAll 이 profileImage(effective ref = 서버 URL 또는 로컬경로)
// 를 받아 엔티티에 저장하고 read provider(currentTeacherProfileProvider)에 반영.
// (RED: copyWith 에 profileImage 를 넘기지 않으면 read 값이 null 로 남는다.)
//
// Oracle 회피: 읽기 값을 주입하지 않고 실제 write(Notifier) -> read(FutureProvider,
// alive listener) 경로를 mock repo 로 실행한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show currentUserIdProvider;
import 'package:lessonaza/features/onboarding/onboarding_facade.dart'
    show currentTeacherProfileProvider, teacherProfileRepositoryProvider;
import 'package:lessonaza/features/profile/data/repositories/mock_teacher_profile_repository.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/presentation/providers/teacher_extended_profile_provider.dart';

TeacherProfile _seed() => TeacherProfile(
  id: 'p1',
  userId: 'u1',
  name: '테스트 선생님',
  instruments: const ['바이올린'],
  introduction: '기존 소개입니다.',
  verification: const TeacherVerification(),
  createdAt: DateTime(2026),
);

void main() {
  test(
    'updateBasicInfoAll 이 profileImage 를 엔티티에 저장하고 read provider 에 반영된다',
    () async {
      final repo = MockTeacherProfileRepository(empty: true);
      await repo.createProfile(_seed());

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => 'u1'),
          teacherProfileRepositoryProvider.overrideWith((ref) => repo),
        ],
      );
      addTearDown(container.dispose);

      // preview·완성도 게이지가 쓰는 read 경로를 alive 로 유지(invalidate 재요청 관찰).
      final sub = container.listen(
        currentTeacherProfileProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      final notifier = container.read(teacherExtendedProfileProvider.notifier);
      await notifier.refresh(); // current 로드

      final before = await container.read(currentTeacherProfileProvider.future);
      expect(before?.profileImage, isNull);

      const uploadedUrl = 'http://cdn.example.com/profile/u1.jpg';
      await notifier.updateBasicInfoAll(
        name: '테스트 선생님',
        introduction: '기존 소개입니다.',
        profileImage: uploadedUrl,
      );

      // Notifier 자체 상태 반영.
      expect(
        container
            .read(teacherExtendedProfileProvider)
            .valueOrNull
            ?.profileImage,
        uploadedUrl,
      );

      // read FutureProvider(preview·게이지 소비 경로)도 반영.
      final after = await container.read(currentTeacherProfileProvider.future);
      expect(
        after?.profileImage,
        uploadedUrl,
        reason:
            'updateBasicInfoAll 은 사진(effective ref)을 엔티티에 저장하고 '
            'read provider 에 반영해야 한다',
      );
    },
  );
}
