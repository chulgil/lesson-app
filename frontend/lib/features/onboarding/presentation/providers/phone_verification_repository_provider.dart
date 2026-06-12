import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/repositories/remote_phone_verification_repository.dart';
import '../../domain/repositories/phone_verification_repository.dart';

part 'phone_verification_repository_provider.g.dart';

/// Phone verification repository provider — #709.
///
/// 항상 remote 구현을 반환한다. mock 모드(mockDataModeProvider)에서는
/// 호출자(TeacherOnboardingNotifier)가 이 repo 를 호출하지 않고 기존
/// 로컬 시뮬레이션 동작을 유지한다 — 개발 편의.
@Riverpod(keepAlive: true)
PhoneVerificationRepository phoneVerificationRepository(
  PhoneVerificationRepositoryRef ref,
) => RemotePhoneVerificationRepository(ref.read(apiClientProvider));
