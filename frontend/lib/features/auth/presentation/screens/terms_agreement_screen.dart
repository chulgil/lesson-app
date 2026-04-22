import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/pencil_primitives.dart';
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
      backgroundColor: AppColors.paperDark,
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
                  color: AppColors.inkSecondary,
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
                    backgroundColor: AppColors.paperAccent,
                    disabledBackgroundColor: AppColors.paperAccent.withValues(
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
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color:
                _allChecked
                    ? AppColors.paperAccent.withValues(alpha: 0.5)
                    : AppColors.inkQuaternary,
          ),
        ),
        child: Row(
          children: [
            // Notebook × Score: Material Checkbox 대신 연필 사각 체크박스.
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space1),
              child: PencilBox(checked: _allChecked, size: 20),
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
    final tagColor = required ? AppColors.paperAccent : AppColors.inkTertiary;

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
            // Notebook × Score: Material Checkbox 대신 연필 사각 체크박스.
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space1),
              child: PencilBox(checked: value, size: 18),
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
                  color: AppColors.inkTertiary,
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
                const BottomSheetHandle(),
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
                        color: AppColors.inkSecondary,
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

const _termsOfServiceContent = '''
제1조 (목적)
이 약관은 Lessonaza(이하 "회사")가 제공하는 음악 레슨 관리 서비스(이하 "서비스")의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (용어의 정의)
1. "서비스"란 회사가 제공하는 음악 레슨 관리, 학생 관리, 연습 관리, 수강료 관리 등 일체의 서비스를 의미합니다.
2. "이용자"란 이 약관에 따라 회사가 제공하는 서비스를 이용하는 회원을 말합니다.
3. "선생님"이란 음악 레슨을 제공하는 이용자를 말합니다.
4. "학생"이란 음악 레슨을 수강하는 이용자를 말합니다.
5. "학부모"란 학생의 보호자로서 서비스를 이용하는 이용자를 말합니다.
6. "학원"이란 대표 회원이 서비스 내에서 개설한 음악 학원 또는 레슨 스튜디오를 말합니다.
7. "수강권"이란 학생이 레슨을 받을 수 있는 권리를 말하며, 체험권, 월정액, 패키지(N회권) 등의 유형이 있습니다.
8. "콘텐츠"란 회원이 서비스 내에서 작성하는 레슨 기록, 학생 메모, 레퍼토리, 녹음 파일 등 일체의 정보를 말합니다.

제3조 (약관의 효력 및 변경)
1. 이 약관은 서비스를 이용하고자 하는 모든 이용자에게 적용됩니다.
2. 회사는 필요한 경우 관련 법령을 위배하지 않는 범위 내에서 이 약관을 변경할 수 있습니다.
3. 변경된 약관은 적용일 7일 전(불리한 변경은 30일 전)부터 공지됩니다.

제4조 (서비스의 제공)
회사는 다음과 같은 서비스를 제공합니다:
1. 레슨 일정 관리
2. 학생 및 레슨 기록 관리
3. 연습 관리 (녹음, 메트로놈, 튜너 등)
4. 수강권 및 결제 기록 관리
5. 학부모 연동
6. 기타 회사가 추가 개발하거나 제휴를 통해 제공하는 서비스

제5조 (이용계약의 성립)
이용계약은 가입신청자가 약관에 동의하고 회원가입을 신청하며, 회사가 이를 승낙함으로써 체결됩니다.

제6조 (서비스 이용 제한)
회사는 다음에 해당하는 경우 서비스 이용을 제한할 수 있습니다:
1. 타인의 개인정보를 도용한 경우
2. 서비스 운영을 방해한 경우
3. 관련 법령을 위반한 경우

제7조 (결제 및 수강권)
1. 회사는 결제 대행 서비스를 제공하지 않습니다. 수강료 결제는 선생님과 학생/학부모 간에 직접 이루어집니다.
2. 서비스는 수강권 판매 기록, 결제 확인 기록, 사용 기록을 관리하는 기능만 제공합니다.

제8조 (회원 탈퇴)
1. 회원은 언제든지 탈퇴를 요청할 수 있으며, 회사는 즉시 처리합니다.
2. 탈퇴 시 미사용 수강권은 환불 규정에 따라 처리됩니다.

제9조 (콘텐츠 소유권)
1. 개인회원이 작성한 콘텐츠는 해당 회원에게 귀속됩니다.
2. 학원 모드에서 강사가 작성한 콘텐츠는 학원과 작성자가 공동으로 권리를 보유합니다.

제10조 (면책)
1. 회사는 무료 서비스 이용으로 발생한 손해에 대해 책임지지 않습니다 (고의/중과실 제외).
2. 선생님/학원과 학생/학부모 간 수강료 분쟁에 대해 회사는 책임지지 않습니다.

제11조 (관할법원 및 준거법)
이 약관의 해석 및 서비스 이용에 관하여는 대한민국 법률을 적용합니다.

부칙
이 약관은 2026년 4월 1일부터 시행합니다.
''';

const _privacyPolicyContent = '''
Lessonaza(이하 "회사")는 개인정보보호법에 따라 이용자의 개인정보를 보호하고 이와 관련한 고충을 신속하고 원활하게 처리하기 위하여 다음과 같이 개인정보 처리방침을 수립·공개합니다.

1. 수집하는 개인정보 항목
[필수] 이메일 주소, 이름, 프로필 이미지 (소셜 로그인 제공 정보)
[선택] 전화번호, 악기 종류, 레슨 정보

2. 개인정보의 수집 및 이용 목적
- 회원 가입 및 관리: 회원 식별, 본인 확인, 서비스 부정 이용 방지
- 서비스 제공: 레슨 관리, 학생 관리, 연습 관리, 수강료 관리
- 알림 서비스: 레슨 일정, 연습 리마인더, 수강권 알림
- 서비스 개선: 서비스 이용 통계, 서비스 개선 및 신규 서비스 개발

3. 개인정보의 보유 및 이용 기간
회원 탈퇴 시까지 보유하며, 탈퇴 후 30일 이내에 파기합니다.
단, 관련 법령에 의한 보존 의무가 있는 경우 다음 기간 동안 보존합니다:
- 계약 또는 청약철회에 관한 기록: 5년 (전자상거래법)
- 대금결제 및 재화 공급에 관한 기록: 5년 (전자상거래법)
- 소비자 불만/분쟁 처리 기록: 3년 (전자상거래법)
- 접속 기록: 최소 6개월 (개인정보보호법)

4. 개인정보의 제3자 제공
회사는 이용자의 개인정보를 원칙적으로 제3자에게 제공하지 않습니다.
다만, 이용자의 동의가 있거나 법률의 규정에 의한 경우에는 예외로 합니다.

5. 개인정보의 파기
회사는 개인정보 보유 기간의 경과, 처리 목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체 없이 해당 개인정보를 파기합니다.

6. 이용자의 권리
이용자는 언제든지 개인정보의 열람, 정정, 삭제, 처리정지를 요청할 수 있습니다.

7. 개인정보 보호 책임자
- 이름: 이철길
- 연락처: support@lessonaza.com
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
