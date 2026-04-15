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
  static const requestUnavailable = '레슨 불가 안내를 전달했습니다';

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
  static String opponentProposed(String name) => '$name님이 시간을 제안했습니다';

  /// 상대방 응답 대기
  static String waitingForResponse(String name) => '$name님의 응답을 기다리고 있습니다';

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

  /// 수강권 더보기
  static String moreSubscriptions(int count) => '$count개 수강권 더보기';

  /// 전체보기
  static const viewAll = '전체보기';

  /// 소진임박
  static const statusExpiringSoon = '소진임박';

  /// 발급 수강권 (선생님 전체 목록 제목)
  static const issuedSubscriptions = '발급 수강권';

  /// 수강권 요약: 이용중
  static const summaryActive = '이용중';

  /// 수강권 요약: 대기중 요청
  static const pendingRequests = '대기중 요청';

  /// 해당 상태의 수강권이 없습니다
  static String noSubscriptionsForStatus(String status) => '$status 수강권이 없습니다';

  // ── Request List Item (Redesign) ──────────────────────────

  /// 희망 시간 외 N건
  static String slotsRemaining(int count) => '외 $count건';

  /// 오전
  static const timeAM = '오전';

  /// 오후
  static const timePM = '오후';

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
  static const requestClosed = '요청이 종료되었습니다';

  /// 슬롯 선택 힌트
  static const slotSelectionHint = '일정을 탭하여 선택하세요';

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

  /// 필터 칩: 개인 (짧은 라벨)
  static const filterIndividual = '개인';

  /// 필터 칩: 진행중 (짧은 라벨)
  static const filterActive = '진행중';

  /// 기간 프리셋: 1주
  static const periodOneWeek = '1주';

  /// 기간 프리셋: 1달
  static const periodOneMonth = '1달';

  /// 기간 프리셋: 3달
  static const periodThreeMonths = '3달';

  /// 기간 프리셋 라벨: 최근 1주
  static const recentOneWeek = '최근 1주';

  /// 기간 프리셋 라벨: 최근 1달
  static const recentOneMonth = '최근 1달';

  /// 기간 프리셋 라벨: 최근 3달
  static const recentThreeMonths = '최근 3달';

  /// 기간 프리셋 라벨: 사용자 지정
  static const periodCustom = '사용자 지정';

  // ── Request List Item Status ──────────────────────────────

  /// 완료
  static const statusCompleted = '완료';

  /// 입금완료
  static const statusPaymentDone = '입금완료';

  /// 만료
  static const statusExpired = '만료';

  // ── Request Status Chip Labels ────────────────────────────

  /// 대기
  static const statusPending = '대기';

  /// 승인
  static const statusApproved = '승인';

  /// 거절
  static const statusRejected = '거절';

  /// 취소
  static const statusCancelled = '취소';

  /// 기간만료
  static const statusExpiredFull = '기간만료';

  /// 제안완료
  static const statusProposalSent = '제안완료';

  /// 수강권수락
  static const statusProposalAccepted = '수강권수락';

  // ── Teacher Action Labels ─────────────────────────────────

  /// 확인 필요
  static const actionRequired = '확인 필요';

  /// 응답 필요
  static const responseRequired = '응답 필요';

  /// 응답 대기
  static const responseWaiting = '응답 대기';

  /// 제안 작성
  static const proposalNeeded = '제안 작성';

  /// 수락 대기 (학생 수락 대기)
  static const teacherWaitingAccept = '수락 대기';

  /// 입금 대기 (학생 입금 대기)
  static const teacherWaitingPayment = '입금 대기';

  /// 입금 확인 (선생님이 입금 확인 필요)
  static const teacherVerifyPayment = '입금 확인';

  // ── Student Action Labels ────────────────────────────────

  /// 요청 전송됨
  static const studentRequestSent = '요청 전송됨';

  /// 선생님 확인 중
  static const studentWaitingTeacher = '선생님 확인 중';

  /// 응답 필요 (학생 턴)
  static const studentResponseRequired = '응답 필요';

  /// 선생님 응답 대기
  static const studentResponseWaiting = '선생님 응답 대기';

  /// 수강권 대기
  static const studentWaitingProposal = '수강권 대기';

  /// 수강권 도착
  static const studentProposalArrived = '수강권 도착';

  /// 입금 확인 중
  static const studentPaymentWaiting = '입금 확인 중';

  /// 결제 필요 (학생이 결제해야 함)
  static const studentPaymentRequired = '결제 필요';

  /// 선생님 이름 포맷
  static String teacherDisplayName(String name) => '$name 선생님';

  /// Phase 2 공지 배너
  static const timeConfirmedNotice = '수강권 발급 방법을 선택해주세요';
  static const timeConfirmedNoticeStudent = '선생님이 수강권 안내를 보내면 알림을 드립니다';

  /// 시간확정
  static const statusTimeConfirmed = '시간확정';

  /// 시간협상 N
  static String statusNegotiating(int round) => '시간협상 $round';
  static const statusNegotiatingShort = '시간조율';

  // ── Phase 2, 3 Status Labels ──────────────────────────────

  /// 수강권 발행됨
  static const statusSubscriptionIssued = '수강권 발행';

  /// 레슨 진행중
  static const statusInProgress = '레슨 진행';

  // ── Event Labels (for RequestEventType.label) ─────────────

  static const eventLessonRequest = '레슨 요청';
  static const eventApprove = '수락';
  static const eventReject = '거절';
  static const eventProposeAlternative = '다른 시간 제안';
  static const eventAcceptAlternative = '시간 수락';
  static const eventCancel = '취소';
  static const eventExpire = '기간 만료';
  static const eventProposalSent = '수강권 제안';
  static const eventProposalAccepted = '수강권 수락';
  static const eventPaymentNotified = '입금 알림';
  static const eventCompleted = '발급 완료';
  static const eventWithdrawApproval = '결정 변경';
  static const eventPaymentRequested = '결제 안내';
  static const eventPaymentConfirmed = '입금 확인';
  static const eventSubscriptionIssued = '수강권 발행';
  static const eventLessonCompleted = '레슨 완료';
  static const eventLessonCancelled = '레슨 취소';
  static const eventScheduleChanged = '스케줄 변경';
  static const eventLessonNoteAdded = '레슨 노트';
  static const eventSubscriptionRenewed = '수강권 연장';
  static const eventSubscriptionCompleted = '수강 완료';

  // ── Chat Display Messages ─────────────────────────────────

  static const chatInitialRequest = '레슨을 요청했습니다';
  static const chatApprove = '요청을 수락했습니다';
  static const chatReject = '레슨 요청을 거절했습니다';
  static const chatProposeAlternative = '다른 시간을 제안했습니다';
  static const chatAcceptAlternative = '제안한 시간을 수락했습니다';
  static const chatCancel = '요청을 취소했습니다';
  static const chatExpire = '요청이 만료되었습니다';
  static const chatProposalSent = '수강권 안내를 보냈습니다';
  static const chatProposalAccepted = '수강권을 수락했습니다';
  static const chatPaymentNotified = '입금했습니다';
  static const chatCompleted = '수강권이 발급되었습니다';
  static const chatWithdrawApproval = '결정을 변경했습니다';
  static const chatPaymentRequested = '결제 안내를 보냈습니다';
  static const chatPaymentConfirmed = '입금을 확인했습니다';
  static const chatSubscriptionIssued = '수강권이 발행되었습니다';
  static const chatLessonCompleted = '레슨이 완료되었습니다';
  static const chatLessonCancelled = '레슨이 취소되었습니다';
  static const chatScheduleChanged = '스케줄이 변경되었습니다';
  static const chatLessonNoteAdded = '레슨 노트가 추가되었습니다';
  static const chatSubscriptionRenewed = '수강권이 연장되었습니다';
  static const chatSubscriptionCompleted = '수강이 완료되었습니다';
  static const chatScheduleChangeProposed = '시간 변경을 제안했습니다';
  static const chatScheduleChangeAccepted = '시간 변경을 수락했습니다';
  static const chatScheduleChangeRejected = '시간 변경을 거절했습니다';
  static const chatScheduleChangeCountered = '다른 시간을 역제안했습니다';

  // ── Schedule Change Event Labels ─────────────────────────────
  static const eventScheduleChangeProposed = '시간 변경 제안';
  static const eventScheduleChangeAccepted = '시간 변경 수락';
  static const eventScheduleChangeRejected = '시간 변경 거절';
  static const eventScheduleChangeCountered = '시간 역제안';

  // ── Schedule Change UI ────────────────────────────────────────
  static const scheduleChangeTitle = '시간 변경';
  static const scheduleChangeTypeTitle = '어떤 변경을 원하시나요?';
  static const scheduleChangeSingleLabel = '이번 회차만';
  static const scheduleChangeSingleDesc = '이번 회차 레슨만 시간을 변경합니다';
  static const scheduleChangeBulkLabel = '앞으로 모두';
  static const scheduleChangeBulkDesc = '앞으로 모든 레슨 시간을 변경합니다';
  static const scheduleChangeSlotTitle = '변경할 시간을 선택하세요';
  static const scheduleChangeRegularTitle = '정규 시간 변경';
  static const scheduleChangeCurrentSchedule = '현재 스케줄';
  static const scheduleChangeNewSchedule = '변경할 스케줄';
  static const everyWeek = '매주';
  static const bulkChangeSlotGuide = '선택한 시간이 매주 반복되는 고정 스케줄로 적용됩니다';
  static const scheduleChangePropose = '시간 변경 제안';
  static const scheduleChangeInProgress = '시간 변경 진행 중';
  static const scheduleChangeRequestArrived = '시간 변경 요청이 도착했습니다';

  // Profile card
  static const studentMessage = '학생 메시지';
  static const scheduleChangeAccept = '수락';
  static const scheduleChangeReject = '거절';
  static const scheduleChangeCounter = '역제안';
  static const scheduleChangeConfirmed = '시간이 변경되었습니다';
  static const scheduleChangeRecommended = '추천';

  // ── Progress Bar Phase Labels ─────────────────────────────

  static const phaseRequest = '신청';
  static const phaseConfirmed = '확정';
  static const phasePayment = '결제';
  static const phaseLessons = '진행';
  static const phaseCompleted = '완료';

  // ── Phase Mini Stats (Dashboard) ──────────────────────────
  static String phaseStatLabel(String phaseName, int count) =>
      '$phaseName $count';
  static const phaseFilterAll = '전체';
  static const phaseFilterRequest = '신청';
  static const phaseFilterSubscription = '수강권';
  static const phaseFilterInProgress = '진행중';
  static const phaseFilterCompleted = '수강완료';
  static const phaseFilterTerminal = '거절/취소';

  // ── Chapter Titles ────────────────────────────────────────

  static const chapterRequest = '레슨 신청';
  static const chapterSubscription = '수강권 & 결제';
  static const chapterLessons = '레슨 진행';

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

  /// 수락 시 메시지 입력 힌트
  static const acceptMessageHint = '학생에게 전할 메시지 (선택)';

  /// 거절 시 디폴트 메시지
  static const declineDefaultMessage = '현재 가능한 시간이 없어 이번에는 어렵습니다.';

  /// 대안 제안 시 디폴트 메시지
  static const proposeDefaultMessage = '다른 시간을 제안드립니다.';

  // ── Reject Bottom Sheet (from schedule comparison) ─────────

  /// 거절 바텀시트 제목
  static const rejectBottomSheetTitle = '거절 메시지';

  /// 거절 바텀시트 안내
  static const rejectBottomSheetGuide = '학생에게 전달할 거절 메시지를 입력해주세요.';

  /// 거절 바텀시트 전송 버튼
  static const rejectSendAndClose = '메시지를 보낸 후 종료합니다';

  // ── Action Box Phase 2,3,4 ─────────────────────────────────

  /// Phase 2: 수강권 발급 방법 선택 헤더
  static const phase2SelectMethod = '수강권 발급 방법을 선택하세요';

  /// Phase 2: 선불 카드
  static const methodPrepaidTitle = '결제 후 발급 (선불)';
  static const methodPrepaidDesc = '학생에게 결제 안내를 보내고, 입금 확인 후 수강권이 발급됩니다';

  /// Phase 2: 후불 카드
  static const methodPostpaidTitle = '먼저 발급 (후불)';
  static const methodPostpaidDesc = '수강권을 바로 발급하고, 결제는 나중에 받습니다';

  /// Phase 2: 무료 카드
  static const methodFreeTitle = '무료 발급';
  static const methodFreeDesc = '결제 없이 수강권을 바로 발급합니다';

  /// Phase 2: Teacher → 결제 안내 전송 (선불)
  static const actionSendPaymentGuide = '결제 안내 보내기';

  /// Phase 2: Teacher → 후불 수강권 발급
  static const actionIssuePostpaid = '수강권 먼저 발급';

  /// Phase 2: Teacher → 무료 수강권 발급 (체험)
  static const actionIssueFree = '무료 수강권 발급';

  /// Phase 2: Student → 입금 완료 알림
  static const actionConfirmPayment = '입금 완료';

  /// Phase 2: Teacher → 입금 확인 완료
  static const actionVerifyPayment = '입금 확인';

  /// Phase 2: 시간 확정 후 안내 메시지
  static const phase2TimeConfirmedTeacher = '수강권 발급 방법을 선택해주세요';
  static const phase2TimeConfirmedTrial = '체험레슨이 확정되었습니다';
  static const phase2WaitingPaymentStudent = '결제를 완료해주세요';
  static const phase2PaymentReceivedTeacher = '학생이 입금을 완료했습니다';

  // ── Action Box Messages (Phase 2 대기 상태) ─────────────────

  /// 선생님: 학생 수강권 수락 대기
  static const actionBoxWaitingAccept = '학생의 수강권 수락을 기다리고 있습니다';

  /// 선생님: 학생 결제 대기
  static const actionBoxWaitingPayment = '학생의 결제를 기다리고 있습니다';

  /// 선생님: 수강권 발행 완료
  static const actionBoxSubscriptionReady =
      '수강권이 발행되었습니다. 레슨을 시작할 준비가 완료되었습니다.';

  /// 학생: 입금 확인 대기
  static const actionBoxWaitingVerify = '선생님의 입금 확인을 기다리고 있습니다';

  // ── Subscription Summary (Phase 3/4 chat) ──────────────────

  /// 수강권 요약 메시지
  static const subscriptionSummaryMessage = '수강권이 발행되었습니다';

  /// 수강권 상세 보기 링크
  static const subscriptionDetailLink = '상세 보기';

  /// 입금 확인 후 수강권 발급 메시지 (이벤트 기록용)
  static const paymentVerifiedMessage = '입금이 확인되어 수강권이 발급되었습니다';

  /// 결제 안내 BottomSheet
  static const paymentGuideTitle = '결제 안내 보내기';
  static const subscriptionTypeMonthly = '월정액';
  static const subscriptionTypePackage = '회차권';
  static const totalLessonsLabel = '총 회차';
  static const amountLabel = '금액';
  static const amountUnit = '원';
  static const lessonsUnit = '회';
  static const paymentMessageHint = '추가 안내 메시지 (선택)';
  static const sendPaymentGuide = '안내 보내기';

  /// Proposal BottomSheet (v8 통합)
  static const proposalTitle = '수강권 발급';
  static const proposalPaymentMethod = '결제 방법';
  static const proposalSelectTemplates = '수강권 선택 (최대 3개)';
  static const proposalBankAccount = '입금 계좌';
  static const proposalSend = '제안 보내기';
  static const proposalNoTemplates = '등록된 수강권 템플릿이 없습니다';
  static const proposalNoBankAccount = '등록된 계좌가 없습니다';

  /// Payment method chips
  static const methodPrepaidChip = '선불';
  static const methodPostpaidChip = '후불';
  static const methodFreeChip = '무료';

  /// Phase 3: Teacher → 레슨 완료
  static const actionLessonComplete = '레슨 완료';

  /// Phase 3: Teacher → 레슨 취소
  static const actionLessonCancel = '레슨 취소';

  /// Phase 3: Both → 시간 변경
  static const actionScheduleChange = '시간 변경';

  /// Phase 3: Teacher → 메모 추가
  static const actionAddNote = '메모 추가';

  /// Phase 4 (completed): Teacher → 연장 제안
  static const actionProposeRenewal = '연장 제안';

  /// Phase 4 (completed): Student → 재수강 신청
  static const actionRequestRenewal = '재수강 신청';

  /// Phase 2 waiting message
  static String waitingForPayment(String name) => '$name의 입금을 기다리고 있습니다';

  /// Phase 3 progress message
  static String lessonProgressStatus(int completed, int total) =>
      '레슨 진행 중 ($completed/$total회)';

  /// Phase 3 waiting (student)
  static const actionRequestScheduleChange = '시간 변경 요청';

  // ── Attendance Confirmation ──────────────────────────────

  static const lessonConfirmation = '레슨 확인';
  static const lessonCompleted = '레슨 완료';

  /// 레슨 완료 (버튼 라벨)
  static const lessonComplete = '레슨 완료';
  static const lessonNotCompleted = '레슨 미진행';
  static const deductOne = '수강권 1회 차감';
  static const selectReason = '사유 선택 필요';
  static const nonCompletionReason = '레슨 미진행 사유';
  static const optionalNote = '추가 메모를 입력하세요 (선택)';
  static String lessonsNeedConfirmation(int count) => '미확인 레슨 ${count}건';

  // ── Day of Week ────────────────────────────────────────

  static const mon = '월';
  static const tue = '화';
  static const wed = '수';
  static const thu = '목';
  static const fri = '금';
  static const sat = '토';
  static const sun = '일';

  // ── Chat Message Only (same-slot re-approve) ───────────────

  static const chatMessageAdded = '메시지를 추가했습니다';

  // ── Preview Conflict ───────────────────────────────────────

  static const previewConflict = '프리뷰 겹침';
  static const previewConflictConfirm = '프리뷰 겹침 — 확정';

  // ── Urgent Actions (Dashboard) ────────────────────────────

  /// 대기 중인 레슨 요청
  static String lessonRequestPending(int count) => '레슨 요청 ${count}건 대기';

  /// 대기 중인 입금 확인
  static String paymentConfirmPending(int count) => '입금 확인 ${count}건 대기';

  // ── Urgent Alert Zone (Dashboard) ──────────────────────────

  /// 만료된 수강권
  static String subscriptionExpired(int count) => '만료 수강권 ${count}건';

  /// 임박한 수강권
  static String subscriptionExpiringSoon(int count) => '수강권 임박 ${count}건';

  /// 예약 승인 대기
  static String pendingBookings(int count) => '예약 승인 대기 ${count}건';

  // ── Subscription Card ─────────────────────────────────────

  /// 변경 횟수
  static String rescheduleCount(int remaining, int total) =>
      '변경: $remaining/$total회';

  /// 변경 불가
  static const rescheduleUnavailable = '변경 불가';

  /// 변경 1회 남음 경고
  static const rescheduleLastOne = '변경 1회 남음';

  /// 변경/취소 기준시간 설정 라벨
  static const rescheduleDeadlineLabel = '변경/취소 기준시간';

  /// 변경/취소 기준시간 설명
  static const rescheduleDeadlineDescription =
      '레슨 시작 전 이 시간 이내에 변경하면 변경취소권이 소진됩니다.';

  /// 시간 단위
  static const hoursUnit = '시간';

  /// 잔여 횟수 접미사
  static const remainingCountSuffix = '회 남음';

  /// 변경취소 라벨
  static const rescheduleLabel = '변경취소';

  /// 횟수 접미사
  static const countSuffix = '회';

  /// 변경취소권 소진 안내
  static String rescheduleDeadlineWarning(int hours) =>
      '레슨 시작 $hours시간 이내 변경 시 변경취소권 1회 소진';

  /// 무료 변경 안내
  static String rescheduleDeadlineFree(int hours) =>
      '레슨 시작 $hours시간 전이므로 무료 변경';

  // === Subscription detail chapter strings ===

  /// 수강권 유형
  static const subscriptionType = '유형';

  /// 금액
  static const amount = '금액';

  /// 원
  static const wonUnit = '원';

  /// 할인
  static const discount = '할인';

  /// 시작일
  static const startDate = '시작일';

  /// 만료일
  static const endDate = '만료일';

  // === Reschedule / Cancel bottom sheet strings ===

  /// N회차 시간 변경
  static String sessionRescheduleTitle(int n) => '$n회차 시간 변경';

  /// N회차 취소
  static String sessionCancelTitle(int n) => '$n회차 취소';

  /// 변경 요청
  static const rescheduleRequest = '변경 요청';

  /// 변경 요청 (변경취소권 1회 사용)
  static const rescheduleRequestWithCredit = '변경 요청 (변경취소권 1회 사용)';

  /// 취소 요청
  static const cancelRequest = '취소 요청';

  /// 취소 사유 선택 안내
  static const cancelReasonPrompt = '취소 사유를 선택해주세요';

  /// 학생 사정 (일정 변경)
  static const cancelReasonStudentSchedule = '학생 사정 (일정 변경)';

  /// 학생 사정 (컨디션)
  static const cancelReasonStudentSick = '학생 사정 (컨디션)';

  /// 선생님 사정
  static const cancelReasonTeacher = '선생님 사정';

  /// 상호 합의
  static const cancelReasonMutual = '상호 합의';

  /// 레슨 횟수 1회 차감 경고
  static const lessonDeductWarning = '레슨 횟수 1회 차감';

  /// 보강/변경 가능 안내
  static const makeupAvailable = '보강/변경 가능 (횟수 유지)';

  /// 학생 취소 차감 안내
  static const studentCancelDeductNotice = '학생 사정으로 인한 취소는 레슨 횟수가 1회 차감됩니다.';

  /// 변경취소권 소진 안내
  static const rescheduleCreditsExhausted = '변경취소권이 모두 소진되었습니다';

  /// 잔여 변경취소권 변화 표시
  static String rescheduleCreditsChange(int from, int to) =>
      '잔여 변경취소권: $from회 → $to회';

  /// 변경할 날짜 선택
  static const selectDatePlaceholder = '변경할 날짜 선택';

  /// 변경할 시간 선택
  static const selectTimePlaceholder = '변경할 시간 선택';

  /// 현재
  static const current = '현재';

  /// 시간 변경 버튼
  static const rescheduleAction = '시간 변경';

  /// 변경 불가 버튼
  static const rescheduleDisabled = '변경 불가';

  // === Chapter titles ===

  /// 수강권 정보 챕터
  static const chapterSubscriptionInfo = '수강권 정보';

  /// 결제 내역 챕터
  static const chapterPaymentHistory = '결제 내역';

  /// 레슨 진행 챕터
  static String chapterLessonProgress(int used, int total) =>
      '레슨 진행 ($used/$total회)';

  // === Chapter payment detail strings ===

  /// 결제 상태
  static const paymentStatus = '결제 상태';

  /// 결제완료
  static const paymentCompleted = '결제완료';

  /// 미결제
  static const paymentPending = '미결제';

  /// 결제 방법
  static const paymentMethod = '결제 방법';

  /// 결제일
  static const paymentDate = '결제일';

  /// 확인일
  static const confirmationDate = '확인일';

  /// 원래 금액
  static const originalAmount = '원래 금액';

  // === Chapter lessons strings ===

  /// 아직 레슨 기록이 없습니다
  static const noLessonRecords = '아직 레슨 기록이 없습니다';

  /// N회차 완료
  static String sessionCompleted(int n, String date) => '$n회차 $date 완료';

  /// N회차 예정
  static String sessionScheduled(int n) => '$n회차 예정';

  /// N회차 미정
  static String sessionPending(int n) => '$n회차 미정';

  /// Collapsed session headers for chat layout
  static String sessionCollapsedCompleted(int n, String dateTime) =>
      '$n회차 · $dateTime 완료';
  static String sessionCollapsedScheduled(int n, String dateTime) =>
      '$n회차 · $dateTime 예정';
  static String sessionCollapsedFuture(int n) => '$n회차 · 미정';

  /// Bottom input bar
  static const subscriptionMessageHint = '학생에게 전달할 메시지를 입력하세요';
  static const subscriptionSendMessage = '메시지 전송';
  static const messageSentSuccess = '메시지를 전송했습니다';
  static const scheduleChangeButton = '일정 변경';
  static const scheduleChange = '일정 변경';
  static const viewDetail = '상세 보기';
  static const sessionUnit = '회';
  static const unregistered = '미등록';
  static const active = '수강 중';
  static const expiringSoon = '만료 예정';
  static const expired = '만료됨';

  // === Common UI strings ===

  /// 수강권 상세 AppBar 제목
  static const subscriptionDetailTitle = '수강권 상세';

  /// 수강권을 찾을 수 없습니다
  static const subscriptionNotFound = '수강권을 찾을 수 없습니다';

  /// 오류가 발생했습니다
  static const errorOccurred = '오류가 발생했습니다';

  /// 레슨 정보를 찾을 수 없습니다
  static const lessonInfoNotFound = '레슨 정보를 찾을 수 없습니다';

  /// 악기 (fallback)
  static const instrumentFallback = '악기';

  /// 사용 N회 / 전체 N회
  static String usageProgress(int used, int total) => '사용 $used회 / 전체 $total회';

  /// N회 남음
  static String remainingCount(int count) => '$count회 남음';

  /// 변경 요청 완료
  static const rescheduleRequestCompleted = '변경 요청 완료';

  /// 변경 요청 완료 (변경취소권 1회 사용)
  static const rescheduleRequestCompletedWithCredit = '변경 요청 완료 (변경취소권 1회 사용)';

  /// 취소 요청 완료 (레슨 횟수 1회 차감)
  static const cancelRequestCompletedDeducted = '취소 요청 완료 (레슨 횟수 1회 차감)';

  /// 취소 요청 완료 (횟수 유지)
  static const cancelRequestCompletedKept = '취소 요청 완료 (횟수 유지)';

  /// 잔여 횟수 경고
  static String remainingLessonsWarning(int count) => '잔여 ${count}회 - 갱신 권장';

  /// 마지막 1회 경고
  static const lastLessonWarning = '마지막 1회!';

  /// 만료 임박 D-day
  static String expirationDday(int days) => 'D-$days 만료 임박';

  /// 만료 긴급
  static String expirationUrgent(int days) => 'D-$days 곧 만료!';

  // ── Teacher Attendance ────────────────────────────────────

  /// 전체 출석률
  static const overallAttendanceRate = '전체 출석률';

  /// 학생별 출석률
  static const studentAttendanceRates = '학생별 출석률';

  /// 결석/노쇼 이력
  static const recentAbsences = '결석/노쇼 이력';

  /// 수강권 차감
  static const subscriptionDeducted = '수강권 차감';

  // ── Student Detail Tabs ──────────────────────────────────

  /// 학생 상세 - 정보 탭
  static const studentTabInfo = '정보';

  /// 학생 상세 - 레슨 탭
  static const studentTabLessons = '레슨';

  /// 학생 상세 - 연습 현황 탭
  static const studentTabPractice = '연습 현황';

  // ── Gamification: Weekly Ranking ──────────────────────────────

  /// 이번 주 연습 랭킹
  static const weeklyRanking = '이번 주 연습 랭킹';

  /// Gold 티어
  static const tierGold = 'Gold';

  /// Silver 티어
  static const tierSilver = 'Silver';

  /// Bronze 티어
  static const tierBronze = 'Bronze';

  /// 주간 포인트
  static const weeklyPoints = '주간 포인트';

  /// 주간 포인트 값 표시
  static String weeklyPointsValue(int points) => '${points}pt';

  // ── Subscription Chapter Lessons (C-3) ──────────────────────

  /// 고정 스케줄 자동 생성 안내 (정규권)
  static const monthlyGuideMessage =
      '고정 스케줄이 자동 생성되었습니다. 변경이 필요하면 해당 회차를 탭하세요.';

  /// 다음 레슨 예약 안내 (회차권)
  static const packageGuideMessage = '다음 레슨 시간을 선생님의 빈 시간대에서 선택하세요.';

  /// 변경 이력 없음
  static const noChangeHistory = '변경 이력 없음';

  /// 예약 필요
  static const bookingRequired = '예약 필요';

  /// N~M회차 (더보기)
  static String moreSessionsLabel(int from, int to) => '$from~$to회차';

  /// 더보기
  static const showMore = '더보기';

  /// 매주 dayTime
  static String fixedScheduleLabel(String dayTime) => '매주 $dayTime';

  // ── Schedule Change Type Selection (C-4) ─────────────────

  /// 이번 회차만 변경
  static const changeTypeSingleLabel = '이번 회차만 변경';

  /// N회차만 다른 시간으로
  static String changeTypeSingleDesc(int session) => '$session회차만 다른 시간으로';

  /// 앞으로 전체 변경
  static const changeTypeBulkLabel = '앞으로 전체 변경';

  /// N~M회차 새로운 고정 시간
  static String changeTypeBulkDesc(int from, int to) => '$from~$to회차 새로운 고정 시간';

  /// 전체 스케줄 변경 요청 완료
  static const bulkScheduleChangeCompleted = '전체 스케줄 변경 요청 완료';

  // ── Schedule Change Requests (C-5) ────────────────────────

  /// 변경요청 N건
  static String pendingChangeRequests(int count) => '변경요청 $count건';

  /// 스케줄 변경요청
  static const scheduleChangeRequests = '스케줄 변경요청';

  /// 변경
  static const changeTypeLabel = '변경';

  /// 취소
  static const cancelTypeLabel = '취소';

  /// 시간변경
  static const sessionChangeRequest = '시간변경';

  /// 취소요청
  static const sessionCancelRequest = '취소요청';

  /// N회차
  static String sessionNumberLabel(int n) => '$n회차';

  // ── Session Progress Bar ────────────────────────────────────

  /// 전체 일괄 변경 버튼
  static const bulkChangeAll = '전체';

  // ── Subscription Issued Card (D-4) ──────────────────────────

  /// 수강권 발급 메시지
  static const subscriptionIssuedMessage = '수강권이 발급되었습니다';

  /// 유효기간
  static const validityPeriod = '유효기간';

  /// 기준시간
  static const deadlineHoursLabel = '기준시간';

  /// 변경취소권
  static const rescheduleCreditsLabel = '변경취소권';

  // ── Schedule Change Request List (D-6) ─────────────────────

  /// 스케줄 변경요청 화면 제목
  static const scheduleChangeRequestTitle = '스케줄 변경요청';

  /// 대기중 탭
  static const tabPending = '대기중';

  /// 완료 탭
  static const tabCompleted = '완료';

  /// 전체 탭
  static const tabAll = '전체';

  /// 변경요청이 없습니다
  static const noChangeRequests = '변경요청이 없습니다';

  // ── Schedule Guide Info Box (D-7) ──────────────────────────

  /// 기본 가이드 메시지 (회차 터치 안내)
  static const guideDefaultMessage = '회차를 터치하여 일정을 변경할 수 있습니다';

  /// 전체 모드 가이드 메시지
  static const guideBulkModeMessage = '앞으로의 전체 스케줄을 변경합니다';

  // ── Schedule Change Chat Bubble (D-5) ─────────────────────

  /// N회차 시간 변경을 요청합니다
  static String sessionChangeRequested(int n) => '$n회차 시간 변경을 요청합니다';

  /// N회차 일정 변경을 제안했습니다
  static String sessionChangeProposed(int n) => '$n회차 일정 변경을 제안했습니다';

  /// 전체 회차(from~to) 일정 변경을 제안했습니다
  static String bulkChangeProposed(int from, int to) =>
      '전체 회차($from~$to) 일정 변경을 제안했습니다';

  /// $slot을 선택했습니다
  static String slotAccepted(String slot) => '$slot을 선택했습니다';

  /// 일정 변경을 거절했습니다
  static const changeRejected = '일정 변경을 거절했습니다';

  /// 다른 시간을 제안합니다
  static const counterProposed = '다른 시간을 제안합니다';

  /// N순위
  static String slotPriority(int n) => '$n순위';

  /// N회차 → dateTime 확정
  static String sessionConfirmed(int n, String dateTime) =>
      '$n회차 → $dateTime 확정';

  /// 사유:
  static const reasonPrefix = '사유: ';

  /// 변경취소권 N회 사용 (잔여 M회)
  static String rescheduleCreditsUsed(int used, int remaining) =>
      '변경취소권 $used회 사용 (잔여 $remaining회)';

  // ── Schedule Change Chat Labels (D-8) ─────────────────────

  /// 전체일정변경
  static const chatBulkScheduleChange = '전체일정변경';

  /// 이번회차 스케줄 변경
  static const chatSingleScheduleChange = '이번회차 스케줄 변경';
}
