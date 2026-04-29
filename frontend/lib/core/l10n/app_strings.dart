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

  /// 삭제 버튼
  static const delete = '삭제';

  /// 저장 버튼
  static const save = '저장';

  /// 추가 버튼 (신규 항목 생성)
  static const add = '추가';

  /// 다시 시도 버튼 (에러 재시도)
  static const retry = '다시 시도';

  /// 좋아요 OFF 라벨 (선생님 토글, verb — 행동 초대)
  static const practiceLikeOff = '좋아요 표시';

  /// 좋아요 ON 라벨 (도장 찍힘, noun — 기록된 결과)
  static const practiceLikeOn = '좋음';

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

  // ── Schedule Change Slot Screen — Chapter guide ─────────────────
  static const scheduleChangeSlotGuideTitle = '시간 변경 제안';
  static const scheduleChangeSlotGuideSingle =
      '변경할 회차의 대안 시간을 최대 3개까지 선택해 학생에게 제안해주세요';
  static const scheduleChangeSlotGuideBulk =
      '앞으로 매주 적용될 새 정규 시간을 최대 3개까지 선택해 학생에게 제안해주세요';

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
  static String lessonsNeedConfirmation(int count) => '미확인 레슨 $count건';

  /// 이 레슨이 진행되었나요? (LessonConfirmationDialog 본문 질문)
  static const lessonConductedQuestion = '이 레슨이 진행되었나요?';

  /// 나중에 (LessonConfirmationDialog 취소 버튼)
  static const later = '나중에';

  /// 메모 (선택) (TextField 라벨)
  static const memoOptional = '메모 (선택)';

  /// 추가 메모를 입력하세요 (TextField hint, "(선택)" 미포함)
  static const memoHint = '추가 메모를 입력하세요';

  /// 횟수 1회 차감 (LessonNonCompletionReason.description, "레슨" prefix 미포함)
  static const lessonDeductOnce = '횟수 1회 차감';

  /// 다른 날짜로 변경 (횟수 유지) (LessonNonCompletionReason.description)
  static const lessonRescheduleNoCount = '다른 날짜로 변경 (횟수 유지)';

  /// 무단 결석 (LessonNonCompletionReason.noShow label)
  static const lessonNoShow = '무단 결석';

  /// 학생 사정으로 불참 (LessonNonCompletionReason.studentAbsent label)
  static const lessonStudentAbsentReason = '학생 사정으로 불참';

  /// 당일 취소 (24시간 이내) (LessonNonCompletionReason.cancelledByStudentLate label)
  static const lessonCancelledByStudentLateReason = '당일 취소 (24시간 이내)';

  /// 선생님 사정으로 취소 (LessonNonCompletionReason.teacherCancelled label)
  static const lessonTeacherCancelledReason = '선생님 사정으로 취소';

  /// 상호 합의로 취소 (LessonNonCompletionReason.mutualCancelled label)
  static const lessonMutualCancelledReason = '상호 합의로 취소';

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
  static String lessonRequestPending(int count) => '레슨 요청 $count건 대기';

  /// 대기 중인 입금 확인
  static String paymentConfirmPending(int count) => '입금 확인 $count건 대기';

  // ── Urgent Alert Zone (Dashboard) ──────────────────────────

  /// 만료된 수강권
  static String subscriptionExpired(int count) => '만료 수강권 $count건';

  /// 임박한 수강권
  static String subscriptionExpiringSoon(int count) => '수강권 임박 $count건';

  /// 예약 승인 대기
  static String pendingBookings(int count) => '예약 승인 대기 $count건';

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

  // === TimeContextBanner (Home) strings ===
  // 선생님 메시지
  static String timeBannerTeacherMorning(int count) =>
      '좋은 아침이에요. 오늘 $count건의 레슨이 있어요';
  static String timeBannerNextLessonInProgress(String time) =>
      '$time 레슨 진행 중이에요';
  static String timeBannerNextLessonMinutes(String time, int minutes) =>
      '다음 레슨: $time ($minutes분 후)';
  static String timeBannerNextLessonHours(String time, int hours) =>
      '다음 레슨: $time (약 $hours시간 후)';
  static const timeBannerTeacherDayDone = '오늘 모든 레슨이 끝났어요. 수고하셨어요';
  static String timeBannerTeacherEveningNotes(int completed, int needed) =>
      '오늘 $completed건 완료. 노트 미작성 $needed건';
  static String timeBannerTeacherEveningDone(int completed) =>
      '오늘 $completed건 완료. 수고하셨어요';
  static const timeBannerTeacherNight = '편안한 밤 되세요. 내일도 좋은 레슨 되시길 바랍니다';

  // 학생 메시지
  static const timeBannerStudentMorningLesson = '좋은 아침이에요. 오늘 레슨이 있어요!';
  static String timeBannerStudentMorningStreak(int streak) =>
      '좋은 아침이에요. $streak일 연속 연습 중이에요!';
  static const timeBannerStudentMorningPractice = '좋은 아침이에요. 오늘 연습해볼까요?';
  static String timeBannerStudentLessonTime(String time) => '$time 레슨 시간이에요!';
  static String timeBannerStudentStreakKeep(int streak) =>
      '오늘도 $streak일째 이어가요!';
  static String timeBannerStudentStreakGreat(int streak) =>
      '$streak일 연속 연습! 멋져요!';
  static String timeBannerStudentStreakContinue(int streak) =>
      '$streak일 연속 연습 중이에요. 오늘도 이어가세요!';
  static const timeBannerStudentEveningAsk = '오늘 연습 어땠나요?';
  static String timeBannerStudentNightStreak(int streak) =>
      '오늘도 수고하셨어요. $streak일째 멋져요!';
  static const timeBannerStudentNight = '편안한 밤 되세요. 내일 파이팅!';

  // 학생 홈 헤더
  static const studentHomeGreeting = '오늘도 화이팅!';
  static const inviteTeacher = '선생님 연결';
  static const notifications = '알림';

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
  static String remainingLessonsWarning(int count) => '잔여 $count회 - 갱신 권장';

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

  // ── Recording Feedback (선생님 공유 녹음 피드백) ─────────

  /// 공유 녹음 피드백
  static const recordingFeedbackTitle = '공유 녹음 피드백';

  /// 학생의 연습에 대한 코멘트를 남겨주세요
  static const recordingFeedbackDescription = '학생의 연습에 대한 코멘트를 남겨주세요';

  /// 예시 힌트
  static const recordingFeedbackHint = '예: 템포를 조금 더 안정적으로 유지해보세요';

  /// 피드백 저장
  static const recordingFeedbackSave = '피드백 저장';

  /// 아직 남긴 피드백이 없습니다
  static const recordingFeedbackEmpty = '아직 남긴 피드백이 없습니다';

  /// 피드백이 저장되었습니다
  static const recordingFeedbackSaved = '피드백이 저장되었습니다';

  /// 피드백 N개
  static String recordingFeedbackCount(int n) => '피드백 $n개';

  /// 재생은 실제 녹음 파일이 연동되면 지원됩니다
  static const recordingPlaybackComingSoon = '재생은 실제 녹음 파일이 연동되면 지원됩니다';

  // ── Payment Reminder (미입금 알림) ─────────────────────────
  /// 입금 알림을 보냈습니다
  static const paymentReminderSent = '입금 알림을 보냈습니다';

  /// 입금 알림 발송에 실패했어요
  static const paymentReminderSendFailed = '입금 알림 발송에 실패했어요';

  /// 수강료 입금 안내
  static const paymentReminderTitle = '수강료 입금 안내';

  /// 수강료 %s원 입금 부탁드려요 (bodyFor 함수로 포맷)
  static String paymentReminderBody({
    required String teacherName,
    required int amount,
  }) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$teacherName 선생님: 수강료 $formatted원 입금을 부탁드려요';
  }

  // ── Booking Cancel (예약 취소 화면) ─────────────────────────
  /// 예약 취소 (AppBar)
  static const bookingCancelTitle = '예약 취소';

  /// 취소할 예약 (카드 라벨)
  static const bookingToBeCancelled = '취소할 예약';

  /// 취소 불가 (배지)
  static const bookingCancelImpossible = '취소 불가';

  /// 변경/취소 횟수 모두 사용 안내
  static String rescheduleQuotaExhausted(int total) =>
      '변경/취소 횟수를 모두 사용하셨습니다 ($total/$total회 사용)';

  /// 선생님 직접 문의 안내
  static const bookingCancelContactTeacher = '취소가 필요하시면 선생님께 직접 문의해주세요.';

  /// 마지막 취소 기회 (배지)
  static const bookingCancelLastChance = '마지막 취소 기회';

  /// 현재 N/M회 사용
  static String rescheduleUsageStatus(int used, int total) =>
      '현재 $used/$total회 사용';

  /// 현재: N/M회 사용 (다이얼로그 콜론 형식)
  static String rescheduleUsageStatusWithColon(int used, int total) =>
      '현재: $used/$total회 사용';

  /// 취소 후 N/N회 (마지막!)
  static String rescheduleAfterCancelLast(int total) =>
      '취소 후 $total/$total회 (마지막!)';

  /// 변경/취소 불가 안내
  static const rescheduleNoMoreAfter = '이후 더 이상 변경/취소가 불가합니다.';

  /// 변경/취소 N/M회 남음
  static String rescheduleRemaining(int remain, int total) =>
      '변경/취소: $remain/$total회 남음';

  /// 취소 시 1회 차감 안내
  static const bookingCancelDeductNotice = '취소 시 1회 차감됩니다.';

  /// 선생님 취소 (배지)
  static const teacherCancelLabel = '선생님 취소';

  /// 학생 차감 없음 안내
  static const teacherCancelNoStudentDeduct = '학생의 변경 횟수는 차감되지 않습니다.';

  /// 취소 사유 (선택) 라벨
  static const cancelReasonOptionalLabel = '취소 사유 (선택)';

  /// 취소 사유 입력 힌트
  static const cancelReasonInputHint = '취소 사유를 입력해주세요';

  /// 예약 취소하기 (CTA 버튼)
  static const bookingCancelAction = '예약 취소하기';

  /// 돌아가기 (보조 버튼)
  static const goBack = '돌아가기';

  /// 선생님에게 문의하기
  static const contactTeacher = '선생님에게 문의하기';

  /// 마지막 취소 기회입니다 (다이얼로그 제목)
  static const bookingCancelLastChanceDialogTitle = '마지막 취소 기회입니다';

  /// 취소 후: N/N회 (마지막)
  static String rescheduleAfterCancelMarker(int total) =>
      '취소 후: $total/$total회 (마지막)';

  /// 예약이 취소되었습니다 (스낵바)
  static const bookingCancelled = '예약이 취소되었습니다';

  /// 예약 취소 실패 (스낵바)
  static const bookingCancelFailed = '예약 취소에 실패했습니다. 다시 시도해주세요.';

  // ── Booking Reschedule (예약 변경 화면) ─────────────────────────
  /// 예약 변경 (AppBar)
  static const bookingRescheduleTitle = '예약 변경';

  /// 현재 예약 (카드 라벨)
  static const currentBookingLabel = '현재 예약';

  /// 변경 불가 (X/Y회 사용완료) — 배지
  static String bookingRescheduleQuotaUsed(int used, int total) =>
      '변경 불가 ($used/$total회 사용완료)';

  /// 마지막 변경 기회! (X/Y회 남음) — 배지
  static String rescheduleLastChanceWithCount(int remaining, int total) =>
      '마지막 변경 기회! ($remaining/$total회 남음)';

  /// 변경 가능: X/Y회 — 배지
  static String bookingRescheduleAvailable(int remaining, int total) =>
      '변경 가능: $remaining/$total회';

  /// 새로운 시간 선택 (섹션 라벨)
  static const selectNewTimeLabel = '새로운 시간 선택';

  /// 예약 가능한 시간이 없습니다 (빈 상태)
  static const noAvailableBookingTime = '예약 가능한 시간이 없습니다';

  /// 변경 후: $date $time (프리뷰 카드)
  static String afterChangeDateTime(String date, String time) =>
      '변경 후: $date $time';

  /// 예약 변경하기 (CTA 버튼)
  static const bookingRescheduleAction = '예약 변경하기';

  /// 마지막 변경 기회입니다 (다이얼로그 제목)
  static const bookingRescheduleLastChanceDialogTitle = '마지막 변경 기회입니다';

  /// 변경 후: N/N회 (마지막) — 다이얼로그 본문
  static String rescheduleAfterChangeMarker(int total) =>
      '변경 후: $total/$total회 (마지막)';

  /// 변경하기 (다이얼로그 확인 액션)
  static const changeAction = '변경하기';

  /// 예약이 $date $time 로 변경되었습니다 (스낵바)
  static String bookingRescheduledTo(String date, String time) =>
      '예약이 $date $time로 변경되었습니다';

  /// 예약 변경 실패 (스낵바)
  static const bookingRescheduleFailed = '예약 변경에 실패했습니다. 다시 시도해주세요.';

  /// 변경권 모두 사용 (알림 제목)
  static const rescheduleCreditsAllUsedTitle = '변경권을 모두 사용했습니다';

  /// 변경권 모두 사용 (알림 본문)
  static const rescheduleCreditsAllUsedBody =
      '더 이상 레슨 일정을 직접 변경할 수 없습니다. 변경이 필요한 경우 선생님에게 문의해주세요.';

  /// 변경권 1회 남음 (알림 제목)
  static const rescheduleCreditLastOneTitle = '변경권 1회 남음';

  /// 변경권 1회 남음 (알림 본문)
  static const rescheduleCreditLastOneBody = '변경권이 1회 남았습니다. 신중하게 사용해주세요.';

  /// 선생님 정보를 찾을 수 없습니다
  static const teacherInfoNotFound = '선생님 정보를 찾을 수 없습니다';

  /// 선생님 연락처 미등록
  static const teacherContactNotRegistered = '선생님 연락처가 등록되지 않았습니다';

  /// $teacherName 연락처 (바텀시트 제목)
  static String teacherContactTitle(String teacherName) => '$teacherName 연락처';

  /// 전화하기
  static const callAction = '전화하기';

  /// 문자 보내기
  static const smsAction = '문자 보내기';

  /// 번호 복사
  static const copyNumber = '번호 복사';

  /// 연락처 복사 완료 (스낵바)
  static const contactCopied = '연락처가 복사되었습니다';

  // ── Group Class (그룹 클래스 상세) ─────────────────────────
  /// $name (그룹) — AppBar 제목
  static String groupClassTitle(String name) => '$name (그룹)';

  /// 정규 클래스 (배지)
  static const groupClassRegular = '정규 클래스';

  /// 드롭인 클래스 (배지)
  static const groupClassDropin = '드롭인 클래스';

  /// 오류가 발생했습니다. 다시 시도해주세요.
  static const errorTryAgain = '오류가 발생했습니다. 다시 시도해주세요.';

  /// 날짜 (라벨)
  static const infoLabelDate = '날짜';

  /// 시간 (라벨)
  static const infoLabelTime = '시간';

  /// 수업 시간 (라벨)
  static const infoLabelDuration = '수업 시간';

  /// $n분 (수업 시간 값)
  static String durationMinutesValue(int n) => '$n분';

  /// 수강료 (라벨)
  static const infoLabelTuition = '수강료';

  /// 만석
  static const capacityFull = '만석';

  /// 마감임박
  static const capacityAlmostFull = '마감임박';

  /// 예약가능
  static const capacityAvailable = '예약가능';

  /// $confirmed / $max명 (정원 표시)
  static String capacityCount(int confirmed, int max) => '$confirmed / $max명';

  /// 대기자 현황: $count명
  static String waitlistStatus(int count) => '대기자 현황: $count명';

  /// 취소 발생 시 순서대로 예약됩니다
  static const waitlistAutoRebook = '취소 발생 시 순서대로 예약됩니다';

  /// ℹ️ 취소 발생 시 순서대로 예약됩니다
  static const waitlistAutoRebookInfo = 'ℹ️ 취소 발생 시 순서대로 예약됩니다';

  /// 대기 취소 (다이얼로그/버튼)
  static const waitlistCancelTitle = '대기 취소';

  /// 예약이 마감되었습니다
  static const bookingClosed = '예약이 마감되었습니다';

  /// 대기자로 등록하기
  static const joinWaitlist = '대기자로 등록하기';

  /// 예약하기
  static const bookAction = '예약하기';

  /// 클래스 소개 (섹션 제목)
  static const classDescription = '클래스 소개';

  /// 예약 안내 (섹션 제목)
  static const bookingPolicy = '예약 안내';

  /// 예약/취소 마감 + 미참석 정책 본문
  static String bookingPolicyText({
    required int bookingDeadlineHours,
    required int cancelDeadlineHours,
    required bool deductOnNoShow,
  }) {
    final noShow = deductOnNoShow ? '수강권 차감' : '수강권 미차감';
    return '• 예약 마감: 수업 $bookingDeadlineHours시간 전\n'
        '• 취소 마감: 수업 $cancelDeadlineHours시간 전\n'
        '• 미참석 시: $noShow';
  }

  /// 대기 N번으로 등록되었습니다
  static String waitlistRegistered(int position) => '대기 $position번으로 등록되었습니다';

  /// 예약이 완료되었습니다
  static const bookingCompleted = '예약이 완료되었습니다';

  /// 대기를 취소하시겠습니까?
  static const cancelWaitlistConfirm = '대기를 취소하시겠습니까?';

  /// 예약을 취소하시겠습니까?
  static const cancelBookingConfirm = '예약을 취소하시겠습니까?';

  /// 대기가 취소되었습니다
  static const waitlistCancelled = '대기가 취소되었습니다';

  // ── Group Class Attendance (출석 체크) ─────────────────────
  /// 출석 체크 (AppBar 제목)
  static const attendanceCheck = '출석 체크';

  /// 출석 (헤더 카운트 캡션)
  static const attendedLabel = '출석';

  /// 미참석자만 탭하세요 (도움말)
  static const attendanceHint = '미참석자만 탭하세요';

  /// 예약된 학생이 없습니다 (빈 상태)
  static const noBookedStudents = '예약된 학생이 없습니다';

  /// 로딩중... (로딩 상태)
  static const loadingText = '로딩중...';

  /// 알 수 없음 (이름 폴백)
  static const unknownName = '알 수 없음';

  /// 미참석 (학생 상태 라벨)
  static const absentLabel = '미참석';

  /// 수업 종료 (버튼/다이얼로그 제목)
  static const finishClass = '수업 종료';

  /// 출석이 저장되었습니다 (스낵바)
  static const attendanceSaved = '출석이 저장되었습니다';

  /// 출석 N명 / 미참석 N명 (다이얼로그 본문)
  static String attendanceSummary(int attended, int absent) =>
      '출석: $attended명\n미참석: $absent명';

  /// 수업 종료 확인 (다이얼로그 본문)
  static const finishClassConfirm = '수업을 종료하시겠습니까?\n출석한 학생의 수강권이 차감됩니다.';

  /// 수업이 종료되었습니다 (스낵바)
  static const classFinished = '수업이 종료되었습니다';

  // ── Weekly Schedule (주간 스케줄 설정) ─────────────────────
  /// 주간 스케줄 설정 (AppBar)
  static const weeklyScheduleSetting = '주간 스케줄 설정';

  /// 스케줄 추가 (FAB)
  static const addSchedule = '스케줄 추가';

  /// 주간 스케줄 (섹션 제목)
  static const weeklyScheduleSection = '주간 스케줄';

  /// 레슨 시간 설정 (카드 헤더)
  static const lessonTimeSettings = '레슨 시간 설정';

  /// 레슨 시간 (라벨)
  static const lessonDurationLabel = '레슨 시간';

  /// 시작 간격 (라벨)
  static const startIntervalLabel = '시작 간격';

  /// 쉬는 시간 (라벨)
  static const breakTimeLabel = '쉬는 시간';

  /// 예약 가능 시간 예시 (intervalMinutes=30 또는 60)
  static String availableSlotsExample(int intervalMinutes) {
    final extra = intervalMinutes == 30 ? '10:30, ' : '';
    final tail = intervalMinutes == 30 ? ', 11:30' : '';
    return '예약 가능 시간: 10:00, ${extra}11:00$tail...';
  }

  /// 탭하여 시간 추가 (빈 요일 셀)
  static const tapToAddTime = '탭하여 시간 추가';

  /// 설정된 스케줄이 없습니다
  static const noScheduleSet = '설정된 스케줄이 없습니다';

  /// 아래 버튼을 눌러 레슨 가능 시간을 추가하세요
  static const addScheduleHint = '아래 버튼을 눌러 레슨 가능 시간을 추가하세요';

  /// 데이터를 불러올 수 없습니다 (에러 상태)
  static const cannotLoadData = '데이터를 불러올 수 없습니다';

  /// 스케줄 삭제 (다이얼로그 제목)
  static const deleteScheduleTitle = '스케줄 삭제';

  /// $dayName요일 $start - $end 스케줄을 삭제하시겠습니까?
  static String deleteScheduleConfirm({
    required String dayName,
    required String startTime,
    required String endTime,
  }) => '$dayName요일 $startTime - $endTime 스케줄을 삭제하시겠습니까?';

  // ── Time Exception (휴무 및 예외 설정) ──────────────────────────

  /// 휴무 및 예외 설정 (AppBar)
  static const timeExceptionTitle = '휴무 및 예외 설정';

  /// 휴무 추가 (FAB / 바텀시트 헤더)
  static const addTimeException = '휴무 추가';

  /// 예정된 휴무 (섹션 제목)
  static const upcomingExceptions = '예정된 휴무';

  /// 지난 휴무 (섹션 제목)
  static const pastExceptions = '지난 휴무';

  /// 휴무 설정 안내 (info 카드 제목)
  static const exceptionInfoTitle = '휴무 설정 안내';

  /// info 카드 본문
  static const exceptionInfoBody = '휴무일로 설정된 날짜는 학생들에게 예약 가능 시간으로 표시되지 않습니다.';

  /// 설정된 휴무가 없습니다 (빈 상태)
  static const noExceptionsSet = '설정된 휴무가 없습니다';

  /// 아래 버튼을 눌러 휴무일을 추가하세요
  static const addExceptionHint = '아래 버튼을 눌러 휴무일을 추가하세요';

  /// 휴무 삭제 (다이얼로그 제목)
  static const deleteExceptionTitle = '휴무 삭제';

  /// $dateRange 휴무를 삭제하시겠습니까?
  static String deleteExceptionConfirm(String dateRange) =>
      '$dateRange 휴무를 삭제하시겠습니까?';

  /// 유형 (라벨, 일반)
  static const typeLabel = '유형';

  /// 시작일 (라벨)
  static const startDateLabel = '시작일';

  /// 종료일 (라벨)
  static const endDateLabel = '종료일';

  /// 사유 (선택) (라벨)
  static const reasonOptionalLabel = '사유 (선택)';

  /// 휴무 사유를 입력하세요 (hint)
  static const reasonHint = '휴무 사유를 입력하세요';

  /// 추가 (제출 버튼)
  static const addAction = '추가';

  // ── Teacher Availability (레슨 운영 시간 설정) ──────────────────

  /// 레슨 운영 시간 설정 (AppBar)
  static const teacherAvailabilityTitle = '레슨 운영 시간 설정';

  /// 주간 레슨 시간 (섹션 1 제목)
  static const weeklyLessonTimes = '주간 레슨 시간';

  /// 섹션 1 부제
  static const weeklyLessonTimesSubtitle = '레슨하는 요일과 시간을 설정하세요';

  /// 섹션 1 도움말
  static const weeklyLessonTimesHelp = '설정한 시간이 스케줄과 학생 예약 화면에 반영됩니다';

  /// 레슨 기본 설정 (섹션 2 제목)
  static const lessonBasicSettings = '레슨 기본 설정';

  /// 이번 주 예상 스케줄 (섹션 3 제목)
  static const weeklyPreview = '이번 주 예상 스케줄';

  /// 섹션 3 부제
  static const weeklyPreviewSubtitle = '설정한 시간 기반 미리보기';

  /// 특별 일정 (섹션 4 제목)
  static const specialSchedules = '특별 일정';

  /// 섹션 4 부제
  static const specialSchedulesSubtitle = '휴가, 공휴일, 추가 오픈 등을 관리합니다';

  /// 쉬는날 (요일 행 빈 상태)
  static const dayOff = '쉬는날';

  /// 레슨 길이 (라벨)
  static const lessonLengthLabel = '레슨 길이';

  /// 레슨 길이 도움말
  static const lessonLengthHelp = '학생이 예약 시 이 길이로 예약됩니다';

  /// 쉬는 시간 도움말
  static const breakTimeHelp = '연속 레슨 사이에 자동으로 쉬는 시간이 추가됩니다';

  /// 시작 간격 동적 예시 (interval 30 또는 60)
  static String startIntervalHelp(int intervalMinutes) {
    final tail = intervalMinutes == 30 ? '30, 11:00' : '00 → 11:00';
    return '$intervalMinutes분이면 10:00, 10:$tail 시작 가능';
  }

  /// 탭하여 변경 (설정 카드 안내)
  static const tapToChange = '탭하여 변경';

  /// 설정된 특별 일정이 없습니다 (빈 상태)
  static const noSpecialSchedules = '설정된 특별 일정이 없습니다';

  /// 특별 일정 관리 (버튼)
  static const manageSpecialSchedules = '특별 일정 관리';

  // ── Register Regular Lesson (정규레슨 등록) ──────────────────────

  /// 정규레슨 등록 (AppBar)
  static const regularLessonTitle = '정규레슨 등록';

  /// 시간 정보를 불러올 수 없습니다 (에러)
  static const timeInfoLoadError = '시간 정보를 불러올 수 없습니다';

  /// 설정 정보를 불러올 수 없습니다 (에러)
  static const settingsInfoLoadError = '설정 정보를 불러올 수 없습니다';

  /// 레슨 유형 (섹션 0 제목)
  static const lessonTypeLabel = '레슨 유형';

  /// 선생님 기본 설정: $formatted (안내)
  static String teacherDefaultDuration(String formatted) =>
      '선생님 기본 설정: $formatted';

  /// 요일 선택 (섹션 2 제목)
  static const daySelectLabel = '요일 선택';

  /// 주 $n회 레슨 - $n개 요일을 선택하세요 (안내)
  static String daySelectHint(int lessonsPerWeek) =>
      '주 $lessonsPerWeek회 레슨 - $lessonsPerWeek개 요일을 선택하세요';

  /// 시간 선택 (섹션 3 제목)
  static const timeSelectLabel = '시간 선택';

  /// 레슨 횟수 (섹션 4 제목)
  static const lessonCountLabel = '레슨 횟수';

  /// 5주차 휴강 정책 (footnote)
  static const fifthWeekFootnote = '* 5주차가 있는 달은 기본 휴강이에요. 추가 레슨은 1회 레슨으로 신청!';

  /// 월 수강료 (섹션 5 제목)
  static const monthlyFeeLabel = '월 수강료';

  /// $n개의 요일을 선택해주세요 (검증 메시지)
  static String selectDaysCountHint(int count) => '$count개의 요일을 선택해주세요';

  /// 각 요일의 레슨 시간을 선택해주세요 (검증 메시지)
  static const selectTimeForEachDay = '각 요일의 레슨 시간을 선택해주세요';

  /// 신규 학생 (기본값)
  static const newStudentDefault = '신규 학생';

  /// 정규레슨이 등록되었습니다 (성공 토스트)
  static const regularLessonRegistered = '정규레슨이 등록되었습니다';

  /// 등록 중 오류가 발생했습니다. 다시 시도해주세요. (실패 토스트)
  static const registrationErrorRetry = '등록 중 오류가 발생했습니다. 다시 시도해주세요.';

  // ── Schedule Tab (스케줄 탭) ──────────────────────────────
  /// 레슨 추가 (IconButton tooltip)
  static const addLessonTooltip = '레슨 추가';

  /// 스케줄 (Programme Title)
  static const scheduleTabTitle = '스케줄';

  /// 오늘 (today indicator badge)
  static const todayLabel = '오늘';

  /// $n개 레슨 (count display)
  static String lessonCountWithUnit(int count) => '$count개 레슨';

  /// 예정된 레슨이 없습니다 (empty state)
  static const noUpcomingLessons = '예정된 레슨이 없습니다';

  /// 레슨 정보를 불러오는데 실패했습니다 (error state)
  static const lessonLoadFailed = '레슨 정보를 불러오는데 실패했습니다';

  /// $name 레슨을 완료 처리하시겠습니까? (confirm dialog message)
  static String confirmLessonCompletion(String studentName) =>
      '$studentName 레슨을 완료 처리하시겠습니까?';

  /// $name 레슨을 취소하시겠습니까? (confirm dialog message)
  static String confirmLessonCancellation(String studentName) =>
      '$studentName 레슨을 취소하시겠습니까?';

  /// $name 레슨이 $action되었습니다 (snackbar after swipe action)
  static String lessonActionCompleted(String studentName, String action) =>
      '$studentName 레슨이 $action되었습니다';

  /// 수강권 상세 화면은 준비 중입니다 (TODO placeholder)
  static const subscriptionDetailComingSoon = '수강권 상세 화면은 준비 중입니다';

  // ── Request Completion (신청 완료 화면) ─────────────────
  /// 신청 완료 (AppBar)
  static const requestSubmittedTitle = '신청 완료';

  /// $teacherName 선생님에게 요청을 보냈습니다 (success header subtitle)
  static String requestSentToTeacherWithName(String teacherName) =>
      '$teacherName 선생님에게 요청을 보냈습니다';

  /// 진행 단계 가이드 (section title)
  static const progressStepGuide = '진행 단계 가이드';

  /// 선생님에게 요청이 전송되었습니다 (step 1 desc)
  static const stepRequestSentDesc = '선생님에게 요청이 전송되었습니다';

  /// 선생님이 시간 확인 (step 2 title)
  static const stepTeacherChecking = '선생님이 시간 확인';

  /// 희망 시간을 검토 중입니다 (step 2 desc)
  static const stepTeacherCheckingDesc = '희망 시간을 검토 중입니다';

  /// 시간 확정 후 입금 (step 3 title)
  static const stepPaymentAfterConfirm = '시간 확정 후 입금';

  /// 확정된 시간에 맞춰 입금합니다 (step 3 desc)
  static const stepPaymentAfterConfirmDesc = '확정된 시간에 맞춰 입금합니다';

  /// 선생님이 수강권 발급 (step 4 title)
  static const stepSubscriptionIssued = '선생님이 수강권 발급';

  /// 수강권이 발급되면 알림을 보내드립니다 (step 4 desc)
  static const stepSubscriptionIssuedDesc = '수강권이 발급되면 알림을 보내드립니다';

  /// 레슨 시작! (step 5 title)
  static const stepLessonStart = '레슨 시작!';

  /// 첫 레슨을 즐겨보세요 (step 5 desc)
  static const stepLessonStartDesc = '첫 레슨을 즐겨보세요';

  /// 신청 정보 요약 (section title)
  static const requestInfoSummary = '신청 정보 요약';

  /// 희망시간 (summary row label)
  static const preferredTimeLabel = '희망시간';

  /// $n순위 (priority rank)
  static String priorityRank(int n) => '$n순위';

  /// (미선택) (empty slot placeholder)
  static const notSelectedParen = '(미선택)';

  /// 메인으로 가기 (home button)
  static const goToMain = '메인으로 가기';

  // ── Unified Lesson Request (통합 레슨 신청) ─────────────
  /// 재수강 신청 — 이전 레슨 정보가 자동 입력되었습니다 (returning student banner)
  static const returningStudentBanner = '재수강 신청 — 이전 레슨 정보가 자동 입력되었습니다';

  /// 레슨 목표 (section title)
  static const lessonGoalLabel = '레슨 목표';

  /// 경험 수준 (section title)
  static const experienceLevelLabel = '경험 수준';

  /// 희망 레슨 시간 (section title)
  static const preferredLessonTimeLabel = '희망 레슨 시간';

  /// 메시지 (section title)
  static const messageLabel = '메시지';

  /// (선택) (optional indicator)
  static const optionalParen = '(선택)';

  /// 선생님께 전달할 메시지를 입력하세요 (text field hint)
  static const messageHintToTeacher = '선생님께 전달할 메시지를 입력하세요';

  /// 참고 레슨비 (price section label)
  static const referencePriceLabel = '참고 레슨비';

  /// $price원 / 회 (price per session)
  static String pricePerSession(String price) => '$price원 / 회';

  /// 악기를 선택해주세요 (validation error)
  static const validationSelectInstrument = '악기를 선택해주세요';

  /// 희망 레슨 시간을 1개 이상 선택해주세요 (validation error)
  static const validationSelectPreferredTime = '희망 레슨 시간을 1개 이상 선택해주세요';

  /// 신청 전송에 실패했습니다. 다시 시도해주세요. (submit error)
  static const requestSubmitFailedRetry = '신청 전송에 실패했습니다. 다시 시도해주세요.';

  // ── My Bookings (내 레슨 예약) ─────────────────────────
  /// 내 레슨 예약 (AppBar)
  static const myBookingsTitle = '내 레슨 예약';

  /// 변경/취소: $remaining/$total회 (subscription header inline)
  static String rescheduleUsageInline(int remaining, int total) =>
      '변경/취소: $remaining/$total회';

  /// 예약된 레슨이 없습니다 (empty title)
  static const noBookings = '예약된 레슨이 없습니다';

  /// 새로운 레슨을 예약해보세요 (empty subtitle)
  static const bookNewLesson = '새로운 레슨을 예약해보세요';

  /// 변경 (reschedule short button)
  static const rescheduleShort = '변경';

  /// 변경/취소 횟수를 모두 사용했습니다 (limit reached note)
  static const rescheduleQuotaUsedUp = '변경/취소 횟수를 모두 사용했습니다';

  // ── Lessons (레슨 도메인 화면 28차) ─────────────────────────
  /// 출석 현황 (attendance screen AppBar)
  static const attendanceTitle = '출석 현황';

  /// 출석 데이터가 없습니다 (attendance empty state)
  static const noAttendanceData = '출석 데이터가 없습니다';

  /// 결석 (LessonStatus.studentAbsent label)
  static const statusAbsent = '결석';

  /// 노쇼 (LessonStatus.noShow label)
  static const statusNoShow = '노쇼';

  /// 당일 취소 (LessonStatus.cancelledByStudentLate label)
  static const statusSameDayCancel = '당일 취소';

  /// 레슨 노트 (lesson note history AppBar)
  static const lessonNotesTitle = '레슨 노트';

  /// 노트 검색... (search hint)
  static const noteSearchHint = '노트 검색...';

  /// 검색 결과가 없습니다 (search empty state)
  static const searchNoResults = '검색 결과가 없습니다';

  /// 레슨 노트가 없습니다 (notes empty state)
  static const noLessonNotes = '레슨 노트가 없습니다';

  /// $year년 $month월 (year-month group header)
  static String yearMonthLabel(int year, int month) => '$year년 $month월';

  /// 피드백 보내기 (quick feedback AppBar)
  static const sendFeedbackTitle = '피드백 보내기';

  /// 데이터를 불러오는데 실패했습니다 (load error)
  static const loadDataFailed = '데이터를 불러오는데 실패했습니다';

  /// 학생 검색... (student search hint)
  static const studentSearchHint = '학생 검색...';

  /// 오늘 레슨 (section header)
  static const todayLessons = '오늘 레슨';

  /// 최근 레슨 (section header)
  static const recentLessons = '최근 레슨';

  /// 예정 (lesson upcoming status)
  static const statusUpcoming = '예정';

  /// $startTime 레슨 ($statusLabel) (today lesson tile subtitle)
  static String todayLessonSubtitle(String startTime, String statusLabel) =>
      '$startTime 레슨 ($statusLabel)';

  /// $month월 $day일 마지막 레슨 (recent lesson tile subtitle)
  static String lastLessonOn(int month, int day) => '$month월 $day일 마지막 레슨';

  /// 피드백을 보낼 레슨이 없습니다 (feedback empty state)
  static const noLessonsForFeedback = '피드백을 보낼 레슨이 없습니다';

  // ── Bulk Feedback (일괄 피드백 화면 29차) ─────────────────────
  /// 일괄 피드백 (default AppBar title)
  static const bulkFeedbackTitle = '일괄 피드백';

  /// 학생 선택 (step 1 title)
  static const bulkFeedbackStepStudent = '학생 선택';

  /// 피드백 작성 (step 2 title)
  static const bulkFeedbackStepWrite = '피드백 작성';

  /// 미리보기 (step 3 title + bottom button)
  static const bulkFeedbackStepPreview = '미리보기';

  /// 완료된 레슨 학생이 자동 선택됩니다. 변경하려면 탭하세요. (info banner)
  static const bulkFeedbackInfoBanner = '완료된 레슨 학생이 자동 선택됩니다. 변경하려면 탭하세요.';

  /// 오늘 레슨이 없습니다 (today empty state)
  static const noTodayLessons = '오늘 레슨이 없습니다';

  /// $startTime ($statusLabel) [· 피드백 있음] (lesson tile subtitle)
  static String bulkLessonTileSubtitle(
    String startTime,
    String statusLabel,
    bool hasFeedback,
  ) => '$startTime ($statusLabel)${hasFeedback ? " · 피드백 있음" : ""}';

  /// 다음 ($count명) (next button label)
  static String bulkFeedbackNextWithCount(int count) => '다음 ($count명)';

  /// 공통 피드백 (common feedback section header)
  static const bulkFeedbackCommonHeader = '공통 피드백';

  /// 모든 선택 학생에게 전달할 피드백을 작성하세요... (common feedback hint)
  static const bulkFeedbackHint = '모든 선택 학생에게 전달할 피드백을 작성하세요...';

  /// 개별 코멘트 (선택) (per-student section header)
  static const bulkFeedbackPerStudentHeader = '개별 코멘트 (선택)';

  /// 각 학생에게 추가할 개별 메시지 (per-student description)
  static const bulkFeedbackPerStudentDesc = '각 학생에게 추가할 개별 메시지';

  /// 추가 코멘트... (per-student textfield hint)
  static const additionalCommentHint = '추가 코멘트...';

  /// 전송 중... (sending in progress)
  static const sendingInProgress = '전송 중...';

  /// $count명에게 전송 (bulk send button)
  static String bulkFeedbackSendButton(int count) => '$count명에게 전송';

  /// $count명에게 피드백을 전송했습니다 (success snackbar)
  static String bulkFeedbackSentMessage(int count) => '$count명에게 피드백을 전송했습니다';

  /// 전송 실패. 다시 시도해주세요. (failure snackbar)
  static const sendFailedRetry = '전송 실패. 다시 시도해주세요.';

  // ── Lesson Notes Widgets (레슨 노트/피드백/연습 팁/녹음 위젯) ─────────
  /// 레슨 피드백 에디터 hint
  static const feedbackEditorHint = '레슨 피드백을 작성하세요...';

  /// 저장 중 상태 표시
  static const savingLabel = '저장 중...';

  /// 저장 완료 상태 표시
  static const savedLabel = '저장됨';

  /// 피드백 카드 빈 상태
  static const feedbackEmpty = '아직 피드백이 없습니다';

  /// 작성 일자 ($date)
  static String feedbackWrittenAt(String date) => '작성: $date';

  /// 주요 포인트 빈 상태 (선생님)
  static const keyPointsEmptyTeacher = '+ 버튼을 눌러 주요 포인트를 추가하세요';

  /// 주요 포인트 빈 상태 (학생)
  static const keyPointsEmptyStudent = '주요 포인트가 없습니다';

  /// 연습 팁 빈 상태 (선생님)
  static const practiceTipsEmptyTeacher = '+ 버튼을 눌러 연습 팁을 추가하세요';

  /// 연습 팁 빈 상태 (학생)
  static const practiceTipsEmptyStudent = '연습 팁이 없습니다';

  /// 녹음 진행 중 라벨
  static const recordingInProgress = '녹음 중';

  /// 녹음 파일 빈 상태
  static const recordingsEmpty = '녹음 파일이 없습니다';

  /// 레슨 취소 확인 다이얼로그 메시지
  static const cancelLessonConfirm = '이 레슨을 취소하시겠습니까?';

  /// 레슨 삭제 다이얼로그 제목
  static const deleteLessonTitle = '레슨 삭제';

  /// 레슨 삭제 확인 다이얼로그 메시지 (녹음/노트 동반 삭제 경고 포함)
  static const deleteLessonConfirm = '이 레슨을 삭제하시겠습니까?\n녹음 파일과 노트도 함께 삭제됩니다.';

  /// 연습 팁 수정 다이얼로그 제목
  static const editPracticeTipTitle = '연습 팁 수정';

  /// 연습 팁 입력 hint
  static const editPracticeTipHint = '연습 팁을 입력하세요';

  /// 학생 메모 카드 제목
  static const studentMemoTitle = '내 메모';

  /// 학생 메모 입력 hint
  static const studentMemoHint = '오늘 배운 것, 어려웠던 점 등을 메모하세요...';

  // ── Edit Lesson (레슨 수정 화면 30차) ─────────────────────────
  /// 레슨 수정 (AppBar title)
  static const editLessonTitle = '레슨 수정';

  /// 일시 (date/time section title)
  static const dateTimeLabel = '일시';

  /// 레슨 내용 (lesson content section title)
  static const lessonContentLabel = '레슨 내용';

  /// 변경사항 저장 (save changes button)
  static const saveChangesButton = '변경사항 저장';

  /// $name 학생의 레슨이 취소되었습니다 (cancel snackbar)
  static String lessonCancelledForStudent(String name) =>
      '$name 학생의 레슨이 취소되었습니다';

  /// 레슨 취소에 실패했습니다. 다시 시도해주세요. (cancel failure)
  static const cancelLessonFailedRetry = '레슨 취소에 실패했습니다. 다시 시도해주세요.';

  /// 레슨이 삭제되었습니다 (delete success)
  static const lessonDeletedMessage = '레슨이 삭제되었습니다';

  /// 레슨 삭제에 실패했습니다. 다시 시도해주세요. (delete failure)
  static const deleteLessonFailedRetry = '레슨 삭제에 실패했습니다. 다시 시도해주세요.';

  /// 시간 충돌 (conflict dialog title)
  static const timeConflictTitle = '시간 충돌';

  /// 해당 시간에 이미 '\$name' 레슨이 있습니다. 계속하시겠습니까? (conflict dialog content)
  static String timeConflictMessage(String name) =>
      "해당 시간에 이미 '$name' 레슨이 있습니다. 계속하시겠습니까?";

  /// 계속 (continue action)
  static const continueAction = '계속';

  /// 레슨 정보가 수정되었습니다 (edit success)
  static const editLessonSuccess = '레슨 정보가 수정되었습니다';

  /// 레슨 수정에 실패했습니다. 다시 시도해주세요. (edit failure)
  static const editLessonFailedRetry = '레슨 수정에 실패했습니다. 다시 시도해주세요.';

  // ── Quick Feedback (빠른 피드백 화면 30차) ─

  /// 피드백 (quick feedback screen title)
  static const feedbackTitle = '피드백';

  /// 레슨을 찾을 수 없습니다 (lesson not found body)
  static const lessonNotFound = '레슨을 찾을 수 없습니다';

  /// {name} 피드백 (app bar title with student name)
  static String studentFeedbackTitle(String name) => '$name 피드백';

  /// 레슨 피드백 (section header)
  static const lessonFeedbackSection = '레슨 피드백';

  /// 주요 포인트 (section header)
  static const keyPointsSection = '주요 포인트';

  /// 연습 팁 (section header)
  static const practiceTipsSection = '연습 팁';

  /// 저장하기 (save action button)
  static const saveAction = '저장하기';

  /// {date} {time} 레슨 (lesson header line 1)
  static String lessonAtDateTime(String date, String time) => '$date $time 레슨';

  /// {instrument} · {duration}분 (lesson header line 2)
  static String instrumentDurationSubtitle(String instrument, int duration) =>
      '$instrument · $duration분';

  /// 프리셋 추가 (preset add dialog title)
  static const presetAddTitle = '프리셋 추가';

  /// 피드백 문구 입력 (preset text hint)
  static const presetTextHint = '피드백 문구 입력';

  /// 숨기기 (preset hide action)
  static const presetHide = '숨기기';

  /// 기본 프리셋은 숨김 처리됩니다 (default preset hide description)
  static const presetHideDescription = '기본 프리셋은 숨김 처리됩니다';

  /// 이 프리셋을 삭제합니다 (preset delete description)
  static const presetDeleteDescription = '이 프리셋을 삭제합니다';

  /// 연습할 때 주의할 점을 적어주세요... (practice tips field hint)
  static const practiceTipsHint = '연습할 때 주의할 점을 적어주세요...';

  /// ✅ 피드백이 저장되었습니다 (feedback saved snackbar)
  static const feedbackSavedSnack = '✅ 피드백이 저장되었습니다';

  /// 피드백 저장 실패 (feedback save error snackbar)
  static const feedbackSaveFailed = '피드백 저장 실패';

  /// 포인트 추가... (key point input hint)
  static const keyPointAddHint = '포인트 추가...';

  // ── Add Practice Item Sheet (연습 추가 바텀시트 30차) ─

  /// 마디 (range type: measure)
  static const measureLabel = '마디';

  /// 줄 (range type: line)
  static const lineLabel = '줄';

  /// 연습 추가 (add practice item sheet title)
  static const addPracticeItemTitle = '연습 추가';

  /// 설명 (선택) (description optional label)
  static const descriptionOptional = '설명 (선택)';

  /// 예: 메트로놈 60으로 정확하게! (practice description hint)
  static const practiceDescriptionHint = '예: 메트로놈 60으로 정확하게!';

  /// 레퍼토리 (repertoire label)
  static const repertoireLabel = '레퍼토리';

  /// 레퍼토리를 불러올 수 없습니다 (repertoire load error)
  static const repertoireLoadFailed = '레퍼토리를 불러올 수 없습니다';

  /// 새 레퍼토리 이름 (new repertoire name label)
  static const newRepertoireNameLabel = '새 레퍼토리 이름';

  /// 예: 스즈키 5권 (repertoire name hint)
  static const repertoireNameHint = '예: 스즈키 5권';

  /// 곡명 (piece name label)
  static const pieceNameLabel = '곡명';

  /// 예: 라폴리아 (piece name hint)
  static const pieceNameHint = '예: 라폴리아';

  /// 연습 구간 (practice section label)
  static const practiceSectionLabel = '연습 구간';

  /// 새 레퍼토리 만들기 (create new repertoire option)
  static const createNewRepertoire = '새 레퍼토리 만들기';

  /// 구간 추가 (add range button)
  static const addRange = '구간 추가';

  /// 시작 (range start hint)
  static const rangeStart = '시작';

  /// 끝 (range end hint)
  static const rangeEnd = '끝';

  /// 레퍼토리를 선택해주세요 (validation: select repertoire)
  static const selectRepertoireValidation = '레퍼토리를 선택해주세요';

  /// 새 레퍼토리 이름을 입력해주세요 (validation: enter new repertoire name)
  static const enterNewRepertoireNameValidation = '새 레퍼토리 이름을 입력해주세요';

  /// 곡명을 입력해주세요 (validation: enter piece name)
  static const enterPieceNameValidation = '곡명을 입력해주세요';

  /// 구간 {n}의 시작/끝 번호를 입력해주세요 (validation: range start/end required)
  static String rangeStartEndRequired(int n) => '구간 $n의 시작/끝 번호를 입력해주세요';

  /// 구간 {n}의 시작 번호가 끝 번호보다 클 수 없습니다 (validation: range order)
  static String rangeInvalidOrder(int n) => '구간 $n의 시작 번호가 끝 번호보다 클 수 없습니다';

  /// 연습이 추가되었습니다 (practice item added success)
  static const practiceItemAdded = '연습이 추가되었습니다';

  /// {n}개 섹션 (repertoire section count caption)
  static String repertoireSectionCount(int n) => '$n개 섹션';

  // ── Add Lesson Screen (레슨 추가/기록 화면 30차) ─

  /// 레슨 기록 (add lesson screen title — past mode)
  static const lessonRecordTitle = '레슨 기록';

  /// 레슨 추가 (add lesson screen title — future mode)
  static const lessonAddTitle = '레슨 추가';

  /// 레슨 장소 (lesson location section title)
  static const lessonLocationLabel = '레슨 장소';

  /// 정기 레슨 예약하기 (recurring lesson submit button)
  static const reserveRecurringLessonButton = '정기 레슨 예약하기';

  /// 레슨 기록하기 (record lesson submit button)
  static const recordLessonButton = '레슨 기록하기';

  /// 레슨 추가하기 (add lesson submit button)
  static const addLessonButton = '레슨 추가하기';

  /// 이 학생은 현재 유효한 수강권이 없습니다... (no active subscription banner)
  static const noActiveSubscriptionBanner =
      '이 학생은 현재 유효한 수강권이 없습니다. 레슨 기록은 가능하지만, 수강권을 먼저 발급하면 횟수가 자동 관리됩니다.';

  /// 과거 레슨 기록 (past lesson record dialog title)
  static const pastLessonRecordTitle = '과거 레슨 기록';

  /// 선택한 시간은 이미 지난 시간입니다. (past time message)
  static const pastTimeMessage = '선택한 시간은 이미 지난 시간입니다.';

  /// 레슨 기록 시: (record lesson checklist header)
  static const recordLessonChecklistHeader = '레슨 기록 시:';

  /// • "완료" 상태로 저장됩니다... (record lesson checklist items)
  static const recordLessonChecklistItems =
      '• "완료" 상태로 저장됩니다\n• 수강권이 있으면 1회 자동 차감됩니다\n• 학생에게 레슨 기록으로 표시됩니다';

  /// 해당 시간에 기존 레슨이 있습니다:\n{info}\n\n그래도 계속 진행하시겠습니까? (conflict dialog content)
  static String conflictDialogContent(String info) =>
      '해당 시간에 기존 레슨이 있습니다:\n$info\n\n그래도 계속 진행하시겠습니까?';

  /// 학생을 선택해주세요 (validation: select student)
  static const selectStudentValidation = '학생을 선택해주세요';

  /// 반복 요일을 선택해주세요 (validation: select recurring days)
  static const selectRecurringDaysValidation = '반복 요일을 선택해주세요';

  /// {dayLabel}요일 ({conflict}) (recurring conflict day template)
  static String recurringConflictDay(String dayLabel, String conflict) =>
      '$dayLabel요일 ($conflict)';

  /// 월/화/수/목/금/토/일 (Korean day-of-week short names, Mon=0)
  static const dayNamesShort = ['월', '화', '수', '목', '금', '토', '일'];

  /// {name} 학생의 정기 레슨 {count}개가 생성되었습니다 (4주간) (recurring created success)
  static String recurringLessonsCreated(String name, int count) =>
      '$name 학생의 정기 레슨 $count개가 생성되었습니다 (4주간)';

  /// {name} 학생의 레슨이 기록되었습니다 (lesson recorded success)
  static String lessonRecordedFor(String name) => '$name 학생의 레슨이 기록되었습니다';

  /// {name} 학생의 레슨이 추가되었습니다 (lesson added success)
  static String lessonAddedFor(String name) => '$name 학생의 레슨이 추가되었습니다';

  /// 레슨 추가에 실패했습니다. 다시 시도해주세요. (add lesson failed)
  static const addLessonFailed = '레슨 추가에 실패했습니다. 다시 시도해주세요.';

  /// 레슨 기록 (사후 등록) (subscription usage note for past lesson)
  static const lessonRecordPostNote = '레슨 기록 (사후 등록)';

  /// 반복 레슨 시간 충돌 (recurring conflict dialog title)
  static const recurringConflictTitle = '반복 레슨 시간 충돌';

  /// 다음 요일에 기존 레슨과 시간이 겹칩니다: (recurring conflict header)
  static const recurringConflictHeader = '다음 요일에 기존 레슨과 시간이 겹칩니다:';

  /// 그래도 계속 진행하시겠습니까? (continue progress question)
  static const continueProgressQuestion = '그래도 계속 진행하시겠습니까?';

  // ── Lesson Detail Screen (레슨 상세화면 30차) ─

  /// {studentName} (레슨) (lesson detail app bar title template)
  static String lessonDetailAppBarTitle(String studentName) =>
      '$studentName (레슨)';

  /// {studentName} {instrument} 레슨\n{date} {startTime} ({duration}분) (share text template)
  static String lessonShareText({
    required String studentName,
    required String instrument,
    required String date,
    required String startTime,
    required int duration,
  }) => '$studentName $instrument 레슨\n$date $startTime ($duration분)';

  /// 공유 텍스트가 복사되었습니다: {text} (share text copied)
  static String shareTextCopied(String text) => '공유 텍스트가 복사되었습니다: $text';

  /// 완료 처리 (mark complete menu item)
  static const markComplete = '완료 처리';

  /// 레슨이 취소되었습니다 (lesson cancelled snack)
  static const lessonCancelled = '레슨이 취소되었습니다';

  /// 레슨 취소에 실패했습니다. 다시 시도해주세요. (lesson cancel failed)
  static const lessonCancelFailed = '레슨 취소에 실패했습니다. 다시 시도해주세요.';

  /// 레슨 완료 (lesson complete dialog title)
  static const lessonCompleteTitle = '레슨 완료';

  /// 이 레슨을 완료 처리하시겠습니까? (lesson complete confirm)
  static const lessonCompleteConfirm = '이 레슨을 완료 처리하시겠습니까?';

  /// 완료 (complete action button)
  static const completeAction = '완료';

  /// 레슨이 완료 처리되었습니다 (lesson completed snack)
  static const lessonCompletedSnack = '레슨이 완료 처리되었습니다';

  /// 레슨 완료 처리에 실패했습니다. 다시 시도해주세요. (lesson complete failed)
  static const lessonCompleteFailed = '레슨 완료 처리에 실패했습니다. 다시 시도해주세요.';

  /// 레슨이 삭제되었습니다 (lesson deleted snack)
  static const lessonDeleted = '레슨이 삭제되었습니다';

  /// 레슨 삭제에 실패했습니다. 다시 시도해주세요. (lesson delete failed)
  static const lessonDeleteFailed = '레슨 삭제에 실패했습니다. 다시 시도해주세요.';

  /// 레슨 노트 (lesson notes tab title)
  static const lessonNotesTab = '레슨 노트';

  /// 과제 (assignments tab title)
  static const assignmentsTab = '과제';

  /// 레슨이 완료되었습니다. 피드백을 작성해주세요! (lesson needs feedback prompt)
  static const lessonNeedsFeedbackPrompt = '레슨이 완료되었습니다. 피드백을 작성해주세요!';

  /// 레슨 피드백 (lesson feedback section title — teacher view)
  static const lessonFeedbackHeader = '레슨 피드백';

  /// 선생님 피드백 (teacher feedback section title — student view)
  static const teacherFeedbackHeader = '선생님 피드백';

  /// 정규 레슨을 제안해보세요 (regular lesson proposal banner title)
  static const regularLessonProposalTitle = '정규 레슨을 제안해보세요';

  /// 수강권을 발급하면 정기 레슨을 시작할 수 있습니다. (regular lesson proposal description)
  static const regularLessonProposalDescription =
      '수강권을 발급하면 정기 레슨을 시작할 수 있습니다.';

  /// 수강권 발급하기 (issue subscription button)
  static const issueSubscriptionButton = '수강권 발급하기';

  /// 주요 포인트 추가 (add key point sheet title)
  static const addKeyPointTitle = '주요 포인트 추가';

  /// 연습 팁 추가 (add practice tip sheet title)
  static const addPracticeTipTitle = '연습 팁 추가';

  /// 주요 포인트가 추가되었습니다 (key point added snack)
  static const keyPointAdded = '주요 포인트가 추가되었습니다';

  /// 주요 포인트 추가에 실패했습니다. (add key point failed)
  static const addKeyPointFailed = '주요 포인트 추가에 실패했습니다.';

  /// 주요 포인트 삭제에 실패했습니다. (remove key point failed)
  static const removeKeyPointFailed = '주요 포인트 삭제에 실패했습니다.';

  /// 피드백 저장에 실패했습니다. (feedback save failed)
  static const feedbackSaveFailedShort = '피드백 저장에 실패했습니다.';

  /// 메모 저장에 실패했습니다. (memo save failed)
  static const memoSaveFailed = '메모 저장에 실패했습니다.';

  /// 연습 팁이 저장되었습니다 (practice tip saved snack)
  static const practiceTipSaved = '연습 팁이 저장되었습니다';
}
