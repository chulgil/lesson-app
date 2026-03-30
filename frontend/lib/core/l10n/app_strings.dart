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
  static const requestClosed = '요청이 종료되었습니다';

  /// 시스템 가이드 메시지 (채팅 상단)
  static const requestGuideMessage =
      '학생이 제안한 일정 중 하나를 선택하여 수락하거나, 일정 비교로 다른 시간을 제안할 수 있습니다.';

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

  /// 시간확정
  static const statusTimeConfirmed = '시간확정';

  /// 시간협상 N
  static String statusNegotiating(int round) => '시간협상 $round';

  // ── Phase 2, 3 Status Labels ──────────────────────────────

  /// 수강권 발행됨
  static const statusSubscriptionIssued = '수강권발행';

  /// 레슨 진행중
  static const statusInProgress = '레슨진행';

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
  static const eventPaymentNotified = '결제 완료';
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
  static const chatReject = '요청이 종료되었습니다';
  static const chatProposeAlternative = '다른 시간을 제안했습니다';
  static const chatAcceptAlternative = '제안한 시간을 수락했습니다';
  static const chatCancel = '요청을 취소했습니다';
  static const chatExpire = '요청이 만료되었습니다';
  static const chatProposalSent = '수강권을 제안했습니다';
  static const chatProposalAccepted = '수강권을 수락했습니다';
  static const chatPaymentNotified = '결제가 완료되었습니다';
  static const chatCompleted = '수강권이 발급되었습니다';
  static const chatWithdrawApproval = '결정을 변경했습니다';
  static const chatPaymentRequested = '결제 안내를 보냈습니다';
  static const chatPaymentConfirmed = '입금이 확인되었습니다';
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
  static const phaseFilterCompleted = '완료';
  static const phaseFilterTerminal = '종료';

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

  // ── Action Box Phase 2,3,4 ─────────────────────────────────

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
  static const phase2TimeConfirmedTeacher =
      '시간이 확정되었습니다. 수강권을 발급해주세요.';
  static const phase2TimeConfirmedTrial =
      '체험레슨이 확정되었습니다.';
  static const phase2WaitingPaymentStudent =
      '결제 안내를 확인해주세요.';
  static const phase2PaymentReceivedTeacher =
      '학생이 입금 완료를 알렸습니다.';

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

  /// Proposal BottomSheet
  static const proposalTitle = '수강권 제안';
  static const proposalSelectTemplates = '수강권 선택 (최대 3개)';
  static const proposalBankAccount = '입금 계좌';
  static const proposalSend = '제안 보내기';
  static const proposalNoTemplates = '등록된 수강권 템플릿이 없습니다';
  static const proposalNoBankAccount = '등록된 계좌가 없습니다';

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
  static String waitingForPayment(String name) =>
      '$name의 입금을 기다리고 있습니다';

  /// Phase 3 progress message
  static String lessonProgressStatus(int completed, int total) =>
      '레슨 진행 중 ($completed/$total회)';

  /// Phase 3 waiting (student)
  static const actionRequestScheduleChange = '시간 변경 요청';

  // ── Attendance Confirmation ──────────────────────────────

  static const lessonConfirmation = '레슨 확인';
  static const lessonCompleted = '레슨 완료';
  static const lessonNotCompleted = '레슨 미진행';
  static const deductOne = '수강권 1회 차감';
  static const selectReason = '사유 선택 필요';
  static const nonCompletionReason = '레슨 미진행 사유';
  static const optionalNote = '추가 메모를 입력하세요 (선택)';
  static String lessonsNeedConfirmation(int count) =>
      '미확인 레슨 ${count}건';

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
  static String lessonRequestPending(int count) =>
      '레슨 요청 ${count}건 대기';

  /// 대기 중인 입금 확인
  static String paymentConfirmPending(int count) =>
      '입금 확인 ${count}건 대기';

  // ── Urgent Alert Zone (Dashboard) ──────────────────────────

  /// 만료된 수강권
  static String subscriptionExpired(int count) =>
      '만료 수강권 ${count}건';

  /// 임박한 수강권
  static String subscriptionExpiringSoon(int count) =>
      '수강권 임박 ${count}건';

  /// 예약 승인 대기
  static String pendingBookings(int count) =>
      '예약 승인 대기 ${count}건';

  // ── Subscription Card ─────────────────────────────────────

  /// 변경 횟수
  static String rescheduleCount(int remaining, int total) =>
      '변경: $remaining/$total회';

  /// 변경 불가
  static const rescheduleUnavailable = '변경 불가';

  /// 변경 1회 남음 경고
  static const rescheduleLastOne = '변경 1회 남음';

  /// 잔여 횟수 경고
  static String remainingLessonsWarning(int count) =>
      '잔여 ${count}회 - 갱신 권장';

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
}
