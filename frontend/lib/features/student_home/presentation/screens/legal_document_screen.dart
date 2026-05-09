// Legal document viewer screen for terms of service and privacy policy.

import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';

/// Reusable legal document viewer screen.
class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(title: title),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version info
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.paperDark,
                border: Border.all(color: AppColors.inkQuaternary),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.ink),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      '버전 1.0 | 시행일: 추후 공지',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.space5),

            // Document content
            Text(
              content,
              style: AppTypography.bodyMedium.copyWith(
                height: 1.8,
                color: AppColors.ink,
              ),
            ),

            const SizedBox(height: AppSpacing.space8),
          ],
        ),
      ),
    );
  }
}

/// Terms of service content.
const termsOfServiceContent = '''제1장 총칙

제1조 (목적)
이 약관은 주식회사 Lessonaza(이하 "회사")가 제공하는 음악 레슨 관리 서비스 "Lessonaza"(이하 "서비스")의 이용과 관련하여 회사와 회원 간의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.

제2조 (용어의 정의)
이 약관에서 사용하는 용어의 정의는 다음과 같습니다.

1. "서비스"란 회사가 제공하는 음악 레슨 관리, 연습 관리, 수강권 관리 등 일체의 서비스를 말합니다.
2. "회원"이란 서비스에 접속하여 이 약관에 따라 회사와 이용계약을 체결하고 서비스를 이용하는 자를 말합니다.
3. "개인회원"이란 학원에 소속되지 않고 개인 자격으로 서비스를 이용하는 회원을 말합니다.
   - 선생님 회원: 레슨을 제공하는 개인 음악 선생님
   - 학생 회원: 레슨을 받는 학생
   - 학부모 회원: 학생의 학부모
4. "수강권"이란 학생이 레슨을 받을 수 있는 권리를 말하며, 체험권, 월정액, 패키지(N회권) 등의 유형이 있습니다.
5. "콘텐츠"란 회원이 서비스 내에서 작성하는 레슨 기록, 학생 메모, 레퍼토리, 녹음 파일 등 일체의 정보를 말합니다.

제3조 (약관의 효력 및 변경)
1. 이 약관은 서비스 화면에 게시하거나 기타의 방법으로 회원에게 공지함으로써 효력이 발생합니다.
2. 회사는 필요하다고 인정되는 경우 이 약관을 변경할 수 있으며, 변경된 약관은 제1항과 같은 방법으로 공지함으로써 효력이 발생합니다.
3. 회원이 변경된 약관에 동의하지 않는 경우 회원탈퇴를 요청할 수 있습니다.


제2장 서비스 이용계약

제5조 (이용계약의 성립)
이용계약은 회원이 되고자 하는 자가 약관의 내용에 대하여 동의를 한 다음 회원가입신청을 하고, 회사가 이를 승낙함으로써 체결됩니다.

제6조 (회원가입)
1. 가입신청자는 회사가 정한 가입양식에 따라 회원정보를 기입한 후 이 약관에 동의한다는 의사표시를 함으로써 회원가입을 신청합니다.
2. 회사는 허위 정보 기재, 타인 명의 이용 등의 경우 승낙을 하지 않을 수 있습니다.

제8조 (회원 탈퇴 및 자격 상실)
1. 회원은 회사에 언제든지 탈퇴를 요청할 수 있으며, 회사는 즉시 회원탈퇴를 처리합니다.
2. 탈퇴 시 미사용 수강권은 환불 규정에 따라 처리됩니다.


제3장 서비스 이용

제9조 (서비스의 제공)
회사는 다음과 같은 서비스를 제공합니다.
- 레슨 일정 관리 서비스
- 레슨 기록 및 학생 관리 서비스
- 연습 관리 및 기록 서비스 (메트로놈, 튜너, 녹음 등)
- 수강권 발행 및 관리 서비스
- 학부모 연동 서비스

제11조 (결제 및 수강권)
1. 회사는 결제 대행 서비스를 제공하지 않습니다.
2. 수강료 결제는 선생님과 학생/학부모 간에 직접 이루어집니다.
3. 수강권의 가격, 유효기간, 환불 정책 등은 선생님이 자율적으로 설정합니다.


제4장 콘텐츠 및 저작권

제15조 (콘텐츠의 소유권)
회원이 서비스 내에서 작성한 레슨 기록, 학생 메모, 레퍼토리 등의 콘텐츠는 해당 회원에게 귀속됩니다.

제17조 (콘텐츠의 보존)
회원이 탈퇴하는 경우에도 작성된 콘텐츠는 회원 본인의 요청이 있는 경우 삭제 처리됩니다.


제5장 손해배상 및 면책

제23조 (손해배상)
회사는 무료로 제공하는 서비스 이용과 관련하여 회원에게 발생한 손해에 대해 책임을 지지 않습니다. 다만, 회사의 고의 또는 중과실로 인한 경우는 제외합니다.

제25조 (관할법원)
서비스 이용과 관련하여 분쟁이 발생한 경우, 민사소송법상의 관할법원에 소를 제기할 수 있습니다.

제26조 (준거법)
이 약관의 해석 및 서비스 이용에 관하여는 대한민국 법률을 적용합니다.


부칙
이 약관은 추후 공지되는 날부터 시행합니다.''';

