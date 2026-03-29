/// Centralized UI strings for the app.
///
/// All user-facing text should reference this class instead of hardcoding.
/// This serves as the foundation for future i18n/l10n support.
///
/// Usage:
///   Text(AppStrings.lessonRequest)
///   showSuccessSnackBar(context, AppStrings.requestAccepted)
class AppStrings {
  AppStrings._();

  // ── Core Actions ──────────────────────────────────────────

  /// 학생 → 선생님 요청 행위
  static const lessonRequest = '레슨 요청';

  /// 선생님이 시간을 수락하는 행위
  static const accept = '수락';

  /// 선생님이 레슨을 거부하는 행위 (부드러운 톤)
  static const unavailable = '다음에';

  /// 선생님이 스케줄을 비교하여 시간을 제안하는 행위
  static const counterPropose = '일정 비교';

  /// 입금 확인
  static const paymentConfirm = '입금 확인';

  /// 수강권
  static const subscription = '수강권';

  // ── Screen Titles ─────────────────────────────────────────

  /// 레슨 요청 목록 화면 제목
  static const lessonRequestTitle = '레슨 요청';

  /// 레슨 요청 폼 화면 제목 (학생 측)
  static const lessonRequestFormTitle = '레슨 요청';

  /// 레슨 요청 완료 화면 제목
  static const requestCompleteTitle = '레슨 요청 완료';

  /// 레슨 요청 완료 헤더
  static const requestCompleteHeader = '레슨 요청 완료!';

  // ── Snackbar / Feedback Messages ──────────────────────────

  /// 수락 성공
  static const requestAccepted = '레슨 요청을 수락했습니다';

  /// 다음에 처리 완료
  static const requestUnavailable = '안내를 전달했습니다';

  /// 체험레슨(무료) 예약 완료
  static const trialComplete = '체험레슨 예약이 완료되었습니다';

  /// 체험레슨(유료) 입금 요청 발송
  static const trialPaymentRequested = '학생에게 입금 요청을 보냈습니다';

  /// 수락 처리 중 오류
  static const acceptError = '수락 처리 중 오류가 발생했습니다';

  /// 역제안 전송 중 오류
  static const counterProposeError = '역제안 전송 중 오류가 발생했습니다';

  /// 레슨 요청 로드 실패
  static const requestLoadError = '레슨 요청을 불러올 수 없습니다';

  // ── Button Labels ─────────────────────────────────────────

  /// 요청 제출 버튼
  static const submitRequest = '레슨 요청하기';

  /// 요청 제출 중 버튼
  static const submittingRequest = '요청 중...';

  /// 메시지만 전달 (레슨 불가 시)
  static const messageOnly = '메시지만 전달';

  // ── Info Sections (Read-only, Naver benchmark) ─────────────

  /// 예상 레슨 시간 라벨
  static const estimatedDuration = '예상 레슨 시간';

  /// 취소/변경 정책 안내
  static const cancellationPolicy = '레슨 24시간 전까지 변경 가능합니다';

  // ── Request Detail Screen ──────────────────────────────────

  /// 레슨 요청 상세 화면 제목
  static const requestDetailTitle = '레슨 요청 상세';

  /// 요청을 불러올 수 없음
  static const requestNotFound = '요청을 찾을 수 없습니다';

  /// 수정 버튼
  static const modify = '수정';

  /// 취소 버튼
  static const cancel = '취소';

  /// 취소 확인 제목
  static const cancelRequestTitle = '요청 취소';

  /// 취소 확인 메시지
  static const cancelRequestMessage = '이 레슨 요청을 취소하시겠습니까?';

  /// 취소하기 버튼
  static const cancelRequestAction = '취소하기';

  /// 아니요 버튼
  static const no = '아니요';

  /// 상대방 시간 제안 알림
  static String opponentProposed(String name) =>
      '$name님이 시간을 제안했습니다';

  /// 상대방 응답 대기
  static String waitingForResponse(String name) =>
      '$name님의 응답을 기다리고 있습니다';

  /// 히스토리 없음
  static const noHistory = '아직 히스토리가 없습니다';

  /// 선생님 (역할명)
  static const teacher = '선생님';

  /// 학생 (역할명)
  static const student = '학생';

  /// 개인 (학원 아님)
  static const individual = '개인';

  /// 개인레슨
  static const individualLesson = '개인레슨';

  /// 학원
  static const academy = '학원';

  /// 재수강
  static const returning = '재수강';

  /// 요청 더보기
  static String moreRequests(int count) => '$count개 요청 더보기';

  // ── Request List Item (Redesign) ──────────────────────────

  /// 희망 시간 외 N건
  static String slotsRemaining(int count) => '외 $count건';

  /// 시간 미지정
  static const noTimeSpecified = '시간 미지정';

  /// 레슨 N회
  static String lessonCount(int count) => '레슨 $count회';

  /// 연습 주N회
  static String practiceRate(int rate) => '연습 주$rate회';

