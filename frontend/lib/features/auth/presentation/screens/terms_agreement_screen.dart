import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';

/// Terms agreement screen shown after OAuth login for new users.
/// Required by Korean privacy law before role selection.
class TermsAgreementScreen extends ConsumerStatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  ConsumerState<TermsAgreementScreen> createState() =>
      _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends ConsumerState<TermsAgreementScreen> {
  bool _termsOfService = false;
  bool _privacyPolicy = false;
  bool _marketingConsent = false;

  bool get _allRequired => _termsOfService && _privacyPolicy;

  bool get _allChecked =>
      _termsOfService && _privacyPolicy && _marketingConsent;

  void _toggleAll(bool? value) {
    setState(() {
      _termsOfService = value ?? false;
      _privacyPolicy = value ?? false;
      _marketingConsent = value ?? false;
    });
  }

  void _onContinue() {
    ref.read(authNotifierProvider.notifier).acceptTerms();
    context.go(AppRoutes.roleSelect);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space8),

              // Title
              Text(
                '서비스 이용 동의',
                style: AppTypography.headingLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                '원활한 서비스 이용을 위해\n아래 약관에 동의해 주세요.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),

              const SizedBox(height: AppSpacing.space8),

              // Select all
              _buildSelectAllItem(),

              const Divider(height: 32),

              // Individual items
              _buildTermItem(
                required: true,
                label: '서비스 이용약관 동의',
                value: _termsOfService,
                onChanged: (v) => setState(() => _termsOfService = v ?? false),
                onViewContent:
                    () => _showTermsContent(
                      context,
                      '서비스 이용약관',
                      _termsOfServiceContent,
                    ),
              ),
              const SizedBox(height: AppSpacing.space3),
              _buildTermItem(
                required: true,
                label: '개인정보 수집·이용 동의',
                value: _privacyPolicy,
                onChanged: (v) => setState(() => _privacyPolicy = v ?? false),
                onViewContent:
                    () => _showTermsContent(
                      context,
                      '개인정보 수집·이용 동의',
                      _privacyPolicyContent,
                    ),
              ),
              const SizedBox(height: AppSpacing.space3),
              _buildTermItem(
                required: false,
                label: '마케팅 정보 수신 동의',
                value: _marketingConsent,
                onChanged:
                    (v) => setState(() => _marketingConsent = v ?? false),
                onViewContent:
                    () => _showTermsContent(
                      context,
                      '마케팅 정보 수신 동의',
                      _marketingConsentContent,
                    ),
              ),

              const Spacer(),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _allRequired ? _onContinue : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMedium,
                      ),
                    ),
                  ),
                  child: Text(
                    '계속',
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectAllItem() {
    return InkWell(
      onTap: () => _toggleAll(!_allChecked),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color:
                _allChecked
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: _allChecked,
              onChanged: _toggleAll,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              '전체 동의',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermItem({
    required bool required,
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onViewContent,
  }) {
    final tag = required ? '[필수]' : '[선택]';
    final tagColor = required ? AppColors.error : AppColors.textTertiaryLight;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space1,
          vertical: AppSpacing.space2,
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              tag,
              style: AppTypography.bodySmall.copyWith(
                color: tagColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.space1),
            Expanded(child: Text(label, style: AppTypography.bodyMedium)),
            GestureDetector(
              onTap: onViewContent,
              child: Text(
                '보기',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiaryLight,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsContent(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Text(title, style: AppTypography.headingMedium),
                ),
                const Divider(height: 1),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    child: Text(
                      content,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Placeholder terms content
const _termsOfServiceContent = '''
제1조 (목적)
이 약관은 Lessonaza(이하 "회사")가 제공하는 음악 레슨 관리 서비스(이하 "서비스")의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (용어의 정의)
1. "서비스"란 회사가 제공하는 음악 레슨 관리, 학생 관리, 연습 관리, 수강료 관리 등 일체의 서비스를 의미합니다.
2. "이용자"란 이 약관에 따라 회사가 제공하는 서비스를 이용하는 회원을 말합니다.
3. "선생님"이란 음악 레슨을 제공하는 이용자를 말합니다.
4. "학생"이란 음악 레슨을 수강하는 이용자를 말합니다.
5. "학부모"란 학생의 보호자로서 서비스를 이용하는 이용자를 말합니다.

제3조 (약관의 효력 및 변경)
1. 이 약관은 서비스를 이용하고자 하는 모든 이용자에게 적용됩니다.
2. 회사는 필요한 경우 관련 법령을 위배하지 않는 범위 내에서 이 약관을 변경할 수 있습니다.

제4조 (서비스의 제공)
회사는 다음과 같은 서비스를 제공합니다:
1. 레슨 일정 관리
2. 학생 관리
3. 연습 관리 (녹음, 메트로놈, 튜너 등)
4. 수강료 및 결제 관리
5. 기타 회사가 추가 개발하거나 제휴를 통해 제공하는 서비스

제5조 (서비스 이용 제한)
회사는 다음 각 호에 해당하는 경우 서비스 이용을 제한할 수 있습니다:
1. 타인의 개인정보를 도용한 경우
2. 서비스 운영을 방해한 경우
3. 관련 법령을 위반한 경우
''';

const _privacyPolicyContent = '''
Lessonaza(이하 "회사")는 개인정보보호법에 따라 이용자의 개인정보를 보호하고 이와 관련한 고충을 신속하고 원활하게 처리하기 위하여 다음과 같이 개인정보 처리방침을 수립·공개합니다.

1. 수집하는 개인정보 항목
[필수] 이메일 주소, 이름, 프로필 이미지 (소셜 로그인 제공 정보)
[선택] 전화번호, 악기 종류, 레슨 정보

2. 개인정보의 수집 및 이용 목적
- 회원 가입 및 관리: 회원 식별, 본인 확인, 서비스 부정 이용 방지
- 서비스 제공: 레슨 관리, 학생 관리, 연습 관리, 수강료 관리
- 서비스 개선: 서비스 이용 통계, 서비스 개선 및 신규 서비스 개발

3. 개인정보의 보유 및 이용 기간
회원 탈퇴 시까지 보유하며, 탈퇴 후 지체 없이 파기합니다.
단, 관련 법령에 의한 보존 의무가 있는 경우 해당 기간 동안 보존합니다.

4. 개인정보의 제3자 제공
회사는 이용자의 개인정보를 원칙적으로 제3자에게 제공하지 않습니다.
다만, 이용자의 동의가 있거나 법률의 규정에 의한 경우에는 예외로 합니다.

5. 개인정보의 파기
회사는 개인정보 보유 기간의 경과, 처리 목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체 없이 해당 개인정보를 파기합니다.
''';

const _marketingConsentContent = '''
Lessonaza의 마케팅 정보 수신에 동의하시면 다음과 같은 정보를 받으실 수 있습니다:

1. 수신 정보
- 새로운 기능 및 서비스 안내
- 이벤트 및 프로모션 정보
- 레슨 관리 팁 및 교육 콘텐츠

2. 수신 방법
- 앱 내 푸시 알림
- 이메일

3. 동의 철회
마케팅 정보 수신 동의는 언제든지 앱 설정에서 철회하실 수 있습니다.

※ 본 동의는 선택 사항이며, 동의하지 않아도 서비스 이용에 제한은 없습니다.
''';
