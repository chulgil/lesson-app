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

  /// 입금 필요 (학생이 앱 밖에서 입금해야 함)
  static const studentPaymentRequired = '입금 필요';

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
  static const eventPaymentRequested = '입금 안내';
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
  static const chatPaymentRequested = '입금 안내를 보냈습니다';
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
  static const phasePayment = '입금';
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
  static const chapterSubscription = '수강권 & 입금';
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
  static const methodPrepaidTitle = '입금 확인 후 발급 (선불)';
  static const methodPrepaidDesc = '학생에게 입금 안내를 보내고, 입금 확인 후 수강권이 발급됩니다';

  /// Phase 2: 후불 카드
  static const methodPostpaidTitle = '먼저 발급 (후불)';
  static const methodPostpaidDesc = '수강권을 바로 발급하고, 입금 확인은 나중에 합니다';

  /// Phase 2: 무료 카드
  static const methodFreeTitle = '무료 발급';
  static const methodFreeDesc = '입금 없이 수강권을 바로 발급합니다';

  /// Phase 2: Teacher → 입금 안내 전송 (선불)
  static const actionSendPaymentGuide = '입금 안내 보내기';

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
  static const phase2WaitingPaymentStudent = '입금 후 완료 알림을 보내주세요';
  static const phase2PaymentReceivedTeacher = '학생이 입금을 완료했습니다';

  // ── Action Box Messages (Phase 2 대기 상태) ─────────────────

  /// 선생님: 학생 수강권 수락 대기
  static const actionBoxWaitingAccept = '학생의 수강권 수락을 기다리고 있습니다';

  /// 선생님: 학생 입금 완료 알림 대기
  static const actionBoxWaitingPayment = '학생의 입금 완료 알림을 기다리고 있습니다';

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

  /// 입금 안내 BottomSheet
  static const paymentGuideTitle = '입금 안내 보내기';
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
  static const proposalPaymentMethod = '입금 확인 방식';
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

  /// 입금 상태 챕터
  static const chapterPaymentHistory = '입금 상태';

  /// 레슨 진행 챕터
  static String chapterLessonProgress(int used, int total) =>
      '레슨 진행 ($used/$total회)';

  // === Chapter payment detail strings ===

  /// 입금 상태
  static const paymentStatus = '입금 상태';

  /// 입금 확인 완료
  static const paymentCompleted = '입금 확인 완료';

  /// 입금 확인 대기
  static const paymentPending = '입금 확인 대기';

  /// 입금 방법
  static const paymentMethod = '입금 방법';

  /// 입금일
  static const paymentDate = '입금일';

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

  /// N회차 예약 필요 (booking required + bookingRequired key)
  static String sessionBookingRequired(int n) => '$n회차 $bookingRequired';

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
  /// 재수강 신청 안내 (returning student banner)
  static const returningStudentBanner = '재수강 신청 — 선생님의 최신 가능 시간 중 다시 선택해주세요';

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

  // ── Lesson Resource Widgets (레슨 자료 위젯 30차 5-2c-5) ─

  // -- Edit Practice Item Sheet --

  /// 연습 수정 (edit practice item sheet title)
  static const editPracticeItemTitle = '연습 수정';

  /// 학생이 이미 연습한 과제입니다 (already-completed practice warning)
  static const practiceItemAlreadyDoneWarning = '학생이 이미 연습한 과제입니다';

  /// 제목 (title input label)
  static const titleLabel = '제목';

  /// 제목을 입력해주세요 (title required validation)
  static const enterTitleValidation = '제목을 입력해주세요';

  /// 연습이 수정되었습니다 (practice item updated snack)
  static const practiceItemUpdated = '연습이 수정되었습니다';

  /// 연습 삭제 (delete practice item dialog title)
  static const deletePracticeItemTitle = '연습 삭제';

  /// 이 연습을 삭제하시겠습니까? (delete practice item confirm)
  static const deletePracticeItemConfirm = '이 연습을 삭제하시겠습니까?';

  /// 연습이 삭제되었습니다 (practice item deleted snack)
  static const practiceItemDeleted = '연습이 삭제되었습니다';

  // -- Add YouTube Resource Sheet --

  /// 유튜브 영상 추가 (add youtube resource sheet title)
  static const addYoutubeResourceTitle = '유튜브 영상 추가';

  /// URL (URL label)
  static const urlLabel = 'URL';

  /// https://youtube.com/watch?v=... (youtube url hint)
  static const youtubeUrlHint = 'https://youtube.com/watch?v=...';

  /// URL 확인됨 (url confirmed badge)
  static const urlConfirmed = 'URL 확인됨';

  /// 예: 힐러리 한 - 바흐 파르티타 (youtube title hint)
  static const youtubeTitleHint = '예: 힐러리 한 - 바흐 파르티타';

  /// 재생 구간 (play section label)
  static const playSectionLabel = '재생 구간';

  /// 종료 (선택) (time end optional label)
  static const timeEndOptionalLabel = '종료 (선택)';

  /// 메모 (학생에게 표시) (memo student-visible label)
  static const memoStudentVisibleLabel = '메모 (학생에게 표시)';

  /// 예: 1:32~2:05 구간의 보잉 방향 전환을 관찰하세요 (youtube memo hint)
  static const youtubeMemoHint = '예: 1:32~2:05 구간의 보잉 방향 전환을 관찰하세요';

  /// 분 (minute hint)
  static const minuteLabel = '분';

  /// 초 (second hint)
  static const secondLabel = '초';

  /// 유튜브 URL을 입력해주세요 (enter youtube url validation)
  static const enterYoutubeUrlValidation = '유튜브 URL을 입력해주세요';

  /// 올바른 유튜브 URL을 입력해주세요 (invalid youtube url validation)
  static const invalidYoutubeUrlValidation = '올바른 유튜브 URL을 입력해주세요';

  /// 유튜브 영상이 추가되었습니다 (youtube resource added snack)
  static const youtubeResourceAdded = '유튜브 영상이 추가되었습니다';

  // -- Add Recording Resource Sheet --

  /// 시범 연주 녹음 추가 (add recording resource sheet title)
  static const addRecordingResourceTitle = '시범 연주 녹음 추가';

  /// 탭하여 오디오 파일 선택 (tap to select audio file)
  static const tapToSelectAudioFile = '탭하여 오디오 파일 선택';

  /// m4a, mp3, wav 지원 (audio file supported formats)
  static const audioFileSupportedFormats = 'm4a, mp3, wav 지원';

  /// 예: 바흐 미뉴에트 G장조 시범연주 (recording title hint)
  static const recordingTitleHint = '예: 바흐 미뉴에트 G장조 시범연주';

  /// 연습 포인트를 적어주세요 (practice point hint)
  static const practicePointHint = '연습 포인트를 적어주세요';

  /// 파일을 선택할 수 없습니다 (cannot select file snack)
  static const cannotSelectFile = '파일을 선택할 수 없습니다';

  /// 녹음 추가에 실패했습니다 (recording add failed snack)
  static const recordingAddFailed = '녹음 추가에 실패했습니다';

  // -- Add External Link Sheet --

  /// 외부 링크 추가 (add external link sheet title)
  static const addExternalLinkTitle = '외부 링크 추가';

  /// https://... (generic url hint)
  static const externalLinkUrlHint = 'https://...';

  /// 예: 바이올린 활잡기 영상 (external link title hint)
  static const externalLinkTitleHint = '예: 바이올린 활잡기 영상';

  /// 참고할 내용을 적어주세요 (reference content hint)
  static const referenceContentHint = '참고할 내용을 적어주세요';

  /// 악보, 강의 영상, 참고 자료 등 모든 URL을 추가할 수 있습니다 (external link info hint)
  static const externalLinkInfoHint = '악보, 강의 영상, 참고 자료 등 모든 URL을 추가할 수 있습니다';

  /// 링크 추가에 실패했습니다 (external link add failed snack)
  static const externalLinkAddFailed = '링크 추가에 실패했습니다';

  // -- Practice Items Section --

  /// 이번 주 연습 과제를 추가해보세요 (teacher empty state)
  static const practiceItemEmptyTeacher = '이번 주 연습 과제를 추가해보세요';

  /// 아직 연습 과제가 없습니다 (student empty state)
  static const practiceItemEmptyStudent = '아직 연습 과제가 없습니다';

  /// 이번 주 연습 (weekly practice summary label)
  static const weeklyPracticeLabel = '이번 주 연습';

  /// {completed} / {total} 완료 (practice completion fraction)
  static String practiceCompletionFraction(int completed, int total) =>
      '$completed / $total 완료';

  /// {n}회 (practice count times)
  static String practiceCountTimes(int n) => '$n회';

  // -- Resource Attachment Section --

  /// 자료 첨부 (attach resource button)
  static const attachResource = '자료 첨부';

  /// 학습 자료 추가 (add learning resource sheet title)
  static const addLearningResourceTitle = '학습 자료 추가';

  /// 라이브러리에서 선택 (select from library option)
  static const selectFromLibrary = '라이브러리에서 선택';

  /// 유튜브 링크 추가 (add youtube link option)
  static const addYoutubeLink = '유튜브 링크 추가';

  /// 내 학습 자료 (my learning resources sheet title)
  static const myLearningResources = '내 학습 자료';

  /// 등록된 자료가 없습니다 (no resources registered)
  static const noResourcesRegistered = '등록된 자료가 없습니다';

  /// 자료를 불러올 수 없습니다 (resource load failed)
  static const resourceLoadFailed = '자료를 불러올 수 없습니다';

  /// 링크를 열 수 없습니다 (url launcher error)
  static const cannotOpenLink = '링크를 열 수 없습니다';

  /// 학습 자료 (N) — 첨부된 자료 개수 라벨
  static String learningResourceCount(int count) => '학습 자료 ($count)';

  // ── Lesson Form / Edit Dialogs (레슨 작성/편집 30차 5-2c-5) ─────

  /// 작성 취소 (lesson form exit confirm title)
  static const cancelWritingTitle = '작성 취소';

  /// 입력한 내용이 저장되지 않습니다 — 정말 나가시겠습니까?
  static const exitWithoutSavingConfirm = '입력한 내용이 저장되지 않습니다.\n정말 나가시겠습니까?';

  /// 계속 작성 (continue writing action)
  static const continueWriting = '계속 작성';

  /// 나가기 (exit action)
  static const exitAction = '나가기';

  /// 변경사항 취소 (cancel changes confirm title)
  static const cancelChangesTitle = '변경사항 취소';

  /// 변경한 내용이 저장되지 않습니다 — 정말 나가시겠습니까?
  static const exitChangesWithoutSavingConfirm =
      '변경한 내용이 저장되지 않습니다.\n정말 나가시겠습니까?';

  /// 계속 수정 (continue editing action)
  static const continueEditing = '계속 수정';

  /// 프로필 보기 (view profile action)
  static const viewProfileAction = '프로필 보기';

  /// 닫기 (close action)
  static const closeAction = '닫기';

  /// 레슨 곡 (lesson content field label)
  static const lessonSongLabel = '레슨 곡';

  /// 레슨할 곡이나 내용을 입력하세요 (lesson content hint)
  static const lessonContentHint = '레슨할 곡이나 내용을 입력하세요';

  /// 메모 (memo field label)
  static const memoLabel = '메모';

  /// 레슨 시 참고할 내용을 입력하세요 (lesson note hint)
  static const lessonNoteHint = '레슨 시 참고할 내용을 입력하세요';

  // -- Tip Template Bottom Sheet (팁 템플릿 바텀시트) --

  /// 템플릿 선택 (template picker title)
  static const templatePickerTitle = '템플릿 선택';

  /// 새 템플릿 (new template button)
  static const newTemplateButton = '새 템플릿';

  /// 템플릿 검색... (template search hint)
  static const templateSearchHint = '템플릿 검색...';

  /// 템플릿 사용 기록에 실패했습니다. 다시 시도해주세요.
  static const templateUsageRecordFailed = '템플릿 사용 기록에 실패했습니다. 다시 시도해주세요.';

  /// 새 템플릿 추가 (add new template title)
  static const addNewTemplateTitle = '새 템플릿 추가';

  /// 템플릿 내용을 입력하세요 (template content hint)
  static const templateContentHint = '템플릿 내용을 입력하세요';

  /// 템플릿이 추가되었습니다 (template added snackbar)
  static const templateAdded = '템플릿이 추가되었습니다';

  /// 템플릿에서 (from template button)
  static const fromTemplate = '템플릿에서';

  /// 직접 입력하세요... (manual input hint)
  static const manualInputHint = '직접 입력하세요...';

  /// {name} 학생 (student suffix label in dialogs)
  static String studentNameSuffix(String name) => '$name 학생';

  /// 학생에게 레슨 취소 알림이 전송됩니다.
  static const cancelLessonNotificationNotice = '학생에게 레슨 취소 알림이 전송됩니다.';

  /// 이 레슨을 삭제하시겠습니까?\n\n삭제된 레슨은 복구할 수 없습니다.
  static const deleteLessonNoRestoreConfirm =
      '이 레슨을 삭제하시겠습니까?\n\n삭제된 레슨은 복구할 수 없습니다.';

  /// 자주 사용 (frequently used templates section header)
  static const frequentlyUsed = '자주 사용';

  /// 카테고리 (category label)
  static const categoryLabel = '카테고리';

  /// 템플릿을 불러오는데 실패했습니다 (template list load error)
  static const templateLoadFailed = '템플릿을 불러오는데 실패했습니다';

  /// {N}회 (template usage count short label)
  static String usageCountShort(int count) => '$count회';

  /// {N}회 사용됨 (template usage count long label)
  static String usageCountUsed(int count) => '$count회 사용됨';

  // ── Subscription Domain (수강권 도메인 30차 5-3a) ─────────────────

  // -- Expiry Monitor (수강권 만료 알림) --

  /// 수강권 만료 임박 (D-day 알림 제목)
  static String subscriptionExpiringTitle(int daysLeft) =>
      '수강권이 $daysLeft일 후 만료됩니다';

  /// 수강권 만료 임박 본문 (남은 횟수 안내 + CTA)
  static String subscriptionExpiringBody(int remaining) =>
      '남은 횟수 $remaining회 · 갱신 요청을 보내보세요';

  /// 수강권 확인 (액션 라벨)
  static const subscriptionViewAction = '수강권 확인';

  /// 수강권 횟수 모두 소진 (low lessons 알림 제목)
  static const subscriptionLessonsExhaustedTitle = '수강권 횟수를 모두 사용했습니다';

  /// 수강권 1회 남음 (low lessons 알림 제목)
  static const subscriptionLastLessonTitle = '수강권이 마지막 1회 남았습니다';

  /// 갱신 요청 안내 본문 (low lessons / expired 공용)
  static const subscriptionRenewalRequestBody = '갱신 요청을 보내 레슨을 이어가세요';

  /// 갱신 요청 (액션 라벨)
  static const subscriptionRenewalAction = '갱신 요청';

  /// 수강권 만료 (이미 만료된 알림 제목)
  static const subscriptionExpiredTitle = '수강권이 만료되었습니다';

  // -- Proposal Reminder (제안 리마인더 알림) --

  /// 24h 리마인더 제목
  static const proposalReminder24hTitle = '수강권 제안이 기다리고 있어요';

  /// 24h 리마인더 본문
  static const proposalReminder24hBody = '선생님의 수강권 제안을 확인해보세요.';

  /// 48h 리마인더 제목
  static const proposalReminder48hTitle = '수강권 제안 확인이 필요해요';

  /// 48h 리마인더 본문
  static const proposalReminder48hBody = '선생님의 수강권 제안을 아직 확인하지 않으셨어요.';

  /// 72h 리마인더 제목 (할인 종료 경고)
  static const proposalReminder72hTitleDiscount = '⏰ 특별 할인이 곧 종료됩니다!';

  /// 72h 리마인더 제목 (일반)
  static const proposalReminder72hTitleNoDiscount = '수강권 제안 마지막 알림';

  /// 72h 리마인더 본문 (할인 종료 경고)
  static const proposalReminder72hBodyDiscount = '할인 혜택이 곧 종료됩니다. 지금 확인하세요!';

  /// 72h 리마인더 본문 (일반)
  static const proposalReminder72hBodyNoDiscount = '선생님의 수강권 제안을 확인해주세요.';

  /// 제안 확인하기 (액션 라벨)
  static const proposalReminderAction = '제안 확인하기';

  // -- Skip Reason Dialog (제안 스킵 다이얼로그) --

  /// 이번엔 스킵 (다이얼로그 제목)
  static const skipProposalTitle = '이번엔 스킵';

  /// 스킵 확인 본문
  static const skipProposalContent = '이번 제안을 스킵하시겠습니까?\n나중에 다시 제안받을 수 있어요.';

  /// 사유 (선택) (입력 필드 라벨)
  static const skipReasonLabel = '사유 (선택)';

  /// 선생님께 전달할 메시지 (입력 필드 힌트)
  static const skipReasonHint = '선생님께 전달할 메시지';

  /// 스킵하기 (확인 버튼)
  static const skipProposalAction = '스킵하기';

  // -- Template Choice Card (수강권 템플릿 카드) --

  /// 추천 (배지)
  static const templateRecommendedBadge = '추천';

  /// 가격 · 유효 N일 (가격 + 유효기간 한 줄)
  static String templatePriceValidity({
    required String price,
    required int days,
  }) => '$price  ·  유효 $days일';

  /// 주 1회 기준 약 N개월 (사용 기간 추정)
  static String templateMonthlyEstimate(String monthsLabel) =>
      '주 1회 기준 약 $monthsLabel개월';

  /// 회당 가격 (단가 라벨)
  static String templateUnitPriceLabel(String price) => '회당 $price';

  /// 선택하기 (수락 버튼)
  static const templateChooseButton = '선택하기';

  /// ⭐ 추천 (selectable template card 배지 — 별 포함)
  static const templateRecommendedBadgeStar = '⭐ 추천';

  /// N회 · M분 · 유효기간 (selectable template card 요약 라인)
  static String templateSummaryLine({
    required int totalLessons,
    required int durationMinutes,
    required String validityLabel,
  }) => '$totalLessons회 · $durationMinutes분 · $validityLabel';

  /// (1회 가격) (selectable template card 회당 가격 부가 라벨)
  static String templatePerLessonPrice(String price) => '(1회 $price)';

  // -- Subscription Policy Sheet (적용 정책 바텀시트) --

  /// 적용 정책 (시트 제목)
  static const policyAppliedTitle = '적용 정책';

  /// 변경 / 취소 (정책 항목 라벨)
  static const policyChangeCancelLabel = '변경 / 취소';

  /// 노쇼 (정책 항목 라벨)
  static const policyNoShowLabel = '노쇼';

  /// 이월 (정책 항목 라벨)
  static const policyCarryoverLabel = '이월';

  /// 변경/취소 정책 요약 (마감시간/월 한도/잔여)
  static String policyChangeSummary({
    required int deadlineHours,
    required int totalAllowance,
    required int remaining,
  }) => '$deadlineHours시간 전까지 · 월 $totalAllowance회 (남은 $remaining회)';

  /// 정책 적용 시점 안내 푸터
  static const policyAppliedFooter =
      '수강권 발급 시점의 정책이 적용됩니다. 선생님이 이후 정책을 변경해도 이 수강권에는 영향을 주지 않습니다.';

  // -- Issue Form Type Options (수강권 발급 폼 타입 옵션) --

  /// 회차 (패키지 회차 입력 라벨)
  static const issueFormLessonsTitle = '회차';

  /// 회 (회차 단위)
  static const issueFormLessonsSuffix = '회';

  /// 유효기간 (유효기간 입력 라벨)
  static const issueFormValidityTitle = '유효기간';

  /// 일 (유효기간 단위)
  static const issueFormValiditySuffix = '일';

  /// 기간 선택 (월정기 옵션 섹션 제목)
  static const issueFormMonthlySectionTitle = '기간 선택';

  /// N개월 (월정기 칩 라벨)
  static String issueFormMonthsLabel(int months) => '$months개월';

  /// 체험 레슨 안내
  static const issueFormTrialNotice =
      '체험 레슨은 1회 수강권이 발급됩니다.\n무료 또는 할인된 금액으로 설정할 수 있습니다.';

  // -- Issue Form Sections (수강권 발급 폼 섹션 5-3b-2a) --

  /// 수강권 유형 (섹션 제목)
  static const issueFormTypeSectionTitle = '수강권 유형';

  /// 체험 (수강권 유형 칩 라벨)
  static const issueFormTypeTrialLabel = '체험';

  /// 회차제 (수강권 유형 칩 라벨)
  static const issueFormTypePackageLabel = '회차제';

  /// 월정액 (수강권 유형 칩 라벨)
  static const issueFormTypeMonthlyLabel = '월정액';

  /// 체험 수강권 설명
  static const issueFormTypeTrialDescription =
      '1회 체험 레슨으로, 학생과 선생님의 적합성을 확인합니다. 무료 또는 할인 금액으로 설정할 수 있습니다.';

  /// 회차제 수강권 설명
  static const issueFormTypePackageDescription =
      '정해진 횟수만큼 레슨을 진행합니다. 매 레슨마다 유연하게 스케줄을 조율할 수 있습니다.';

  /// 월정액 수강권 설명
  static const issueFormTypeMonthlyDescription =
      '월 단위 정기 수강권입니다. 고정된 요일·시간에 레슨이 자동 배정되어 스케줄 관리가 편리합니다.';

  /// 입금 확인 방식 (섹션 제목)
  static const issueFormPaymentSectionTitle = '입금 확인 방식';

  /// 선불 (입금 확인 칩 라벨)
  static const issueFormPaymentPrepaidLabel = '선불';

  /// 후불 (입금 확인 칩 라벨)
  static const issueFormPaymentPostpaidLabel = '후불';

  /// 후불 수강권 안내
  static const issueFormPaymentPostpaidNotice =
      '후불 수강권은 입금 확인 대기로 표시됩니다. 입금 확인 후 완료 처리할 수 있습니다.';

  /// 정가 (섹션 제목)
  static const issueFormAmountSectionTitle = '정가';

  /// N만원 (금액 프리셋 칩 라벨)
  static String issueFormAmountChipLabel(int amount) => '${amount ~/ 10000}만원';

  /// 직접 입력 (금액 입력 hint)
  static const issueFormAmountHint = '직접 입력';

  /// 원 (금액 단위)
  static const issueFormAmountSuffix = '원';

  /// 금액 입력 검증 메시지
  static const issueFormAmountValidation = '금액을 입력해주세요';

  /// 회당 N (회당 금액 라벨)
  static String issueFormPerLessonAmount(String price) => '회당 $price';

  /// 시작일 (섹션 제목)
  static const issueFormStartDateSectionTitle = '시작일';

  /// 날짜 선택 (시작일 placeholder)
  static const issueFormStartDateHint = '날짜 선택';

  // -- Issue Form Membership (멤버십 선택) --

  /// 레슨 선택 (섹션 제목)
  static const issueFormMembershipSectionTitle = '레슨 선택';

  /// 개인레슨 (멤버십 기본 이름)
  static const issueFormMembershipDefaultName = '개인레슨';

  /// 레슨 (오류 시 fallback)
  static const issueFormMembershipFallback = '레슨';

  /// 레벨 미설정
  static const issueFormMembershipNoLevel = '레벨 미설정';

  /// 등록된 레슨이 없습니다 (빈 상태 제목)
  static const issueFormNoMembershipTitle = '등록된 레슨이 없습니다';

  /// 빈 상태 안내
  static const issueFormNoMembershipBody = '학생을 레슨에 먼저 등록해주세요.';

  /// 오류가 발생했습니다 (에러 상태 제목)
  static const issueFormErrorTitle = '오류가 발생했습니다';

  // -- Issue Form Discount/Bonus (할인·보너스) --

  /// 할인 (섹션 제목)
  static const issueFormDiscountTitle = '할인';

  /// % (퍼센트 단위)
  static const issueFormPercentSuffix = '%';

  /// 없음 (zero 라벨)
  static const issueFormZeroLabel = '없음';

  /// 보너스 (섹션 제목)
  static const issueFormBonusTitle = '보너스';

  /// +N회 (보너스 라벨 포매터)
  static String issueFormBonusFormatter(int value) =>
      value == 0 ? '없음' : '+$value회';

  /// 대량 구매 (보너스 사유)
  static const issueFormBonusReasonBulk = '대량 구매';

  /// 5주차 (보너스 사유)
  static const issueFormBonusReasonFifthWeek = '5주차';

  /// 추천 (보너스 사유)
  static const issueFormBonusReasonReferral = '추천';

  /// 재등록 (보너스 사유)
  static const issueFormBonusReasonRenewal = '재등록';

  /// 기타 (보너스 사유)
  static const issueFormBonusReasonOther = '기타';

  /// 사유를 직접 입력해주세요 (custom 사유 hint)
  static const issueFormBonusReasonCustomHint = '사유를 직접 입력해주세요';

  // -- Issue Form Summary Widgets (수강권 발급 요약 카드 5-3b-6) --

  /// 발급 요약 (요약 카드 제목)
  static const issueFormSummaryTitle = '발급 요약';

  /// 배치 발급 요약 (배치 요약 카드 제목)
  static const issueFormSummaryBatchTitle = '배치 발급 요약';

  /// 유형 (요약 행 라벨)
  static const issueFormSummaryTypeLabel = '유형';

  /// 입금 예정 금액 (요약 행 라벨)
  static const issueFormSummaryFinalAmountLabel = '입금 예정 금액';

  /// 금액 (요약 행 라벨)
  static const issueFormSummaryAmountLabel = '금액';

  /// 입금 상태 (요약 행 라벨)
  static const issueFormSummaryPaymentLabel = '입금 상태';

  /// 만료일 (요약 행 라벨)
  static const issueFormSummaryEndDateLabel = '만료일';

  /// 입금 확인 대기 (후불) (입금 미확인 시 표기)
  static const issueFormSummaryUnpaidLabel = '입금 확인 대기 (후불)';

  /// $method (확인됨) (입금 확인 시 표기)
  static String issueFormSummaryPaymentConfirmed(String method) =>
      '$method (확인됨)';

  /// -$amount ($percent%) (할인 요약 표기)
  static String issueFormSummaryDiscountValue(String amount, int percent) =>
      '-$amount ($percent%)';

  /// +$bonus회 ($reason) 또는 +$bonus회 (보너스 요약 표기)
  static String issueFormSummaryBonusValue(int bonus, String? reason) =>
      reason != null ? '+$bonus회 ($reason)' : '+$bonus회';

  /// $deadline시간 전까지 · 월 $allowance회 (정책 변경/취소 요약)
  static String issueFormSummaryPolicyChangeLine(int deadline, int allowance) =>
      '$deadline시간 전까지 · 월 $allowance회';

  /// 체험 (1회) (수강권 유형 표시)
  static const issueFormSummaryLessonsTrial = '체험 (1회)';

  /// 회차제 ($total + $bonus회, $days일) (보너스 포함 패키지 표시)
  static String issueFormSummaryLessonsPackageWithBonus(
    int total,
    int bonus,
    int days,
  ) => '회차제 ($total + $bonus회, $days일)';

  /// 회차제 ($total회, $days일) (패키지 표시)
  static String issueFormSummaryLessonsPackage(int total, int days) =>
      '회차제 ($total회, $days일)';

  /// 월정액 ($months개월) (월정액 표시)
  static String issueFormSummaryLessonsMonthly(int months) => '월정액 ($months개월)';

  /// $count명의 학생에게 동일한 수강권을 발급합니다 (배치 배너 제목)
  static String issueFormBatchBannerTitle(int count) =>
      '$count명의 학생에게 동일한 수강권을 발급합니다';

  /// 각 학생에게 개별 수강권이 생성됩니다 (배치 배너 본문)
  static const issueFormBatchBannerBody = '각 학생에게 개별 수강권이 생성됩니다';

  /// 발급 대상 (배치 요약 라벨)
  static const issueFormBatchTargetLabel = '발급 대상';

  /// $count명 (배치 학생 수 표기)
  static String issueFormBatchStudentCount(int count) => '$count명';

  /// 개인당 금액 (배치 요약 라벨)
  static const issueFormBatchPerPersonLabel = '개인당 금액';

  /// 총 예상 금액 (배치 요약 라벨)
  static const issueFormBatchTotalLabel = '총 예상 금액';

  // -- Proposal Card Widgets (제안 카드 5-3b-7) --

  /// 입금 확인을 기다리고 있습니다 (paymentNotified 배너)
  static const proposalBannerPaymentNotified = '입금 확인을 기다리고 있습니다';

  /// 수강권이 발급되었습니다! (confirmed 배너)
  static const proposalBannerConfirmed = '수강권이 발급되었습니다!';

  /// 스킵한 제안입니다 (rejected 배너)
  static const proposalBannerRejected = '스킵한 제안입니다';

  /// 제안이 만료되었습니다 (expired 배너)
  static const proposalBannerExpired = '제안이 만료되었습니다';

  /// 선생님이 제안을 취소했습니다 (cancelled 배너)
  static const proposalBannerCancelled = '선생님이 제안을 취소했습니다';

  /// 선생님 제안 (헤더 카드 부제)
  static const proposalHeaderSubtitle = '선생님 제안';

  /// 횟수 (디테일 행 라벨)
  static const proposalDetailsLessonsLabel = '횟수';

  /// $count회 (횟수 값 포매터)
  static String proposalDetailsLessonsValue(int count) => '$count회';

  /// 레슨시간 (디테일 행 라벨)
  static const proposalDetailsDurationLabel = '레슨시간';

  /// 입금 확인일로부터 $validity (유효기간 값 포매터)
  static String proposalDetailsValidityValue(String validity) =>
      '입금 확인일로부터 $validity';

  /// 선생님 메시지 (메시지 카드 라벨)
  static const proposalMessageCardLabel = '선생님 메시지';

  /// 할인 적용 (할인 카드 기본 사유)
  static const proposalDiscountReasonDefault = '할인 적용';

  /// 입금 예정 금액 (할인 카드 최종 라벨)
  static const proposalDiscountFinalLabel = '입금 예정 금액';

  /// $man만원 (가격 포매터: 만 단위 정확히)
  static String proposalPriceManwon(int man) => '$man만원';

  /// $man만 $remainder원 (가격 포매터: 만 + 나머지)
  static String proposalPriceManRemainder(int man, int remainder) =>
      '$man만 $remainder원';

  /// $price원 (가격 포매터: 만 미만)
  static String proposalPriceWon(int price) => '$price원';

  /// 계좌 미등록 (입금 정보 카드 fallback)
  static const proposalPaymentBankNotRegistered = '계좌 미등록';

  /// 입금 정보 (입금 정보 카드 제목)
  static const proposalPaymentInfoTitle = '입금 정보';

  /// 은행 (입금 정보 행 라벨)
  static const proposalPaymentBankLabel = '은행';

  /// 계좌번호 (입금 정보 행 라벨)
  static const proposalPaymentAccountNumberLabel = '계좌번호';

  /// 예금주 (입금 정보 행 라벨)
  static const proposalPaymentAccountHolderLabel = '예금주';

  /// 계좌 변경 (입금 정보 다중 계좌 셀렉터)
  static const proposalPaymentAccountChange = '계좌 변경';

  /// 계좌번호가 복사되었습니다 (스낵바)
  static const proposalPaymentAccountCopied = '계좌번호가 복사되었습니다';

  /// 복사 (입금 정보 카피 버튼 라벨)
  static const proposalPaymentCopyLabel = '복사';

  /// 입금 확인 대기중 (대기 카드 제목)
  static const proposalWaitingTitle = '입금 확인 대기중';

  /// 대기 카드 본문 (멀티라인)
  static const proposalWaitingBody =
      '선생님이 입금을 확인하면 수강권이 발급됩니다.\n입금 확인까지 1~2일 정도 소요될 수 있습니다.';

  /// 선생님께 문의하기 (대기 카드 CTA)
  static const proposalWaitingContactCta = '선생님께 문의하기';

  // -- Subscription Domain Services (자동 제안/갱신 메시지 5-3b-8) --

  /// 골든타임 할인 사유 (자동 제안)
  static String autoProposalGoldenTimeReason(int percent, int hours) =>
      '골든타임 할인 ($percent%, $hours시간 이내)';

  /// 자동 제안 메시지 인사 ("체험레슨 수고하셨습니다! ")
  static const autoProposalGreeting = '체험레슨 수고하셨습니다! ';

  /// 자동 제안 골든타임 안내 ("N시간 이내 등록 시 ")
  static String autoProposalGoldenTimeHours(int hours) => '$hours시간 이내 등록 시 ';

  /// 자동 제안 골든타임 할인율 ("N% 할인이 적용됩니다. ")
  static String autoProposalGoldenTimePercent(int percent) =>
      '$percent% 할인이 적용됩니다. ';

  /// 자동 제안 마무리 ("원하시는 수강권을 선택해주세요.")
  static const autoProposalSelectionPrompt = '원하시는 수강권을 선택해주세요.';

  /// 갱신 메시지 — 모두 소진 ("수강권이 모두 소진되었습니다. ")
  static const renewalMessageDepleted = '수강권이 모두 소진되었습니다. ';

  /// 갱신 메시지 — 마지막 1회 ("수강권이 마지막 1회 남았습니다. ")
  static const renewalMessageLastOne = '수강권이 마지막 1회 남았습니다. ';

  /// 갱신 메시지 — N회 남음 ("수강권이 N회 남았습니다. ")
  static String renewalMessageRemaining(int count) => '수강권이 $count회 남았습니다. ';

  /// 갱신 메시지 마무리 ("이전과 동일한 수강권으로 레슨을 이어가세요.")
  static const renewalMessageContinue = '이전과 동일한 수강권으로 레슨을 이어가세요.';

  // ─── Subscription entities (P2 5-3b-2) ───────────────────────

  // LessonPolicy summaries
  /// 당일 취소 가능
  static const policyCancelSameDay = '당일 취소 가능';

  /// N시간 전까지 취소 가능
  static String policyCancelMinHours(int hours) => '$hours시간 전까지 취소 가능';

  /// 변경 불가
  static const policyChangeNone = '변경 불가';

  /// 무제한 변경 가능
  static const policyChangeUnlimited = '무제한 변경 가능';

  /// 월 N회 변경 가능
  static String policyChangeMonthly(int max) => '월 $max회 변경 가능';

  /// 노쇼 시 횟수 차감
  static const policyNoShowDeduct = '노쇼 시 횟수 차감';

  /// 노쇼 시 횟수 유지
  static const policyNoShowKeep = '노쇼 시 횟수 유지';

  /// 이월 불가
  static const policyCarryoverNone = '이월 불가';

  /// 최대 N회 이월 (M개월 내)
  static String policyCarryoverMax(int max, int months) =>
      '최대 $max회 이월 ($months개월 내)';

  // SubscriptionUsage labels & default notes
  /// 정상 수업
  static const usageTypeNormal = '정상 수업';

  /// 당일 취소
  static const usageTypeLateCancellation = '당일 취소';

  /// 학생 결석
  static const usageTypeStudentAbsent = '학생 결석';

  /// 변경 수업
  static const usageTypeRescheduled = '변경 수업';

  /// 당일 취소 (24시간 이내)
  static const usageNoteLateCancellation = '당일 취소 (24시간 이내)';

  // SubscriptionSettings 디폴트 description
  /// 대량 구매 보너스
  static const bulkPurchaseBonus = '대량 구매 보너스';

  // ProposalPaymentStatus
  /// 입금 확인 대기
  static const proposalPaymentStatusPending = '입금 확인 대기';

  /// 입금 확인 완료
  static const proposalPaymentStatusCompleted = '입금 확인 완료';

  /// 입금 확인 필요
  static const proposalPaymentDescPending = '입금 확인 필요';

  /// 이미 입금 확인됨
  static const proposalPaymentDescCompleted = '이미 입금 확인됨';

  // ProposalStatus
  /// 제안됨
  static const proposalStatusPending = '제안됨';

  /// 입금 알림
  static const proposalStatusPaymentNotified = '입금 알림';

  /// 발급 완료
  static const proposalStatusConfirmed = '발급 완료';

  /// 스킵됨
  static const proposalStatusRejected = '스킵됨';

  /// 취소됨
  static const proposalStatusCancelled = '취소됨';

  // ProposalType
  /// 제안 (action 라벨)
  static const proposalTypeProposal = '제안';

  /// 즉시 발급
  static const proposalTypeDirectIssue = '즉시 발급';

  // 시간 경과 / 만료 표시
  /// N일 전
  static String timeAgoDays(int days) => '$days일 전';

  /// N시간 전
  static String timeAgoHours(int hours) => '$hours시간 전';

  /// N분 전
  static String timeAgoMinutes(int minutes) => '$minutes분 전';

  /// 방금 전
  static const timeAgoJustNow = '방금 전';

  /// N일 후 만료
  static String expiresInDays(int days) => '$days일 후 만료';

  /// N시간 후 만료
  static String expiresInHours(int hours) => '$hours시간 후 만료';

  /// N분 후 만료
  static String expiresInMinutes(int minutes) => '$minutes분 후 만료';

  /// 곧 만료
  static const expiresVerySoon = '곧 만료';

  // SubscriptionPaymentMethod
  /// 현금
  static const paymentMethodCash = '현금';

  /// 계좌이체
  static const paymentMethodBankTransfer = '계좌이체';

  /// 카드 (레거시)
  static const paymentMethodCard = '카드(레거시)';

  /// 기타 (입금 수단)
  static const paymentMethodOther = '기타';

  // Subscription payment status / type / status / summary
  /// 입금 확인 완료
  static const paymentStatusPaid = '입금 확인 완료';

  /// 입금 확인 대기
  static const paymentStatusUnpaid = '입금 확인 대기';

  /// 체험 (수강권 유형)
  static const subscriptionTypeTrial = '체험';

  /// 월정액 (N회) — 형식
  static String subscriptionTypeMonthlyWithCount(int count) => '월정액 ($count회)';

  /// N회권 — 패키지 라벨
  static String subscriptionTypePackageWithCount(int total) => '$total회권';

  /// 이용중 (status)
  static const subscriptionStatusActive = '이용중';

  /// 만료 임박 (status)
  static const subscriptionStatusExpiringSoon = '만료 임박';

  /// 만료됨 (status)
  static const subscriptionStatusExpired = '만료됨';

  /// 일시정지 (status)
  static const subscriptionStatusPaused = '일시정지';

  /// 체험 완료
  static const trialCompleted = '체험 완료';

  /// 체험중
  static const trialOngoing = '체험중';

  /// N회 모두 사용 (depleted)
  static String subscriptionAllUsed(int total) => '$total회 모두 사용';

  /// N회 미사용 (만료됨)
  static String subscriptionUnusedExpired(int remaining) =>
      '$remaining회 미사용 (만료됨)';

  /// remaining/total회 남음
  static String subscriptionRemainingOf(int remaining, int total) =>
      '$remaining/$total회 남음';

  /// D-N
  static String daysUntilExpirationFormat(int days) => 'D-$days';

  /// summary 합성: "$count ($daysOrStatus)"
  static String subscriptionSummaryWithDays(
    String count,
    String daysOrStatus,
  ) => '$count ($daysOrStatus)';

  /// 보너스 (디폴트 사유)
  static const bonusDefault = '보너스';

  /// 🎁 +N회 (사유) — bonusText
  static String bonusText(int count, String reason) => '🎁 +$count회 ($reason)';

  /// 체험 레슨 (금액)
  static String trialLessonWithAmount(String amount) => '체험 레슨 ($amount)';

  /// 무료 체험 레슨
  static const freeTrialLesson = '무료 체험 레슨';

  /// 기본: N회 (월정액 detail)
  static String detailBaseLessons(int base) => '기본: $base회';

  /// N회권 중 M회 사용 (package detail)
  static String detailPackageUsage(int base, int used) => '$base회권 중 $used회 사용';

  /// \n보너스: +N회 (detail 보너스 라인)
  static String detailBonusLine(int count) => '\n보너스: +$count회';

  /// (사유) — 보너스 사유 인라인 부착
  static String detailBonusReasonInline(String reason) => ' ($reason)';

  /// N만원
  // ignore: unnecessary_brace_in_string_interps
  static String amountManwon(String value) => '${value}만원';

  /// N원
  static String amountWon(int amount) => '$amount원';

  /// 회차 기준 입금 (BillingType.perPackage)
  static const billingTypePerPackage = '회차 기준 입금';

  /// 월정액 (매월 N일) — BillingType.monthly with day
  static String billingTypeMonthlyWithDay(int day) => '월정액 (매월 $day일)';

  /// 휴강 (FifthWeekPolicy.skip)
  static const fifthWeekSkip = '휴강';

  /// 보너스 지급 (FifthWeekPolicy.bonus)
  static const fifthWeekBonus = '보너스 지급';

  /// 기존에서 차감 (FifthWeekPolicy.deduct)
  static const fifthWeekDeduct = '기존에서 차감';

  /// 학생 선택 (FifthWeekPolicy.optional)
  static const fifthWeekOptional = '학생 선택';

  // -- Location & Travel Selector (위치/이동시간 선택 5-3b-4) --

  /// 학생 집 (LocationType.studentHome chip label)
  static const locationStudentHomeLabel = '학생 집';

  /// 외부 스튜디오 (LocationType.externalPlace chip label)
  static const locationExternalPlaceLabel = '외부 스튜디오';

  /// 선생님 집 (LocationType.teacherStudio chip label)
  static const locationTeacherHomeLabel = '선생님 집';

  /// 온라인 (LocationType.online chip label)
  static const locationOnlineLabel = '온라인';

  /// 이 학생의 기본 레슨 장소를 선택하세요 (lesson location section description)
  static const lessonLocationDescription = '이 학생의 기본 레슨 장소를 선택하세요';

  /// 학원 주소 (자동) (academy auto address)
  static const locationAcademyAddressAuto = '학원 주소 (자동)';

  /// 선생님 스튜디오 (자동) (teacher studio auto address)
  static const locationTeacherStudioAddressAuto = '선생님 스튜디오 (자동)';

  /// 이동시간 없음 (online — no travel)
  static const locationOnlineNoTravel = '이동시간 없음';

  /// 학생 주소 미등록 (student home address empty warning)
  static const locationStudentAddressEmpty = '학생 주소 미등록';

  /// 주소 불러오는 중... (address loading)
  static const locationAddressLoading = '주소 불러오는 중...';

  /// 주소 조회 실패 (address fetch failed)
  static const locationAddressFetchFailed = '주소 조회 실패';

  /// 외부 장소 주소 (external place address input label)
  static const locationExternalAddressLabel = '외부 장소 주소';

  /// 예: 강남 OO 스튜디오 (external place address input hint)
  static const locationExternalAddressHint = '예: 강남 OO 스튜디오';

  /// 이동시간 (travel time section title)
  static const travelTimeLabel = '이동시간';

  /// 없음 (travel time dropdown 0 label)
  static const travelTimeNone = '없음';

  /// 스케줄에서 레슨 시작 전 이동 블록으로 표시됩니다 (travel time helper)
  static const travelTimeDescription = '스케줄에서 레슨 시작 전 이동 블록으로 표시됩니다';

  // -- Expiring Subscriptions Screen (수강권 임박 화면 5-3b-6) --

  /// N명의 학생 (subtitle: count of students with expiring subscriptions)
  static String studentsCountSubtitle(int n) => '$n명의 학생';

  /// 학생 #ID (fallback when student name is unknown)
  static String studentNameFallback(String idShort) => '학생 $idShort';

  /// 확인이 필요한 수강권이 없습니다 (empty state title)
  static const expiringEmptyTitle = '확인이 필요한 수강권이 없습니다';

  /// 모든 학생의 수강권이 정상입니다 (empty state body)
  static const expiringEmptyBody = '모든 학생의 수강권이 정상입니다';

  // -- Issue Subscription Actions (수강권 발급 액션 5-3b-10) --

  /// 레슨을 선택해주세요 (validation: membership 미선택)
  static const chooseLessonValidation = '레슨을 선택해주세요';

  /// 시작일을 선택해주세요 (validation: startDate 미선택)
  static const chooseStartDateValidation = '시작일을 선택해주세요';

  /// 보너스 사유를 선택해주세요 (validation: bonus 사유 미선택)
  static const chooseBonusReasonValidation = '보너스 사유를 선택해주세요';

  /// $percent% 할인 (discountReason 합성)
  static String discountPercentReason(int percent) => '$percent% 할인';

  /// 수강권이 발급되었습니다 (snackbar: 단건 발급 성공)
  static const subscriptionIssueSuccess = '수강권이 발급되었습니다';

  /// 발급 실패. 다시 시도해주세요. (snackbar: 발급 실패)
  static const subscriptionIssueFailRetry = '발급 실패. 다시 시도해주세요.';

  /// $count명에게 수강권이 발급되었습니다 (snackbar: 일괄 발급 전체 성공)
  static String batchSubscriptionIssueSuccess(int count) =>
      '$count명에게 수강권이 발급되었습니다';

  /// $success명 발급 완료, $fail명 실패 (snackbar: 일괄 발급 부분 성공)
  static String batchSubscriptionIssuePartial(int success, int fail) =>
      '$success명 발급 완료, $fail명 실패';

  // -- Subscription Display Layer (badge + status colors, P2 5-3b-7a) --

  /// $remain/$total회 (badge format for package subscription)
  static String subscriptionPackageBadgeFormat(int remain, int total) =>
      '$remain/$total회';

  /// $remain/$total회 남음 (summary text for package subscription)
  static String subscriptionPackageRemainingFormat(int remain, int total) =>
      '$remain/$total회 남음';

  /// D-N 남음 (summary text for monthly subscription)
  static String subscriptionDaysRemaining(int days) => 'D-$days 남음';

  /// 체험 중 (summary text for trial subscription)
  static const subscriptionTrialActive = '체험 중';

  /// 사용 완료 (status — depleted, all lessons used)
  static const subscriptionStatusDepleted = '사용 완료';

  /// 갱신 필요 (status — expiring soon, renewal needed)
  static const subscriptionStatusRenewalNeeded = '갱신 필요';

  /// 수강권을 모두 사용했습니다 (message — depleted)
  static const subscriptionMessageDepleted = '수강권을 모두 사용했습니다';

  /// 수강권 유효기간이 지났습니다 (message — expired)
  static const subscriptionMessageExpired = '수강권 유효기간이 지났습니다';

  /// 수강권 갱신이 필요합니다 (message — renewal needed)
  static const subscriptionMessageRenewalNeeded = '수강권 갱신이 필요합니다';

  /// 수강권이 일시정지 상태입니다 (message — paused)
  static const subscriptionMessagePaused = '수강권이 일시정지 상태입니다';

  /// 수강권이 활성화되어 있습니다 (message — active)
  static const subscriptionMessageActive = '수강권이 활성화되어 있습니다';

  // -- Subscription Card (수강권 카드 5-3b-8) --

  /// 남음: $remain/$total회 (subscription_card.dart 진행바 라벨)
  static String subscriptionRemainingPrefix(int remain, int total) =>
      '남음: $remain/$total회';

  /// (기본 $base + 보너스 $bonus) (subscription_card.dart 보너스 분해 표기)
  static String subscriptionBonusBreakdown(int base, int bonus) =>
      '(기본 $base + 보너스 $bonus)';

  /// 📋 상세 (subscription_card.dart 상세 섹션 헤더)
  static const subscriptionDetailHeader = '📋 상세';

  /// • 기본 (subscription_card.dart 상세 행 라벨)
  static const subscriptionDetailRowBase = '• 기본';

  /// • 보너스
  static const subscriptionDetailRowBonus = '• 보너스';

  /// • 사용
  static const subscriptionDetailRowUsed = '• 사용';

  /// • 잔여
  static const subscriptionDetailRowRemaining = '• 잔여';

  /// • 변경
  static const subscriptionDetailRowChanges = '• 변경';

  /// • 유효기간
  static const subscriptionDetailRowExpiry = '• 유효기간';

  /// • 입금
  static const subscriptionDetailRowPayment = '• 입금';

  /// • 5주차
  static const subscriptionDetailRowFifthWeek = '• 5주차';

  /// 보너스 (보너스 reason 기본값 fallback)
  static const subscriptionBonusReasonFallback = '보너스';

  /// ⚠️ 미사용분 소멸 (이월 불가) (월정액 카드 경고)
  static const subscriptionMonthlyCarryoverWarning = '⚠️ 미사용분 소멸 (이월 불가)';

  /// 유효기간 내 자유롭게 사용 (회차권 카드 안내)
  static const subscriptionPackageFreeUseInfo = '유효기간 내 자유롭게 사용';

  // -- Proposal Confirm Screen (입금 확인 5-3b-9) --

  /// 입금 확인 대기 중인 제안이 없습니다 (빈 상태 타이틀)
  static const proposalConfirmEmptyTitle = '입금 확인 대기 중인 제안이 없습니다';

  /// 학생이 입금 완료를 알리면 여기에 표시됩니다 (빈 상태 본문)
  static const proposalConfirmEmptyBody = '학생이 입금 완료를 알리면 여기에 표시됩니다';

  /// 학생 정보 오류 (학생 로딩 실패 fallback)
  static const studentInfoError = '학생 정보 오류';

  /// 알 수 없는 학생 (학생 데이터 null fallback)
  static const unknownStudent = '알 수 없는 학생';

  /// 입금 알림: $time (제안 카드 알림 라벨)
  static String proposalPaymentNotificationFormat(String time) =>
      '입금 알림: $time';

  /// 템플릿을 찾을 수 없습니다 (템플릿 null fallback)
  static const templateNotFound = '템플릿을 찾을 수 없습니다';

  /// $total회 · $duration분 · $validity (템플릿 요약 포매터)
  static String proposalTemplateSummaryFormat(
    int total,
    int duration,
    String validity,
  ) => '$total회 · $duration분 · $validity';

  /// 입금 미확인 (Inquiry 버튼 + 다이얼로그 타이틀)
  static const paymentUnverifiedAction = '입금 미확인';

  /// 입금 확인 → 수강권 발급 (확인 버튼)
  static const paymentVerifyToIssueButton = '입금 확인 → 수강권 발급';

  /// 입금 내역을 확인할 수 없습니다.\n학생에게 확인 요청 메시지를 보내시겠습니까? (Inquiry 다이얼로그 본문)
  static const paymentInquiryDialogBody =
      '입금 내역을 확인할 수 없습니다.\n학생에게 확인 요청 메시지를 보내시겠습니까?';

  /// 메시지 보내기 (Inquiry 다이얼로그 확인 버튼)
  static const sendMessage = '메시지 보내기';

  /// 확인 요청 메시지를 보냈습니다 (Inquiry 전송 후 snackbar)
  static const inquiryMessageSent = '확인 요청 메시지를 보냈습니다';

  // -- Subscription List Screen (학생 수강권 목록 5-3b-12) --

  /// 내 수강권 (AppBar 타이틀)
  static const subscriptionListAppBarTitle = '내 수강권';

  /// 등록된 수강권이 없습니다 (수강권 0건 빈 상태 타이틀)
  static const noSubscriptionsRegisteredTitle = '등록된 수강권이 없습니다';

  /// $count개의 레슨에 등록되어 있습니다.\n선생님에게 수강권 발급을 요청하세요. (수강권 0건 본문)
  static String noSubscriptionsRegisteredBody(int count) =>
      '$count개의 레슨에 등록되어 있습니다.\n선생님에게 수강권 발급을 요청하세요.';

  /// 등록된 레슨이 없습니다 (멤버십 0건 빈 상태 타이틀)
  static const noLessonsRegisteredTitle = '등록된 레슨이 없습니다';

  /// 선생님에게 초대를 요청하거나\n체험 레슨을 신청하세요. (멤버십 0건 본문)
  static const noLessonsRegisteredBody = '선생님에게 초대를 요청하거나\n체험 레슨을 신청하세요.';

  /// 선생님 찾기 (멤버십 0건 CTA 버튼)
  static const teacherSearchButton = '선생님 찾기';

  /// 레슨 (lessonClass 로딩 실패 시 className fallback)
  static const lessonClassErrorFallback = '레슨';

  // -- Issue Subscription Screen (수강권 발급 화면 5-3b-13) --

  /// 수강권 발급 ($count명) (일괄 발급 AppBar 타이틀)
  static String batchSubscriptionAppBarTitle(int count) => '수강권 발급 ($count명)';

  /// $count명에게 수강권 발급 (일괄 발급 하단 버튼 라벨)
  static String batchIssueButtonLabel(int count) => '$count명에게 수강권 발급';

  /// 변경/취소 가능 횟수 (예약 변경 허용 횟수 섹션 제목)
  static const rescheduleAllowanceTitle = '변경/취소 가능 횟수';

  /// 학생이 예약 변경 또는 취소할 수 있는 횟수입니다. 소진 시 변경/취소 불가. (섹션 설명)
  static const rescheduleAllowanceDescription =
      '학생이 예약 변경 또는 취소할 수 있는 횟수입니다. 소진 시 변경/취소 불가.';

  /// 선생님 기본 정책: $summary (이 수강권에서 개별 조정 가능) (정책 일치 안내)
  static String rescheduleAllowanceMatchesPolicy(String summary) =>
      '선생님 기본 정책: $summary (이 수강권에서 개별 조정 가능)';

  /// 선생님 기본 정책 $summary → 이 수강권만 $count회로 재설정 (정책 override 안내)
  static String rescheduleAllowanceOverridePolicy(String summary, int count) =>
      '선생님 기본 정책 $summary → 이 수강권만 $count회로 재설정';

  /// 불가 (변경/취소 0회 chip 라벨)
  static const rescheduleAllowanceNone = '불가';

  /// 기본 정책 (정책 매치 badge)
  static const policyBadgeDefault = '기본 정책';

  /// 개별 조정됨 (정책 override badge)
  static const policyBadgeCustom = '개별 조정됨';

  // -- Student Proposal Accept Screen (학생 제안 수락 5-3b-14) --

  /// 수강권 선택 (학생 제안 수락 AppBar 타이틀)
  static const studentProposalAcceptAppBarTitle = '수강권 선택';

  /// 제안을 찾을 수 없습니다 (제안 null 빈 상태)
  static const proposalNotFoundEmpty = '제안을 찾을 수 없습니다';

  /// $name 선생님 (헤더 — 선생님 이름 + 호칭)
  static String teacherWithName(String name) => '$name $teacher';

  /// 수강권을 제안했어요 (헤더 부제)
  static const proposalSubmittedSubtitle = '수강권을 제안했어요';

  /// 다음에 할게요 (제안 거절 버튼)
  static const proposalDeclineNextTime = '다음에 할게요';

  /// 선택 후 위 계좌로 입금해 주세요 (입금 안내 캡션)
  static const paymentDepositInstruction = '선택 후 위 계좌로 입금해 주세요';

  /// 수강권을 선택했습니다 (수락 성공 SnackBar)
  static const subscriptionSelectedSnackbar = '수강권을 선택했습니다';

  /// 다음에 다시 제안 받을 수 있어요 (거절 SnackBar)
  static const proposalRejectedNextTimeSnackbar = '다음에 다시 제안 받을 수 있어요';

  // -- Proposal Create Screen (수강권 제안 생성 5-3b-15) --

  /// 수강권 제안 (생성 AppBar 타이틀)
  static const proposalCreateAppBarTitle = '수강권 제안';

  /// 등록된 학생이 없습니다 (학생 0건 빈 상태 타이틀)
  static const proposalCreateNoStudentsTitle = '등록된 학생이 없습니다';

  /// 학생을 먼저 추가해주세요 (학생 0건 빈 상태 본문)
  static const proposalCreateNoStudentsBody = '학생을 먼저 추가해주세요';

  /// 수강권 템플릿이 없습니다 (템플릿 0건 빈 상태 타이틀)
  static const proposalCreateNoTemplatesTitle = '수강권 템플릿이 없습니다';

  /// 먼저 수강권 템플릿을 생성해주세요 (템플릿 0건 본문)
  static const proposalCreateNoTemplatesBody = '먼저 수강권 템플릿을 생성해주세요';

  /// 템플릿 만들기 (템플릿 0건 CTA)
  static const proposalCreateTemplateButton = '템플릿 만들기';

  /// 학생 선택 (Step 1 헤더)
  static const proposalCreateStepStudent = '학생 선택';

  /// 수강권 선택 (최대 $max개) (Step 2 헤더 포매터)
  static String proposalCreateStepTemplateMaxFormat(int max) =>
      '수강권 선택 (최대 $max개)';

  /// 메시지 (선택) (Step 3 섹션 타이틀)
  static const proposalCreateMessageOptional = '메시지 (선택)';

  /// 학생을 선택하세요 (학생 드롭다운 hint)
  static const proposalCreateStudentSelectHint = '학생을 선택하세요';

  /// 수강권을 선택하세요. 복수 선택 시 학생이 하나를 선택합니다. (템플릿 단계 안내 배너)
  static const proposalCreateTemplateInfoBanner =
      '수강권을 선택하세요. 복수 선택 시 학생이 하나를 선택합니다.';

  /// 추천 지정: 카드를 길게 누르세요. (추천 카드 안내)
  static const proposalCreateRecommendedHint = '추천 지정: 카드를 길게 누르세요.';

  /// $count개 선택됨 — 학생이 하나를 선택합니다.  (복수 선택 안내)
  static String proposalCreateMultiSelectInfoFormat(int count) =>
      '$count개 선택됨 — 학생이 하나를 선택합니다. ';

  /// 학생에게 전달할 메시지를 입력하세요 (메시지 입력 hint)
  static const proposalCreateMessageHint = '학생에게 전달할 메시지를 입력하세요';

  /// 즉시 발급: 학생 확인 없이 바로 수강권을 발급합니다 (즉시 발급 안내)
  static const proposalCreateImmediateIssueHelp =
      '즉시 발급: 학생 확인 없이 바로 수강권을 발급합니다';

  /// 수강권 제안을 보냈습니다 (제안 발송 성공 SnackBar)
  static const proposalCreateSentMessage = '수강권 제안을 보냈습니다';

  /// $count개 수강권 제안 보내기 (복수 템플릿 송신 버튼)
  static String proposalCreateMultiTemplateSendFormat(int count) =>
      '$count개 수강권 제안 보내기';

  /// $count개 수강권 제안을 보냈습니다 (복수 템플릿 송신 SnackBar)
  static String proposalCreateMultiSentMessageFormat(int count) =>
      '$count개 수강권 제안을 보냈습니다';

  /// 제안 실패. 다시 시도해주세요. (제안 실패 SnackBar)
  static const proposalCreateFailMessage = '제안 실패. 다시 시도해주세요.';

  /// $name을 추천으로 지정했습니다 (추천 지정 SnackBar 포매터)
  static String proposalCreateRecommendedDesignatedFormat(String name) =>
      '$name을 추천으로 지정했습니다';

  /// $selected/$max개 선택 (선택 카운터 포매터)
  static String proposalCreateSelectedCountFormat(int selected, int max) =>
      '$selected/$max개 선택';

  // -- Renewal Detail Screen (수강권 갱신 제안 5-3b-16) --

  /// 수강권 갱신 제안 (AppBar 타이틀)
  static const renewalProposalAppBarTitle = '수강권 갱신 제안';

  /// 수강권을 선택하세요 (템플릿 선택 헤더 — 갱신 컨텍스트)
  static const renewalSelectTemplatePrompt = '수강권을 선택하세요';

  /// $name이 수강권 갱신을 제안했어요 (헤더 포매터)
  static String renewalProposedByFormat(String name) => '$name이 수강권 갱신을 제안했어요';

  /// 지난번과 동일한 수강권입니다 ("Same as before" 힌트)
  static const renewalSameAsPreviousHint = '지난번과 동일한 수강권입니다';

  /// 수강권 선택하기 (Primary CTA)
  static const renewalSelectButton = '수강권 선택하기';

  /// 나중에 할게요 (Decline 버튼)
  static const renewalDeclineLater = '나중에 할게요';

  /// 다음에 다시 안내해 드릴게요 (거절 SnackBar)
  static const renewalDeclineSnackbar = '다음에 다시 안내해 드릴게요';

  // ── Proposal Detail Screen (수강권 제안 상세 5-3b-17) ─────────

  /// 수강권을 선택하세요 (multi-choice 단계 제목)
  static const proposalDetailSelectTemplate = '수강권을 선택하세요';

  /// 수강권을 선택해주세요 (하단 액션바 안내)
  static const proposalDetailSelectTemplateRequired = '수강권을 선택해주세요';

  /// 자동 발송 (auto proposal 배지)
  static const proposalDetailAutoSentBadge = '자동 발송';

  /// 선생님이 보낸 제안 (헤더 subtitle)
  static const proposalDetailFromTeacherSubtitle = '선생님이 보낸 제안';

  /// 추천 (recommended template 배지)
  static const proposalDetailRecommendedBadge = '추천';

  /// 입금 완료했어요 (학생 입금 알림 CTA)
  static const proposalDetailPaymentDoneAction = '입금 완료했어요';

  /// 이번엔 스킵할게요 (학생 거절 CTA)
  static const proposalDetailSkipAction = '이번엔 스킵할게요';

  /// 이번 제안을 스킵했습니다 (거절 SnackBar)
  static const proposalDetailSkippedSnackbar = '이번 제안을 스킵했습니다';

  /// 선생님 정보를 찾을 수 없습니다 (teacher profile null)
  static const teacherProfileNotFound = '선생님 정보를 찾을 수 없습니다';

  /// 선생님 연락처 정보가 없습니다 (teacher phone null)
  static const teacherContactNotAvailable = '선생님 연락처 정보가 없습니다';

  /// 선생님 정보를 불러오는 중... (teacher profile loading)
  static const teacherProfileLoading = '선생님 정보를 불러오는 중...';

  /// 선생님 정보를 불러올 수 없습니다 (teacher profile load error)
  static const teacherProfileLoadError = '선생님 정보를 불러올 수 없습니다';

  /// $name 선생님께 연락하기 (contact sheet title)
  static String teacherContactSheetTitleFormat(String name) =>
      '$name 선생님께 연락하기';

  /// 전화하기 (call action)
  static const callTeacherAction = '전화하기';

  /// 문자 보내기 (sms action)
  static const messageTeacherAction = '문자 보내기';

  /// 전화번호가 복사되었습니다: $phoneNumber (clipboard SnackBar)
  static String phoneNumberCopiedFormat(String phoneNumber) =>
      '전화번호가 복사되었습니다: $phoneNumber';

  // -- Subscription History Section (수강 이력 위젯 5-3b-18) --

  /// 수강 이력 (섹션 제목)
  static const subscriptionHistoryTitle = '수강 이력';

  /// 수강 기간 (stat row 라벨)
  static const subscriptionPeriodLabel = '수강 기간';

  /// 총 수강 (stat row 라벨)
  static const subscriptionTotalLessonsLabel = '총 수강';

  /// 출석률 (stat row 라벨 — section local)
  static const subscriptionAttendanceRateLabel = '출석률';

  /// $count회 완료 (총 수강 값 포매터)
  static String subscriptionTotalUsedFormat(int count) => '$count회 완료';

  /// $months개월 · $count회 완료 (수강 기간 + 총 수강 composite 포매터)
  static String subscriptionMonthsAndUsedFormat(int months, int count) =>
      '$months개월 · $count회 완료';

  // ── Proposal Settings Screen (자동 제안 설정 5-3b-19) ─────────
  // 외부 5-3b-18 (subscription_history_section) 점유로 5-3b-19 재매핑

  /// 자동 제안 설정 (AppBar)
  static const proposalSettingsAppBarTitle = '자동 제안 설정';

  /// 체험 후 자동 제안 (메인 토글 타이틀)
  static const proposalSettingsAutoToggleTitle = '체험 후 자동 제안';

  /// 체험레슨 완료 시 수강권을 자동으로 제안합니다 (메인 토글 서브타이틀)
  static const proposalSettingsAutoToggleSubtitle = '체험레슨 완료 시 수강권을 자동으로 제안합니다';

  /// 체험 후 즉시 제안하여 전환율을 높이세요 (메인 토글 활성 시 힌트)
  static const proposalSettingsAutoToggleHint = '체험 후 즉시 제안하여 전환율을 높이세요';

  /// 제안할 수강권 (템플릿 선택 섹션 타이틀)
  static const proposalSettingsTemplateSectionTitle = '제안할 수강권';

  /// 선택하지 않으면 모든 활성 수강권이 제안됩니다 (템플릿 선택 섹션 힌트)
  static const proposalSettingsTemplateSectionHint =
      '선택하지 않으면 모든 활성 수강권이 제안됩니다';

  /// 수강권 템플릿이 없습니다 (빈 상태)
  static const proposalSettingsTemplateEmpty = '수강권 템플릿이 없습니다';

  /// $lessons회 · $price (템플릿 항목 정보 포매터)
  static String proposalSettingsTemplateInfoFormat(int lessons, String price) =>
      '$lessons회 · $price';

  /// 골든타임 할인 (섹션 타이틀)
  static const proposalSettingsGoldenTimeTitle = '골든타임 할인';

  /// 전환율 UP (배지)
  static const proposalSettingsConversionUpBadge = '전환율 UP';

  /// 체험 완료 후 일정 시간 내 등록 시 할인을 적용합니다 (섹션 힌트)
  static const proposalSettingsGoldenTimeHint =
      '체험 완료 후 일정 시간 내 등록 시 할인을 적용합니다';

  /// 할인율 (드롭다운 라벨)
  static const proposalSettingsDiscountPercentLabel = '할인율';

  /// 유효 시간 (드롭다운 라벨)
  static const proposalSettingsValidityHoursLabel = '유효 시간';

  /// $hours시간 (시간 드롭다운 항목 포매터)
  static String proposalSettingsHoursFormat(int hours) => '$hours시간';

  /// 체험 후 $hours시간 이내 등록 시 $percent% 할인 (요약 메시지 포매터)
  static String proposalSettingsGoldenTimeSummaryFormat(
    int hours,
    int percent,
  ) => '체험 후 $hours시간 이내 등록 시 $percent% 할인';

  /// 자동 리마인더 (섹션 타이틀)
  static const proposalSettingsAutoReminderTitle = '자동 리마인더';

  /// 제안 후 응답이 없으면 자동으로 알림을 보냅니다 (섹션 힌트)
  static const proposalSettingsAutoReminderHint = '제안 후 응답이 없으면 자동으로 알림을 보냅니다';

  /// 24시간, 48시간, 72시간 후 알림 (스케줄 설명)
  static const proposalSettingsAutoReminderSchedule = '24시간, 48시간, 72시간 후 알림';

  /// 설정이 저장되었습니다 (저장 성공 SnackBar)
  static const proposalSettingsSavedSnackbar = '설정이 저장되었습니다';

  /// 저장 실패. 다시 시도해주세요. (저장 실패 SnackBar)
  static const proposalSettingsSaveFailedSnackbar = '저장 실패. 다시 시도해주세요.';

  // ── Lesson Policy Screen (레슨/클래스 정책 설정 5-3b-20) ───────

  /// 클래스 정책 설정 (AppBar — lessonClassId 있는 경우)
  static const policyClassAppBarTitle = '클래스 정책 설정';

  /// 레슨 정책 설정 (AppBar — 기본)
  static const policyLessonAppBarTitle = '레슨 정책 설정';

  /// 변경/취소 정책 (섹션 헤더)
  static const policyChangeCancelHeader = '변경/취소 정책';

  /// 최소 취소 시간 (Chip 입력 타이틀)
  static const policyMinCancelHoursTitle = '최소 취소 시간';

  /// 시간 전 (suffix)
  static const policyHoursBeforeSuffix = '시간 전';

  /// $hours시간 (라벨 포매터)
  static String policyHoursFormat(int hours) => '$hours시간';

  /// 월 변경 횟수 (Chip 입력 타이틀)
  static const policyMonthlyChangesTitle = '월 변경 횟수';

  /// 무제한 (라벨/요약 값)
  static const policyUnlimited = '무제한';

  /// $count회 (라벨 포매터)
  static String policyTimesFormat(int count) => '$count회';

  /// 당일 취소 허용 (토글 라벨)
  static const policyAllowSameDayCancelToggle = '당일 취소 허용';

  /// 노쇼 정책 (섹션 헤더)
  static const policyNoShowHeader = '노쇼 정책';

  /// 지각 허용 시간 (Chip 입력 타이틀)
  static const policyGracePeriodTitle = '지각 허용 시간';

  /// 이월 정책 (월정액) (섹션 헤더)
  static const policyCarryoverHeader = '이월 정책 (월정액)';

  /// 미사용 수업 이월 허용 (토글 라벨)
  static const policyAllowCarryoverToggle = '미사용 수업 이월 허용';

  /// 최대 이월 횟수 (Chip 입력 타이틀)
  static const policyMaxCarryoverTitle = '최대 이월 횟수';

  /// 이월 유효 기간 (Chip 입력 타이틀)
  static const policyCarryoverPeriodTitle = '이월 유효 기간';

  /// 개월 (suffix)
  static const policyMonthsSuffix = '개월';

  /// 📋 정책 요약 (요약 섹션 헤더)
  static const policySummaryHeader = '📋 정책 요약';

  /// 취소 (요약 라벨)
  static const policyCancelLabel = '취소';

  /// $hours시간 전까지 (요약 값 포매터)
  static String policyHoursBeforeFormat(int hours) => '$hours시간 전까지';

  /// 변경 (요약 라벨)
  static const policyChangeLabel = '변경';

  /// 월 $max회 (요약 값 포매터)
  static String policyMonthlyChangesFormat(int max) => '월 $max회';

  /// 횟수 차감 (요약 값 — 노쇼 ON)
  static const policyDeductCount = '횟수 차감';

  /// 횟수 유지 (요약 값 — 노쇼 OFF)
  static const policyKeepCount = '횟수 유지';

  /// 지각 (요약 라벨)
  static const policyLatenessLabel = '지각';

  /// $minutes분까지 허용 (요약 값 포매터)
  static String policyLatenessFormat(int minutes) => '$minutes분까지 허용';

  /// 최대 $count회 ($months개월 내) (이월 요약 값 포매터)
  static String policyCarryoverFormat(int count, int months) =>
      '최대 $count회 ($months개월 내)';

  /// 불가 (이월 OFF 요약 값)
  static const policyNotAllowed = '불가';

  /// 관련 설정 (섹션 헤더)
  static const policyRelatedHeader = '관련 설정';

  /// 입금 확인 대기 (관련 설정 항목)
  static const policyTuitionManagement = '입금 확인 대기';

  /// 템플릿 관리 (관련 설정 항목)
  static const policyTemplateManagement = '템플릿 관리';

  /// 정책이 저장되었습니다 (저장 성공 SnackBar)
  static const policySavedSnackbar = '정책이 저장되었습니다';

  // ── Unified Subscription Sheet (수강권 발급 바텀시트 5-3b-21) ──

  /// 수강권 발급 (바텀시트 헤더)
  static const unifiedSubscriptionAppBarTitle = '수강권 발급';

  /// 템플릿 선택 (섹션 라벨)
  static const unifiedSubscriptionTemplateSection = '템플릿 선택';

  /// 등록된 템플릿이 없습니다 (빈 상태)
  static const unifiedSubscriptionNoTemplates = '등록된 템플릿이 없습니다';

  /// 직접 입력 (확장 토글 라벨)
  static const unifiedSubscriptionDirectInputToggle = '직접 입력';

  /// 자동: $days일 (자동 산출 유효기간 보조 텍스트)
  static String unifiedSubscriptionAutoValidityFormat(int days) => '자동: $days일';

  /// $count회 (회차 chip 라벨)
  static String unifiedSubscriptionLessonChipFormat(int count) => '$count회';

  /// 직접입력 (회차 chip 직접입력 옵션 — space 없음)
  static const unifiedSubscriptionDirectInputChip = '직접입력';

  /// 금액을 입력하세요 (금액 입력 hint)
  static const unifiedSubscriptionAmountHint = '금액을 입력하세요';

  /// $days일 (유효기간 chip 라벨)
  static String unifiedSubscriptionDaysChipFormat(int days) => '$days일';

  /// 바로 발급 (단일 선택 시 outlined 액션)
  static const unifiedSubscriptionDirectIssueButton = '바로 발급';

  /// $count개 제안 보내기 (복수 템플릿 송신 버튼)
  static String unifiedSubscriptionMultiSendFormat(int count) =>
      '$count개 제안 보내기';

  /// 회차 입력 (custom lesson count 다이얼로그 타이틀)
  static const unifiedSubscriptionLessonCountDialogTitle = '회차 입력';

  /// 횟수를 입력하세요 (custom lesson count 입력 hint)
  static const unifiedSubscriptionLessonCountHint = '횟수를 입력하세요';

  // ── Assignment Dashboard / Summary (5-3b-22) ──

  /// 이번 주 과제 (AppBar / 섹션 헤더 공용)
  static const weeklyAssignmentTitle = '이번 주 과제';

  /// 이번 주 과제가 없습니다 (대시보드 빈 상태)
  static const weeklyAssignmentEmpty = '이번 주 과제가 없습니다';

  /// 미완료 학생 (섹션 헤더)
  static const incompleteStudentsLabel = '미완료 학생';

  /// 완료한 학생 (섹션 헤더)
  static const completedStudentsLabel = '완료한 학생';

  /// 이번 주 완료율 (원형 진행률 카드 라벨)
  static const weeklyCompletionRate = '이번 주 완료율';

  /// $count명 (학생 수 카운트 — 섹션 헤더 trailing)
  static String peopleCount(int count) => '$count명';

  /// $done / $total 과제 완료 (전체 진행률 보조 텍스트)
  static String assignmentCompletionFormat(int done, int total) =>
      '$done / $total 과제 완료';

  /// 전체 과제 (stat 카드 라벨)
  static const totalAssignmentsLabel = '전체 과제';

  /// 완료 학생 (stat 카드 — 짧은 라벨)
  static const completedStudentsShort = '완료 학생';

  /// 미완료 (stat 카드 — 짧은 라벨)
  static const incompleteShort = '미완료';

  /// 완료율 (요약 섹션 라벨)
  static const completionRateLabel = '완료율';

  // ── Notification Settings Screen (5-3b-23) ──

  /// 알림 설정 (AppBar)
  static const notificationSettingsAppBarTitle = '알림 설정';

  /// 전체 알림 (master 섹션 헤더)
  static const notificationSettingsMasterSection = '전체 알림';

  /// 알림 받기 (master toggle title)
  static const notificationToggleAllTitle = '알림 받기';

  /// 모든 알림을 켜거나 끕니다 (master toggle subtitle)
  static const notificationToggleAllSubtitle = '모든 알림을 켜거나 끕니다';

  /// 레슨 알림 (섹션 헤더)
  static const notificationSettingsLessonSection = '레슨 알림';

  /// 레슨 시작 알림 (toggle title)
  static const notificationLessonStartTitle = '레슨 시작 알림';

  /// 레슨 30분 전 알림 (toggle subtitle)
  static const notificationLessonStartSubtitle = '레슨 30분 전 알림';

  /// 레슨 변경 알림 (toggle title)
  static const notificationLessonChangeTitle = '레슨 변경 알림';

  /// 레슨 시간/일정 변경 시 (toggle subtitle)
  static const notificationLessonChangeSubtitle = '레슨 시간/일정 변경 시';

  /// 수강권 알림 (섹션 헤더)
  static const notificationSettingsSubscriptionSection = '수강권 알림';

  /// 수강권 제안 알림 (toggle title)
  static const notificationSubscriptionProposalTitle = '수강권 제안 알림';

  /// 선생님이 수강권을 제안할 때 (toggle subtitle)
  static const notificationSubscriptionProposalSubtitle = '선생님이 수강권을 제안할 때';

  /// 수강권 만료 알림 (toggle title)
  static const notificationSubscriptionExpiryTitle = '수강권 만료 알림';

  /// 수강권 만료 7일 전 알림 (toggle subtitle)
  static const notificationSubscriptionExpirySubtitle = '수강권 만료 7일 전 알림';

  /// 연습 알림 (섹션 헤더)
  static const notificationSettingsPracticeSection = '연습 알림';

  /// 연습 리마인더 (toggle title)
  static const notificationPracticeReminderTitle = '연습 리마인더';

  /// 매일 설정한 시간에 알림 (toggle subtitle)
  static const notificationPracticeReminderSubtitle = '매일 설정한 시간에 알림';

  /// 선생님이 피드백을 남길 때 (toggle subtitle — 제목은 teacherFeedbackHeader 재사용)
  static const notificationTeacherFeedbackSubtitle = '선생님이 피드백을 남길 때';

  /// 수강권 만료 자동 알림 (선생님) (선생님 전용 섹션 헤더)
  static const notificationSettingsExpiryAutoSectionTeacher =
      '수강권 만료 자동 알림 (선생님)';

  /// 만료 자동 알림 (master toggle title)
  static const notificationExpiryAutoMasterTitle = '만료 자동 알림';

  /// 활성 수강권의 만료 시점에 자동으로 알림 (master toggle subtitle)
  static const notificationExpiryAutoMasterSubtitle = '활성 수강권의 만료 시점에 자동으로 알림';

  /// D-14 (14일 전) — D-N prefix 는 ASCII (다국어 무관 universal)
  static const notificationExpiryD14Title = 'D-14 (14일 전)';

  /// 여유 있게 재등록 제안 시점
  static const notificationExpiryD14Subtitle = '여유 있게 재등록 제안 시점';

  /// D-7 (7일 전)
  static const notificationExpiryD7Title = 'D-7 (7일 전)';

  /// 재등록 유도 주차 알림
  static const notificationExpiryD7Subtitle = '재등록 유도 주차 알림';

  /// D-1 (하루 전)
  static const notificationExpiryD1Title = 'D-1 (하루 전)';

  /// 만료 임박 최종 알림
  static const notificationExpiryD1Subtitle = '만료 임박 최종 알림';

  /// D-0 (당일)
  static const notificationExpiryD0Title = 'D-0 (당일)';

  /// 만료 당일 보관 이동 알림
  static const notificationExpiryD0Subtitle = '만료 당일 보관 이동 알림';

  /// 푸시 알림 준비 안내 (info 배너 — \n 포함)
  static const notificationPushPreparingNotice =
      '푸시 알림은 준비 중입니다.\n'
      '알림 설정은 저장되며, 기능이 활성화되면 자동 적용됩니다.';

  // ── Subscription Template List Screen (수강권 관리 5-3b-24) ────────

  /// 수강권 관리 (AppBar)
  static const templateListAppBarTitle = '수강권 관리';

  /// 수강권 추가 (FAB / 빈상태 CTA보조)
  static const templateAddButton = '수강권 추가';

  /// 수강권을 만들어 학생들에게 제안해보세요 (빈 상태 본문)
  static const templateEmptyHint = '수강권을 만들어 학생들에게 제안해보세요';

  /// 첫 수강권 만들기 (빈 상태 CTA)
  static const templateFirstCreate = '첫 수강권 만들기';

  /// 수강권 삭제 (AlertDialog 타이틀)
  static const templateDeleteDialogTitle = '수강권 삭제';

  /// "$name"을(를) 삭제하시겠습니까? (AlertDialog 본문 — 템플릿 이름 인터폴레이션)
  static String templateDeleteConfirmFormat(String name) =>
      '"$name"을(를) 삭제하시겠습니까?';

  /// 비활성 (카드 비활성 배지)
  static const templateInactiveBadge = '비활성';

  /// 자동 (자동 제안 활성 배지 — flash_on 아이콘 우측 텍스트)
  static const templateAutoBadge = '자동';

  /// 비활성화 (popup menu — 활성 카드의 toggle 액션)
  static const templateMenuDeactivate = '비활성화';

  /// 활성화 (popup menu — 비활성 카드의 toggle 액션)
  static const templateMenuActivate = '활성화';

  /// 수강권 수정 (편집 바텀시트 헤더)
  static const templateEditSheetTitle = '수강권 수정';

  /// 수강권 수강권 추가 (추가 바텀시트 헤더 — 원본 코드의 중복 단어 보존, 별도 수정 PR 권장)
  static const templateAddSheetTitle = '수강권 수강권 추가';

  /// 이름 * (이름 필드 라벨)
  static const templateNameLabel = '이름 *';

  /// 예: 8회권, 기본 패키지 (이름 필드 hint)
  static const templateNameHint = '예: 8회권, 기본 패키지';

  /// 이름을 입력해주세요 (이름 validator)
  static const templateNameRequired = '이름을 입력해주세요';

  /// 가격 (원) * (가격 필드 라벨)
  static const templatePriceLabel = '가격 (원) *';

  /// 예: 400000 (가격 필드 hint)
  static const templatePriceHint = '예: 400000';

  /// 가격을 입력해주세요 (가격 validator — 빈값)
  static const templatePriceRequired = '가격을 입력해주세요';

  /// 숫자만 입력해주세요 (가격 validator — 비숫자)
  static const templatePriceNumbersOnly = '숫자만 입력해주세요';

  /// 예: 가장 인기 있는 패키지입니다 (설명 필드 hint)
  static const templateDescHint = '예: 가장 인기 있는 패키지입니다';

  /// 수정하기 (저장 버튼 — 편집 모드)
  static const templateSaveEdit = '수정하기';

  /// 추가하기 (저장 버튼 — 추가 모드)
  static const templateSaveAdd = '추가하기';

  /// 자동 제안 대상 (Checkbox 라벨)
  static const templateAutoProposalCheckbox = '자동 제안 대상';

  /// 체험레슨 완료 또는 수강권 만료 시 학생에게\n이 수강권이 자동으로 제안됩니다.
  static const templateAutoProposalEnabledDesc =
      '체험레슨 완료 또는 수강권 만료 시 학생에게\n'
      '이 수강권이 자동으로 제안됩니다.';

  /// 이 수강권은 선생님이 직접 제안할 때만 사용됩니다.\n자동 제안에 포함되지 않습니다.
  static const templateAutoProposalDisabledDesc =
      '이 수강권은 선생님이 직접 제안할 때만 사용됩니다.\n'
      '자동 제안에 포함되지 않습니다.';

  /// 수강권이 수정되었습니다 (저장 SnackBar — 편집)
  static const templateUpdatedSnackbar = '수강권이 수정되었습니다';

  /// 수강권이 추가되었습니다 (저장 SnackBar — 추가)
  static const templateAddedSnackbar = '수강권이 추가되었습니다';

  // ── Profile Visibility Screen (공개 프로필 설정 5-3b-25) ────────

  /// 공개 프로필 설정 (AppBar)
  static const profileVisibilityAppBarTitle = '공개 프로필 설정';

  /// 저장 중 오류가 발생했습니다. 다시 시도해주세요. (저장 실패 SnackBar)
  static const profileVisibilitySaveErrorSnackbar =
      '저장 중 오류가 발생했습니다. 다시 시도해주세요.';

  /// 오류가 발생했습니다. (프로필 로딩 에러 상태)
  static const profileVisibilityErrorState = '오류가 발생했습니다.';

  /// 프로필을 찾을 수 없습니다 (프로필 null 상태)
  static const profileVisibilityNullState = '프로필을 찾을 수 없습니다';

  /// 항목별 공개 범위 (섹션 타이틀)
  static const profileVisibilitySectionTitle = '항목별 공개 범위';

  /// 이름 (VisibilityTile title — 이름 항목)
  static const profileVisibilityNameTitle = '이름';

  /// 프로필에 표시되는 이름 (VisibilityTile subtitle — 이름 항목)
  static const profileVisibilityNameSubtitle = '프로필에 표시되는 이름';

  /// 프로필 사진 (VisibilityTile title — 사진 항목)
  static const profileVisibilityPhotoTitle = '프로필 사진';

  /// 프로필 이미지 (VisibilityTile subtitle — 사진 항목)
  static const profileVisibilityPhotoSubtitle = '프로필 이미지';

  /// 연락처 (VisibilityTile title — 연락처 항목)
  static const profileVisibilityContactTitle = '연락처';

  /// 전화번호, 이메일 등 (VisibilityTile subtitle — 연락처 항목)
  static const profileVisibilityContactSubtitle = '전화번호, 이메일 등';

  /// 레슨료 (VisibilityTile title — 레슨료 항목)
  static const profileVisibilityFeeTitle = '레슨료';

  /// 레슨 가격 정보 (VisibilityTile subtitle — 레슨료 항목)
  static const profileVisibilityFeeSubtitle = '레슨 가격 정보';

  /// 경력 (VisibilityTile title — 경력 항목)
  static const profileVisibilityCareerTitle = '경력';

  /// 학력 및 경력 정보 (VisibilityTile subtitle — 경력 항목)
  static const profileVisibilityCareerSubtitle = '학력 및 경력 정보';

  /// 자격증 (VisibilityTile title — 자격증 항목)
  static const profileVisibilityCertificateTitle = '자격증';

  /// 인증된 자격증 정보 (VisibilityTile subtitle — 자격증 항목)
  static const profileVisibilityCertificateSubtitle = '인증된 자격증 정보';

  /// 공개 프로필 미리보기 (Preview 버튼 라벨)
  static const profileVisibilityPreviewButton = '공개 프로필 미리보기';

  // ── Teacher Analytics Dashboard (선생님 통계 대시보드 5-3c-1) ────────

  /// 통계 (AppBar 타이틀)
  static const analyticsAppBarTitle = '통계';

  /// 총 레슨 (StatCard 타이틀)
  static const analyticsTotalLessons = '총 레슨';

  /// 완료 N회 (StatCard subtitle 포매터 — 총 레슨 카드)
  static String analyticsCompletedFormat(int count) => '완료 $count회';

  /// 취소 N회 (StatCard subtitle 포매터 — 출석률 카드)
  static String analyticsCancelledFormat(int count) => '취소 $count회';

  /// 학생 수 (StatCard 타이틀)
  static const analyticsStudentCountLabel = '학생 수';

  /// 신규 +N명 (StatCard subtitle 포매터 — 학생 수 카드)
  static String analyticsNewStudentsFormat(int count) => '신규 +$count명';

  /// 월 수입 (StatCard 타이틀)
  static const analyticsMonthlyRevenue = '월 수입';

  /// 수익 현황 (섹션 헤더)
  static const analyticsRevenueSection = '수익 현황';

  /// 이번 달 수익 (라벨)
  static const analyticsThisMonthRevenue = '이번 달 수익';

  /// +12.3% / -5.2% (수익 변화 포매터, sign 포함)
  static String analyticsRevenueChangeFormat(double percent) {
    final sign = percent >= 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}%';
  }

  /// 학생 현황 (섹션 헤더)
  static const analyticsStudentSection = '학생 현황';

  /// 총 학생 (학생 현황 stat 라벨)
  static const analyticsTotalStudentsLabel = '총 학생';

  /// 신규 (학생 현황 stat 라벨)
  static const analyticsNewLabel = '신규';

  /// +N명 (학생 현황 신규 value 포매터)
  static String analyticsNewCountFormat(int count) => '+$count명';

  /// 이탈 (학생 현황 stat 라벨)
  static const analyticsChurnedLabel = '이탈';

  /// -N명 (학생 현황 이탈 value 포매터, count 는 양수로 받아 부호 자동 부착)
  static String analyticsChurnedCountFormat(int count) => '-$count명';

  // ── Analytics Widgets (analytics 위젯 5-3c-2) ────────────────────────

  /// 레슨 추이 (MonthlyTrendChart 섹션 헤더)
  static const analyticsLessonTrendSection = '레슨 추이';

  /// N월 (MonthlyTrendChart 월별 라벨 포매터)
  static String analyticsMonthLabelFormat(int month) => '$month월';

  /// 연습률 TOP 5 (PracticeRankingList 섹션 헤더)
  static const analyticsPracticeRankingSection = '연습률 TOP 5';

  /// 연습 데이터가 없습니다 (PracticeRankingList 빈 상태)
  static const analyticsNoPracticeData = '연습 데이터가 없습니다';

  // ── Edit Repertoire Screen (레퍼토리 편집 5-3b-26) ──────────────────────
  /// 레퍼토리 편집 (AppBar 타이틀)
  static const editRepertoireAppBarTitle = '레퍼토리 편집';

  /// 레퍼토리를 찾을 수 없습니다 (null 상태)
  static const repertoireNotFound = '레퍼토리를 찾을 수 없습니다';

  /// 기본 정보 (섹션 헤더)
  static const basicInfoTitle = '기본 정보';

  /// 레퍼토리 이름, 설명 설정 (기본 정보 섹션 subtitle)
  static const editRepertoireBasicInfoSubtitle = '레퍼토리 이름, 설명 설정';

  /// 레퍼토리 이름 * (이름 입력 라벨)
  static const repertoireNameLabel = '레퍼토리 이름 *';

  /// 예: 스즈키 6권, 바흐 협주곡 (이름 입력 hint)
  static const editRepertoireNameHint = '예: 스즈키 6권, 바흐 협주곡';

  /// 레퍼토리 이름을 입력해주세요 (이름 입력 validator)
  static const repertoireNameRequired = '레퍼토리 이름을 입력해주세요';

  /// 예: Bach Violin Concerto in A minor (설명 입력 hint)
  static const repertoireDescriptionHint = '예: Bach Violin Concerto in A minor';

  /// 시작일 선택 (start date picker helpText)
  static const selectStartDate = '시작일 선택';

  /// 종료일 선택 (end date picker helpText)
  static const selectEndDate = '종료일 선택';

  /// 설정 안함 (매일 반복) (end date placeholder)
  static const endDateNotSetDaily = '설정 안함 (매일 반복)';

  /// 레퍼토리 수정에 실패했습니다. 다시 시도해주세요. (저장 실패 SnackBar)
  static const editRepertoireUpdateFailedRetry = '레퍼토리 수정에 실패했습니다. 다시 시도해주세요.';

  /// 관리 (관리 섹션 헤더 타이틀)
  static const managementSectionTitle = '관리';

  /// 레퍼토리를 아카이브하거나 삭제합니다 (관리 섹션 description)
  static const managementSectionDescription = '레퍼토리를 아카이브하거나 삭제합니다';

  /// 아카이브 (다이얼로그 타이틀 + 액션 버튼)
  static const archiveButton = '아카이브';

  /// 이 레퍼토리를 아카이브하시겠습니까?\n아카이브된 레퍼토리는 목록에서 숨겨집니다. (아카이브 확인 다이얼로그 본문)
  static const archiveRepertoireConfirm =
      '이 레퍼토리를 아카이브하시겠습니까?\n아카이브된 레퍼토리는 목록에서 숨겨집니다.';

  /// 레퍼토리가 아카이브되었습니다 (아카이브 성공 SnackBar)
  static const repertoireArchivedSnackbar = '레퍼토리가 아카이브되었습니다';

  /// 아카이브에 실패했습니다. 다시 시도해주세요. (아카이브 실패 SnackBar)
  static const archiveFailedRetry = '아카이브에 실패했습니다. 다시 시도해주세요.';

  /// 레퍼토리 삭제 (다이얼로그 타이틀 + 액션 버튼)
  static const deleteRepertoireTitle = '레퍼토리 삭제';

  /// 이 레퍼토리를 삭제하시겠습니까?\n연결된 모든 섹션과 녹음이 함께 삭제됩니다.\n이 작업은 되돌릴 수 없습니다. (삭제 확인 다이얼로그 본문)
  static const deleteRepertoireConfirm =
      '이 레퍼토리를 삭제하시겠습니까?\n연결된 모든 섹션과 녹음이 함께 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.';

  /// 레퍼토리가 삭제되었습니다 (삭제 성공 SnackBar)
  static const repertoireDeletedSnackbar = '레퍼토리가 삭제되었습니다';

  /// 삭제에 실패했습니다. 다시 시도해주세요. (삭제 실패 SnackBar)
  static const deleteFailedRetry = '삭제에 실패했습니다. 다시 시도해주세요.';

  // ── Backup Settings Screen (녹음 백업 설정 5-3d-1) ──────────────────────
  /// 녹음 백업 (AppBar 타이틀)
  static const backupAppBarTitle = '녹음 백업';

  /// 오류가 발생했습니다. (백업 로딩 에러 상태 — 마침표 포함)
  static const backupErrorState = '오류가 발생했습니다.';

  // ── Backup Service Progress (백업/복원 진행 상태 5-3d-2) ───────────────

  /// 백업 준비 중... (createBackup 진입)
  static const backupPreparing = '백업 준비 중...';

  /// 메타데이터 생성 중... (백업 메타데이터 생성 단계)
  static const backupMetadataCreating = '메타데이터 생성 중...';

  /// Hive 데이터 내보내기 중... (백업 Hive 박스 export 단계)
  static const backupHiveExporting = 'Hive 데이터 내보내기 중...';

  /// 녹음 파일 추가 중... (백업 녹음 파일 추가 단계 — 시작 헤더)
  static const backupRecordingsAdding = '녹음 파일 추가 중...';

  /// 녹음 파일 추가 중... (current/total) — 백업 녹음 파일 추가 진행 포매터
  static String backupRecordingsAddingProgressFormat(int current, int total) =>
      '녹음 파일 추가 중... ($current/$total)';

  /// ZIP 압축 중... (백업 ZIP 인코딩 단계)
  static const backupZipCompressing = 'ZIP 압축 중...';

  /// 백업 완료 (백업 성공 종결)
  static const backupComplete = '백업 완료';

  /// 백업 파일 읽는 중... (restoreFromBackup 진입)
  static const backupFileReading = '백업 파일 읽는 중...';

  /// 유효하지 않은 백업 파일입니다. (메타데이터 누락 시 실패 사유)
  static const backupInvalidFile = '유효하지 않은 백업 파일입니다.';

  /// 백업 버전 확인 중... (복원 버전 호환성 단계)
  static const backupVersionChecking = '백업 버전 확인 중...';

  /// 지원되지 않는 백업 버전입니다: $version (호환 불가 실패 포매터)
  static String backupUnsupportedVersionFormat(String version) =>
      '지원되지 않는 백업 버전입니다: $version';

  /// Hive 데이터 복원 중... (복원 Hive 박스 import 단계)
  static const backupHiveRestoring = 'Hive 데이터 복원 중...';

  /// 녹음 파일 복원 중... (복원 녹음 파일 단계 — 시작 헤더)
  static const backupRecordingsRestoring = '녹음 파일 복원 중...';

  /// 녹음 파일 복원 중... (processed/total) — 복원 녹음 파일 진행 포매터
  static String backupRecordingsRestoringProgressFormat(
    int processed,
    int total,
  ) => '녹음 파일 복원 중... ($processed/$total)';

  /// 복원 완료 (복원 성공 종결)
  static const restoreComplete = '복원 완료';

  /// 복원 중 오류 발생: $error (복원 catch 블록 실패 사유 포매터)
  static String restoreErrorFormat(Object error) => '복원 중 오류 발생: $error';

  // ── All Recordings Screen (전체 녹음 관리 5-3d-5) ────────────────────────
  /// 전체 녹음 파일 (AppBar 타이틀)
  static const allRecordingsAppBarTitle = '전체 녹음 파일';

  /// 녹음 가져오기 (파일 가져오기 IconButton tooltip)
  static const allRecordingsImportTooltip = '녹음 가져오기';

  /// 새로고침 (refresh IconButton tooltip — 다도메인 재사용 가능)
  static const refreshTooltip = '새로고침';

  /// 오류가 발생했습니다. (per-domain error state — backup/profileVisibility 패턴)
  static const allRecordingsErrorState = '오류가 발생했습니다.';

  /// 파일을 읽을 수 없습니다 (file path null SnackBar)
  static const allRecordingsFileReadError = '파일을 읽을 수 없습니다';

  /// 녹음 파일을 가져왔습니다: $fileName (import success SnackBar 포매터)
  static String allRecordingsImportedFormat(String fileName) =>
      '녹음 파일을 가져왔습니다: $fileName';

  /// 파일 가져오기 중 오류가 발생했습니다 (import failure SnackBar)
  static const allRecordingsImportError = '파일 가져오기 중 오류가 발생했습니다';

  /// 오류가 발생했습니다. 다시 시도해주세요. (generic catch-all retry SnackBar — 다도메인 재사용)
  static const errorOccurredRetryAgain = '오류가 발생했습니다. 다시 시도해주세요.';

  /// 연결되지 않은 녹음 (orphaned recordings 섹션 헤더)
  static const allRecordingsOrphanedSection = '연결되지 않은 녹음';

  /// 연결된 녹음 (connected recordings 섹션 헤더)
  static const allRecordingsConnectedSection = '연결된 녹음';

  /// 연결됨 (stats card connected 라벨)
  static const allRecordingsConnectedStatLabel = '연결됨';

  /// 미연결 (stats card orphaned 라벨)
  static const allRecordingsOrphanedStatLabel = '미연결';

  /// 녹음을 연결할 섹션 선택 (SectionPickerScreen title)
  static const allRecordingsSectionPickerTitle = '녹음을 연결할 섹션 선택';

  /// 녹음이 "$sectionName"에 연결되었습니다 (link success SnackBar 포매터)
  static String allRecordingsLinkedFormat(String sectionName) =>
      '녹음이 "$sectionName"에 연결되었습니다';

  /// 연결 중 오류가 발생했습니다 (reassign failure SnackBar)
  static const allRecordingsLinkError = '연결 중 오류가 발생했습니다';

  /// 녹음 삭제 (delete confirm Dialog title)
  static const allRecordingsDeleteDialogTitle = '녹음 삭제';

  /// 이 녹음을 영구적으로 삭제하시겠습니까? + 이 작업은 되돌릴 수 없습니다. (delete confirm Dialog content)
  static const allRecordingsDeleteDialogContent =
      '이 녹음을 영구적으로 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.';

  /// 녹음이 삭제되었습니다 (delete success SnackBar)
  static const allRecordingsDeletedSnack = '녹음이 삭제되었습니다';

  /// 연결되지 않음 (orphaned 인라인 카드 라벨)
  static const allRecordingsOrphanedInline = '연결되지 않음';

  /// 섹션에 연결 (orphaned 카드 link IconButton tooltip)
  static const allRecordingsLinkSectionTooltip = '섹션에 연결';

  /// 섹션 변경 (connected 카드 change IconButton tooltip)
  static const allRecordingsChangeSectionTooltip = '섹션 변경';

  // ── Orphan Recordings Screen (미연결 녹음 관리 5-3d-9) ──────────────────
  /// 새로고침 (경로 복구 포함) (orphan refresh tooltip — 경로 복구 부가 동작 명시)
  static const orphanRecordingsRefreshTooltip = '새로고침 (경로 복구 포함)';

  /// 연결되지 않은 녹음이 없습니다 (orphan empty state title)
  static const orphanRecordingsEmptyTitle = '연결되지 않은 녹음이 없습니다';

  /// 모든 녹음이 섹션에 연결되어 있습니다 (orphan empty state subtitle)
  static const orphanRecordingsEmptySubtitle = '모든 녹음이 섹션에 연결되어 있습니다';

  /// 진단 정보 (orphan diagnostic card 헤더)
  static const orphanRecordingsDiagnosticTitle = '진단 정보';

  /// Hive에 저장된 녹음 (orphan diagnostic stat — 전체 Hive 레코드 수 라벨)
  static const orphanRecordingsHiveCountLabel = 'Hive에 저장된 녹음';

  /// 섹션 수 (orphan diagnostic stat — 섹션 총 개수 라벨)
  static const orphanRecordingsSectionCountLabel = '섹션 수';

  /// $count개의 녹음이 섹션에 연결되지 않았습니다.\n각 녹음을 섹션에 연결하거나 삭제할 수 있습니다. (orphan list 안내 포매터)
  static String orphanRecordingsDescriptionFormat(int count) =>
      '$count개의 녹음이 섹션에 연결되지 않았습니다.\n각 녹음을 섹션에 연결하거나 삭제할 수 있습니다.';

  /// $n개 (count + 한국어 단위 — 다도메인 재사용 가능)
  static String countItemsSuffix(int n) => '$n개';

  // ── Invite Code Input Screen (초대 코드 입력 5-3d-11) ──────────────────
  /// 초대 코드 입력 (AppBar 타이틀)
  static const inviteCodeAppBarTitle = '초대 코드 입력';

  /// $targetRole의 초대 코드를 입력하세요 (입력 안내 — 선생님/학생 동적)
  static String inviteCodeInputPromptFormat(String targetRole) =>
      '$targetRole의 초대 코드를 입력하세요';

  /// 6자리 숫자 코드를 입력해주세요 (입력 서브타이틀)
  static const inviteCodeInputSubtitle = '6자리 숫자 코드를 입력해주세요';

  /// 클립보드에서 붙여넣기 (붙여넣기 액션 라벨)
  static const inviteCodePasteFromClipboard = '클립보드에서 붙여넣기';

  /// QR 코드 스캔하기 (QR 스캔 대안 라벨)
  static const inviteCodeQrScan = 'QR 코드 스캔하기';

  /// 클립보드에 유효한 코드가 없습니다 (붙여넣기 실패 메시지)
  static const inviteCodeClipboardInvalid = '클립보드에 유효한 코드가 없습니다';

  /// 초대 코드를 찾을 수 없습니다 (lookup 결과 없음)
  static const inviteCodeNotFound = '초대 코드를 찾을 수 없습니다';

  /// 만료된 초대 코드입니다 (InviteStatus.expired)
  static const inviteCodeExpired = '만료된 초대 코드입니다';

  /// 유효하지 않은 초대 코드입니다 (InviteStatus 그 외 invalid)
  static const inviteCodeInvalid = '유효하지 않은 초대 코드입니다';

  /// 코드 확인 중 오류가 발생했습니다 (lookup catch 블록)
  static const inviteCodeLookupError = '코드 확인 중 오류가 발생했습니다';

  // ── Invite QR Scan Screen (초대 QR 스캔 5-3d-13) ──────────────────────
  /// $targetRole QR 스캔 (AppBar 타이틀 — 선생님/학생 동적)
  static String inviteScanAppBarTitleFormat(String targetRole) =>
      '$targetRole QR 스캔';

  /// 플래시 (스캐너 플래시 토글 tooltip)
  static const inviteScanFlashTooltip = '플래시';

  /// 카메라 전환 (전·후면 카메라 전환 tooltip)
  static const inviteScanCameraSwitchTooltip = '카메라 전환';

  /// $targetRole의 QR 코드를 스캔하세요 (스캔 안내 프롬프트 — 동적)
  static String inviteScanPromptFormat(String targetRole) =>
      '$targetRole의 QR 코드를 스캔하세요';

  /// QR 코드가 프레임 안에 들어오도록 해주세요 (프레임 안내 서브텍스트)
  static const inviteScanFrameInstruction = 'QR 코드가 프레임 안에 들어오도록 해주세요';

  /// 코드로 입력하기 (QR 스캔 대안 — 코드 입력 화면 진입)
  static const inviteScanEnterCodeAlternative = '코드로 입력하기';

  /// 올바른 QR 코드가 아닙니다 (QR 파싱 실패 메시지)
  static const inviteScanInvalidQr = '올바른 QR 코드가 아닙니다';

  /// QR 코드 처리 중 오류가 발생했습니다 (QR 처리 catch 블록)
  static const inviteScanProcessingError = 'QR 코드 처리 중 오류가 발생했습니다';

  // ── Certificate Edit Screen (자격증 편집 5-3b-27) ──────────────────────
  /// 자격증 추가 (AppBar 타이틀 — 신규 등록 모드)
  static const certificateEditAppBarAdd = '자격증 추가';

  /// 자격증 수정 (AppBar 타이틀 — 편집 모드)
  static const certificateEditAppBarEdit = '자격증 수정';

  /// 음악 교원 자격증 (CertificateType.musicTeacher 라벨)
  static const certificateTypeMusicTeacher = '음악 교원 자격증';

  /// 문화예술교육사 (CertificateType.cultureArtsEducator 라벨)
  static const certificateTypeCultureArtsEducator = '문화예술교육사';

  /// 학교 교원 자격증 (CertificateType.schoolTeacher 라벨)
  static const certificateTypeSchoolTeacher = '학교 교원 자격증';

  /// 음악원 수료증 (CertificateType.conservatory 라벨)
  static const certificateTypeConservatory = '음악원 수료증';

  /// 음악 학위 (CertificateType.degree 라벨)
  static const certificateTypeDegree = '음악 학위';

  /// 연주 자격증 (CertificateType.performance 라벨)
  static const certificateTypePerformance = '연주 자격증';

  /// 기타 (CertificateType.other 라벨)
  static const certificateTypeOther = '기타';

  /// 카메라로 촬영 (이미지 소스 선택 — camera)
  static const imageSourceCamera = '카메라로 촬영';

  /// 갤러리에서 선택 (이미지 소스 선택 — gallery)
  static const imageSourceGallery = '갤러리에서 선택';

  /// 저장 중 오류가 발생했습니다. 다시 시도해주세요. (자격증 저장 실패 SnackBar)
  static const certificateSaveErrorRetry = '저장 중 오류가 발생했습니다. 다시 시도해주세요.';

  /// 삭제 중 오류가 발생했습니다. 다시 시도해주세요. (자격증 삭제 실패 SnackBar)
  static const certificateDeleteErrorRetry = '삭제 중 오류가 발생했습니다. 다시 시도해주세요.';

  /// 자격증 삭제 (삭제 확인 다이얼로그 타이틀)
  static const certificateDeleteDialogTitle = '자격증 삭제';

  /// 이 자격증 정보를 삭제하시겠습니까? (삭제 확인 다이얼로그 본문)
  static const certificateDeleteConfirm = '이 자격증 정보를 삭제하시겠습니까?';

  /// 자격증 종류 (폼 라벨)
  static const certificateTypeLabel = '자격증 종류';

  /// 자격증명 (폼 라벨)
  static const certificateNameLabel = '자격증명';

  /// 예: 중등학교 정교사 2급 (음악) (자격증명 hint)
  static const certificateNameHint = '예: 중등학교 정교사 2급 (음악)';

  /// 자격증명을 입력해주세요 (자격증명 validator)
  static const certificateNameRequired = '자격증명을 입력해주세요';

  /// 발급 기관 (폼 라벨)
  static const certificateIssuingBodyLabel = '발급 기관';

  /// 예: 교육부 (발급 기관 hint)
  static const certificateIssuingBodyHint = '예: 교육부';

  /// 발급 기관을 입력해주세요 (발급 기관 validator)
  static const certificateIssuingBodyRequired = '발급 기관을 입력해주세요';

  /// 발급일 (폼 라벨)
  static const certificateIssueDateLabel = '발급일';

  /// 자격증 번호 (폼 라벨)
  static const certificateNumberLabel = '자격증 번호';

  /// 선택사항 (자격증 번호 hint — optional indicator)
  static const certificateNumberHint = '선택사항';

  /// 자격증 이미지 (폼 라벨)
  static const certificateImageLabel = '자격증 이미지';

  /// 이미지 삭제 (이미지 제거 버튼)
  static const certificateImageDeleteLabel = '이미지 삭제';

  /// 제출된 자격증은 관리자의 검토 후 승인됩니다. 승인 후 프로필에 인증 뱃지가 표시됩니다. (정보 안내)
  static const certificateInfoBox =
      '제출된 자격증은 관리자의 검토 후 승인됩니다. 승인 후 프로필에 인증 뱃지가 표시됩니다.';

  /// 제출하기 (저장 버튼 — 신규 등록)
  static const certificateSubmitButton = '제출하기';

  /// 수정하기 (저장 버튼 — 편집)
  static const certificateUpdateButton = '수정하기';

  /// 자격증 이미지를 등록하세요 (빈 이미지 placeholder 타이틀)
  static const certificateImageEmptyTitle = '자격증 이미지를 등록하세요';

  /// 카메라 촬영 또는 갤러리에서 선택 (빈 이미지 placeholder 힌트)
  static const certificateImageEmptyHint = '카메라 촬영 또는 갤러리에서 선택';

  // ── Dashboard Tab (홈 대시보드 5-3d-2) ──────────────────────────────────

  /// 오늘의 레슨 — Programme 페이지 타이틀 (Notebook × Score 브랜드).
  static const dashboardProgrammeTitle = '오늘의 레슨';

  /// 레슨 카운트 — 한국어 서수 렌더링 (한/두/세 편의 수업).
  /// count == 0 일 때 '예정된 레슨 없음'.
  static String dashboardLessonCountFormat(int count) {
    if (count == 0) return '예정된 레슨 없음';
    const korean = ['한', '두', '세', '네', '다섯', '여섯', '일곱', '여덟', '아홉', '열'];
    final label = count <= korean.length ? korean[count - 1] : '$count';
    return '$label 편의 수업';
  }

  /// 레슨 로딩 실패 에러 카드 메시지.
  static const dashboardLessonsLoadError = '레슨을 불러올 수 없습니다';

  /// 이번 달 — 통계 카드 타이틀.
  static const dashboardThisMonth = '이번 달';

  /// 오늘 레슨 빈 상태 — 타이틀.
  static const dashboardEmptyTitle = '오늘 예정된 레슨이 없습니다';

  /// 오늘 레슨 빈 상태 — 서브타이틀.
  static const dashboardEmptySubtitle = '비어 있는 프로그램 — 새 레슨을 추가해 보세요.';

  /// 레슨 더보기 — 5건 초과 시 노출 ("12개 레슨 더보기").
  static String dashboardMoreLessonsFormat(int count) => '$count개 레슨 더보기';

  /// 통계 더보기 — Fine. 푸터 링크.
  static const dashboardAnalyticsMoreLink = '통계 더보기';

  // ── Getting Started Card (홈 온보딩 체크리스트 5-3d-3) ────────────────────

  /// Getting Started 인트로 안내 — 학생 0명일 때 노출.
  static const gettingStartedIntro = '아래 단계를 따라 레슨 관리를 시작하세요';

  /// Step 1 — 학생 등록 타이틀.
  static const gettingStartedStep1Title = '학생 등록하기';

  /// Step 1 — 학생 등록 서브타이틀.
  static const gettingStartedStep1Subtitle = '첫 학생을 추가해보세요';

  /// Step 2 — 레슨 일정 만들기 타이틀.
  static const gettingStartedStep2Title = '레슨 일정 만들기';

  /// Step 2 — 레슨 일정 만들기 서브타이틀.
  static const gettingStartedStep2Subtitle = '학생 등록 후 레슨을 추가하세요';

  /// Step 3 — 첫 레슨 완료 타이틀.
  static const gettingStartedStep3Title = '첫 레슨 완료하기';

  /// Step 3 — 첫 레슨 완료 서브타이틀.
  static const gettingStartedStep3Subtitle = '레슨을 탭해 완료 처리하세요';

  // ── Bottom Navigation (홈 화면 하단 탭 5-3d-6) ─────────────────────────
  /// 홈 (bottom nav label, 로마숫자 I)
  static const homeTabLabel = '홈';

  /// 수강관리 (bottom nav label, 로마숫자 III)
  static const studentsTabLabel = '수강관리';

  /// 프로필 (bottom nav label, 로마숫자 IV)
  static const profileTabLabel = '프로필';

  // ── Urgent Alert Zone (홈 긴급 메모 스트립 5-3d-7) ──────────────────────
  /// 입금 확인 대기 alert 텍스트 — 만원/원 단위 자동 선택 + 학생 수.
  /// 예: '입금 확인 대기 5만원 (3명)' / '입금 확인 대기 5000원 (1명)'
  static String urgentAlertOutstandingFormat(
    int totalAmount,
    int studentCount,
  ) {
    final formattedAmount =
        totalAmount >= 10000
            ? '${(totalAmount / 10000).toStringAsFixed(0)}만원'
            : '$totalAmount원';
    return '입금 확인 대기 $formattedAmount ($studentCount명)';
  }

  /// 접기 — expand toggle 축소 라벨.
  static const urgentAlertCollapse = '접기';

  /// 외 $count건 — expand toggle 확장 라벨.
  static String urgentAlertMoreFormat(int count) => '외 $count건';

  // ── Pending Requests Screen (연결 요청 대기 5-3d-10) ───────────────────
  /// 연결 요청 — AppBar 타이틀.
  static const pendingRequestsAppBarTitle = '연결 요청';

  /// 요청 목록을 불러올 수 없습니다 — 로드 에러 짧은 안내.
  static const pendingRequestsLoadErrorRetry = '요청 목록을 불러올 수 없습니다. 다시 시도해주세요.';

  /// 요청 목록을 불러오는 중 오류 — 로드 에러 위젯 본문.
  static const pendingRequestsLoadErrorDescription = '요청 목록을 불러오는 중 오류가 발생했습니다';

  /// 대기 중인 연결 요청이 없습니다 — empty state 타이틀.
  static const pendingRequestsEmptyTitle = '대기 중인 연결 요청이 없습니다';

  /// 학생이 초대 코드를 사용하면\n여기에 요청이 표시됩니다 — 선생님 시점.
  static const pendingRequestsEmptyTeacher = '학생이 초대 코드를 사용하면\n여기에 요청이 표시됩니다.';

  /// 선생님이 초대 코드를 사용하면\n여기에 요청이 표시됩니다 — 학생 시점.
  static const pendingRequestsEmptyStudent = '선생님이 초대 코드를 사용하면\n여기에 요청이 표시됩니다.';

  /// $name님과 연결되었습니다 — 수락 SnackBar.
  static String connectionAcceptedFormat(String name) => '$name님과 연결되었습니다!';

  /// 연결 거절 — 거절 다이얼로그 타이틀.
  static const connectionRejectDialogTitle = '연결 거절';

  /// $name님의 연결 요청을 거절하시겠습니까 — 거절 다이얼로그 본문.
  static String connectionRejectConfirmFormat(String name) =>
      '$name님의 연결 요청을 거절하시겠습니까?';

  /// 요청이 거절되었습니다 — 거절 SnackBar.
  static const connectionRejected = '요청이 거절되었습니다';

  /// $method로 연결 요청 — 연결 방법 메타 라벨.
  static String connectionMethodLabelFormat(String method) => '$method로 연결 요청';

  /// $days일 남음 — 만료까지 일수.
  static String daysRemainingFormat(int days) => '$days일 남음';

  /// $hours시간 남음 — 만료까지 시간.
  static String hoursRemainingFormat(int hours) => '$hours시간 남음';

  // ── Invite Screen (초대 생성 화면 5-3d-12) ──────────────────────────────
  /// 학생 초대하기 — AppBar 타이틀 (선생님 시점).
  static const inviteScreenTitleTeacher = '학생 초대하기';

  /// 선생님 연결하기 — AppBar 타이틀 (학생 시점).
  static const inviteScreenTitleStudent = '선생님 연결하기';

  /// 초대 내역 — history IconButton 툴팁.
  static const inviteHistoryTooltip = '초대 내역';

  /// 초대 링크 생성 중 오류 — error 타이틀.
  static const inviteCreateErrorTitle = '초대 링크 생성 중 오류가 발생했습니다';

  /// 잠시 후 다시 시도해주세요 — error 본문.
  static const inviteCreateErrorSubtitle = '잠시 후 다시 시도해주세요';

  /// $targetRole에게 QR 코드를 보여주거나 링크를 공유해주세요 — 헤더 안내.
  static String inviteShareGuideFormat(String targetRole) =>
      '$targetRole에게 QR 코드를 보여주거나 링크를 공유해주세요';

  /// QR 코드 — QR 카드 섹션 타이틀.
  static const qrCodeSectionTitle = 'QR 코드';

  /// 대면 수업 시 스캔하세요 — QR 카드 안내.
  static const qrCodeScanInstruction = '대면 수업 시 스캔하세요';

  /// 초대 코드 — 코드 카드 섹션 타이틀.
  static const inviteCodeSectionTitle = '초대 코드';

  /// 코드 복사 — copy IconButton 툴팁.
  static const inviteCodeCopyTooltip = '코드 복사';

  /// 앱에서 직접 입력할 수 있는 코드입니다 — 코드 카드 본문.
  static const inviteCodeManualEntryHint = '앱에서 직접 입력할 수 있는 코드입니다';

  /// 링크 공유하기 — primary share 버튼.
  static const inviteShareLinkButton = '링크 공유하기';

  /// 링크 복사 — secondary copy 버튼.
  static const inviteCopyLinkButton = '링크 복사';

  /// 카카오톡 — Kakao 공유 버튼.
  static const inviteKakaoButton = '카카오톡';

  /// 유효기간: $formatted — 만료 정보.
  static String inviteExpiryFormat(String formatted) => '유효기간: $formatted';

  /// 다른 방법으로 연결하기 — alternative options 섹션 헤더.
  static const inviteAlternativeOptionsTitle = '다른 방법으로 연결하기';

  /// QR 코드 스캔 — alternative ListTile 타이틀.
  static const inviteScanQrTitle = 'QR 코드 스캔';

  /// 학생의 QR 코드 스캔하기 — 선생님 시점 부제.
  static const inviteScanQrTeacherSubtitle = '학생의 QR 코드 스캔하기';

  /// 선생님의 QR 코드 스캔하기 — 학생 시점 부제.
  static const inviteScanQrStudentSubtitle = '선생님의 QR 코드 스캔하기';

  /// 6자리 코드로 연결하기 — code-input ListTile 부제.
  static const inviteCodeInputShortSubtitle = '6자리 코드로 연결하기';

  /// 선생님 검색 — teacher-search ListTile 타이틀 (학생 전용).
  static const inviteTeacherSearchTitle = '선생님 검색';

  /// 앱에서 선생님 찾기 — teacher-search ListTile 부제.
  static const inviteTeacherSearchSubtitle = '앱에서 선생님 찾기';

  /// 초대 코드가 복사되었습니다 — 코드 복사 SnackBar.
  static const inviteCodeCopiedSnack = '초대 코드가 복사되었습니다';

  /// 초대 링크가 복사되었습니다 — 링크 복사 SnackBar.
  static const inviteLinkCopiedSnack = '초대 링크가 복사되었습니다';

  /// 레슨앱 초대 공유 메시지 ($code, $url, $role) — multi-line share text.
  static String inviteShareMessageFormat(
    String code,
    String url,
    String role,
  ) =>
      '레슨앱에서 저와 함께해요!\n\n'
      '초대 코드: $code\n'
      '또는 링크: $url\n\n'
      '- $role 드림';

  /// 레슨앱 초대 — share subject.
  static const inviteShareSubject = '레슨앱 초대';

  // ── Invite History Screen (초대 내역 5-3d-14) ──────────────────────────
  /// 초대 목록을 불러올 수 없습니다. 다시 시도해주세요. — 로딩 실패.
  static const inviteHistoryLoadErrorRetry = '초대 목록을 불러올 수 없습니다. 다시 시도해주세요.';

  /// 초대 내역을 불러오는 중 오류가 발생했습니다 — 에러 화면 본문.
  static const inviteHistoryLoadErrorDescription = '초대 내역을 불러오는 중 오류가 발생했습니다';

  /// 생성한 초대가 없습니다 — 빈 상태 헤드라인.
  static const inviteHistoryEmptyTitle = '생성한 초대가 없습니다';

  /// 초대 링크를 생성하면\n여기에 기록이 표시됩니다. — 빈 상태 본문.
  static const inviteHistoryEmptyBody = '초대 링크를 생성하면\n여기에 기록이 표시됩니다.';

  /// 활성 초대 — 활성 섹션 헤더.
  static const inviteHistoryActiveSection = '활성 초대';

  /// 만료/취소된 초대 — 비활성 섹션 헤더.
  static const inviteHistoryInactiveSection = '만료/취소된 초대';

  /// 초대 취소 — 취소 다이얼로그 타이틀 + 카드 액션 버튼 라벨.
  static const inviteRevokeDialogTitle = '초대 취소';

  /// 이 초대 링크를 취소하시겠습니까?\n취소 후에는 이 코드로 연결할 수 없습니다. — 취소 다이얼로그 본문.
  static const inviteRevokeDialogContent =
      '이 초대 링크를 취소하시겠습니까?\n취소 후에는 이 코드로 연결할 수 없습니다.';

  /// 아니오 — 취소 다이얼로그 부정 버튼 (기존 표기 유지).
  static const inviteRevokeDialogNo = '아니오';

  /// 초대가 취소되었습니다 — 취소 완료 SnackBar.
  static const inviteRevokedSnack = '초대가 취소되었습니다';

  /// $count회 사용 — 초대 카드 사용 횟수.
  static String inviteUseCountFormat(int count) => '$count회 사용';

  /// 어제 — 1일 전 라벨.
  static const yesterdayLabel = '어제';

  // ── Feedback Template (선생님 피드백 템플릿) ─────────────────────

  static const feedbackTemplateMenuTitle = '피드백 템플릿';
  static const feedbackTemplateMenuSubtitle = '레슨 피드백 본문을 미리 등록';
  static const feedbackTemplateScreenTitle = '피드백 템플릿';
  static const feedbackTemplateAddTitle = '새 템플릿 추가';
  static const feedbackTemplateEditTitle = '템플릿 수정';
  static const feedbackTemplateEmptyTitle = '등록된 피드백 템플릿이 없습니다';
  static const feedbackTemplateEmptyBody = '자주 쓰는 피드백을 미리 등록해 1탭으로 사용하세요';
  static const feedbackTemplateTitleLabel = '제목';
  static const feedbackTemplateTitleHint = '예: 활 주법 연습';
  static const feedbackTemplateBodyLabel = '피드백 본문';
  static const feedbackTemplateBodyHint = '학생에게 전달할 피드백 전체 내용을 입력하세요';
  static const feedbackTemplateTagsLabel = '태그 (검색용)';
  static const feedbackTemplateTagsHint = '쉼표로 구분 (예: 음정, 리듬)';
  static const feedbackTemplateCategoryLabel = '카테고리';
  static const feedbackTemplatePickerTitle = '피드백 템플릿 선택';
  static const feedbackTemplatePickerSearchHint = '제목·본문·태그 검색';
  // §7.135 두 진입점 통일 → §7.137 누적 추가 반영 + 메모 톤 명사화.
  // 변천: "템플릿 선택"(모호) → "템플릿 가져오기"(1회성 import 뉘앙스)
  // → "템플릿으로 피드백 추가"(누적 가능 + 진입점 컨텍스트 명시).
  static const feedbackTemplatePickerSelectButton = '템플릿으로 피드백 추가';
  static const lessonNoteUndoTooltip = '되돌리기';
  static const lessonNoteUndoSnack = '되돌렸습니다';
  static const feedbackTemplatePickerFrequentSection = '자주 사용';
  static const feedbackTemplatePickerAllSection = '전체 템플릿';
  static const feedbackTemplatePickerEmptyResult = '검색 결과가 없습니다';
  static const feedbackTemplateReplaceConfirmTitle = '피드백 본문을 교체하시겠습니까?';
  static const feedbackTemplateReplaceConfirmContent =
      '현재 입력한 피드백이 선택한 템플릿으로 교체됩니다.';
  static const feedbackTemplateReplaceConfirmCta = '교체';
  static const feedbackTemplateAddedSnack = '템플릿이 추가되었습니다';
  static const feedbackTemplateUpdatedSnack = '템플릿이 수정되었습니다';
  static const feedbackTemplateDeletedSnack = '템플릿이 삭제되었습니다';
  static const feedbackTemplateAppliedSnack = '템플릿을 적용했습니다';
  static const feedbackTemplateValidateTitle = '제목을 입력하세요';
  static const feedbackTemplateValidateBody = '본문을 입력하세요';
}