  /// 학원 경유
  static String viaAcademy(String name) => '$name 경유';

  /// 학생 희망 일정
  static const studentPreferredSlots = '학생 희망 일정';

  /// 이 일정으로 확정
  static const confirmThisSchedule = '이 일정으로 확정';

  /// 일정이 확정되었습니다
  static const scheduleConfirmed = '일정이 확정되었습니다';

  /// 레슨을 요청했습니다 (접미사)
  static const lessonRequestSuffix = '레슨을 요청했습니다';

  /// 종료됨 (terminal 상태 하단바)
  static const requestClosed = '종료됨';

  // ── Schedule Comparison & Actions ─────────────────────────

  /// 결정 변경
  static const withdrawApproval = '결정 변경';

  /// 결정 변경 확인 메시지
  static const withdrawApprovalMessage =
      '수락한 결정을 취소하고 다시 선택할 수 있습니다.\n히스토리는 그대로 유지됩니다.';

  /// 이전 상태로 돌아갔습니다
  static const withdrawApprovalSuccess = '이전 상태로 돌아갔습니다. 다시 선택해주세요.';

  /// 대안 시간 제안 성공
  static const alternativeProposeSent = '대안 시간과 함께 안내가 전달되었습니다';

  /// 요청 수정 준비 중
  static const modifyRequestPreparing = '요청 수정 기능은 준비 중입니다';

  /// 거절하기
  static const rejectAction = '거절하기';

  /// 시간을 선택하세요
  static const selectTimePrompt = '시간을 선택하세요';

  /// 제안하기 (N개)
  static String proposeAction(int count) => '제안하기 ($count개)';

  /// 최대 3개까지 선택 가능
  static const maxSlotsReached = '최대 3개까지 선택할 수 있습니다';

  /// 이미 수업이 있는 시간
  static const slotConflict = '이미 수업이 있는 시간입니다';

  /// 제안 시간 (N/3)
  static String suggestedSlotsCount(int count) => '제안 시간 ($count/3)';

  /// 불러오기 실패
  static const loadFailed = '불러오기 실패';

  /// 희망 (그리드 표시용)
  static const preferredSlotLabel = '희망';

  /// 레슨 (학생 비공개 표시)
  static const lessonPrivateLabel = '레슨';

  /// 날짜 선택
  static const selectDate = '날짜 선택';

  /// 시작 시간
  static const selectStartTime = '시작 시간';

  /// 확인
  static const confirm = '확인';

  /// 레슨 요청 (학생 프로필 메뉴)
  static const lessonRequestMenu = '레슨 요청';

  // ── Filter Labels ─────────────────────────────────────────

  /// 시간순
  static const sortByTime = '시간순';

  /// 이름순
  static const sortByName = '이름순';

  /// 전체 상태
  static const allStatus = '전체 상태';

  /// 진행 중
  static const statusActive = '진행 중';

  /// 취소/만료
  static const statusCancelledExpired = '취소/만료';

  /// 기간
  static const period = '기간';

  /// 전체
  static const all = '전체';

  // ── Request List Item Status ──────────────────────────────

  /// 완료
  static const statusCompleted = '완료';

  /// 입금완료
  static const statusPaymentDone = '입금완료';

  /// 만료
  static const statusExpired = '만료';

  // ── Profile Menu ──────────────────────────────────────────

  /// 레슨 요청 관리 메뉴
  static const lessonRequestManagement = '레슨 요청 관리';

  /// 레슨 요청 관리 설명
  static const lessonRequestManagementDesc = '받은 레슨 요청 확인 및 관리';

  // ── Decline Bottom Sheet ───────────────────────────────────

  /// 바텀시트 제목
  static const declineBottomSheetTitle = '이 시간에 레슨이 어렵습니다';

  /// 메시지 입력 힌트
  static const messageHint = '학생에게 전달할 메시지';

  /// 거절 시 디폴트 메시지
  static const declineDefaultMessage =
      '현재 가능한 시간이 없어 이번에는 어렵습니다.';

  /// 대안 제안 시 디폴트 메시지
  static const proposeDefaultMessage = '다른 시간을 제안드립니다.';

  // ── Reject Bottom Sheet (from schedule comparison) ─────────

  /// 거절 바텀시트 제목
  static const rejectBottomSheetTitle = '거절 메시지';

  /// 거절 바텀시트 안내
  static const rejectBottomSheetGuide = '학생에게 전달할 거절 메시지를 입력해주세요.';

  /// 거절 바텀시트 전송 버튼
  static const rejectSendAndClose = '메시지를 보낸 후 종료합니다';

  // ── Urgent Actions (Dashboard) ────────────────────────────

  /// 대기 중인 레슨 요청
  static String lessonRequestPending(int count) =>
      '레슨 요청 ${count}건 대기';

  /// 대기 중인 입금 확인
  static String paymentConfirmPending(int count) =>
      '입금 확인 ${count}건 대기';
}