/// Privacy policy content.
const privacyPolicyContent =
    '''주식회사 Lessonaza(이하 "회사")는 「개인정보보호법」 제30조에 따라 정보주체의 개인정보를 보호하고 이와 관련한 고충을 신속하고 원활하게 처리할 수 있도록 하기 위하여 다음과 같이 개인정보 처리방침을 수립·공개합니다.


제1조 (개인정보의 처리 목적)
회사는 다음의 목적을 위하여 개인정보를 처리합니다.

1. 회원 가입 및 관리
   - 회원 가입의사 확인, 본인 식별·인증, 회원자격 유지·관리

2. 서비스 제공
   - 레슨 일정 관리, 레슨 기록 및 학생 관리, 연습 관리 및 기록, 수강권 발행 및 관리, 학부모 연동 서비스

3. 서비스 개선
   - 서비스 이용 통계 분석, 서비스 품질 향상


제2조 (수집하는 개인정보 항목)

1. 필수 항목
   - 이름, 이메일 주소, 비밀번호, 사용자 역할(선생님/학생/학부모)

2. 선택 항목
   - 전화번호, 프로필 사진, 악기 종류

3. 자동 수집 항목
   - 기기 정보(OS 버전, 기기 모델), 앱 버전, 접속 일시


제3조 (개인정보의 처리 및 보유 기간)

1. 회원 정보: 회원 탈퇴 시까지 (탈퇴 후 30일 이내 파기)
2. 레슨/연습 기록: 회원 탈퇴 시까지
3. 결제 관련 기록: 5년 (전자상거래법)
4. 소비자 불만/분쟁 기록: 3년 (전자상거래법)
5. 접속 기록: 최소 6개월 (개인정보보호법)


제4조 (개인정보의 제3자 제공)

회사는 원칙적으로 회원의 개인정보를 제3자에게 제공하지 않습니다. 다만, 다음의 경우에는 예외로 합니다.

1. 회원이 사전에 동의한 경우
2. 법령의 규정에 의거하거나, 수사 목적으로 법령에 정해진 절차와 방법에 따라 수사기관의 요구가 있는 경우


제5조 (개인정보 처리의 위탁)

회사는 서비스 제공을 위해 다음과 같이 개인정보 처리를 위탁합니다.

- 클라우드 서비스: 데이터 저장 및 관리
- 푸시 알림 서비스: 알림 발송 (준비 중)


제6조 (정보주체의 권리·의무 및 행사방법)

회원은 다음과 같은 권리를 행사할 수 있습니다.

1. 개인정보 열람 요구
2. 오류 등이 있을 경우 정정 요구
3. 삭제 요구
4. 처리정지 요구

권리 행사는 앱 내 설정 또는 이메일을 통해 할 수 있습니다.


제7조 (개인정보의 파기)

1. 파기 절차: 보유기간이 경과한 개인정보는 지체없이 파기합니다.
2. 파기 방법
   - 전자적 파일: 복구 불가능한 방법으로 삭제
   - 종이 문서: 분쇄기로 파쇄 또는 소각


제8조 (개인정보의 안전성 확보조치)

회사는 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고 있습니다.

1. 개인정보의 암호화
2. 해킹 등에 대비한 기술적 대책
3. 개인정보 접근 제한
4. 접속기록의 보관 및 위변조 방지


제9조 (개인정보 보호책임자)

회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.

- 개인정보 보호책임자: (추후 지정)
- 연락처: (추후 공개)


제10조 (권익침해 구제방법)

개인정보 침해로 인한 구제를 받기 위하여 다음 기관에 분쟁해결이나 상담 등을 신청할 수 있습니다.

- 개인정보분쟁조정위원회: 1833-6972
- 개인정보침해신고센터: 118
- 대검찰청 사이버수사과: 1301
- 경찰청 사이버안전국: 182


제11조 (개인정보 처리방침 변경)

이 개인정보 처리방침은 추후 공지되는 날부터 적용됩니다.
변경 사항은 시행 7일 전부터 앱 내 공지를 통해 안내합니다.''';
