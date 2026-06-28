import 'string_overlay.dart';

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
  static const counterPropose = '다른 시간 제안하기';

  /// 입금 확인
  static const paymentConfirm = '입금 확인';

  /// 수강권
  static const subscription = '수강권';

  /// 학원 발행 수강권 배지
  static const academyIssuedBadge = '학원 발행';

  // ── Schedule Domain Visuals ───────────────────────────────

  static const lessonRequestTypeTrial = '체험레슨';
  static const lessonRequestTypeRegular = '정규레슨';
  static const lessonRequestTypePackage = '회차권';
  static const lessonGoalHobby = '취미';
  static const lessonGoalExam = '입시';
  static const lessonGoalMajor = '전공';
  static const lessonGoalOther = '기타';
  static const experienceLevelBeginner = '초급';
  static const experienceLevelIntermediate = '중급';
  static const experienceLevelAdvanced = '고급';
  static const makeupStatusPending = '예약 대기';
  static const makeupStatusScheduled = '예약됨';
  static const makeupStatusCompleted = '완료';
  static const makeupStatusExpired = '만료됨';
  static const makeupStatusWaived = '면제';
  static const makeupReasonStudentCancellation = '학생 취소';
  static const makeupReasonTeacherCancellation = '선생님 취소';
  static const makeupReasonNoShowReschedule = '노쇼 보강';
  static const makeupReasonOther = '기타';
  static const noShowPolicyDeductCredit = '회차 차감';
  static const noShowPolicyHalfCredit = '0.5회 차감';
  static const noShowPolicyNoDeduction = '차감 없음';
  static const noShowPolicyReschedule = '보강으로 전환';
  static const noShowPolicyDeductCreditDescription = '무단 결석 시 1회 차감됩니다';
  static const noShowPolicyHalfCreditDescription = '무단 결석 시 0.5회 차감됩니다';
  static const noShowPolicyNoDeductionDescription = '무단 결석 시에도 차감되지 않습니다';
  static const noShowPolicyRescheduleDescription = '무단 결석 시 보강 1회로 전환됩니다';
  static const scheduleCardTypeAfterTrial = '체험 후 등록';
  static const scheduleCardTypeReEnrollment = '재등록';
  static const scheduleCardTypeAdditionalInstrument = '추가 악기';
  static const scheduleCardSuggestionAfterTrial = '체험 레슨 시간으로 예약할까요?';
  static const scheduleCardSuggestionReEnrollment = '이전 스케줄로 예약할까요?';
  static const scheduleCardSuggestionAdditionalInstrument = '레슨 시간을 선택해주세요';
  static const scheduleCardStatusPending = '확인 대기';
  static const scheduleCardStatusConfirmed = '확정됨';
  static const scheduleCardStatusChangedTime = '시간 변경됨';
  static const scheduleCardStatusDismissed = '닫힘';

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

  /// 취소 처리 중 오류
  static const cancelError = '취소 처리 중 오류가 발생했습니다';

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

  /// 취소/변경 정책 안내 (레슨 요청 단계 — 수강권 발급 전이라 구체 시간 미정).
  /// 마감 기준은 수강권별 [Subscription.effectiveCancelDeadlineHours] 로 확정되며,
  /// 수강권 컨텍스트 화면은 [policyChangeSummary] 로 동적 표시한다.
  /// reschedule_credit_spec.md §3 — 고정 24h 표기는 실제 정책(기본 12h, 6~48h
  /// 선택)과 불일치하여 제거함 (2026-06-12 launch-readiness audit).
  static const cancellationPolicy =
      '마감 시간 전 취소·변경은 무료입니다. 마감 기준은 수강권 발급 시 확정돼요.';

  // ── Request Detail Screen ──────────────────────────────────

  /// 레슨 요청 상세 화면 제목
  static const requestDetailTitle = '레슨 요청 상세';

  /// 요청을 불러올 수 없음
  static const requestNotFound = '요청을 찾을 수 없습니다';

  /// 수정 버튼
  static const modify = '수정';

  /// 삭제 버튼
  static const delete = '삭제';

  /// 스와이프 편집 액션
  static const swipeActionEdit = '편집';

  /// 스와이프 삭제 액션 (destructive 단일 액션 통일 라벨 — swipe_action_consistency_audit §2 원칙 1).
  static const swipeActionDelete = '삭제';

  /// 스와이프 액션 접근성 힌트
  static const swipeActionHint = '스와이프 액션';

  /// 스와이프 연결 해제 액션 라벨 (관계/연결 카드용 destructive)
  static const swipeActionDisconnect = '연결 해제';

  /// 스와이프 연결 해제 확인 다이얼로그 — 제목
  static const swipeActionDisconnectConfirmTitle = '연결을 해제할까요?';

  /// 스와이프 연결 해제 확인 다이얼로그 — 본문
  static const swipeActionDisconnectConfirmBody = '이 학생과의 연결이 해제됩니다.';

  /// 스와이프 보관 액션 라벨 (레퍼토리 보관 destructive 톤 — practice v2 D2).
  static const swipeActionArchive = '보관';

  /// 스와이프 보관 확인 다이얼로그 — 제목 (레퍼토리 보관)
  static const swipeActionArchiveConfirmTitle = '이 레퍼토리를 보관할까요?';

  /// 스와이프 보관 확인 다이얼로그 — 본문 (복원 가능 안내)
  static const swipeActionArchiveConfirmBody = '보관함에서 복원할 수 있습니다.';

  /// 스와이프 영구 삭제 액션 라벨 (아카이브 영구 삭제 — practice v2 D3).
  static const swipeActionPermanentDelete = '영구 삭제';

  /// 스와이프 영구 삭제 확인 다이얼로그 — 제목 (강화 확인)
  static const swipeActionPermanentDeleteConfirmTitle = '영구 삭제할까요?';

  /// 스와이프 영구 삭제 확인 다이얼로그 — 본문 (복구 불가 강조)
  static const swipeActionPermanentDeleteConfirmBody = '복구할 수 없습니다.';

  /// 스와이프 편의 액션 — 공유 (좌→우 convenience 톤)
  static const swipeActionShare = '공유';

  /// 스와이프 편의 액션 — 재발송 (좌→우 convenience 톤)
  static const swipeActionResend = '재발송';

  /// 스와이프 편의 액션 — 기본설정 (좌→우 convenience 톤)
  static const swipeActionSetDefault = '기본설정';

  /// 스와이프 편의 액션 — 대표설정 (좌→우 convenience 톤)
  static const swipeActionSetRepresentative = '대표설정';

  /// 스와이프 편의 액션 — 복원 (좌→우 convenience 톤)
  static const swipeActionRestore = '복원';

  /// 스와이프 편의 액션 — 배정 (좌→우 convenience 톤)
  static const swipeActionAssign = '배정';

  /// 자녀 카드 액션 시트 — 학생 계정 전환
  static const childProfileActionsSwitchAccount = '학생 계정 전환';

  /// 자녀 카드 액션 시트 — 프로필 편집
  static const childProfileActionsEditProfile = '프로필 편집';

  /// 보관 버튼
  static const archive = '보관함으로 이동';

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

  /// 상대방 (fallback)
  static const opponent = '상대';

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

  /// 학원에 비공개 toggle label
  static const academyPrivacyLabel = '학원에 비공개';

  /// 학원에 비공개 toggle hint
  static const academyPrivacyHint = '이 일정을 학원에 비공개 처리하면 바쁨 상태만 표시됩니다';

  /// 발표회 (팔로우 게시글 유형)
  static const postTypePerformance = '발표회';

  /// 이벤트 (팔로우 게시글 유형)
  static const postTypeEvent = '이벤트';

  /// 공지사항 (팔로우 게시글 유형)
  static const postTypeNotice = '공지사항';

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

  /// 레슨 일정이 확정되었습니다
  static const lessonScheduleConfirmed = '레슨 일정이 확정되었습니다';

  /// 레슨을 요청했습니다 (접미사)
  static const lessonRequestSuffix = '레슨을 요청했습니다';

  /// 종료됨 (terminal 상태 하단바)
  static const requestClosed = '요청이 종료되었습니다';

  /// 가능한 일정 선택 섹션 제목
  static const availableSchedules = '가능한 일정';

  /// 슬롯 선택 힌트
  static const slotSelectionHint = '가능한 일정 중 하나를 선택해 확정하세요';

  /// 가능한 일정 없음
  static const noAvailableSchedules = '가능한 일정이 없습니다';

  /// 순위 접미사
  static const prioritySuffix = '순위';

  /// 선택됨 상태
  static const selected = '선택됨';

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

  /// 수강권 보기
  static const viewSubscription = '수강권 보기';

  /// 거절하기
  static const rejectAction = '거절하기';

  /// 승인하기
  static const approveAction = '승인하기';

  /// 시간을 선택하세요
  static const selectTimePrompt = '시간을 선택하세요';

  /// 유연 일정 역할 안내 카드 문구
  static const flexibleScheduleGuide = '유연한 일정은 매 레슨마다 학생과 시간을 조율해 잡습니다.';

  /// 제안하기 (N개)
  static String proposeAction(int count) => '제안하기 ($count개)';

  /// 최대 3개까지 선택 가능
  static const maxSlotsReached = '최대 3개까지 선택할 수 있습니다';

  /// 이미 수업이 있는 시간
  static const slotConflict = '이미 수업이 있는 시간입니다';

  /// 휴가/휴무 기간과 겹치는 시간 (#526 역제안 충돌 검증)
  static const slotVacationConflict = '휴가 기간입니다';

  /// 운영시간 밖 시간 (#526 역제안 충돌 검증)
  static const slotOutsideOperatingHours = '운영시간이 아닙니다';

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

  /// 미수금
  static const teacherWaitingPayment = '미수금';

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
  static String statusNegotiating(int round) => '시간 조율 중 ($round회차)';
  static const statusNegotiatingShort = '시간 조율 중';

  // ── Phase 2, 3 Status Labels ──────────────────────────────

  /// 수강권 발행됨
  static const statusSubscriptionIssued = '수강권 발행';

  /// 레슨 진행중
  static const statusInProgress = '레슨 진행';

  // ── Event Labels (for RequestEventType.label) ─────────────

  static const eventLessonRequest = '레슨 요청';
  static const eventApprove = '수락';
  static const eventReject = '거절';
  static const eventProposeAlternative = '다른 시간 제안하기';
  static const eventCounterPropose = '역제안';
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
  static const eventLessonCancellationConfirmed = '취소 확정';
  static const eventCancellationCreditRefunded = '무료 처리';
  static const eventLessonCancelledByTeacher = '휴강';
  static const eventTeacherAnnouncement = '공지';
  static const eventScheduleChanged = '스케줄 변경';
  static const eventLessonNoteAdded = '레슨 노트';
  static const eventScheduleChangeReminder = '응답 리마인드';
  static const eventMessage = '메시지';
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
  static const chatCompleted = '수강권이 준비됐어요';
  static const chatWithdrawApproval = '결정을 변경했습니다';
  static const chatPaymentRequested = '입금 안내를 보냈습니다';
  static const chatPaymentConfirmed = '입금을 확인했습니다';
  static const chatSubscriptionIssued = '수강권이 준비됐어요';
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

  // ── Schedule Change Expiry (#692) ─────────────────────────────
  static const chatScheduleChangeExpired = '이 변경 요청은 응답 없이 만료되었어요';
  static const eventScheduleChangeExpired = '일정 변경 만료';
  static const scheduleChangeExpiredRequesterAction = '다시 요청하기';
  static const scheduleChangeExpiredBannerTitle = '직접 연락을 권장해요';
  static const scheduleChangeExpiredBannerBody =
      '같은 회차에서 일정 변경 요청이 3회 연속 만료되었습니다. '
      '선생님께 직접 연락해 일정을 조율해 보세요.';

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
  static const scheduleChangeAccept = '선택한 일정으로 확정';
  static const scheduleChangeAccepted = '선택한 일정으로 확정했습니다';
  static const scheduleChangeReject = '거절';
  static const scheduleChangeCounter = '다른 시간 제안하기';
  static const scheduleChangeConfirmed = '시간이 변경되었습니다';

  // 일정 변경 협상 알림 (#541) — 상대에게 보내는 비동기 핸드오프 통지
  static const scheduleChangeNotifyProposedTitle = '일정 변경 제안';
  static const scheduleChangeNotifyAcceptedTitle = '일정 변경 수락';
  static const scheduleChangeNotifyRejectedTitle = '일정 변경 거절';
  static const scheduleChangeNotifyCounteredTitle = '일정 변경 역제안';
  static String scheduleChangeNotifyProposedBody(bool fromTeacher) =>
      '${fromTeacher ? '선생님' : '학생'}이 일정 변경을 제안했습니다.';
  static String scheduleChangeNotifyAcceptedBody(bool fromTeacher) =>
      '${fromTeacher ? '선생님' : '학생'}이 일정 변경을 수락했습니다.';
  static String scheduleChangeNotifyRejectedBody(bool fromTeacher) =>
      '${fromTeacher ? '선생님' : '학생'}이 일정 변경을 거절했습니다.';
  static String scheduleChangeNotifyCounteredBody(bool fromTeacher) =>
      '${fromTeacher ? '선생님' : '학생'}이 다른 시간을 제안했습니다.';
  static const scheduleChangeRecommended = '추천';
  static const scheduleChangeResponseNeeded = '일정 변경 응답이 필요합니다';
  static const scheduleChangeResponseAction = '일정 변경 응답 필요 →';

  // ── Schedule Change Response — reject reason / accept memo (#544/#545) ──
  static const scheduleChangeResponseMessageHint = '사유나 메모를 남겨주세요 (선택)';

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

  // ── Profile Labels (프로필 시트 공통 라벨) ─────────────────

  static const phoneLabel = '연락처';
  static const parentPhoneLabel = '학부모';
  static const levelLabel = '레벨';

  // ── Profile Menu ──────────────────────────────────────────

  /// 레슨 요청 관리 메뉴
  static const lessonRequestManagement = '레슨 요청 관리';

  /// 레슨 요청 관리 설명
  static const lessonRequestManagementDesc = '받은 레슨 요청 확인 및 관리';

  // ── Decline Bottom Sheet ───────────────────────────────────

  /// 바텀시트 제목
  static const declineBottomSheetTitle = '이 시간에 레슨이 어렵습니다';

  /// 메시지 입력 힌트
  static const messageHint = '전달할 메시지를 입력하세요';

  /// 수락 시 메시지 입력 힌트
  static const acceptMessageHint = '전달할 메시지 (선택)';

  /// 거절 시 디폴트 메시지
  static const declineDefaultMessage = '현재 가능한 시간이 없어 이번에는 어렵습니다.';

  /// 대안 제안 시 디폴트 메시지
  static const proposeDefaultMessage = '다른 시간을 제안드립니다.';

  // ── Reject Bottom Sheet (from schedule comparison) ─────────

  /// 거절 바텀시트 제목
  static const rejectBottomSheetTitle = '거절 메시지';

  /// 거절 바텀시트 안내
  static const rejectBottomSheetGuide = '전달할 거절 메시지를 입력해주세요.';

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
  static const actionBoxSubscriptionReady = '수강권이 준비됐어요. 레슨을 시작할 준비가 완료되었습니다.';

  /// 학생: 선생님 입금 확인 필요
  static const actionBoxWaitingVerify = '선생님의 입금 확인을 기다리고 있습니다';

  // ── Subscription Summary (Phase 3/4 chat) ──────────────────

  /// 수강권 요약 메시지
  static const subscriptionSummaryMessage = '수강권이 준비됐어요';

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
  static String teacherHomeConnectionRequestsTitle(int count) =>
      '학생 연결 요청 $count건';
  static const teacherHomeConnectionRequestsSubtitle =
      '초대코드로 가입한 학생을 승인하면 학생 목록에 추가됩니다';

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

  /// N회차 레슨 취소를 요청했어요
  static String sessionLessonCancelRequested(int n) => '$n회차 레슨 취소를 요청했어요';

  /// N회차 레슨이 취소되었습니다
  static String sessionLessonCancelled(int n) => '$n회차 레슨이 취소되었습니다';

  /// 변경/취소권 1회가 사용될 예정입니다. 잔여 N회
  static String cancelCreditWillBeUsed(int remaining) =>
      '변경/취소권 1회가 사용될 예정입니다. 잔여 $remaining회';

  /// 변경/취소권 1회가 사용되었습니다. 잔여 N회
  static String cancelCreditUsed(int remaining) =>
      '변경/취소권 1회가 사용되었습니다. 잔여 $remaining회';

  /// 취소 확정 후 다음 진행 회차 안내
  static String cancelKeepsSessionAfterRequest(int n) =>
      '확정되면 이번 일정만 건너뛰고, 다음 진행 레슨이 $n회차로 이어집니다.';

  /// 취소 확정 후 회차 차감 없음 안내
  static String cancelKeepsSubscriptionSession(int n) =>
      '수강권 회차는 차감되지 않으며, 다음 진행 레슨이 $n회차입니다.';

  /// 진행탭 취소 요약
  static String cancelProgressSummary(int n) =>
      '변경/취소권 1회 사용 예정 · 다음 진행 레슨은 $n회차';

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

  /// 입금 확인 필요
  static const paymentPending = '입금 확인 필요';

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
  static const subscriptionMessageHint = '확정 메시지를 남겨주세요 (선택)';
  static const subscriptionSendMessage = '메시지 전송';
  static const messageSentSuccess = '메시지를 전송했습니다';
  static const scheduleChangeButton = '일정 변경';
  static const scheduleChangeGuideDefault = '일정 변경이 필요하면 아래 버튼을 눌러 요청하세요';
  static const scheduleChange = '일정 변경';

  /// Cancellation confirmed — teacher bottom bar
  static String cancellationConfirmedTitle(int session) =>
      '$session회차 레슨이 취소되었습니다';
  static String cancellationCreditUsed(int used, int remaining) =>
      '변경/취소권 $used회 사용 · 잔여 $remaining회';
  static const cancellationNoCreditUsed = '마감 시간 전 취소 · 변경/취소권 미사용';
  static const rescheduleNoCreditUsed = '마감 시간 전 변경 · 변경/취소권 미사용';
  static const cancellationFreeProcess = '무료 처리';
  static const cancellationAcknowledge = '확인';
  static const cancellationFreeConfirmDialog =
      '이번 취소에 사용된 변경/취소권 1회를 돌려주시겠습니까?';
  static const cancellationFreeProcessed = '변경/취소권을 돌려주었습니다';
  static const cancellationCreditRefundedChat = '선생님이 변경/취소권을 돌려주었습니다';

  // Bulk teacher actions (§7.119 v2)
  static const chatLessonCancelledByTeacher = '레슨이 휴강 처리되었습니다';
  static const chatTeacherAnnouncement = '선생님 공지';
  static String bulkCancelSessionLabel(int session) => '$session회차 휴강';
  static const bulkCancelNoCreditDeduction = '※ 변경권 차감 없음';
  static String bulkCancelCreditRemaining(int remaining) =>
      '※ 변경권 차감 없음 (잔여 $remaining회)';
  static const bulkCancelKeepsSession = '※ 회차 번호 유지';
  static const bulkCancelRescheduleCta = '→ 보강 일정을 요청할 수 있어요';
  static const bulkMessageTargetActive = '활성 수강권 학생만';
  static const bulkMessageTargetAll = '선택된 전체 학생';
  static const selectAll = '전체 선택';
  static const deselectAll = '선택 해제';
  static const bulkMessageActiveOnlyNotice = '활성 수강권이 있는 학생에게만 전송됩니다';

  // v3 공지 시스템
  static const announcementTitle = '공지';
  static const announcementTypeDayOff = '휴강';
  static const announcementTypeGeneral = '일반 공지';
  static const announcementSelectDate = '날짜 선택';
  static const announcementMessageHint = '공지 내용을 입력하세요';
  static const announcementSend = '공지 보내기';
  static const announcementSending = '발송 중…';
  static const announcementSentTitle = '공지 발송 완료';
  static String announcementSentCount(int count) => '$count명에게 알림 발송';
  static const announcementAffectedHeader = '이 날 수업이 있는 학생';
  static const announcementNoAutoCancel =
      '※ 레슨은 자동 취소되지 않습니다.\n   개별 스케줄 변경을 진행해주세요.';
  static const announcementScheduleChange = '스케줄 변경';

  // 공지 이력
  static const announcementHistoryTitle = '공지 이력';
  static const announcementHistoryEmpty = '보낸 공지가 없습니다';
  static String announcementAffectedStudents(int count) => '영향 학생 $count명';
  static const announcementStatusResolved = '완료';
  static const announcementStatusPending = '미처리';

  /// Notification mock strings (i18n)
  static const notifProposalTitle = '수강권 제안이 도착했어요!';
  static const notifProposalBody = '체험레슨 후 72시간 골든타임 할인 혜택을 확인해보세요';
  static const notifProposalAction = '제안 확인하기';
  static String notifSubExpiringTitle(int days) => '수강권이 $days일 후 만료됩니다';
  static String notifSubExpiringBody(int remaining) =>
      '남은 횟수 $remaining회 · 갱신 요청을 보내보세요';
  static const notifSubExpiringAction = '수강권 확인';
  static String notifLessonsRunningLowTitle(int remaining) =>
      '수강권이 $remaining회 남았습니다';
  static const notifLessonsRunningLowBody = '남은 레슨 일정을 확인하고 갱신을 준비하세요';
  static const notifConnectionComplete = '연결 완료';
  static String notifConnectionTeacher(String name) => '$name님과 연결되었습니다';
  static String notifConnectionStudent(String name) =>
      '$name과 연결되었습니다! 지금 체험레슨을 예약해보세요.';
  static const notifViewStudent = '학생 보기';
  static const notifViewTeacher = '선생님 보기';
  static const notifLessonReminderTitle = '레슨 알림';
  static String notifLessonReminderTeacher(String student, String time) =>
      '$time $student 레슨이 있습니다';
  static String notifLessonReminderStudent(String teacher, String time) =>
      '$time $teacher과 레슨이 있습니다';
  static const notifTrialRequestTitle = '새 체험 요청';
  static String notifTrialRequestBody(String student, String instrument) =>
      '$student님이 $instrument 체험 레슨을 요청했습니다';
  static const notifTrialRequestAction = '요청 확인';
  static const notifPaymentReceivedTitle = '입금 완료 알림';
  static String notifPaymentReceivedBody(String student) =>
      '$student님이 수강료 입금 완료를 알렸습니다';
  static const notifPaymentReceivedAction = '입금 확인';
  static const notifPracticeReminderTitle = '연습 시간이에요!';
  static const notifPracticeReminderBody = '오늘의 연습 목표를 달성해보세요';
  static const notifStreakTitle = '연속 연습 달성!';
  static String notifStreakBody(int days) => '$days일 연속 연습을 달성했어요!';
  static const notifScheduleChangeTitle = '일정 변경 요청';
  static String notifScheduleChangeBody(String student, int session) =>
      '$student $session회차 레슨 일정 변경 요청';
  static const notifScheduleChangeAction = '변경 확인';
  static const viewDetail = '상세 보기';
  static const sessionUnit = '회';
  static const unregistered = '미등록';
  static const active = '수강 중';
  static const expiringSoon = '만료 예정';
  static const expired = '만료됨';

  /// Practice tab
  static const repertoireHistory = '레퍼토리 히스토리';
  static const repertoireAdd = '레퍼토리 추가';

  /// Trial lesson detail bottom sheet
  static const trialLessonDetail = '체험레슨 상세';
  static const instrumentLabel = '악기';
  static const lessonDate = '날짜';
  static const lessonTime = '시간';
  static const statusLabel = '상태';
  static const myMessage = '내 메시지';

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
      '좋은 아침이에요. 연습 일지 $streak일째예요!';
  static const timeBannerStudentMorningPractice = '좋은 아침이에요. 오늘 연습해볼까요?';
  static String timeBannerStudentLessonTime(String time) => '$time 레슨 시간이에요!';
  static String timeBannerStudentStreakKeep(int streak) =>
      '오늘도 연습 일지 $streak일째예요!';
  static String timeBannerStudentStreakGreat(int streak) =>
      '연습 일지 $streak일째를 채웠어요! 멋져요!';
  static String timeBannerStudentStreakContinue(int streak) =>
      '연습 일지 $streak일째 이어가고 있어요. 오늘도 기록해볼까요?';
  static const timeBannerStudentEveningAsk = '오늘 연습 어땠나요?';
  static String timeBannerStudentNightStreak(int streak) =>
      '오늘도 수고하셨어요. 연습 일지 $streak일째예요!';
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

  /// 취소 요청 완료 (마감 전 · 변경/취소권 미사용)
  static const cancelRequestCompletedFree = '취소 완료 · 마감 시간 전 취소로 변경/취소권 미사용';

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

  /// 챌린지 주기: 주간
  static const challengePeriodWeekly = '주간';

  /// 챌린지 주기: 월간
  static const challengePeriodMonthly = '월간';

  /// 챌린지 목표 포인트 표시
  static String challengeTargetPoints(int value) => '${value}P';

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

  /// 수강권 준비 완료 메시지
  static const subscriptionIssuedMessage = '수강권이 준비됐어요';

  /// 수강권 준비 후 스케줄 확인 안내
  static const subscriptionReadyScheduleNeeded = '첫 레슨 시간을 확인해주세요';

  /// 수강권 준비 후 스케줄 확정 안내
  static const subscriptionReadyScheduleConfirmed = '다음 레슨 일정에 맞춰 시작합니다';

  /// 후불 수강권 준비 안내
  static const subscriptionReadyPostpaid = '수강권은 준비됐고, 입금 확인은 나중에 진행됩니다';

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
  static const rangeOneWeek = '1주';
  static const rangeOneMonth = '1달';
  static const rangeThreeMonths = '3달';

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

  /// N회차 일정이 확정되었습니다
  static String sessionScheduleConfirmed(int n) => '$n회차 일정이 확정되었습니다';

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

  /// 변경 불가 (배지) — 마감 후 변경/취소권 소진
  static const bookingRescheduleImpossible = '변경 불가';

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
  static const bookingCancelFreeBeforeDeadline = '마감 전 취소는 변경권 차감 없이 무료입니다.';

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

  /// 예약 변경 롤백 실패 — 새 예약 취소까지 실패해 이중 예약이 남을 수 있음 (스낵바)
  static const bookingRescheduleRollbackFailed =
      '예약 변경에 실패했고 새 예약 정리도 실패했습니다. 예약 내역을 확인해주세요.';

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

  /// 그룹 클래스 정보를 불러올 수 없습니다 (route extra 누락 placeholder)
  static const groupClassInfoUnavailable = '그룹 클래스 정보를 불러올 수 없습니다.';

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
  static const waitlistAutoRebookInfo = '취소 발생 시 순서대로 예약됩니다';

  /// 대기 취소 (다이얼로그/버튼)
  static const waitlistCancelTitle = '대기 취소';

  /// 예약이 마감되었습니다
  static const bookingClosed = '예약이 마감되었습니다';

  /// 대기자로 등록하기
  static const joinWaitlist = '대기자로 등록하기';

  /// 예약하기
  static const bookAction = '예약하기';

  // ── 학생 직접 예약 (#580 student_direct_booking_spec) ──────────────
  /// 레슨 예약 (AppBar)
  static const lessonBookingTitle = '레슨 예약';

  /// 예약할 시간을 선택하세요 (슬롯 선택 안내)
  static const lessonBookingSelectTimeLabel = '예약할 시간을 선택하세요';

  /// 예약 확인 다이얼로그 제목
  static const lessonBookingConfirmTitle = '레슨 예약';

  /// 예약 확인 메시지: "6/10(화) 15:00 레슨을 예약할까요?"
  static String lessonBookingConfirmMessage(String date, String time) =>
      '$date $time 레슨을 예약할까요?';

  /// 예약 완료 스낵바: "6/10(화) 15:00 예약이 확정되었습니다"
  static String lessonBookingConfirmed(String date, String time) =>
      '$date $time 예약이 확정되었습니다';

  /// 예약 실패 (이미 다른 학생이 예약한 슬롯 등)
  static const lessonBookingFailed = '예약에 실패했습니다. 다른 시간을 선택해주세요';

  /// 리드타임 미달 안내: "최소 24시간 전에 예약할 수 있어요" (#850)
  static String lessonBookingTooSoon(int hours) => '최소 $hours시간 전에 예약할 수 있어요';

  /// 미리보기: "선생님 · 50분 · 잔여 N회"
  static String lessonBookingPreview(String teacher, int minutes) =>
      '$teacher · $minutes분';

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

  /// 레슨 1회 시간 (라벨) — G5 #9 spec §70 친숙 용어
  static const lessonDurationLabel = '레슨 1회 시간';

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

  /// 휴무 (요일 행 빈 상태)
  static const dayOff = '휴무';

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

  // ── Split 레이아웃 (G5 #433) ──────────────────────────────────

  /// Split 레이아웃 좌측 설정 패널 헤더
  static const availabilitySettingsPanel = '레슨 시간 설정';

  /// Split 레이아웃 우측 미리보기 헤더
  static const availabilityPreviewPanel = '학생이 보게 될 예약 화면';

  /// Split 레이아웃 미리보기 부제
  static const availabilityPreviewHint = '좌측 설정이 실시간으로 반영됩니다';

  /// 미리보기 — 예약 가능 시간 라벨
  static const previewAvailableSlot = '예약 가능';

  /// 미리보기 — 빈 상태 (요일 OFF)
  static const previewDayOff = '쉼';

  /// 미리보기 — 설정된 시간 없음 (모든 요일 OFF)
  static const previewEmptyHint = '주간 레슨 시간을 설정하면 미리보기가 표시됩니다';

  /// 레슨 1회 시간 옵션 단위 라벨
  static String lessonDurationOptionLabel(int minutes) => '$minutes분';

  /// 쉬는 시간 옵션 — 0분일 때 표시
  static const breakTimeNoneOption = '없음';

  /// 모바일 fallback 안내 (현재 미사용, 향후 sticky 미리보기 토글 시 활용)
  static const previewToggleLabel = '미리보기';

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

  /// 같은 요일에 겹치는 시간대가 있습니다 — [start, start+duration) 구간 중복 검증 메시지
  static const slotTimeOverlap = '같은 요일에 겹치는 시간대가 있습니다. 시간을 다시 선택해주세요';

  /// 신규 학생 (기본값)
  static const newStudentDefault = '신규 학생';

  /// 정규레슨이 등록되었습니다 (성공 토스트)
  static const regularLessonRegistered = '정규레슨이 등록되었습니다';

  /// 정규레슨 등록 — 일부 회차가 기존 일정과 겹쳐 제외됨 (부분 성공 토스트, #301)
  static String regularLessonRegisteredWithConflicts(int skipped) =>
      '정규레슨이 등록되었습니다 ($skipped개 회차는 기존 일정과 겹쳐 제외)';

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

  /// 학생 선택 바텀시트 빈 상태 타이틀
  static const studentPickerEmptyTitle = '등록된 학생이 없습니다';

  /// 학생 등록 CTA
  static const studentRegisterAction = '학생 등록';

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

  /// 사전 취소 (LessonStatus.cancelledByStudentAdvance label)
  static const statusAdvanceCancel = '사전 취소';

  /// 합의 취소 (LessonStatus.cancelledMutual label)
  static const statusMutualCancel = '합의 취소';

  /// 학생 불참 (LessonStatus.studentAbsent label)
  static const statusStudentAbsent = '학생 불참';

  /// 변경 대기 (LessonStatus.reschedulePending label)
  static const statusReschedulePending = '변경 대기';

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
  static const cancelLessonConfirm = '이 레슨을 취소하시겠습니까?\n학생에게 취소 알림이 전송됩니다.';

  /// 레슨 삭제 다이얼로그 제목
  static const deleteLessonTitle = '레슨 삭제';

  /// 레슨 삭제 확인 다이얼로그 메시지 (녹음/노트 동반 삭제 경고 포함)
  static const deleteLessonConfirm = '이 레슨을 삭제하시겠습니까?\n녹음 파일과 노트도 함께 삭제됩니다.';

  /// 레슨 보관 다이얼로그 제목
  static const archiveLessonTitle = '보관함으로 이동';

  /// 레슨 보관 확인 다이얼로그 메시지
  static const archiveLessonConfirm =
      '이 레슨을 보관하시겠습니까?\n보관된 레슨은 목록에서 숨겨지며 언제든지 복원할 수 있습니다.';

  /// 레슨이 보관되었습니다 (archive success)
  static const lessonArchivedSnack = '레슨이 보관되었습니다';

  /// 레슨 보관에 실패했습니다. (archive failure)
  static const archiveLessonFailed = '레슨 보관에 실패했습니다. 다시 시도해주세요.';

  /// 연습 팁 수정 다이얼로그 제목
  static const editPracticeTipTitle = '연습 팁 수정';

  /// 연습 팁 입력 hint
  static const editPracticeTipHint = '연습 팁을 입력하세요';

  /// 학생 메모 카드 제목
  static const studentMemoTitle = '내 메모';

  /// 학생 메모 입력 hint
  static const studentMemoHint = '오늘 배운 것, 어려웠던 점 등을 메모하세요...';

  /// 연락처·메모 카드 (정보 탭 #24/#25)
  static const studentContactSectionTitle = '연락처 · 메모';
  static const studentContactStudentLabel = '학생';
  static const studentContactParentLabel = '학부모';
  static const studentContactAddressLabel = '주소';
  static const studentContactMemoLabel = '학생 메모';

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

  /// 편집 (수기 레슨 action label) — 레거시
  static const editManual = '전체 수정';

  /// 내용 수정 (수강권 레슨 content-only edit action label) — 레거시
  static const editContent = '곡/메모 수정';

  /// 내용 수정 subtitle
  static const editContentSubtitle = '곡/메모 수정';

  /// 편집 (수기) subtitle
  static const editManualSubtitle = '모든 항목 수정 가능';

  // §13.2 v2 액션 시트 라벨
  static const editManualFull = '수기 등록 레슨 편집';
  static const scheduleChangeLabel = '일정 변경';

  /// 수강권 레슨 잠금 필드 안내 배너
  static const subscriptionFieldLocked = '수강권 레슨의 날짜/시간 변경은\n스케줄 변경에서 진행해주세요.';

  /// 스케줄 변경으로 이동 링크 텍스트
  static const goToScheduleChange = '스케줄 변경으로 이동 →';

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
  static const feedbackSavedSnack = '피드백이 저장되었습니다';

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

  /// 수강권 없는 학생 레슨 추가 시 안내 — 체험권 자동연결 (spec §2.4: 선생님은 수강권을 의식하지 않는다)
  static const noActiveSubscriptionBanner =
      '이 레슨은 1회 체험 수강권으로 자동 연결됩니다.\n'
      '수강권을 발급하면 이후 레슨 횟수와 이동시간이\n'
      '자동으로 관리됩니다.';
  static String activeSubscriptionBanner(int remaining, int total) =>
      '수강권 $remaining/$total회 남음 · 이 레슨은 1회차로 차감됩니다.';

  // === 다수 활성 수강권 선택 (spec §2.5) ===

  /// 수강권 선택 (multi-subscription picker sheet title)
  static const manualLessonPickerTitle = '수강권 선택';

  /// 시트 부제 — 여러 활성 수강권 중 차감 대상 선택 안내
  static const manualLessonPickerSubtitle =
      '활성 수강권이 여러 개입니다. 이 레슨을 차감할 수강권을 선택하세요.';

  /// 추천(권장 선택) 배지 — 만료 임박 우선
  static const manualLessonPickerRecommendedBadge = '만료 임박';

  /// 배너 CTA — 활성 N개, 선택 필요
  static String manualLessonSelectSubscriptionPrompt(int count) =>
      '활성 수강권 $count개 · 차감할 수강권을 선택하세요';

  /// 악기 상속 칩 — 수강권(멤버십)에서 상속
  static String manualLessonInstrumentInherited(String instrument) =>
      '악기 $instrument · 수강권 상속';

  /// 악기 칩 — 학생 정보 기준 (수강권 0개)
  static String manualLessonInstrumentFromStudent(String instrument) =>
      '악기 $instrument';

  /// 변경 (reopen picker)
  static const manualLessonChangeSubscription = '변경';

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

  /// 학생과 공유하기 토스트 — #808 요약 공유 링크 복사 성공.
  static const lessonSummaryShareCopied = '학생과 공유하기 · 링크가 복사되었습니다';

  /// 요약 공유 실패 — #808.
  static const lessonSummaryShareError = '공유 링크 생성에 실패했습니다. 다시 시도해주세요.';

  /// 완료 처리 (mark complete menu item)
  static const markComplete = '완료 처리';

  /// 레슨이 취소되었습니다 (lesson cancelled snack)
  static const lessonCancelled = '레슨이 취소되었습니다';

  /// 레슨 취소에 실패했습니다. 다시 시도해주세요. (lesson cancel failed)
  static const lessonCancelFailed = '레슨 취소에 실패했습니다. 다시 시도해주세요.';

  /// 수강권에서 취소 (cancel via subscription menu item)
  static const cancelViaSubscription = '수강권에서 취소';

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

  /// 참고 녹음 추가 (add recording resource sheet short title)
  static const addRecordingTitle = '참고 녹음 추가';

  /// 새로 녹음하기 (record new button)
  static const recordNew = '새로 녹음하기';

  /// 파일에서 선택 (select from file button)
  static const selectFile = '파일에서 선택';

  /// 녹음 중... (recording in progress label)
  static const recordingInProgressLabel = '녹음 중...';

  /// 녹음 완료 (recording complete label)
  static const recordingComplete = '녹음 완료';

  /// 녹음 제목을 입력하세요 (recording title hint text)
  static const recordingTitleHintText = '녹음 제목을 입력하세요';

  /// 학생에게 전달할 메모 (선택) (recording memo hint)
  static const recordingMemoHint = '학생에게 전달할 메모 (선택)';

  /// 최대 50MB (m4a/mp3/wav) (max file size note)
  static const maxFileSize = '최대 50MB (m4a/mp3/wav)';

  /// 녹음을 시작할 수 없습니다 (cannot start recording)
  static const cannotStartRecording = '녹음을 시작할 수 없습니다';

  /// 마이크 권한이 필요합니다 (microphone permission needed)
  static const micPermissionNeeded = '마이크 권한이 필요합니다';

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

  /// 유튜브 검색 (youtube search option label)
  static const youtubeSearch = '유튜브 검색';

  /// 유튜브 검색 시트 제목
  static const youtubeSearchTitle = '유튜브 검색';

  /// 유튜브 검색창 힌트 텍스트
  static const youtubeSearchHint = '검색어를 입력하세요';

  /// 유튜브 검색 결과 선택 버튼
  static const youtubeSearchSelect = '선택';

  /// URL 직접 입력 링크 라벨
  static const youtubeSearchDirectUrl = 'URL 직접 입력 →';

  /// 검색 결과 없음
  static const youtubeSearchNoResults = '검색 결과가 없습니다';

  /// 통합 검색 힌트 (URL + 검색어)
  static const youtubeSearchUnifiedHint = '유튜브 링크 또는 검색어 입력';

  /// 검색 전 안내
  static const youtubeSearchEmptyState = '유튜브 링크를 붙여넣거나\n검색어를 입력하세요';

  /// 유튜브 링크 추가 (add youtube link option — URL direct input)
  static const addYoutubeLink = 'URL 직접 입력';

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

  /// #806 만료임박 카드 교사용 갱신 제안 CTA — 이전 수강권 프리필 발급 화면 진입.
  static const subscriptionRenewProposeCta = '갱신 제안';

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
  static const proposalReminder72hTitleDiscount = '특별 할인이 곧 종료됩니다!';

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
  static const templateRecommendedBadgeStar = '추천';

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

  // -- Subscription Policy Override Screen (수강권 단위 override 화면) --

  /// 수강권 취소 정책 (override 화면 제목)
  static const subscriptionPolicyOverrideTitle = '수강권 취소 정책';

  /// 학원 귀속 수강권 read-only 안내
  static const subscriptionPolicyOverrideAcademyReadOnly =
      '학원 귀속 수강권입니다. 정책은 학원 관리자만 변경할 수 있습니다.';

  /// override 화면 푸터
  static const subscriptionPolicyOverrideFooter =
      'ⓘ 이 값들은 본 수강권에만 적용됩니다. 기본값을 바꾸려면 설정 화면에서 변경하세요.';

  /// 시트 행 — override 미설정 (기본값 사용)
  static const subscriptionPolicyUsingDefault = '기본값 사용';

  /// 시트 행 — 1개 이상 override 적용 중
  static const subscriptionPolicyOverridden = '개별 설정 적용';

  /// 변경/취소 마감 시간 안내 (기본값)
  static String policyDeadlineHoursHelper(int defaultHours) =>
      '기본값: $defaultHours시간 전. 이 시간 안에 학생이 변경하면 변경권을 차감합니다.';

  /// 학생 변경권 자동 적립 (라벨)
  static const policyCompensationCreditLabel = '학생 변경권 자동 적립';

  /// 학생 변경권 자동 적립 안내 (기본값 ON/OFF)
  static String policyCompensationCreditHelper(bool defaultEnabled) =>
      '기본값: ${defaultEnabled ? "켜짐" : "꺼짐"}. 강사 사유 12시간 이내 취소 시 학생에게 변경권 1회를 자동으로 적립합니다.';

  /// 추가 시간 안내 문구 포함 (라벨)
  static const policyIncludeExtraMinutesTextLabel = '"추가 시간 안내" 문구 포함';

  /// 추가 시간 안내 문구 포함 안내
  static String policyIncludeExtraMinutesTextHelper(bool defaultEnabled) =>
      '기본값: ${defaultEnabled ? "켜짐" : "꺼짐"}. 학생에게 보내는 카톡에 "다음 레슨 추가 시간 안내" 문구를 포함합니다.';

  /// 안내 문구 (라벨)
  static const policyCompensationMessageLabel = '안내 문구';

  /// 안내 문구 도움말 (기본값 메시지가 있을 때)
  static String policyCompensationMessageHelper(String? defaultMessage) =>
      defaultMessage == null || defaultMessage.isEmpty
      ? '비워두면 기본 안내 문구가 사용됩니다.'
      : '기본값: "$defaultMessage" — 본 수강권의 카톡 본문에 사용됩니다.';

  /// 안내 문구 placeholder
  static const policyCompensationMessageHint =
      '예) 다음 레슨 시 10분 추가 시간을 안내드릴 예정입니다.';

  /// 학원 관리자 알림 (라벨)
  static const policyNotifyOwnerLabel = '학원 관리자에게 알림';

  /// 학원 관리자 알림 안내
  static String policyNotifyOwnerHelper(bool defaultEnabled) =>
      '기본값: ${defaultEnabled ? "켜짐" : "꺼짐"}. 강사 사유 12시간 이내 취소 시 학원 관리자에게 푸시 알림을 보냅니다.';

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

  /// 월 회차 (월정기 한 달 레슨 횟수 입력 라벨)
  static const issueFormMonthlyLessonsTitle = '월 회차';

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
      '후불 수강권은 먼저 발급하고 나중에 입금받습니다. 아직 입금 완료 기록이 없는 수강권은 미수금으로 관리됩니다.';

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
  static const issueFormBonusTitle = '추가 증정 회차';

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

  /// 미수금 (입금 미확인 시 표기)
  static const issueFormSummaryUnpaidLabel = '미수금';

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

  /// 입금 확인 중 (대기 카드 제목)
  static const proposalWaitingTitle = '입금 확인 중';

  /// 대기 카드 본문 (멀티라인)
  static const proposalWaitingBody =
      '선생님이 입금을 확인하면 수강권이 발급됩니다.\n입금 확인까지 1~2일 정도 소요될 수 있습니다.';

  /// 선생님께 문의하기 (대기 카드 CTA)
  static const proposalWaitingContactCta = '선생님께 문의하기';

  /// 입금 계좌 재확인 (대기 카드 — 결제 후 계좌 다시 보기, #773)
  static const proposalReconfirmAccountCta = '입금 계좌 재확인';

  // -- Payment Pending Visibility (#693) --

  /// 입금 완료 알림 전송 직후 SnackBar — "선생님에게 전달되었어요"
  static const paymentNotifiedSnackbar = '선생님에게 전달되었어요';

  /// paymentNotified 상태 버튼 라벨 (비활성)
  static const paymentNotifiedButtonLabel = '입금 확인 대기 중';

  /// 제안 상세 paymentNotified 배너 — 수강권 발급 안내
  static const proposalPaymentPendingBannerBody = '선생님이 입금을 확인하면 수강권이 발급돼요';

  /// 3단계 프로그레스 — 1단계 라벨
  static const paymentProgressStep1 = '입금 알림';

  /// 3단계 프로그레스 — 2단계 라벨
  static const paymentProgressStep2 = '확인 대기';

  /// 3단계 프로그레스 — 3단계 라벨
  static const paymentProgressStep3 = '수강권 발급';

  /// 학부모 홈 결제 섹션 — paymentNotified 제안 섹션 헤더
  static const parentHomePaymentPendingSection = '입금 확인 대기 중';

  /// 학부모 홈 결제 섹션 — paymentNotified 제안 카드 본문
  static const parentHomePaymentPendingBody = '선생님의 입금 확인을 기다리고 있어요';

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
  /// 입금 확인 필요
  static const proposalPaymentStatusPending = '입금 확인 필요';

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

  /// 카드 결제
  static const paymentMethodCard = '카드';

  /// 기타 (입금 수단)
  static const paymentMethodOther = '기타';

  // Subscription payment status / type / status / summary
  /// 입금 확인 완료
  static const paymentStatusPaid = '입금 확인 완료';

  /// 미수금
  static const paymentStatusUnpaid = '미수금';

  /// 입금 확인 필요
  static const paymentStatusNeedsConfirmation = '입금 확인 필요';

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
  static String bonusText(int count, String reason) => '+$count회 ($reason)';

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

  /// N만 M원
  static String amountManwonWithRemainder(int man, int remainder) =>
      '$man만 $remainder원';

  /// N원
  static String amountWon(int amount) => '$amount원';

  /// N개월
  static String monthCount(int count) => '$count개월';

  /// N일
  static String dayCount(int count) => '$count일';

  /// N회 이상: V% 할인
  static String packageDiscountPolicyText({
    required int minLessons,
    required int value,
  }) => '$minLessons회 이상: $value% 할인';

  /// N회 이상: +V회 무료
  static String packageBonusPolicyText({
    required int minLessons,
    required int value,
  }) => '$minLessons회 이상: +$value회 무료';

  /// N회 · D분 · 가격
  static String subscriptionTemplateSummaryText({
    required int totalLessons,
    required int durationMinutes,
    required String priceLabel,
  }) => '$totalLessons회 · $durationMinutes분 · $priceLabel';

  /// N회 · D분 (가격을 별도로 표시할 때 — 템플릿 카드 정가/할인 행)
  static String subscriptionTemplateSummaryNoPrice({
    required int totalLessons,
    required int durationMinutes,
  }) => '$totalLessons회 · $durationMinutes분';

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

  /// 선생님 레슨실 (LocationType.teacherStudio chip label)
  static const locationTeacherHomeLabel = '선생님 레슨실';

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

  /// 이동시간 입력 필드 레이블
  static const travelTimeInputLabel = '이동시간';

  /// 분 접미사
  static const travelTimeMinutesSuffix = '분';

  /// API 제안 힌트: (카카오 기준 약 N분)
  static String travelTimeSuggestion(int minutes, String source) =>
      '($source 기준 약 $minutes분)';

  /// 추가금 참고 표시: 참고 추가금: +N,000원/회
  static String travelSurchargeReference(int amount) {
    final formatted = _formatWithComma(amount);
    return '참고 추가금: +$formatted원/회';
  }

  /// 추가금 자동 계산 설명
  static const travelSurchargeDescription = '선생님 시급 기준 자동 계산';

  /// 숫자를 천단위 쉼표 포맷으로 변환 (intl 없이 경량 구현)
  static String _formatWithComma(int value) {
    final s = value.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return value < 0 ? '-${buf.toString()}' : buf.toString();
  }

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

  /// 후불(선불 미확인) 발급 직후 — 미수금 추적 안내 (검토 #848).
  static const subscriptionIssuePostpaidSuccess =
      '수강권을 발급했어요. 입금 확인은 미수금에서 추적하세요';

  /// 연결 수락 직후 교사 다음 단계 CTA (검토 #848).
  static const connectionAcceptedIssueCta = '수강권 발급';

  /// 발급 실패. 다시 시도해주세요. (snackbar: 발급 실패)
  static const subscriptionIssueFailRetry = '발급 실패. 다시 시도해주세요.';

  /// $count명에게 수강권이 발급되었습니다 (snackbar: 일괄 발급 전체 성공)
  static String batchSubscriptionIssueSuccess(int count) =>
      '$count명에게 수강권이 발급되었습니다';

  /// $success명 발급 완료, $fail명 실패 (snackbar: 일괄 발급 부분 성공)
  static String batchSubscriptionIssuePartial(int success, int fail) =>
      '$success명 발급 완료, $fail명 실패';

  /// 일괄 발급 중 이미 제안이 있어 건너뛴 학생들 (검토 #849).
  static String batchSubscriptionSkipped(String names) =>
      '이미 진행 중인 제안이 있어 건너뜀: $names';

  /// 일괄 발급 실패 학생들 (검토 #849).
  static String batchSubscriptionFailed(String names) => '발급 실패: $names';

  // -- Subscription Display Layer (badge + status colors, P2 5-3b-7a) --

  /// $remain/$total회 (badge format for package subscription)
  static String subscriptionPackageBadgeFormat(int remain, int total) =>
      '$remain/$total회';

  /// 미수금 (badge — 후불 결제 미입금)
  static const subscriptionBadgeUnpaid = '미수금';

  /// 수강권 없음 (badge — 활성 수강권 0건, 학생탭 래퍼 전용)
  static const subscriptionBadgeNone = '수강권 없음';

  /// D-$days (badge — 정기권 만료까지 일수. 기존 인라인 'D-$days' 형식화)
  static String subscriptionBadgeDday(int days) => 'D-$days';

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
  static const subscriptionDetailHeader = '상세';

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
  static const subscriptionMonthlyCarryoverWarning = '미사용분 소멸 (이월 불가)';

  /// 유효기간 내 자유롭게 사용 (회차권 카드 안내)
  static const subscriptionPackageFreeUseInfo = '유효기간 내 자유롭게 사용';

  // -- Proposal Confirm Screen (입금 확인 5-3b-9) --

  /// 입금 확인이 필요한 제안이 없습니다 (빈 상태 타이틀)
  static const proposalConfirmEmptyTitle = '입금 확인이 필요한 제안이 없습니다';

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

  // [검토 #47] 입금 일괄 확인 (다건 체크박스)
  /// 선택 N건 일괄 입금확인 (하단 일괄 액션 바)
  static String paymentBatchConfirmAction(int n) => '선택 $n건 일괄 입금확인';

  /// 일괄 입금 확인 (확인 다이얼로그 타이틀)
  static const paymentBatchConfirmDialogTitle = '일괄 입금 확인';

  /// N명에게 수강권을 발급합니다 ... (확인 다이얼로그 본문)
  static String paymentBatchConfirmDialogBody(int n, String amount) =>
      '$n명에게 수강권을 발급합니다. 입금을 모두 확인하셨나요?\n합계 $amount';

  /// 발급하기 (일괄 확인 다이얼로그 확인 버튼)
  static const paymentBatchIssueConfirm = '발급하기';

  /// N건 발급 완료 (일괄 전건 성공 SnackBar)
  static String paymentBatchConfirmResultAll(int n) => '$n건 발급 완료';

  /// M건 발급 완료, K건 실패 (일괄 부분 성공 SnackBar)
  static String paymentBatchConfirmResultPartial(int ok, int fail) =>
      '$ok건 발급 완료, $fail건 실패';

  /// 입금자명 {name} (통장 대조용 예금주 표시)
  static String paymentDepositorFormat(String name) => '입금자명 $name';

  // [검토 #48] 입금 미확인 → 확인 보류 상태 기록
  /// 확인 보류 (입금 미확인으로 표시한 항목 배지)
  static const paymentHoldBadge = '확인 보류';

  /// 마지막 문의 {time} (확인 보류 카드 부가 캡션)
  static String paymentInquiryRecordedFormat(String time) => '마지막 문의 $time';

  /// 전체 N (보류 필터 — 전체 칩)
  static String paymentFilterAllCount(int n) => '전체 $n';

  /// 보류 N (보류 필터 — 보류 칩)
  static String paymentFilterHoldCount(int n) => '보류 $n';

  /// 학생이 아직 수강권을 선택하지 않았습니다 (멀티초이스 미선택 가드)
  static const proposalAwaitingTemplateSelection = '학생이 아직 수강권을 선택하지 않았습니다';

  /// 입금 내역을 확인할 수 없습니다.\n학생에게 확인 요청 메시지를 보내시겠습니까? (Inquiry 다이얼로그 본문)
  static const paymentInquiryDialogBody =
      '입금 내역을 확인할 수 없습니다.\n학생에게 확인 요청 메시지를 보내시겠습니까?';

  /// 메시지 보내기 (Inquiry 다이얼로그 확인 버튼)
  static const sendMessage = '메시지 보내기';

  /// 확인 요청 메시지를 보냈습니다 (Inquiry 전송 후 snackbar)
  static const inquiryMessageSent = '확인 요청 메시지를 보냈습니다';

  /// 최근에 요청을 보냈어요 ... (입금 확인 요청 쿨다운 — 409)
  static const paymentInquiryCooldown = '최근에 요청을 보냈어요. 잠시 후 다시 시도해 주세요';

  /// 요청 전송에 실패했어요 ... (입금 확인 요청 실패)
  static const paymentInquiryFailed = '요청 전송에 실패했어요. 잠시 후 다시 시도해 주세요';

  /// 아직 앱에 가입하지 않은 학생 ... (미가입 학생 — notified=false)
  static const paymentInquiryNoAccount = '아직 앱에 가입하지 않은 학생이라 알림을 보낼 수 없어요';

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

  /// 전달할 메시지를 입력하세요 (메시지 입력 hint)
  static const proposalCreateMessageHint = '전달할 메시지를 입력하세요';

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

  /// 이번 제안을 스킵했습니다 (거절 SnackBar)
  static const proposalDetailSkippedSnackbar = '이번 제안을 스킵했습니다';

  // ── Proposal Issued — 수강권 발급 완료 후 첫 레슨 CTA (audit C2-F02) ──

  /// 수강권 발급 완료 후 학생용 CTA — subscription detail 로 이동
  /// (proposal_detail_screen.dart 의 confirmed status 액션바)
  static const proposalDetailViewSubscriptionAction = '내 수강권 보고 첫 레슨 잡기';

  /// 수강권 발급 완료 상단 안내 (confirmed 액션바 위 hint)
  static const proposalDetailIssuedHint = '수강권이 발급되었어요. 이제 첫 레슨 일정을 잡아볼까요?';

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
  static const policySummaryHeader = '정책 요약';

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

  /// 미수금 관리 (관련 설정 항목)
  static const policyTuitionManagement = '미수금 관리';

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

  /// #769: 발급 방식 차이 캡션 — 교사 즉시 발급.
  static const unifiedSubscriptionDirectIssueCaption = '교사가 즉시 발급';

  /// #769: 발급 방식 차이 캡션 — 학생 수락·입금 후 발급(제안).
  static const unifiedSubscriptionProposalCaption = '학생 수락·입금 후 발급';

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

  /// #412 과제 진척 — 연습 누적 횟수 (예: "3회 연습"). 완료와 별개 표시.
  static String practiceProgressCount(int n) => '$n회 연습';

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

  // ── Subscription Template List Screen (수강권 템플릿 관리 5-3b-24) ────────

  /// 수강권 템플릿 관리 (AppBar)
  static const templateListAppBarTitle = '수강권 템플릿 관리';

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

  /// 수강권 템플릿 수정 (편집 바텀시트 헤더)
  static const templateEditSheetTitle = '수강권 템플릿 수정';

  /// 수강권 템플릿 추가 (추가 바텀시트 헤더)
  static const templateAddSheetTitle = '수강권 템플릿 추가';

  /// 이름 * (이름 필드 라벨)
  static const templateNameLabel = '이름 *';

  /// 예: 8회권, 기본 패키지 (이름 필드 hint)
  static const templateNameHint = '예: 8회권, 기본 패키지';

  /// 이름을 입력해주세요 (이름 validator)
  static const templateNameRequired = '이름을 입력해주세요';

  /// 판매가 (원) * (판매가 필드 라벨 — 실제 결제 금액)
  static const templatePriceLabel = '판매가 (원) *';

  /// 예: 400000 (판매가 필드 hint)
  static const templatePriceHint = '예: 400000';

  /// 판매가를 입력해주세요 (판매가 validator — 빈값)
  static const templatePriceRequired = '판매가를 입력해주세요';

  /// 숫자만 입력해주세요 (판매가 validator — 비숫자)
  static const templatePriceNumbersOnly = '숫자만 입력해주세요';

  /// 정가 (원) (정가 필드 라벨 — 할인 표시용, 선택)
  static const templateRegularPriceLabel = '정가 (원)';

  /// 예: 500000 (정가 필드 hint)
  static const templateRegularPriceHint = '예: 500000';

  /// 악기 (가격표 연동 드롭다운 라벨)
  static const templateInstrumentLabel = '악기';

  /// 악기·레벨 선택 시 정가 자동 입력 안내
  static const templatePriceAutofillHint = '악기·레벨을 선택하면 정가가 자동 입력됩니다';

  /// 정가 대비 N% 할인 (작성 시트 미리보기)
  static String templateDiscountPreview(int percent) => '정가 대비 $percent% 할인';

  /// N% 할인 (카드 할인율 배지)
  static String templateDiscountRate(int percent) => '$percent% 할인';

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

  // ── Analytics Dashboard Tabs (분석 대시보드 탭 — Refs #354) ──────────────

  /// 분석 (AnalyticsDashboardScreen AppBar 타이틀)
  static const analyticsTitle = '분석';

  /// 월간 요약 (Tab 1 라벨)
  static const analyticsMonthlySummary = '월간 요약';

  /// 학생 성장 (Tab 2 라벨)
  static const analyticsStudentGrowth = '학생 성장';

  /// 수입 분석 (Tab 3 라벨)
  static const analyticsRevenue = '수입 분석';

  /// 학생 선택 드롭다운 플레이스홀더
  static const analyticsSelectStudent = '학생 선택';

  /// 기간 선택 드롭다운 1개월
  static const analyticsPeriod1Month = '1개월';

  /// 기간 선택 드롭다운 3개월
  static const analyticsPeriod3Months = '3개월';

  /// 기간 선택 드롭다운 6개월
  static const analyticsPeriod6Months = '6개월';

  /// 기간 선택 드롭다운 12개월
  static const analyticsPeriod12Months = '12개월';

  /// 완료율 StatCard 타이틀
  static const analyticsCompletionRateLabel = '완료율';

  /// 취소율 StatCard 타이틀
  static const analyticsCancellationRateLabel = '취소율';

  /// 수강료 수입 StatCard 타이틀
  static const analyticsRevenueLabel = '수강료 수입';

  /// 활성 학생 StatCard 타이틀
  static const analyticsActiveStudentsLabel = '활성 학생';

  /// 이동시간 StatCard 타이틀
  static const analyticsTravelTimeLabel = '이동시간';

  /// 미수금 StatCard 타이틀
  static const analyticsPendingLabel = '미수금';

  /// 예상 수입 StatCard 타이틀
  static const analyticsExpectedLabel = '예상 수입';

  /// 만료 임박 StatCard 타이틀
  static const analyticsExpiringLabel = '만료 임박';

  /// N% 포매터 (달성률)
  static String analyticsRatePercent(double rate) =>
      '${(rate * 100).toStringAsFixed(1)}%';

  /// N% 포매터 (정수)
  static String analyticsIntPercent(int percent) => '$percent%';

  /// 이동 Nh시간 Nm분 포매터
  static String analyticsTravelTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m분';
    if (m == 0) return '$h시간';
    return '$h시간 $m분';
  }

  /// 전월 대비 +N.N% / -N.N%
  static String analyticsVsPrevMonth(double percent) {
    final sign = percent >= 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}% 전월 대비';
  }

  /// N명 대기 (미수금 카드 부제)
  static String analyticsPendingWaiting(int count) => '$count명 대기';

  /// 이번 달 만료 N개
  static String analyticsExpiringThisMonth(int count) => '이번 달 만료 $count개';

  /// 활성 수강권 N개 기준
  static String analyticsExpectedBasis(int count) => '활성 수강권 $count개 기준';

  /// 학생별 수입 비중 (섹션 헤더)
  static const analyticsStudentRevenuePortion = '학생별 수입 비중';

  /// 월별 수입 추이 (섹션 헤더)
  static const analyticsMonthlyRevenueTrend = '월별 수입 추이';

  /// 연습률 (학생 성장 탭 라벨)
  static const analyticsPracticeRateLabel = '연습률';

  /// 출석률 (학생 성장 탭 라벨)
  static const analyticsAttendanceRateLabel = '출석률';

  /// 레퍼토리 진도 (섹션 헤더)
  static const analyticsRepertoireProgress = '레퍼토리 진도';

  /// 녹음 기록 (섹션 헤더)
  static const analyticsRecordingHistory = '녹음 기록';

  /// 피드백 요약 (섹션 헤더)
  static const analyticsFeedbackSummary = '피드백 요약';

  /// 연습 시간 추이 (섹션 헤더)
  static const analyticsPracticeTrend = '연습 시간 추이';

  /// 연습률 / 출석률 (학생 목록 행 부제 포매터)
  static String analyticsStudentRates(
    double practiceRate,
    double attendanceRate,
  ) {
    final pr = (practiceRate * 100).round();
    final ar = (attendanceRate * 100).round();
    return '연습 $pr% · 출석 $ar%';
  }

  /// 학생 데이터가 없습니다 (빈 상태)
  static const analyticsNoStudentData = '학생 데이터가 없습니다';

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

  // ── Practice Backup Phase 1 (practice §6.3 — Issue #497) ────────────────
  /// 백업 (Phase 1 다이얼로그/메뉴 공통 타이틀)
  static const backupTitle = '백업';

  /// 백업 내보내기 (ZIP 생성 CTA)
  static const backupExport = '백업 내보내기';

  /// 백업 복원 (ZIP 복원 CTA)
  static const backupRestore = '백업 복원';

  /// 백업 생성 중... (진행 다이얼로그 헤더 — create)
  static const backupExporting = '백업 생성 중...';

  /// 백업 복원 중... (진행 다이얼로그 헤더 — restore)
  static const backupRestoring = '백업 복원 중...';

  /// 백업이 완료되었습니다. (스낵바 — create success)
  static const backupSuccess = '백업이 완료되었습니다.';

  /// 백업에 실패했습니다. (스낵바 — create/restore failure 헤더)
  static const backupFailure = '백업에 실패했습니다.';

  /// 백업을 복원하시겠습니까? 중복되는 파일은 건너뜁니다. (복원 확인 다이얼로그 본문)
  static const backupRestoreConfirm = '백업을 복원하시겠습니까? 중복되는 파일은 건너뜁니다.';

  /// ZIP 인코딩에 실패했습니다. (archive 패키지 encode 반환 null 시 throw)
  static const backupEncodeFailure = 'ZIP 인코딩에 실패했습니다.';

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

  /// 녹음 삭제 실패 피드백 (#707 — silent fail 방지).
  static const allRecordingsDeleteError = '녹음 삭제에 실패했어요. 잠시 후 다시 시도해주세요';

  /// swipe destructive 확인 다이얼로그 — 녹음 삭제 title
  static const swipeActionDeleteRecordingConfirmTitle = '녹음 삭제';

  /// swipe destructive 확인 다이얼로그 — 녹음 삭제 body
  static const swipeActionDeleteRecordingConfirmBody =
      '이 녹음을 영구적으로 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.';

  /// 녹음 행 BottomSheet — 재생 액션 라벨
  static const recordingActionsPlay = '재생';

  /// 녹음 행 BottomSheet — 공유 액션 라벨 (시스템 공유)
  static const recordingActionsShare = '공유';

  /// 녹음 행 BottomSheet — 섹션 링크 변경/연결 액션 라벨
  static const recordingActionsCopyLink = '링크 변경';

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

  /// 레슨 로딩 실패 — 부드러운 재시도 상태 타이틀(에러처럼 보이지 않게).
  static const dashboardLessonsLoadErrorTitle = '레슨을 잠시 불러오지 못했어요';

  /// 레슨 로딩 실패 — 재시도 안내 서브타이틀.
  static const dashboardLessonsLoadErrorHint = '네트워크를 확인하고 다시 시도해 주세요';

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

  /// 오늘의 레슨 섹션 제목.
  static const dashboardTodayLessonsSection = '오늘의 레슨';

  /// Demo dashboard overlay eyebrow.
  static const demoDashboardOverlayEyebrow = '둘러보기 예시';

  /// Demo dashboard overlay title.
  static const demoDashboardOverlayTitle = '샘플 대시보드 둘러보기';

  /// Demo dashboard overlay body.
  static const demoDashboardOverlayDescription =
      '샘플 학생, 오늘의 레슨, 시작 체크리스트를 보며 실제 운영 흐름을 확인하세요.';

  /// Demo dashboard overlay dismiss button.
  static const demoDashboardOverlayConfirm = '확인';

  /// Demo dashboard overlay never show again button.
  static const demoDashboardOverlayNeverShowAgain = '다시 보지 않기';

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

  /// Step 4 — 첫 레슨 노트 작성 타이틀.
  static const gettingStartedStep4Title = '첫 레슨 노트 작성';

  /// Step 4 — 첫 레슨 노트 작성 서브타이틀.
  static const gettingStartedStep4Subtitle = '레슨 후 피드백을 남겨보세요';

  /// Step 5 — 전화번호 인증 타이틀.
  static const gettingStartedStep5Title = '전화번호 인증하기';

  /// Step 5 — 전화번호 인증 서브타이틀.
  static const gettingStartedStep5Subtitle = '안전한 수업 관리를 위해 연락처를 확인하세요';

  // ── Quest Board (프로필 완성도 퀘스트 보드) ───────────────────────────────

  // ── Onboarding v3 ──
  static const onboardingFieldName = '이름';
  static const onboardingFieldInstrument = '악기';
  static const onboardingIntroOptionalHint = '나중에 작성해도 돼요';

  /// Quest Board 섹션 헤더 라벨.
  static const questBoardTitle = '준비 체크리스트';

  /// Quest Board 인트로 안내 — 프로필 완성 유도.
  static const questBoardIntro = '프로필을 완성하면 학생에게 더 많이 노출돼요!';

  // §13 퀘스트 시스템 — 3-group 분류 헤더 (Job 4)
  /// 그룹 1 — 프로필 설정 (Q1~Q5, 학생에게 보일 정보 준비).
  static const questGroupProfileLabel = '프로필 설정';

  /// 그룹 2 — 운영 시작 (Q6~Q10, 실제 레슨 운영 흐름).
  static const questGroupOperationLabel = '운영 시작';

  /// 그룹 3 — 선택 보너스 (Q11, 신뢰도 강화 보상).
  static const questGroupBonusLabel = '선택 보너스';

  /// 선택 보너스 그룹 라벨 (점선 카드 외).
  static const questGroupBonusOptionalTag = '선택';

  /// Lock 토스트 — Q7~Q10 클릭 시 Q6 으로 이동 안내.
  static const questLockedStudentRequiredToast = '먼저 학생을 초대해주세요';

  /// Lock hint — Q7~Q10 카드 reward 영역 (학생 없을 때).
  static const questLockedStudentRequiredHint = '학생 초대 후 진행 가능';

  // §13 퀘스트 임계값 hint (Job 6) — 스펙 §9 완료 임계값 공개
  /// Q3 소개글 — 최소 20자 임계값 hint (카드 본문 표시).
  static const questThresholdIntroHint = '최소 20자 입력 시 완료';

  /// Q4 레슨비 — 최소 1개 가격 항목 임계값 hint.
  static const questThresholdPriceHint = '최소 1개 가격 항목 등록 시 완료';

  /// Q10 숙제 — 1건 등록 임계값 hint.
  static const questThresholdPracticeHint = '1건 등록 시 완료';

  // §8.3 전체 완료 축하 카드 (Job 7-FE)
  /// 축하 카드 제목 — 11/11 완료 시 1회 표시.
  static const questCelebrationTitle = '모든 준비를 마치셨어요!';

  /// 축하 카드 본문.
  static const questCelebrationBody = '이제 본격적으로 레슨을 운영해보세요.';

  /// 축하 카드 액션 1 — 오늘의 레슨.
  static const questCelebrationActionLessons = '오늘의 레슨 보기';

  /// 축하 카드 액션 2 — 주간 통계 (현재 라우트 미존재, practiceStats 로 대체).
  static const questCelebrationActionStats = '주간 통계';

  /// 축하 카드 dismiss 라벨 (semantics + IconButton tooltip).
  static const questCelebrationDismiss = '닫기';

  // §B3 잠금 해제 축하 시트 (감사 §4.5) — Q6 (첫 학생 초대) 완료 직후 1회 표시.
  /// 잠금 해제 시트 제목.
  static const questUnlockCelebrationTitle = '잠금 해제!';

  /// 잠금 해제 시트 본문.
  static const questUnlockCelebrationMessage =
      '학생 초대, 수강권 발급, 레슨 등록, 메모, 연습 과제 퀘스트가 열렸어요.';

  /// 잠금 해제 시트 CTA.
  static const questUnlockCelebrationAction = '계속하기';

  /// Quest I — 이름 + 악기 설정 타이틀.
  static const questTitleNameInstrument = '이름 + 악기 설정';

  /// Quest II — 레슨 시간 설정 타이틀.
  static const questTitleSlots = '레슨 시간 설정';

  /// Quest III — 첫 학생 초대 타이틀.
  static const questTitleStudent = '첫 학생 초대';

  /// Quest IV — 프로필 사진 추가 타이틀.
  static const questTitlePhoto = '프로필 사진 추가';

  /// Quest V — 소개글 작성 타이틀.
  static const questTitleIntro = '소개글 작성';

  /// Quest VI — 레슨비 설정 타이틀.
  static const questTitlePrice = '레슨비 설정';

  /// Quest VII — 전화번호 인증 타이틀.
  static const questTitlePhone = '전화번호 인증';

  /// Quest 보상 — 학생 예약 가능.
  static const questRewardSlots = '학생 예약 가능';

  /// Quest 보상 — 연결 시스템 활성화.
  static const questRewardConnection = '연결 시스템 활성화';

  /// Quest 보상 — 학생 검색 노출.
  static const questRewardSearch = '학생 검색 노출';

  /// Quest 보상 — 웹 프로필 공유 가능.
  static const questRewardWebProfile = '웹 프로필 공유 가능';

  /// Quest 보상 — 학생에게 가격 표시.
  static const questRewardPrice = '학생에게 가격 표시';

  /// Quest 보상 — 인증 선생님 배지.
  static const questRewardVerified = '인증 선생님 배지';

  // Verification Badge — 프로필/카드에 표시되는 인증 칩
  /// 인증 배지 라벨 — 전화인증 완료한 선생님.
  static const verificationBadgePhoneLabel = '인증 선생님';

  /// 인증 배지 라벨 — 자격증 승인된 선생님.
  static const verificationBadgeCertifiedLabel = '자격증 인증';

  /// 인증 배지 라벨 — 프리미엄 프로필 (100% 완성).
  static const verificationBadgePremiumLabel = '프리미엄';

  // Quest Board — Action Phase (실제 레슨 운영)
  static const questTitleBankAccount = '입금 계좌 등록';
  static const questRewardBankAccount = '학생에게 입금 안내 가능';
  static const questTitleSubscription = '첫 수강권 발급';
  static const questRewardSubscription = '레슨 관리 시작';
  static const questTitleFirstLesson = '첫 레슨 완료';
  static const questRewardFirstLesson = '레슨 워크플로우 완성';
  static const questTitleLessonNote = '레슨 메모 작성';
  static const questRewardLessonNote = '학생에게 피드백 전달';
  static const questTitlePracticeAssign = '연습 과제 등록';
  static const questRewardPracticeAssign = '학생 연습 관리 시작';

  // Quest Board — Phase C (보상 퀘스트)
  /// #430 G1 — 선택 보상 퀘스트: 전화인증 → 인증 선생님 배지.
  /// 정책: docs/specs/user/phone_verification_policy.md §2.
  static const questTitlePhoneVerification = '전화인증';

  // ── OnboardingProgress required quest checklist (#602) ───────────────
  // OnboardingQuest 표시 문자열 — 도메인 엔티티에서 이전. id → 라벨 매핑은
  // features/onboarding/presentation/extensions/onboarding_quest_visuals.dart.
  // 식별자: profile-created, first-student, first-lesson, first-note, phone-verified.
  static const onboardingQuestProfileCreatedTitle = '프로필 생성';
  static const onboardingQuestProfileCreatedDescription =
      '선생님 프로필을 최소 정보로 완성합니다.';
  static const onboardingQuestFirstStudentTitle = '첫 학생 추가';
  static const onboardingQuestFirstStudentDescription = '첫 학생을 등록합니다.';
  static const onboardingQuestFirstLessonTitle = '첫 레슨 등록';
  static const onboardingQuestFirstLessonDescription = '첫 레슨 일정을 등록합니다.';
  static const onboardingQuestFirstNoteTitle = '첫 레슨 노트 작성';
  static const onboardingQuestFirstNoteDescription = '첫 레슨 피드백을 남깁니다.';
  static const onboardingQuestPhoneVerifiedTitle = '전화번호 인증';
  static const onboardingQuestPhoneVerifiedDescription = '전화번호 인증을 완료합니다.';

  // ── Bottom Navigation (홈 화면 하단 탭 5-3d-6) ─────────────────────────
  /// 홈 (bottom nav label, 로마숫자 I)
  static const homeTabLabel = '홈';

  /// Student/parent bottom navigation home tab.
  static const navHome = '홈';

  /// Student/parent bottom navigation lessons tab.
  static const navLessons = '레슨';

  /// Student bottom navigation practice tab.
  static const navPractice = '연습';

  /// Student/parent bottom navigation profile tab.
  static const navProfile = '프로필';

  /// Parent bottom navigation assignments tab.
  static const navAssignments = '과제';

  /// Parent bottom navigation payments tab.
  static const navPayments = '입금';

  /// 수강관리 (bottom nav label, 로마숫자 III)
  static const studentsTabLabel = '수강관리';

  /// 프로필 (bottom nav label, 로마숫자 IV)
  static const profileTabLabel = '프로필';

  // ── Urgent Alert Zone (홈 긴급 메모 스트립 5-3d-7) ──────────────────────
  /// 미수금 alert 텍스트 — 만/원 단위 정확 표기 + 학생 수.
  /// 예: '미수금 5만 5000원 (3명)' / '미수금 5000원 (1명)'
  static String urgentAlertOutstandingFormat(
    int totalAmount,
    int studentCount,
  ) {
    final String formattedAmount;
    if (totalAmount >= 10000) {
      final man = totalAmount ~/ 10000;
      final remainder = totalAmount % 10000;
      formattedAmount = remainder == 0 ? '$man만원' : '$man만 $remainder원';
    } else {
      formattedAmount = '$totalAmount원';
    }
    return '미수금 $formattedAmount ($studentCount명)';
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

  /// 학부모 초대 코드 유효기간 안내(다이얼로그) — #799 일원화.
  static const inviteParentValidityNote = '* 코드는 24시간 동안 유효합니다';

  /// 학부모 초대 공유 텍스트 내 유효기간 줄 — #799.
  static const inviteParentShareValidity = '유효기간: 24시간 (발급 후 24시간 이내 입력)';

  /// 학부모 초대 코드 입력(수신) 화면 유효기간 캡션 — #799.
  static const inviteParentCodeValidityHint = '초대 코드는 발급 후 24시간 이내 유효합니다';

  /// 학생 초대 코드 입력(수신) 화면 유효기간 캡션 — #799.
  static const inviteStudentCodeValidityHint = '초대 코드는 발급 후 7일 이내 유효합니다';

  /// 학생/동료 초대 공유 메시지 내 유효기간 줄 — #799.
  static const inviteStudentShareValidity = '유효기간: 7일 (발급 후 7일 이내 입력)';

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

  /// 레슨앱 초대 공유 메시지 — multi-line share text.
  ///
  /// 선생님 케이스에서 [senderName] 과 [instruments] 가 비어있지 않으면
  /// "악기 선생님 OOO" 형태의 헤더를 추가해 카톡 미리보기에서 신뢰도를 높인다.
  static String inviteShareMessageFormat(
    String code,
    String url,
    String role, {
    String? senderName,
    List<String> instruments = const [],
  }) {
    final hasIdentity = senderName != null && senderName.isNotEmpty;
    final header = hasIdentity
        ? (instruments.isEmpty
              ? '$senderName $role님이 레슨앱에 초대했어요!'
              : '${instruments.join(', ')} $role $senderName 님이 레슨앱에 초대했어요!')
        : '레슨앱에서 저와 함께해요!';
    final signature = hasIdentity ? '- $senderName $role 드림' : '- $role 드림';
    return '$header\n\n'
        '초대 코드: $code\n'
        '또는 링크: $url\n\n'
        '$inviteStudentShareValidity\n\n'
        '$signature';
  }

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

  // ── Search ──
  static const searchFilter = '필터';
  static const searchFilterReset = '초기화';
  static const searchFilterApply = '필터 적용';
  static const searchCertifiedTeachersOnly = '자격증 인증 선생님만';
  static const searchCertifiedTeachersSubtitle = '검증된 자격증을 보유한 선생님';
  static const searchFindTeacher = '선생님 찾기';
  static const searchLessonApply = '레슨 신청';
  static const searchRestartLesson = '다시 시작하기';
  static const searchTrialApply = '체험 신청';
  static const searchAffiliatedTeachers = '소속 선생님';
  // Search — i18n (2026-05-06)
  static const searchTabAcademy = '학원';
  static const searchTabIndividual = '개인 선생님';
  static const searchContextHint = '학원 또는 개인 선생님을 검색해 레슨을 신청하세요';
  static const searchHintAcademy = '학원 이름, 악기, 지역으로 검색';
  static const searchHintTeacher = '선생님 이름, 악기, 지역으로 검색';
  static const searchErrorOccurred = '검색 중 오류가 발생했습니다';
  static const searchClearAllFilters = '전체 해제';
  static const searchNoAcademiesFound = '검색된 학원이 없습니다';
  static const searchNoTeachersFound = '검색된 선생님이 없습니다';
  static const searchTrySuggestion = '다른 검색어나 필터를 시도해보세요';
  static const searchPreviousTeacher = '이전에 레슨했어요';
  static const searchProfileLoadError = '프로필을 불러올 수 없습니다';
  static const searchProfileNotFound = '선생님 정보를 찾을 수 없습니다';
  static const searchAnonymousTeacher = '익명 선생님';
  static const searchSpecialtyInstrumentTitle = '전문 악기';
  static const searchLessonStyleTitle = '수업 방식';
  static const searchLessonAreaTitle = '수업 지역';
  static const searchCareerDetailTitle = '경력 사항';
  static const searchCertifiedTitle = '인증된 자격증';
  static const searchPreviousLessonTeacher = '이전에 레슨을 받았던 선생님입니다';
  static const searchPremiumProfileLabel = '프리미엄 프로필';
  static const searchLessonTypeInPerson = '대면 수업';
  static const searchLessonTypeVisit = '방문 수업';
  static const searchAcademyLoadError = '학원 정보를 불러올 수 없습니다';
  static const searchAcademyNotFound = '학원 정보를 찾을 수 없습니다';
  static const searchAcademyTeacherListError = '선생님 목록을 불러올 수 없습니다';
  static const searchAcademyNoPublicTeachers = '공개된 강사 정보가 없습니다';
  static const searchFilterLessonInPerson = '대면 레슨';
  static const searchFilterLessonOnline = '온라인 레슨';
  static const searchFilterLessonVisit = '방문 레슨';
  static const searchLessonRequestInfo = '선생님에게 레슨 신청서가 전달됩니다';
  static const searchScopeAll = '전체';
  static const searchScopeTeachers = '선생님';
  static const searchScopeStudents = '학생';
  static const searchScopeLessons = '레슨';
  static const searchResultTeacher = '선생님';
  static const searchResultStudent = '학생';
  static const searchResultLesson = '레슨';
  static const searchResultPractice = '연습';
  static String searchExperienceYears(int years) => '$years년 이상';
  // Sort labels
  static const sortRelevance = '관련도순';
  static const sortExperienceDesc = '경력 높은순';
  static const sortExperienceAsc = '경력 낮은순';
  static const sortFeeAsc = '레슨료 낮은순';
  static const sortFeeDesc = '레슨료 높은순';
  static const sortRating = '평점순';
  static const sortCompletionLevel = '프로필 완성도순';
  // Lesson type
  static const lessonTypeInPerson = '대면';
  static const lessonTypeOnline = '온라인';
  static const lessonTypeVisit = '방문';
  // Filter section titles
  static const filterInstruments = '악기';
  static const filterLocation = '지역';
  static const filterLessonType = '레슨 방식';
  static const filterMinExperience = '최소 경력';
  // Fee range (search_master.md §39, 2026-06-04)
  static const filterFeeRange = '레슨료 범위 (원)';
  static const filterFeeMinHint = '최소';
  static const filterFeeMaxHint = '최대';
  // Profile completion level (search_master.md §42, 2026-06-04)
  static const filterMinCompletionLevel = '최소 프로필 완성도';
  static const completionAny = '상관없음';
  static const completionBasic = '기본 (60%+)';
  static const completionStandard = '표준 (80%+)';
  static const completionComplete = '완전 (100%)';
  // Experience options
  static const experienceAny = '상관없음';
  static const experience3plus = '3년 이상';
  static const experience5plus = '5년 이상';
  static const experience10plus = '10년 이상';

  // ── Invite / Connection ──
  static const inviteHowToConnect = '연결 방법 알아보기';
  static const inviteConnectWithTeacher = '선생님과 연결하는 방법';
  static const inviteViewLessonSchedule = '레슨 일정 보기';
  static const inviteSendMessage = '메시지 보내기';
  static const inviteDisconnect = '연결 해제';
  static const inviteReconnect = '다시 연결';
  static const inviteConnectionRequest = '연결 요청';
  static const inviteSendConnectionRequest = '연결 요청 보내기';
  static const inviteConnectionFailed = '연결 요청에 실패했습니다';
  static const inviteGoHome = '홈으로';
  static const inviteLessonBooking = '레슨 예약';
  static const inviteStudentList = '학생 목록';
  static const inviteInviter = '초대한 사람';
  static const inviteCode = '초대 코드';
  static const inviteValidPeriod = '유효기간';
  static const inviteMessageHint = '간단한 자기소개나 인사말을 작성해주세요';

  // ── Onboarding ──
  static const onboardingRoleSelect = '역할 선택';
  static const onboardingPhoneVerification = '휴대폰 인증';
  static const onboardingContinueWithQuest = '퀘스트 보드에서 계속';
  static const onboardingProfileSetup = '프로필 설정';
  static const onboardingTutorial = '튜토리얼';
  static const onboardingCompleted = '완료';
  static const onboardingPhone = '휴대폰';
  static const onboardingProfile = '프로필';
  static const onboardingProfileSaveError = '프로필 저장 중 오류가 발생했습니다. 다시 시도해주세요.';
  static const onboardingProfileSaveFailure = '프로필 저장 실패. 다시 시도해주세요.';
  static const onboardingSelectFromGallery = '갤러리에서 선택';
  static const onboardingTakePhoto = '카메라로 촬영';
  static const onboardingProfilePhotoOptional = '프로필 사진 (선택)';
  static const onboardingProfilePhotoTrustHint =
      '전문적인 사진을 추가하면 학생과 학부모가 선생님을 더 신뢰하고 기억하기 쉽습니다.';
  static const onboardingProfileImageError =
      '사진을 불러오지 못했습니다. 권한을 확인하거나 다시 시도해주세요.';
  static const onboardingProfileImageCanceled = '사진 선택이 취소되었습니다.';
  static const onboardingNext = '다음';
  static const onboardingPrevious = '이전';
  static const tutorialDescProfileSetup = '이름과 대표 악기를 입력해 첫 설정을 완성하세요';
  static const tutorialDescStudentPreview = '학생 카드가 어떻게 보이는지 샘플로 확인하세요';
  static const tutorialDescLessonNote = '레슨 후 남길 기록을 미리 작성해보세요';
  static const studentTutorialDescTuner = '원하는 음을 선택해 정확한 음높이를 확인하세요';
  static const studentTutorialDescRecording = '버튼을 길게 눌러 2초 이상 녹음해보세요';
  static const studentTutorialDescFeedback = '레슨 후 받게 될 피드백을 미리 살펴보세요';
  static const tutorialSampleStudentHint = '샘플 학생을 생성하면 수강 관리 카드가 준비됩니다.';
  static const tutorialSampleStudentCreated = '생성 완료';
  static const tutorialSampleStudentCreate = '샘플 학생 생성';
  static const tunerStepGuide = '원하는 음을 선택하면 정확한 음높이를 확인할 수 있어요';
  static const recordingStepGuide = '버튼을 길게 눌러 녹음을 시작하세요\n(2초 이상)';
  static String recordingInProgressSeconds(String seconds) =>
      '녹음중... ${seconds}s';
  static const recordingStepHoldLonger = '조금 더 길게 눌러보세요';
  static const recordingStepTrimInfo = '원본 2.0초 → 자동 트리밍\n0.3 ~ 1.8초 (저장 가능)';
  static const feedbackStepGuide = '선생님이 남기는 피드백 카드를 펼쳐보세요';
  static const onboardingSelectInstrument = '악기 선택';
  static const onboardingNameHint = '선생님 이름을 입력해주세요';
  static const onboardingIntroHint = '학생들에게 보여질 자기소개를 작성해주세요 (20자 이상)';

  // ── Review ──
  static const reviewAuthorStudent = '학생';
  static const reviewAuthorParent = '학부모';
  static const reviewVisibilityPublic = '공개';
  static const reviewVisibilityTeacherOnly = '선생님만';
  static const onboardingStudentNameHint = '이름을 입력해주세요';

  // ── Auth ──
  static const authParentLogin = '학부모 로그인';
  static const authSelectRole = '역할을 선택하세요';
  static const authRoleSetupFailed = '역할 설정 실패. 다시 시도해주세요.';
  static const authLoginFailed = '로그인 실패. 다시 시도해주세요.';

  // -- Auth error messages (server error differentiation, #866) --
  /// 네트워크 연결 없음 또는 타임아웃 시 로그인 실패 메시지.
  static const authLoginNetworkError = '네트워크 연결을 확인해주세요.';

  /// 서버 오류(5xx) 발생 시 로그인 실패 메시지.
  static const authLoginServerError = '서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';

  /// 인증 만료 또는 실패(401) 시 메시지.
  static const authLoginUnauthorized = '인증에 실패했습니다. 다시 로그인해주세요.';

  /// Google 로그인 클라이언트 미설정 안내.
  static const authGoogleNotConfigured =
      'Google 로그인이 아직 설정되지 않았습니다. 테스트 계정을 사용해주세요.';

  /// Apple 로그인 준비 중 안내.
  static const authAppleNotReady = 'Apple 로그인은 준비 중입니다.';

  /// 자동 로그인 실패 시 서버/네트워크 오류 안내 (홈 복귀 후 토스트).
  static const authAutoLoginServerError =
      '서버 연결에 실패했습니다. 네트워크를 확인하고 다시 로그인해주세요.';

  // 학생 직접 가입 안전망 (phone_verification_policy.md §3.2)
  /// 학생 직접 가입 차단 화면 제목.
  static const studentSignupBlockedTitle = '학생 직접 가입은 준비 중이에요';

  /// 학생 직접 가입 차단 화면 본문.
  static const studentSignupBlockedBody =
      '본인 인증 도입 전까지 학생 직접 가입은 잠시 닫혀 있어요.\n'
      '아래 두 가지 방법으로 시작할 수 있어요.';

  /// CTA — 학부모 가입으로 이동.
  static const studentSignupBlockedParentCta = '부모님 계정으로 시작하기';

  /// CTA — 선생님이 보낸 초대코드 입력.
  static const studentSignupBlockedInviteCta = '선생님이 보낸 초대코드가 있어요';

  /// 안내 — 다음 액션 분기 (만 14세 이상 + 선생님 미보유 케이스).
  static const studentSignupBlockedHelper =
      '아직 선생님이 없다면 가까운 선생님께 초대를 부탁해 주세요.\n'
      '본인 인증이 열리면 직접 가입도 가능해질 예정이에요.';
  static const authKakaoNotReady = '카카오 로그인은 준비 중입니다. 테스트 계정을 사용해주세요.';
  static const authParentLoginNotReady = '학부모 로그인은 준비 중입니다.';
  static const academyInviteAcceptFailed = '학원 초대 수락에 실패했습니다. 다시 시도해주세요.';

  /// 학원 초대 수락 성공 환영 메시지 (audit C3-F08)
  /// `_handleAccept` 성공 후 SnackBar 로 표시 — 멤버십 형성을 명시.
  /// 학원명 placeholder `{0}` 는 academy.name 로 치환.
  static String academyInviteAcceptedFormat(String academyName) =>
      '$academyName 학원에 가입되었어요. 곧 강사·수강권 안내가 도착합니다.';
  static const authTermsAgreement = '서비스 이용 동의';
  static const authTermsOfService = '서비스 이용약관 동의';
  static const authPrivacyPolicy = '개인정보 수집·이용 동의';
  static const authMarketingConsent = '마케팅 정보 수신 동의';
  static const authKakaoContinue = '카카오로 계속하기';
  static const authStudentRegister = '학생 등록';
  static const authParentRegister = '학부모 등록';
  static const authTeacherConnectionRequested = '선생님에게 연결 요청을 보냈습니다!';
  static const authChildConnected = '자녀가 성공적으로 연결되었습니다!';
  static const authInviteCodeHint = '초대 코드 입력';
  static const authInviteCodeInvalid = '올바르지 않은 초대 코드입니다';
  static const authInviteCodeExpired = '만료되었거나 사용할 수 없는 초대 코드입니다';
  static const authInviteCodeError = '코드 확인 중 오류가 발생했습니다';
  static const authDevTeacher = '선생님';
  static const authDevStudent = '학생';
  static const authDevParent = '학부모';

  // ── Parent Invite Code (#601) ──
  static const authParentInviteCodeDesc = '자녀의 선생님으로부터 받은\n초대 코드를 입력해주세요';
  static const authInviteOrDivider = '또는';
  static const authParentSkipTitle = '코드가 없어도 괜찮아요';
  static const authParentSkipSubtitle = '나중에 프로필에서 자녀를 등록할 수 있습니다';

  // ── Terms Agreement (#606) — 보기용 시트 타이틀/라벨 (본문은 위젯 const 유지) ──
  static const authTermsOfServiceTitle = '서비스 이용약관';
  static const authTermsSelectAll = '전체 동의';
  static const authTermsView = '보기';

  // ── Academy Invite Accept (#605) ──
  static const academyInviteTitle = '학원 초대';
  static const academyInviteRejectReasonTitle = '거절 사유를 선택해주세요';
  static const academyInviteRejectReasonNotInterested = '관심 없음';
  static const academyInviteRejectReasonAlreadyMember = '이미 다른 학원 소속';
  static const academyInviteRejectReasonOther = '기타';
  static const academyInviteOwnerPrefix = '대표: ';
  static const academyInviteRolesTitle = '부여될 권한';
  static const academyInvitePublicConsentLabel = '학원 공개 페이지에 내 프로필 노출 허용';

  // ── Age Gate (만 14세 미만 차단 안전망) ──
  // 정책: docs/specs/user/phone_verification_policy.md — 본인인증(PASS) 통합
  // 전까지의 최소 안전망. 자가신고 기반 확인이며, 정식 연령 검증은 PASS 연동 시
  // 대체된다.
  static const authAgeGateTitle = '나이 확인';
  static const authAgeGateBody = '만 14세 이상만 코드 없이 시작할 수 있어요.\n만 14세 이상이 맞나요?';
  static const authAgeGateConfirm = '네, 만 14세 이상입니다';
  static const authAgeGateCancel = '아니요';
  static const authAgeGateBlocked = '만 14세 미만은 보호자(학부모) 계정을 통해 이용할 수 있어요.';

  // ── Settings / Backup ──
  static const settingsBackupCreateFailed = '백업 생성에 실패했습니다. 다시 시도해주세요.';
  static const settingsBackupRestoreFailed = '백업 복원에 실패했습니다. 다시 시도해주세요.';
  static const settingsRestore = '복원';
  static const settingsShare = '공유';
  static const settingsBackupDeleteConfirm =
      '이 백업을 삭제하시겠습니까?\n삭제된 백업은 복구할 수 없습니다.';
  static const settingsRecordingFiles = '녹음 파일';
  static const settingsTotalSize = '전체 용량';

  // ── Practice Overview (집계 준비 중 placeholder) ──
  static const studentPracticeOverviewPreparingTitle = '연습 통계 준비 중';
  static const studentPracticeOverviewPreparingSubtitle =
      '학생의 연습 기록 집계 기능을 준비하고 있어요.';

  // ── Gamification ──
  static const gamificationContinue = '계속하기';
  static const gamificationChallenges = '도전 과제';
  static const gamificationMyGrowth = '내 성장';
  static const gamificationDataLoadFailed = '데이터를 불러올 수 없습니다';
  static const gamificationEarnedBadges = '획득한 뱃지';
  static const gamificationPointHistory = '포인트 히스토리';
  static const gamificationChallengesComingSoon = '도전 과제 준비 중';
  static const gamificationChallengesComingSoonSubtitle =
      '새로운 도전 과제를 준비하고 있어요. 곧 만나요!';

  // ── Growth Heatmap Day Detail (P2 Visual Growth — Job 6 Task 6.2 / AC-6.2) ──
  static const heatmapDayDetailMetronome = '메트로놈';
  static const heatmapDayDetailTuner = '튜너';
  static const heatmapDayDetailYoutube = 'YouTube';
  static const heatmapDayDetailManual = '수동';
  static const heatmapDayDetailRecording = '녹음';
  static const heatmapDayDetailTotalLabel = '총';
  static const heatmapDayDetailEmptyMessage = '이날은 연습 기록이 없어요';
  static String heatmapDayDetailMinutes(int minutes) => '$minutes분';
  static String heatmapDayDetailCount(int count) => '$count회';

  // ── Trophy Collection (P2 Visual Growth — Job 7 Task 7.1 / AC-6.3) ──
  static const trophyCollectionTitle = '내 트로피';
  static const trophyCollectionEmptyMessage = '곧 첫 트로피!';
  static const trophyCollectionMoreLabel = '더 보기';
  static String trophyCollectionCountLabel(int count) => '($count)';

  // ── Rest Recommendation (P2 Visual Growth — Job 8 / AC-7) ──
  static const restRecommendationSessionMessage = '잠깐 쉬는 게 어때요?';
  static const restRecommendationDailyMessage = '오늘은 충분히 했어요';
  static const restRecommendationDismissLabel = '계속하기';

  // ── Growth Detail Screen (P2 Visual Growth — Job 9 / AC-6.4) ──
  static const growthDetailScreenTitle = '내 성장';
  static const growthDetailYearLabel = '1년 동안';
  static const growthDetailSpotlightPlaceholder = '추천은 곧 추가됩니다';
  static const growthDetailComparisonPlaceholder = '비교 보기는 곧 추가됩니다';

  // ── Practice Badge (§2.7) ──
  static const practiceBadgeCollectionTitle = '뱃지 컬렉션';
  static const practiceBadgeUnlockedSection = '획득한 뱃지';
  static const practiceBadgeLockedSection = '미획득';
  static const practiceBadgeEmpty = '아직 획득한 뱃지가 없어요';
  static const practiceBadgePopupTitle = '새 뱃지 획득!';
  static const practiceBadgePopupConfirm = '확인';
  static const practiceBadgeCategoryConsistency = '꾸준함';
  static const practiceBadgeCategoryDiligence = '성실함';
  static const practiceBadgeCategoryChallenge = '도전';
  static const practiceBadgeCategorySpecial = '특별';
  static const practiceBadgeFirstPracticeName = '첫 연습';
  static const practiceBadgeFirstPracticeDesc = '첫 연습을 완료했어요';
  static const practiceBadgeStreak3Name = '3일 연속';
  static const practiceBadgeStreak3Desc = '3일 연속 연습 달성';
  static const practiceBadgeStreak7Name = '7일 연속';
  static const practiceBadgeStreak7Desc = '7일 연속 연습 달성';
  static const practiceBadgeStreak30Name = '30일 연속';
  static const practiceBadgeStreak30Desc = '30일 연속 연습 달성';
  static const practiceBadgeStreak100Name = '100일 연속';
  static const practiceBadgeStreak100Desc = '100일 연속 연습 달성';
  static const practiceBadgePerfectWeekName = '완벽한 한 주';
  static const practiceBadgePerfectWeekDesc = '주간 완료율 100%';
  static const practiceBadgeMustMasterName = '필수 달인';
  static const practiceBadgeMustMasterDesc = '필수 연습 10회 완료';
  static const practiceBadgePracticeKingName = '연습왕';
  static const practiceBadgePracticeKingDesc = '월간 완료율 90% 이상';
  static const practiceBadgeFirstPieceName = '첫 곡 완주';
  static const practiceBadgeFirstPieceDesc = '레퍼토리 1곡 완료';
  static const practiceBadgeFivePiecesName = '5곡 마스터';
  static const practiceBadgeFivePiecesDesc = '레퍼토리 5곡 완료';
  static const practiceBadgeChallengeKingName = '도전왕';
  static const practiceBadgeChallengeKingDesc = '도전 연습 10회 완료';
  static const practiceBadgeFirstLikeName = '선생님 칭찬';
  static const practiceBadgeFirstLikeDesc = '좋아요 5회 받기';
  static const practiceBadgeLovedStudentName = '사랑받는 학생';
  static const practiceBadgeLovedStudentDesc = '좋아요 20회 받기';
  static const practiceBadgePerformanceName = '무대 경험';
  static const practiceBadgePerformanceDesc = '발표회 참가';
  static const badgePracticeRepeat10Name = '반복 연습 10회';
  static const badgePracticeRepeat50Name = '반복 연습 50회';
  static const badgePracticeRepeat100Name = '반복 연습 100회';
  static const badgePracticeRepeatDescription = '구간 반복 누적 횟수 달성';

  // ── Follow ──
  static const followFollowing = '팔로잉';
  static const followFollow = '팔로우';
  static const followTitle = '팔로우';
  static const followUnfollowed = '팔로우가 취소되었습니다';
  static const followFeedTitle = '소식';
  static const followTabAll = '전체';
  static const followTabAcademy = '학원';
  static const followEmptyAll = '팔로우한 계정이 없습니다';
  static const followEmptyTeacher = '팔로우한 선생님이 없습니다';
  static const followEmptyAcademy = '팔로우한 학원이 없습니다';
  static const followEmptySubtitle = '선생님이나 학원을 팔로우하면\n소식을 받아볼 수 있습니다';
  static const followCancelTitle = '팔로우 취소';
  static const followCancelConfirmLabel = '팔로우 취소';
  static const followNotificationOnTooltip = '알림 켜기';
  static const followNotificationOffTooltip = '알림 끄기';
  static const followUnfollowTooltip = '팔로우 취소';

  // ─── Student Home ───
  static const studentHomePracticeReminder = '연습 리마인더';
  static const studentHomePracticeReminderDesc = '설정한 시간에 연습 알림을 받습니다';
  static const studentHomeWeeklyPractice = '이번 주 연습';
  static const studentHomePracticeJournal = '연습 일지';
  static const studentHomeMySubscriptions = '내 수강권';
  static const studentHomeTrialLesson = '체험레슨';
  static const studentHomeScheduleChangeLabel = '일정 변경';
  static const studentHomeRetryBooking = '다른 시간으로 다시 신청';
  static const studentHomeScheduleChangePreparing = '일정 변경 요청 기능 준비 중입니다';
  static const studentHomeTrialCancelTitle = '체험레슨 취소';
  static const studentHomeTrialCancelConfirm = '체험레슨 신청을 취소하시겠습니까?';
  static const studentHomeTrialCancelSuccess = '체험레슨 신청이 취소되었습니다';
  static const studentHomeTrialCancelError = '취소 처리 중 오류가 발생했습니다. 다시 시도해주세요.';
  static const studentHomeLanguageSettings = '언어 설정';
  static const studentHomeLanguageKorean = '한국어';
  static const studentHomeMyTrialLessons = '내 체험레슨';
  static const studentHomeApply = '신청';
  static const studentHomeAllTrialInScheduleTab =
      '모든 체험 레슨은 스케줄 탭에서 확인할 수 있습니다';
  static const studentHomeTrialBooking = '체험레슨 신청';
  static const studentHomeStartNewLesson = '새로운 선생님과 레슨을 시작해보세요';
  static const studentHomePracticeSummaryDetail = '상세 보기';
  static const studentHomePracticeStreak = '연속 일수';
  static const studentHomePracticeWeeklyTotal = '이번 주 총 연습';
  static const studentHomePracticeGoalAchievement = '주간 달성률';
  static const studentHomeRecentFeedback = '최근 피드백';
  static const studentHomeFindTeacher = '선생님 찾기';
  static const studentHomeNoUpcomingLesson = '예정된 레슨이 없습니다';
  static const studentHomeBookLessonSuggestion = '선생님을 찾아 레슨을 예약해보세요';
  static const studentHomeHelpTitle = '도움말';
  static const studentHomeFaqTitle = '자주 묻는 질문';
  static const studentHomeContactSupport = '문의하기';
  static const studentHomeNeedHelp = '도움이 필요하신가요?';
  static const studentHomeCannotOpenEmail = '이메일 앱을 열 수 없습니다';
  static const studentHomeAppInfoTitle = '앱 정보';
  static const appUpdateBannerTitle = '새 버전이 준비되었습니다';
  static String appUpdateBannerSubtitle(String version) =>
      'v$version 업데이트와 개선 예정 기능을 확인하세요';
  static const appUpdateBannerAction = '새 소식';
  static const reviewPromptTitle = '레슨 경험이 쌓였어요';
  static String reviewPromptSubtitle(int count) =>
      '$count회 레슨 후 앱 리뷰로 더 나은 경험을 만들어주세요';
  static const reviewPromptAction = '지금 리뷰하기';
  static const reviewPromptThanks = '좋은 의견 감사합니다';
  static const newsRoadmapTitle = '앱 업데이트 안내';
  static String newsRoadmapVersion(String current, String latest) =>
      '현재 $current · 최신 $latest';
  static const newsRoadmapReleaseSectionTitle = '최근 변경사항';
  static const newsRoadmapSectionTitle = '앞으로의 개선';
  static const newsRoadmapStatusPlanned = '준비 중';
  static const newsRoadmapStatusInProgress = '진행 중';
  static const newsRoadmapStatusShipped = '완료';

  // Force update screen
  static const forceUpdateTitle = '업데이트가 필요합니다';
  static String forceUpdateBody(String minVersion) =>
      '원활한 사용을 위해 v$minVersion 이상으로\n업데이트해 주세요.';
  static String forceUpdateCurrentVersion(String version) => '현재 버전: v$version';
  static const forceUpdateAction = '업데이트하기';
  static const forceUpdateStoreUnavailable =
      '스토어를 열 수 없습니다. 앱 스토어에서 직접 업데이트해 주세요.';
  static const studentHomeTermsOfService = '이용약관';
  static const studentHomePrivacyPolicy = '개인정보처리방침';
  static const studentHomeOpenSourceLicense = '오픈소스 라이선스';
  static const studentHomeLogout = '로그아웃';
  static const studentHomeLogoutConfirm = '정말 로그아웃 하시겠습니까?';
  static const studentHomeParentInviteCodeTitle = '학부모 초대 코드';
  static const studentHomeParentInviteMessage = '학부모님을 초대합니다';
  static const studentHomeInviteCodeCopied = '초대 코드가 복사되었습니다';
  static const studentHomeCopyAction = '복사';
  static const studentHomeShareAction = '공유';
  static const studentHomeProfileSaved = '프로필이 저장되었습니다';
  static const studentHomeProfileSaveFailed = '저장에 실패했습니다. 다시 시도해주세요.';
  static const studentHomeProfileEdit = '프로필 수정';
  static const studentHomeProfilePhoto = '프로필 사진';
  static const studentHomeNameHint = '이름을 입력하세요';
  static const studentHomeEmailHint = '이메일을 입력하세요';
  static const studentHomePhoneHint = '전화번호를 입력하세요';
  static const studentHomeEditNameLabel = '이름';
  static const studentHomeEditInstrumentLabel = '악기';
  static const studentHomeEditEmailLabel = '이메일';
  static const studentHomeEditPhoneLabel = '전화번호';
  static const studentHomeEditProfileShareInfo =
      '프로필 정보는 선생님에게 공유됩니다.\n정확한 정보를 입력해주세요.';
  static const studentHomeDeleteTeacher = '선생님 삭제';
  static const studentHomeCancelWriting = '작성 취소';
  static const studentHomeCancelWritingConfirm = '작성 중인 내용이 있습니다. 나가시겠습니까?';
  static const studentHomeSaveFailedRetry = '저장 실패. 다시 시도해주세요.';
  static const studentHomeDeleteTeacherConfirm =
      '이 선생님을 삭제하시겠습니까? 삭제 후 복구할 수 없습니다.';
  static const studentHomeTeacherDeleted = '선생님이 삭제되었습니다';
  static const studentHomeDeleteFailedRetry = '삭제 실패. 다시 시도해주세요.';
  static const studentHomeTodayPractice = '오늘의 연습';
  static const studentHomeMyTeachers = '내 선생님';
  static const studentHomeManualTeacherRegister = '선생님 직접 등록';
  static const studentHomeEditAction = '편집';
  static const studentHomeScheduleTitle = '스케줄';
  static const studentHomeBookAction = '예약';
  static const studentHomePracticeEmpty = '아직 연습 과제가 없습니다';
  static const studentHomePracticeTeacherHint = '선생님이 과제를 등록하면 여기에 표시됩니다';
  static const studentHomeConnectTeacher = '선생님 연결하기';
  static const studentHomeConnectTeacherHint = '선생님을 검색하거나 초대 코드를 입력하세요';
  static const studentHomeTeacherConnectionPending = '선생님 승인 대기';
  static const studentHomeTeacherConnectionPendingHint = '초대 코드 연결 요청을 보냈습니다';
  static const studentHomeCompleteProfile = '프로필 완성하기';
  static const studentHomeCompleteProfileHint = '온보딩에서 프로필이 설정되었습니다';
  static const studentHomeCheckFirstLesson = '첫 레슨 확인하기';
  static const studentHomeCheckFirstLessonHint = '선생님과 첫 레슨을 예약하세요';
  static const studentHomeLessonProgressLabel = '레슨 진행';
  static const studentHomeRenewalNeeded = '수강권 갱신이 필요해요';
  static const studentHomeSubscriptionReady = '수강권이 준비됐어요';
  static const studentHomeFirstLessonCheck = '첫 레슨 시간을 확인해주세요';
  static const studentHomeNextLessonSchedule = '다음 레슨 일정에 맞춰 시작합니다';
  static const studentHomeMenuProfileEdit = '프로필 수정';
  static const studentHomeMenuMyTeachers = '내 선생님';
  static const studentHomeMenuRepertoire = '레퍼토리';
  static const studentHomeMenuPracticeHistory = '연습 기록 내역';
  static const studentHomeMenuRecordings = '레슨 녹음 파일';
  static const studentHomeMenuRecordingsSubtitle = '전체 녹음 관리';
  static const studentHomeMenuParentInvite = '학부모 초대';
  static const studentHomeMenuParentInviteSubtitle = '학부모님과 연결하기';
  static const studentHomeMenuNotificationSettings = '알림 설정';
  static const studentHomeMenuNotificationSubtitle = '카테고리별 알림 관리';
  static const studentHomeMenuLanguage = '언어';
  static const studentHomeMenuLanguageValue = '한국어';
  static const studentHomeMenuRecordingBackup = '녹음 백업';
  static const studentHomeTeacherNameHint = '선생님 이름을 입력하세요';
  static const studentHomeLessonNoteHint = '레슨 관련 메모를 입력하세요';
  static const studentHomeSearchTeacherHint = '선생님을 검색하여 레슨을 시작해보세요';
  static const studentHomeManualTeacherSection = '직접 등록한 선생님';
  static const studentHomeManualTeacherHint = '앱에 가입하지 않은 선생님을 직접 등록하세요';
  static const studentHomeManualTeacherEmpty = '직접 등록한 선생님이 없습니다';
  static const studentHomeDataLoadError = '데이터를 불러올 수 없습니다';
  static const studentHomeBookNewLesson = '새로운 레슨을 예약해보세요';
  static const studentHomeTeacherEditLabel = '선생님 편집';
  static const studentHomeTeacherRegisterLabel = '선생님 등록';
  static const studentHomeTeacherSaveLabel = '선생님 저장하기';
  static const studentHomeTeacherRegisterAction = '선생님 등록하기';
  static const studentHomeTeacherInfoUpdated = '선생님 정보가 수정되었습니다';
  static const studentHomeTeacherRegistered = '선생님이 등록되었습니다';

  // ── Parent Home ───────────────────────────────────────────

  static const parentHomeProfile = '프로필';
  static const parentHomeNotificationSettings = '알림 설정';
  static const parentHomeDetailSettings = '상세 설정';
  static const parentHomeNotificationDetailSettings = '알림 상세 설정';
  static const parentHomeAssignmentNotification = '과제 알림';
  static const parentHomeAssignmentNotificationSubtitle = '새 과제 등록, 미완료 알림';
  static const parentHomeLessonNotification = '레슨 알림';
  static const parentHomePracticeNotification = '연습 알림';
  static const parentHomePaymentNotification = '입금 상태 알림';
  static const parentHomeRequired = '필수';
  static const parentHomeConnectedChildren = '연결된 자녀';
  static const parentHomeChildStatusActive = '활성';
  static const parentHomeChildStatusInactive = '비활성';
  static const parentHomeChildConnectionConnected = '연결됨';
  static const parentHomeChildConnectionPending = '대기 중';
  static const parentHomeChildConnectionUnconnected = '미연결';
  static const parentHomeParentStatusPending = '초대 대기';
  static const parentHomeParentStatusActive = '활성';
  static const parentHomeParentStatusInactive = '비활성';
  static const parentHomePermissionViewOnly = '열람 전용';
  static const parentHomePermissionManagePayments = '입금 상태 관리';
  static const parentHomePermissionManageLessons = '레슨 관리';
  static const parentHomePermissionFullAccess = '전체 권한';
  static const parentHomeInvitationSourceStudent = '학생 초대';
  static const parentHomeInvitationSourceTeacher = '선생님 초대';
  static const parentHomeRelationStatusPending = '대기';
  static const parentHomeRelationStatusActive = '활성';
  static const parentHomeRelationStatusInactive = '해제';
  static const parentHomeProfileTypeParent = '학부모';
  static const parentHomeProfileTypeStudent = '학생';
  static const parentHomeProfileTypeChild = '자녀';
  static const parentHomeNotificationCategoryPayment = '입금 상태';
  static const parentHomeNotificationCategoryLesson = '레슨';
  static const parentHomeNotificationCategoryAssignment = '과제/숙제';
  static const parentHomeNotificationCategoryPractice = '연습';
  static const parentHomeNotificationCategoryCommunication = '소통';
  static const parentHomeNotificationCategoryReport = '리포트';
  static const parentHomeNotificationRequiredSuffix = '(필수)';
  static const parentHomeNotificationRecommendedSuffix = '(권장)';
  static const parentHomeNotificationPaymentRequest = '입금 안내';
  static const parentHomeNotificationPaymentComplete = '입금 확인';
  static const parentHomeNotificationPaymentDueSoon = '입금 예정일 임박';
  static const parentHomeNotificationLessonChange = '레슨 일정 변경';
  static const parentHomeNotificationLessonCancel = '레슨 취소/노쇼';
  static const parentHomeNotificationLessonStart = '레슨 시작 알림';
  static const parentHomeNotificationLessonEnd = '레슨 종료 알림';
  static const parentHomeNotificationNewAssignment = '새 과제 등록';
  static const parentHomeNotificationAssignmentIncomplete = '과제 미완료 알림 (D-1)';
  static const parentHomeNotificationPracticeComplete = '연습 완료 알림';
  static const parentHomeNotificationStreakAchievement = '스트릭 달성 알림';
  static const parentHomeNotificationTeacherMessage = '선생님 메시지';
  static const parentHomeNotificationLessonNoteUpdate = '레슨 노트 업데이트';
  static const parentHomeNotificationWeeklyReport = '주간 요약 리포트';
  static const parentHomeNotificationMonthlyReport = '월간 상세 리포트';
  static const parentHomeManage = '관리';
  static const parentHomeAddChildMethod = '자녀 추가 방법';
  static const parentHomeAddChild = '자녀 추가하기';
  static const parentHomeAddChildShort = '자녀 추가';
  static const parentHomeChildManagement = '자녀 관리';
  static const parentHomeChildSelect = '자녀 선택';
  static const parentHomeNoChildren = '등록된 자녀가 없습니다';
  static const parentHomeNoChildrenDesc = '자녀를 추가하거나\n선생님 초대코드를 입력하세요';
  static const parentHomeAssignmentStatus = '과제 현황';
  static const parentHomePaymentSubscription = '입금·수강권';
  static const parentHomeUpcomingLessons = '예정된 레슨';
  static const parentHomePastLessons = '지난 레슨';
  static const parentHomeLessonNote = '레슨 노트';
  static const parentHomeViewDetail = '상세보기';
  static const parentHomeRegularLesson = '정규 레슨';
  static const parentHomeTodayPractice = '오늘의 연습';
  static const parentHomeFindTeacher = '선생님 찾기';
  static const parentHomeInviteCode = '초대코드 입력';
  static const parentHomeWeeklyPractice = '이번 주 연습';
  static const parentHomeConnect = '연결';
  static const parentHomeChildDeleted = '자녀 프로필이 삭제되었습니다';
  static const parentHomeDeleteError = '삭제 중 오류가 발생했습니다. 다시 시도해주세요.';
  static const parentHomeLogout = '로그아웃';
  static const parentHomeLogoutConfirm = '정말 로그아웃 하시겠습니까?';
  static const parentHomeWeeklyLesson = '이번주 레슨';
  static const parentHomeAssignmentDone = '과제 완료';
  static const parentHomePracticeStreak = '연습 스트릭';
  static const parentHomePaymentGuideCheck = '입금 안내 확인';
  static const parentHomeNextLesson = '다음 레슨';
  static const parentHomeTodayPracticeLabel = '오늘 연습';
  static const parentHomeChildNameHint = '자녀 이름 또는 별명 입력';
  static const parentHomeInviteCodeHint = '선생님에게 받은 코드를 입력하세요';
  static const parentHomeParentLabel = '학부모';
  static const parentHomeTotal = '전체';
  static const parentHomeInProgress = '진행중';
  static const parentHomeChildAddTitle = '자녀 추가';
  static const parentHomeChildEditTitle = '자녀 정보 수정';
  // ── Parent Dashboard / Assignments (실데이터) ──────────────
  static const parentHomeNotLinked = '선생님과 연결되지 않았습니다';
  static const parentHomeNotLinkedDesc = '선생님 연결 후 레슨·연습 정보가 표시됩니다';
  static const parentHomeNoUpcomingLesson = '예정된 레슨이 없습니다';
  static const parentHomeNoAssignment = '등록된 과제가 없습니다';
  static const parentHomeRemainingLesson = '수강권 잔여';
  static const parentHomeThisWeekPractice = '이번 주 연습';
  static const parentHomeIncompleteAssignment = '미완료 과제';
  static const parentHomeCompletedAssignment = '완료된 과제';
  static const parentHomeWeeklyAssignment = '이번 주 과제';
  static const parentHomePriorityMust = '필수';
  static const parentHomePriorityShould = '권장';
  static const parentHomePriorityCould = '선택';
  static const parentHomeCompletedLabel = '완료됨';
  // ── Parent Lessons tab (실데이터) + 노트 접근동의 게이트 ──────
  static const parentHomeNoUpcomingLessons = '예정된 레슨이 없습니다';
  static const parentHomeNoPastLessons = '지난 레슨이 없습니다';
  static const parentHomeLessonLoadError = '레슨 정보를 불러오지 못했습니다';
  static const parentHomeChildNotLinked = '아직 선생님과 연결되지 않았습니다';
  static const parentHomeChildNotLinkedHint = '선생님 연결 후 레슨 일정이 표시됩니다';
  static const parentHomeLessonNoteContent = '수업 내용';
  static const parentHomeLessonTeacherComment = '선생님 코멘트';
  static const parentHomeLessonAssignments = '과제';
  static const parentHomeLessonRecording = '녹음';
  static const parentHomeLessonNoteEmpty = '아직 작성된 레슨 노트가 없습니다';
  // 레슨 노트 접근 동의 게이트 (data-privacy P0)
  static const parentHomeLessonNoteNotShared = '선생님이 노트 공유를 허용하지 않았습니다';
  static const parentHomeLessonFeedbackNotShared = '선생님이 상세 피드백 공유를 허용하지 않았습니다';

  // ── Schedule (추가) ───────────────────────────────────────

  static const scheduleRestoreSchedule = '이 스케줄로 복원';
  static const scheduleMonthlyFee = '월 수강료';
  static const scheduleRegisterRegularLesson = '정규레슨 등록하기';
  static const scheduleSelectTime = '시간 선택하기';
  static const scheduleDifferentTime = '다른 시간';
  static const scheduleBookThisTime = '이 시간으로 예약';
  static const scheduleConfirmError = '스케줄 확정 중 오류가 발생했습니다. 다시 시도해주세요.';
  static const scheduleNoTeacherSchedule = '선생님의 스케줄 정보가 없습니다';
  static const scheduleAlternativeProposal = '대안 시간 제안';
  static const scheduleLessonTimeSetting = '레슨 시간 설정';
  static const scheduleReject = '거절';
  static const scheduleApprove = '승인';
  static const scheduleTeacherProposal = '선생님의 제안';
  static String scheduleLoadFailed(String error) => '불러오기 실패: $error';
  static const scheduleSelect = '선택하기';
  static const scheduleGuestInfo = '예약자 정보 입력';
  static const scheduleBook = '예약하기';
  static const scheduleGuestNameHint = '예약자 이름을 입력하세요';
  static const scheduleMarkComplete = '완료 처리';
  static const scheduleChangeSchedule = '일정 변경';
  static String scheduleCompleteFailed(String error) => '완료 처리 실패: $error';
  static String scheduleCancelFailed(String error) => '취소 실패: $error';
  static const scheduleActivate = '활성화';
  static const scheduleEndTimeError = '종료 시간은 시작 시간보다 늦어야 합니다';
  static const scheduleApprovalError = '승인 처리 중 오류가 발생했습니다. 다시 시도해주세요.';
  static const scheduleProcessError = '처리 중 오류가 발생했습니다. 다시 시도해주세요.';
  static const scheduleBackToStudentTime = '학생 희망 시간으로 돌아가기';
  static const scheduleGoBack = '돌아가기';
  static const scheduleCheckProposal = '수강권 제안 확인하기';
  static const scheduleApply = '적용';
  static const schedulePendingApproval = '승인 대기';
  static const scheduleTrialLessonHint = '배우고 싶은 곡이나 궁금한 점을 적어주세요';
  static const scheduleAvailable = '예약가능';
  static const scheduleOpen = '가용';
  static const scheduleMyBooking = '내 예약';
  static const scheduleBooked = '예약됨';
  static const scheduleHoliday = '휴무';
  static const schedulePastTime = '지난 시간';

  // ── Practice Domain (연습 도메인 한글 상수) ────────────────────────

  // -- Metronome -- (분야 의존 문구 → StringOverlay #968, music overlay 위임)
  static String get metronomeTimeSignaturePickerTitle =>
      StringOverlayRegistry.music.metronome.timeSignaturePickerTitle;
  static String get metronomeSimpleTimeTitle =>
      StringOverlayRegistry.music.metronome.simpleTimeTitle;
  static String get metronomeCompoundTimeTitle =>
      StringOverlayRegistry.music.metronome.compoundTimeTitle;
  static String get metronomeSubdivisionPickerTitle =>
      StringOverlayRegistry.music.metronome.subdivisionPickerTitle;
  static String get metronomeBasicPatternTitle =>
      StringOverlayRegistry.music.metronome.basicPatternTitle;
  static String get metronomeVariationTitle =>
      StringOverlayRegistry.music.metronome.variationTitle;
  static String get metronomeOptionsTitle =>
      StringOverlayRegistry.music.metronome.optionsTitle;
  static String get metronomeVisualFlashLabel =>
      StringOverlayRegistry.music.metronome.visualFlashLabel;
  static String get metronomeVibrationLabel =>
      StringOverlayRegistry.music.metronome.vibrationLabel;

  // -- Goal --
  static const practiceGoalTodayTitle = '오늘의 목표';
  static const practiceGoalAchievedBadge = '달성!';
  static const practiceGoalSettingsTooltip = '목표 설정';
  static const practiceTimeLabel = '연습 시간';
  static const practiceCompletedSectionLabel = '완료 섹션';
  static const practiceThisWeekLabel = '이번 주';
  static const practiceWeeklyGoalAchievedBadge = '주간 목표 달성!';
  static const practiceTimeShortLabel = '시간';
  static const practiceDayLabel = '연습일';
  static const practiceCustomInputLabel = '직접 입력';
  static const practiceTotalTimeLabel = '총 연습 시간';

  // -- Goal Setting Screen --
  static const practiceGoalSavedSnack = '연습 목표가 저장되었습니다';
  static const practiceGoalSettingTitle = '연습 목표 설정';
  static const practiceGoalSaveButton = '저장';
  static const practiceGoalDailyTitle = '일일 목표';
  static const practiceGoalDailySectionLabel = '완료 섹션 수';
  static const practiceGoalWeeklyTitle = '주간 목표';
  static const practiceGoalWeeklyTimeLabel = '총 연습 시간';
  static const practiceGoalWeeklyDayLabel = '연습 일수';
  static const practiceGoalResetTitle = '목표 초기화';
  static const practiceGoalResetConfirm = '모든 목표 설정을 초기화할까요?';

  // -- Goal Progress Widget --
  static const goalProgressTitle = '연습 목표';
  static const goalProgressDaily = '오늘';
  static const goalProgressWeekly = '이번 주';
  static const goalProgressTime = '시간';
  static const goalProgressSection = '섹션';
  static const goalProgressDay = '연습일';
  static const goalProgressEmptyTitle = '연습 목표를 설정해 보세요';
  static const goalProgressEmptyAction = '목표 설정';
  static const goalProgressEditTooltip = '목표 수정';

  // -- Goal Achieved Dialog --
  static const goalAchievedDailyTitle = '오늘의 목표 달성!';
  static const goalAchievedWeeklyTitle = '이번 주 목표 달성!';
  static const goalAchievedDailyMessage = '오늘의 연습 목표를 모두 달성했어요. 멋져요!';
  static const goalAchievedWeeklyMessage =
      '이번 주 연습 목표를 모두 달성했어요. 한 주 정말 수고했어요!';
  static const goalAchievedConfirm = '확인';

  // -- Section Management --
  static const practiceRestore = '복원';
  static const practicePermanentDelete = '영구 삭제';
  static const practiceRepertoireRestoreTitle = '레퍼토리 복원';
  static const practiceRepertoirePermanentDeleteTitle = '레퍼토리 영구 삭제';
  static const practiceInProgress = '진행 중';

  // -- Recording --
  static const practiceRecordingFileNotFound = '녹음 파일을 찾을 수 없습니다';
  static const practiceRecordingCompareTitle = '녹음 비교';
  static const practiceSequentialPlayLabel = '순차 재생';
  static const practiceParallelWaveLabel = '병렬 파형';
  static const practicePeriodLabel = '기간';
  static const practiceRecordingRecordDeleteTitle = '녹음 기록 삭제';
  static const practiceSetRepresentative = '대표 녹음으로 설정';
  static const practiceShareExternal = '외부 앱 공유';

  /// 녹음 행 탭 시 표시되는 BottomSheet 헤더 제목 (swipe consistency 통일 — 다중 액션은 BottomSheet 분리).
  static const recordingActionsSheetTitle = '녹음 옵션';
  static const practiceRecordingSaved = '녹음 저장됨';
  static const practiceRestoreOriginal = '원본 복구';
  static const practiceRecordingDeleteTitle = '녹음 삭제';
  static const practiceRecordingDeleteConfirm = '이 녹음을 삭제하시겠습니까?';
  static const practiceRecordingDeletedSnack = '녹음이 삭제되었습니다';
  static const practiceShare = '공유';
  static const practiceShareToTeacherAction = '선생님께 공유';
  static const practiceShareToTeacherTitle = '선생님께 공유';
  static const practiceShareToTeacherConfirm = '대표 녹음을 선생님께 공유하시겠습니까?';
  static const practiceSharedToTeacherSnack = '선생님께 공유했어요';
  static const practiceSelectAsRepresentative = '대표로 선택';
  static const practiceTeacherFeedbackArrived = '선생님 피드백이 도착했어요';

  // Quick recording (§4.3 바로 녹음)
  static const quickRecordButton = '바로 녹음';
  static const quickRecordSectionTitle = '바로 녹음';
  static const quickRecordRepertoireName = '무제';
  static const quickRecordHint = '레퍼토리/섹션을 선택하지 않고 바로 녹음을 시작합니다';
  static const quickRecordTooltip = '바로 녹음 시작';
  static const practiceJournalTitle = '연습 일지';
  static const practiceJournalContinuousDays = '연속 일수';
  static const practiceJournalBestRun = '최고 연속 일수';
  static const practiceJournalShareHint = '대표 녹음을 선생님께 공유할 수 있어요';
  static const practiceJournalErrorShort = '일지 정보를 불러올 수 없습니다';
  static String practiceJournalMotivationStart() => '오늘 연습 일지를 시작해보세요!';
  static String practiceJournalMotivationGrowing(int days) =>
      '$days일째 연습 일지가 쌓이고 있어요.';
  static String practiceJournalMotivationContinuing(int days) =>
      '연습 일지가 $days일째 이어지고 있어요.';
  static String practiceJournalMotivationCelebration(int days) =>
      '연습 일지가 멋지게 $days일째 이어지고 있어요!';
  static String practiceJournalStreakSummary(int days) =>
      '연습 일지 $days일째 이어졌어요!';

  // -- Section Detail Screen --
  static const practiceSectionNotFound = '섹션을 찾을 수 없습니다';
  static const practiceErrorOccurred = '오류가 발생했습니다';
  static const practicePracticeRecordTitle = '연습기록';
  static const practiceRecordingTitle = '녹음';
  static const practiceStatusChangeFailedRetry = '상태 변경에 실패했습니다. 다시 시도해주세요.';
  static const practiceStatsUpdatedSnack = '연습 기록이 수정되었습니다';
  static const practiceUpdateFailedRetry = '수정에 실패했습니다. 다시 시도해주세요.';
  static const practiceSectionDeleteTitle = '섹션 삭제';
  static const practiceSectionDeleteConfirm = '이 섹션과 모든 녹음을 삭제하시겠습니까?';

  // -- Recording Mixin --
  static const practiceRecordingMicPermissionRequired = '마이크 권한이 필요합니다';
  static const practiceRecordingStartFailed = '녹음을 시작할 수 없습니다';
  static const practiceRecordingTooShort = '녹음 시간이 너무 짧습니다 (최소 3초)';
  static const practiceRecordingSaveFailed = '녹음 저장에 실패했습니다';
  static const practiceOriginalRestoredSnack = '원본 파일이 복구되었습니다';
  static const practiceRecordingSavedSnack = '녹음이 저장되었습니다';
  static const practiceRecordingSaveFailedRetry = '녹음 저장에 실패했습니다. 다시 시도해주세요.';
  static const practiceRepresentativeSetSnack = '대표 녹음으로 설정되었습니다';
  static const practiceSettingFailedRetry = '설정에 실패했습니다. 다시 시도해주세요.';
  static const practiceDeleteFailedRetry = '삭제에 실패했습니다. 다시 시도해주세요.';

  // -- Practice Stats --
  static const practiceCountLabel = '연습 횟수';
  static const practiceRecordingCountLabel = '녹음';
  static const practiceCountSettingTitle = '연습 횟수 설정';
  static const practiceTotalTimeSettingTitle = '총 연습 시간 설정';

  // -- Section Form --
  static const practiceNone = '없음';
  static const practiceTargetTimeTitle = '목표 연습시간';
  static const practiceNotSet = '설정 안함';
  static const practicePeriodSectionTitle = '연습 기간';
  static const practiceStartDateLabel = '시작일';
  static const practiceEndDateLabel = '종료일';

  // -- Pitch Analysis --
  static const practicePitchAnalysisTitle = '피치 분석';
  static const practicePitchAccuracyLabel = '정확도';
  static const practicePitchStabilityLabel = '안정성';
  static const practicePitchAvgDeviationLabel = '평균 편차';
  static const practicePitchRangeLabel = '음역';

  // -- Stats --
  static const practiceStatsSummaryTitle = '요약';
  static const practiceCompletionRateLabel = '완료율';
  static const practiceDailyAvgLabel = '일평균';
  static const practiceCurrentStreakLabel = '현재 스트릭';
  static const practiceMaxStreakLabel = '최대 스트릭';
  static const practiceByRepertoireTitle = '레퍼토리별 연습';
  static const practiceWeeklyTrendTitle = '주간 트렌드';
  static const practiceDailyTimeChartTitle = '일별 연습 시간';
  static const practiceTotalLabel = '전체';
  static const practiceCompletedLabel = '완료';

  // -- Practice Streak Card --
  static const practiceRecordTodayLabel = '오늘 연습 기록하기';
  static const practiceErrorOccurredShort = '오류 발생';

  // -- Manual practice entry (#405) --
  static const manualPracticeTitle = '연습 기록 추가';
  static const manualPracticeMinutesLabel = '연습 시간 (분)';
  static const manualPracticeMinutesHint = '예: 30';
  static const manualPracticeDateLabel = '날짜';
  static const manualPracticeInvalidMinutes = '연습 시간을 분 단위로 입력하세요';
  static const manualPracticeSaved = '연습 기록이 추가되었습니다';
  static const manualPracticeSaveFailed = '연습 기록 저장에 실패했습니다';

  // -- Tuner --
  static const tunerSettingsTitle = '튜너 설정';
  static const tunerReferenceFrequencyTitle = '기준 주파수 (A4)';
  static const tunerTransposeTitle = '조옮김 (관악기용)';
  static const tunerDifficultyTitle = '판정 난이도';
  static const tunerEnharmonicTitle = '이명동음 표시';
  static const tunerClefTitle = '음자리표';
  static const tunerShowComboTitle = '콤보 카운터 표시';
  static const tunerVibrationFeedbackTitle = '진동 피드백';
  static const tunerAppBarTitle = '튜너';

  // -- Practice Notes --
  static const practiceNoteHint = '연습하면서 느낀 점을 기록하세요...';
  static const practiceNoteTitle = '연습노트';
  static const practiceNoteEmptyTitle = '연습노트가 없습니다';
  static const practiceNoteEmptySubtitle = '연습하면서 느낀 점을 기록해보세요';
  static const practiceNoteAddedSnack = '연습노트가 추가되었습니다';
  static const practiceNoteUpdatedSnack = '연습노트가 수정되었습니다';
  static const practiceNoteDeleteTitle = '노트 삭제';
  static const practiceNoteDeleteConfirm = '이 연습노트를 삭제할까요?';
  static const practiceNoteDeletedSnack = '연습노트가 삭제되었습니다';
  // 학생 홈 연습 탭의 노트 섹션 라벨/안내 (#492)
  static const practiceNoteSectionTitle = '오늘의 연습노트';
  static const practiceNoteHomeEmpty = '아직 작성한 연습노트가 없습니다';
  static const practiceNoteAdd = '노트 추가';
  static const practiceNoteAddTooltip = '연습노트 추가';
  static const practiceNoteShowMore = '전체보기';
  static const practiceNotePickSection = '노트를 작성할 섹션을 선택하세요';
  static const practiceNoteNoSectionsHint = '먼저 연습할 레퍼토리/섹션을 추가해 주세요';

  // -- Screens --
  static const practiceArchiveTitle = '아카이브';
  static const practiceRepertoireHistoryTitle = '레퍼토리 히스토리';
  // §3.4.6 — empty state when student has no repertoires yet.
  static const practiceRepertoireHistoryEmptyTitle = '아직 레퍼토리가 없습니다';
  static const practiceRepertoireHistoryEmptySubtitle =
      '레퍼토리를 추가하면\n이곳에 월별 히스토리가 쌓입니다';
  static const practiceSectionSearchHint = '레퍼토리 또는 섹션 검색...';
  static const practiceEdit = '편집';
  static const practiceMoveToArchive = '아카이브로 이동';
  static const practiceErrorOccurredDot = '오류가 발생했습니다.';
  static const practiceStatsTitle = '연습 통계';
  static const practiceTotalCountLabel = '총 연습 횟수';
  static const practiceTotalRecordingLabel = '총 녹음';
  static const practiceSectionCountLabel = '섹션 수';
  static const practiceSectionListTitle = '섹션 목록';
  static const practiceAppBarTitle = '연습';
  static const practiceRepertoireEmptyTitle = '아직 연습할 레퍼토리가 없습니다';
  static const practiceRepertoireEmptySubtitle = '레퍼토리를 추가하고\n섹션별로 연습을 시작해보세요';
  static const practiceSectionAddLabel = '섹션 추가';
  static const practiceStatsAppBarTitle = '연습 통계';

  // -- Practice Report (§5.2 주간/월간 리포트) --
  static const practiceReportTitle = '연습 리포트';
  static const practiceReportWeekly = '주간';
  static const practiceReportMonthly = '월간';
  static const practiceReportTotalMinutes = '총 연습 시간';
  static const practiceReportPracticeDays = '연습 일수';
  static const practiceReportAvgMinutes = '평균 연습 시간';
  static const practiceReportEmpty = '아직 연습 기록이 없습니다';
  static const practiceReportEmptyChart = '표시할 연습 기록이 없습니다';
  static const practiceReportEmptyRepertoire = '연습한 레퍼토리가 없습니다';
  static const practiceReportDailyChartTitle = '일별 연습 시간';
  static const practiceReportRepertoireRatioTitle = '레퍼토리 비중';
  static const practiceReportMinutesUnit = '분';
  static const practiceReportDaysUnit = '일';

  // -- Section Edit/Add --
  static const practiceStartMeasureGreaterError = '시작 마디가 끝 마디보다 클 수 없습니다';
  static const practiceStartLineGreaterError = '시작 줄이 끝 줄보다 클 수 없습니다';
  static const practiceSectionUpdateFailedRetry = '섹션 수정에 실패했습니다. 다시 시도해주세요.';
  static const practiceSectionEditTitle = '섹션 수정';
  static const practicePieceNameHint = '예: 1번, Allegro, Etude No.1';
  static const practiceRangeTypeTitle = '범위 유형';
  static const practiceRangeTypeFull = '전체';
  static const practiceRangeTypeLine = '줄';
  static const practiceRangeTypeMeasure = '마디';
  static const practiceMeasureRangeTitle = '마디 범위 *';
  static const practiceLineRangeTitle = '줄 범위 *';
  static const practiceSectionAliasHint = '예: 도입부, 주제 A, 코다';
  static const practiceSaveChanges = '변경사항 저장';
  static const practiceSectionAddTitle = '섹션 추가';
  static const practiceRepertoireAddTitle = '레퍼토리 추가';
  static const practiceRepertoireNameHintSuzuki = '예: 스즈키 바이올린 1권';
  static const practiceSaveButton = '저장하기';
  static const practicePieceNameHintStar = '예: 작은 별 변주곡';
  static const practiceRangeLabel = '구간';
  static const practiceRepertoireAddFailedRetry = '레퍼토리 추가에 실패했습니다. 다시 시도해주세요.';
  static const practiceSaveThenAddSection = '저장 후 섹션 추가하기';
  static const practiceRepertoireDeleteTitle = '레퍼토리 삭제';

  // -- Repertoire/Section Add (#616 i18n) --
  static const practiceSaveThenAddSectionHint = '레퍼토리 저장 후 섹션 추가 화면으로 이동합니다';
  static const practiceSectionDuplicateError = '동일한 곡명과 범위의 섹션이 이미 존재합니다';
  static const practiceSectionAddFailedRetry = '섹션 추가에 실패했습니다. 다시 시도해주세요.';
  static const practiceSaveFailedRetry = '저장에 실패했습니다. 다시 시도해주세요.';
  static const practiceStartMeasureLabel = '시작 마디';
  static const practiceEndMeasureLabel = '끝 마디';
  static const practiceStartLineLabel = '시작 줄';
  static const practiceEndLineLabel = '끝 줄';
  static const practicePieceNameLabel = '곡/연습곡 이름 *';
  static const practicePieceNameSimpleLabel = '곡명 *';
  static const practicePieceNameRequired = '곡 이름을 입력해주세요';
  static const practiceMeasureRangeSelectHint = '연습할 마디 구간을 선택하세요';
  static const practiceLineRangeSelectHint = '연습할 줄 구간을 선택하세요 (1~10줄)';
  static const practiceSectionAliasLabel = '섹션 별칭 (선택)';
  static String practiceSectionAliasHelper(String preview) =>
      '비워두면 "$preview"로 표시됩니다';
  static String practiceSectionNumberLabel(int number) => '섹션 $number';
  static String practiceSectionPieceNameRequired(int number) =>
      '섹션 $number의 곡명을 입력해주세요';

  // -- Smart Recording --
  static String practiceSmartTrimFront(String duration) => '앞 $duration 트림';
  static String practiceSmartTrimEnd(String duration) => '뒤 $duration 트림';

  // ── Profile Tab ──
  static const profileSectionSubscriptionPayment = '수강권·입금';
  static const profileSubscriptionTemplateLabel = '수강권 템플릿';
  static const profileSubscriptionTemplateSubtitle = '수강권 종류 및 가격 설정';
  static const profileOutstandingPaymentsLabel = '미수금 관리';
  static const profileOutstandingPaymentsSubtitle = '아직 입금 완료 기록이 없는 후불 수강권';
  static const profileBankAccountLabel = '입금 계좌';
  static const profileBankAccountSubtitle = '수강료 입금받을 계좌 설정';
  static const profileSectionAboutMe = '내 소개';
  static const profileBasicInfoEditLabel = '기본 정보 수정';
  static const profileBasicInfoEditSubtitle = '이름, 사진, 소개, 교수 스타일, 활동 지역';
  static const profileInstrumentManagementLabel = '악기 관리';
  static const profileInstrumentManagementSubtitle = '가르치는 악기 추가/관리';
  static const profileCredentialsLabel = '학력·경력·자격증';
  static const profileCredentialsSubtitle = '교육 배경 및 경력 사항';
  static const profileSectionLessonOperation = '레슨 운영';
  static const profileLessonTimeSettingsLabel = '레슨 시간 설정';
  static const profileLessonTimeSettingsSubtitle = '시간 길이, 쉬는시간, 시작 간격';
  static const profileAvailabilityLabel = '가용 시간 관리';
  static const profileAvailabilitySubtitle = '주간 스케줄, 휴무, 예외 시간';
  static const profileCancelPolicyLabel = '취소/노쇼 정책';
  static const profileCancelPolicySubtitle = '변경 횟수, 최소 취소 시간, 노쇼·이월';
  static const profileCancellationDefaultsLabel = '취소 정책 기본값';
  static const profileCancellationDefaultsSubtitle = '마감 시간, 학생 보상, 학원 알림 기본값';
  static const profileRepertoireLabel = '레퍼토리 관리';
  static const profileRepertoireSubtitle = '교재 및 곡 목록';
  static const profileTipTemplateLabel = '연습 팁 템플릿';
  static const profileTipTemplateSubtitle = '학생에게 보내는 짧은 연습 팁';
  static const profileSectionSocial = '소셜';
  static const profileFollowingLabel = '팔로잉';
  static const profileFollowingSubtitle = '팔로우한 선생님·학원 관리';
  static const profileNewsLabel = '소식';
  static const profileNewsSubtitle = '팔로우한 선생님의 공지·이벤트';
  static const profileSectionSettings = '설정';
  static const profileNotificationLabel = '알림 설정';
  static const profileRecordingLabel = '녹음 관리';
  static const profileVisibilityLabel = '공개 설정';
  static const profileVisibilitySubtitleLabel = '프로필 항목별 공개/비공개';
  static const profileSectionSupport = '지원';
  static const profileHelpLabel = '도움말';
  static const profileAppInfoLabel = '앱 정보';
  static const profileSectionAccount = '계정';
  static const profileTermsLabel = '이용약관';
  static const profilePrivacyPolicyLabel = '개인정보처리방침';
  static const profileLogoutLabel = '로그아웃';
  static const profileLogoutConfirm = '정말 로그아웃 하시겠습니까?';
  static const profilePreviewCta = '내 프로필 미리보기';
  // G5 #9 C-G2 — 친숙 용어 매핑 (availability_settings_ux_redesign_spec.md §70)
  static const profileShortcutAvailability = '운영시간';
  static const profileShortcutOutstandingPayment = '미수금';
  static const profileShortcutSubscription = '수강권';

  // ── Profile Preview ──
  static const profilePreviewTitle = '프로필 미리보기';
  static const profilePreviewNotFound = '프로필을 찾을 수 없습니다';
  static const profilePreviewError = '오류가 발생했습니다';
  static const profilePreviewSectionIntro = '소개';
  static const profilePreviewSectionTeachingStyle = '교수 스타일';
  static const profilePreviewSectionSpecialty = '전문 분야';
  static const profilePreviewSectionEducation = '학력';
  static const profilePreviewSectionCareer = '경력';
  static const profilePreviewSectionCertificate = '자격증';
  static const profilePreviewEditCta = '프로필 수정하기';
  static const profilePreviewCopied = '프로필이 복사되었습니다';
  static const profilePreviewExperienceYearsLabel = '경력';

  // ── Profile Visibility ──
  static const profileVisibilitySectionIntro = '소개';
  static const profileVisibilitySectionFee = '레슨료';
  static const profileVisibilitySectionCareerEdu = '경력 및 학력';
  static const profileVisibilitySectionCertificate = '자격증';
  static const profileVisibilitySectionContact = '연락처';

  // ── Extended Profile (Credentials) ──
  static const profileExtendedTitle = '학력·경력·자격증';
  static const profileExtendedError = '오류가 발생했습니다.';
  static const profileExtendedNotFound = '프로필을 찾을 수 없습니다';
  static const profileEducationEmpty = '학력 정보가 없습니다';
  static const profileEducationAdd = '학력 추가';
  static const profileCareerEmpty = '경력 정보가 없습니다';
  static const profileCareerAdd = '경력 추가';

  // ── Context Toggle ──
  static const contextToggleButtonLabel = '계정 전환';
  static const contextToggleButtonSubtitle = '학원과 개인 계정';
  static const contextToggleDialogTitle = '계정 전환';
  static const contextToggleCurrentContext = '현재 계정';
  static const contextToggleSwitchTo = '다음 계정으로 전환';
  static const contextToggleCancel = '취소';
  static const contextToggleConfirm = '전환하기';
  static const contextToggleLoadingMessage = '계정을 전환 중입니다...';
  static const contextToggleSwitchedToTeacher = '개인 강사 계정으로 전환되었습니다';
  static const contextToggleSwitchedToOwner = '학원장 계정으로 전환되었습니다';
  static const contextToggleSwitchFailed = '계정 전환에 실패했습니다. 다시 시도해주세요.';
  static const contextToggleOwnerContext = '학원장 계정';
  static const contextToggleTeacherContext = '개인 강사 계정';
  static const profileCertificateEmpty = '등록된 자격증이 없습니다';
  static const profileCertificateAdd = '자격증 추가';

  // ── Education Edit ──
  static const profileEducationEditTitle = '학력 수정';
  static const profileEducationAddTitle = '학력 추가';
  static const profileEducationDeleteTitle = '학력 삭제';
  static const profileEducationDeleteConfirm = '이 학력 정보를 삭제하시겠습니까?';
  static const profileEducationHintSchool = '예: 서울대학교';
  static const profileEducationHintMajor = '예: 음악학과 바이올린 전공';
  static const profileEducationHintGradYear = '예: 2020';
  static const profileSaveErrorRetry = '저장 중 오류가 발생했습니다. 다시 시도해주세요.';
  static const profileDeleteErrorRetry = '삭제 중 오류가 발생했습니다. 다시 시도해주세요.';

  // ── Career Edit ──
  static const profileCareerEditTitle = '경력 수정';
  static const profileCareerAddTitle = '경력 추가';
  static const profileCareerDeleteTitle = '경력 삭제';
  static const profileCareerDeleteConfirm = '이 경력 정보를 삭제하시겠습니까?';
  static const profileCareerHintOrganization = '예: 서울시립교향악단';
  static const profileCareerHintPosition = '예: 제1바이올린 단원';
  static const profileCareerHintStartYear = '시작년도';
  static const profileCareerHintEndYear = '종료년도';
  static const profileCareerHintEndYearCurrent = '현재';
  static const profileCareerCurrentlyWorking = '현재 재직 중';
  static const profileCareerHintDescription = '담당 업무나 주요 활동 내용을 입력해주세요';

  // ── Basic Info Edit ──
  static const profileBasicInfoTitle = '기본 정보 수정';
  static const profileBasicInfoSaved = '저장되었습니다';
  static const profileBasicInfoPhotoTitle = '프로필 사진';
  static const profileBasicInfoBackgroundTitle = '배경 사진';
  static const profileBasicInfoHintName = '예: 홍길동';
  static const profileBasicInfoHintIntroduction = '선생님을 소개해주세요';
  static const profileBasicInfoHintTeachingStyle = '레슨 방식과 철학을 설명해주세요';
  static const profileBasicInfoHintArea = '예: 강남구, 서초구';
  static const profileBasicInfoAreaDuplicate = '이미 추가된 지역입니다';
  static String profileBasicInfoMaxSelections(int max) =>
      '최대 $max개까지 선택할 수 있습니다';
  static String profileBasicInfoMaxAreas(int max) => '최대 $max개까지 추가할 수 있습니다';

  // ── Bank Account Edit ──
  static const profileBankAccountTitle = '입금 계좌';
  static const profileBankAccountAddLabel = '계좌 추가';
  static const profileBankAccountSetDefault = '기본 계좌로 설정';
  static const profileBankAccountDeleteTitle = '계좌 삭제';

  /// swipe destructive 확인 다이얼로그 — 계좌 삭제 title
  static const swipeActionDeleteBankAccountConfirmTitle = '계좌 삭제';

  /// swipe destructive 확인 다이얼로그 — 계좌 삭제 body (학생 영향 강화 메시지)
  static const swipeActionDeleteBankAccountConfirmBody =
      '이 계좌를 삭제하면 학생에게 표시되는 결제 정보(수강권 제안)에서 사라집니다. 진행할까요?';

  /// 계좌 저장/삭제 실패 피드백 (2026-06-12 — silent fail 방지).
  static const profileBankAccountSaveError = '계좌 저장에 실패했어요. 잠시 후 다시 시도해주세요';

  static const profileBankAccountAddFormTitle = '계좌 추가';
  static const profileBankAccountBankNameLabel = '은행명 *';
  static const profileBankAccountHintBankSelect = '은행 선택';
  static const profileBankAccountHintBankName = '은행명 입력';
  static const profileBankAccountNumberLabel = '계좌번호 *';
  static const profileBankAccountHintNumber = '계좌번호를 입력하세요';
  static const profileBankAccountHolderLabel = '예금주 *';
  static const profileBankAccountHintHolder = '예금주명을 입력하세요';

  // ── Instrument Management ──
  static const profileInstrumentTitle = '악기 관리';
  static const profileInstrumentError = '오류가 발생했습니다.';
  static const profileInstrumentCurrentSection = '현재 가르치는 악기';
  static const profileInstrumentAddSection = '악기 추가';
  static const profileInstrumentHintCustom = '악기 이름 입력';
  static const profileInstrumentDeleteTitle = '악기 삭제';

  /// Profile completion next-step hint — instruments not yet set (#732 i18n fix).
  static const profileCompletionAddInstruments = '가르치는 악기를 추가해보세요';

  /// swipe destructive 확인 다이얼로그 — 악기 삭제 title
  static const swipeActionDeleteInstrumentConfirmTitle = '악기 삭제';

  /// swipe destructive 확인 다이얼로그 — 악기 삭제 body
  static const swipeActionDeleteInstrumentConfirmBody = '이 악기를 목록에서 삭제할까요?';

  /// swipe destructive 확인 다이얼로그 — 곡 삭제 title (Repertoire #668 D4)
  static const swipeActionDeletePieceConfirmTitle = '곡 삭제';

  /// swipe destructive 확인 다이얼로그 — 곡 삭제 body
  static const swipeActionDeletePieceConfirmBody = '이 곡을 레퍼토리에서 삭제할까요?';

  /// swipe destructive 확인 다이얼로그 — 학력 삭제 title (#668 D5)
  static const swipeActionDeleteEducationConfirmTitle = '학력 삭제';

  /// swipe destructive 확인 다이얼로그 — 학력 삭제 body
  static const swipeActionDeleteEducationConfirmBody = '이 학력 정보를 삭제할까요?';

  /// swipe destructive 확인 다이얼로그 — 경력 삭제 title (#668 D5)
  static const swipeActionDeleteCareerConfirmTitle = '경력 삭제';

  /// swipe destructive 확인 다이얼로그 — 경력 삭제 body
  static const swipeActionDeleteCareerConfirmBody = '이 경력 정보를 삭제할까요?';

  /// swipe destructive 확인 다이얼로그 — 자격증 삭제 title (#668 D5)
  static const swipeActionDeleteCertificateConfirmTitle = '자격증 삭제';

  /// swipe destructive 확인 다이얼로그 — 자격증 삭제 body
  static const swipeActionDeleteCertificateConfirmBody = '이 자격증 정보를 삭제할까요?';

  /// swipe destructive 확인 다이얼로그 — 백업 삭제 title (#668 D6)
  static const swipeActionDeleteBackupConfirmTitle = '백업 삭제';

  /// swipe destructive 확인 다이얼로그 — 백업 삭제 body
  static const swipeActionDeleteBackupConfirmBody = '이 백업을 삭제할까요? 복구할 수 없습니다.';

  /// PieceActions BottomSheet 타이틀 (#668 D4)
  static const pieceActionsSheetTitle = '곡 액션';

  /// PieceActions BottomSheet — 편집 라벨 (#668 D4)
  static const pieceActionsEdit = '편집';

  /// PieceActions BottomSheet — 배정 라벨 (#668 D4)
  static const pieceActionsAssign = '학생에게 할당';

  /// BackupItemActions BottomSheet 타이틀 (#668 D6)
  static const backupActionsSheetTitle = '백업 액션';

  /// BackupItemActions BottomSheet — 복원 라벨 (#668 D6)
  static const backupActionsRestore = '복원';

  /// BackupItemActions BottomSheet — 공유 라벨 (#668 D6)
  static const backupActionsShare = '공유';

  // ── Lesson Time Settings ──
  static const profileLessonTimeTitle = '레슨 시간 설정';
  static const profileLessonTimeError = '오류가 발생했습니다.';
  static const profileLessonTimeOptionsSection = '레슨 시간 옵션';

  /// 레슨 시간 사용 토글 박스 — 사용중
  static const profileDurationInUse = '사용';

  /// 레슨 시간 사용 토글 박스 — 사용 안 함
  static const profileDurationOff = '해제';
  static const profileBookingSettingsSection = '예약 설정';
  static const profileBreakTimeTitle = '레슨 간 휴식 시간';
  static const profileMinBookingTitle = '최소 예약 가능 시간';
  static const profileBreakTimeNone = '없음';
  static const profileOperatingHoursSection = '운영 시간대';
  static const profileGuidanceMessageSection = '레슨 요청 안내';
  static const profileTrialLessonSection = '체험레슨 설정';
  static const profileTrialLessonFree = '체험레슨 무료';
  // Trial-free toggle subtitles. The setting only controls whether the trial
  // lesson is charged (reference price 0); it does NOT skip the subscription
  // proposal / time-confirmation flow. Worded to match actual behavior. (#18)
  static const profileTrialLessonFreeOn = '체험레슨 수강료를 받지 않아요 (참고가 0원)';
  static const profileTrialLessonFreeOff = '체험레슨도 수강료를 부과해요';
  static const profilePriceTableSection = '레슨 가격표';
  static const profilePriceTableHint = '예: 50000';

  // ── Cancellation Defaults Settings ──
  static const profileCancellationDefaultsTitle = '취소 정책 기본값';

  /// 취소 정책 기본값 화면 역할 안내 — #801. 변경권·노쇼는 취소/노쇼 정책 소관 명시.
  static const cancellationDefaultsRoleNote =
      '지각취소 시 보상·알림의 전역 기본값입니다. 변경 횟수·최소 취소 시간·노쇼·이월은 「취소/노쇼 정책」에서 설정합니다.';
  static const profileCancellationDefaultsSection = '취소 정책 기본값';
  static const profileCancellationDeadlineHours = '취소 페널티 없는 시간';
  static const profileCancellationDeadlineHoursHint = '시간';
  static const profileCancellationDeadlineDescription =
      '레슨 시작 몇 시간 전까지 취소하면 페널티를 받지 않는지 설정합니다';
  static const profileStudentCompensation = '학생 취소 시 보상 제공';
  static const profileStudentCompensationDescription =
      '마감 후 학생 취소 시 추가 연습시간으로 보상합니다';
  static const profileIncludeExtraMinutesText = '취소 알림에 보상 메시지 포함';
  static const profileCompensationMessage = '보상 메시지';
  static const profileCompensationMessageHint = '예: 10분 보너스 연습시간을 제공해드립니다';
  static const profileCompensationMessageDescription = '학생에게 표시할 보상 메시지를 입력하세요';
  static const profileNotifyOwnerOnLateCancel = '마감 후 취소 시 알림 (학원 강사만)';
  static const profileNotifyOwnerDescription = '학생이 마감 후 취소하면 강사에게 알림을 보냅니다';

  // ── Lesson Time Settings Widgets ──
  static const profileTimeSlotAdd = '시간대 추가';
  static const profileTimeSlotEditTitle = '시간대 수정';
  static const profileTimeSlotAddTitle = '시간대 추가';
  static const profileTimeSlotEndTimeError = '종료 시간은 시작 시간 이후여야 합니다';
  static const profileCustomDurationTitle = '커스텀 레슨 시간 추가';
  static const profileDirectInput = '직접 입력';
  static const profileDirectInputHint = '예: 50';
  static const profileSliderSelect = '슬라이더로 선택';
  static const profileDurationDeleteTitle = '레슨 시간 삭제';

  // ── Extended Profile Dialogs ──
  static const profileExperienceTitle = '교육 경력';
  static const profileFeeSettingTitle = '레슨료 설정';
  static const profileLessonTypeTitle = '레슨 방식';
  static const profileLessonAreaTitle = '레슨 가능 지역';
  static const profileLessonAreaHint = '예: 서울 강남구';
  static const profileDeleteItemConfirm = '정보를 삭제하시겠습니까?';
  static String profileDeleteItemTitle(String itemType) =>
      '$itemType ${AppStrings.delete}';
  static String profileDeleteItemMessage(String itemType) =>
      '이 $itemType 정보를 삭제하시겠습니까?';

  // ── Repertoire Management ──
  static const profileRepertoireTitle = '레퍼토리 관리';
  static const profileRepertoireError = '오류가 발생했습니다.';
  static const profileRepertoireAddPiece = '곡 추가';
  static const profileRepertoirePieceUpdated = '곡 정보가 수정되었습니다';
  static const profileRepertoireSearchHint = '곡 제목 또는 작곡가 검색';
  static const profileRepertoireDifficultyLabel = '난이도';
  static const profileRepertoireComposerLabel = '작곡가';
  static const profileRepertoireFilterReset = '필터 초기화';
  static const profileRepertoireAssignStudent = '학생에게 할당';
  static const profileRepertoirePieceEditTitle = '곡 수정';
  static const profileRepertoirePieceAddTitle = '곡 추가';
  static const profileRepertoireHintTitle = '예: 봄의 소리 왈츠';
  static const profileRepertoireHintComposer = '예: J. Strauss II';
  static const profileRepertoireHintOpus = '예: Op. 410';
  static const profileRepertoireHintMovement = '예: 1악장';
  static const profileRepertoireHintNotes = '특이사항이나 연습 포인트';
  static const profileRepertoireDifficultySelect = '난이도 선택';
  static const profileRepertoireDeselect = '선택 해제';
  static const profileRepertoireComposerSelect = '작곡가 선택';
  static const profileRepertoireNoComposers = '등록된 작곡가가 없습니다';
  static const profileRepertoireOpusLabel = '작품번호';
  static const profileRepertoireMovementLabel = '악장';
  static const profileRepertoirePieceDeleteTitle = '곡 삭제';
  static const profileRepertoireAssignTitle = '학생에게 곡 할당';
  static const profileRepertoireNoStudents = '등록된 학생이 없습니다';

  // ── Outstanding Payments ──
  static const profileOutstandingTitle = '미수금 관리';
  static const profileOutstandingError = '오류가 발생했습니다.';
  static const profileOutstandingEmpty = '미수금 항목이 없습니다';
  static const profileOutstandingListTitle = '미수금 목록';
  static const profileOutstandingSendReminder = '알림 보내기';
  static const profileOutstandingConfirmPayment = '입금 확인';
  static const profileOutstandingPaymentConfirmed = '입금이 확인되었습니다';
  // #426 입금 확인 24h Undo
  static const paymentConfirmedUndoSnackbar = '입금 확인 완료. 24시간 내 되돌릴 수 있습니다.';
  static const paymentUndoLabel = '되돌리기';
  static const paymentUndoSuccessSnackbar = '입금 확인을 되돌렸습니다.';
  static const paymentUndoFailedSnackbar = '되돌리기에 실패했습니다.';
  static const paymentUndoWindowExpired = '24시간이 지나 되돌릴 수 없습니다.';
  static const paymentUndoBlockedByLesson = '첫 레슨이 진행되어 되돌릴 수 없습니다.';

  // #424 입금 미확인 대시보드
  static const paymentPendingCardTitle = '입금 확인 대기';
  static const paymentPendingListTitle = '입금 확인 대기';
  static const paymentPendingEmpty = '입금 확인 대기 항목이 없습니다.';
  static const paymentPendingSectionImminent = '오늘 만료';
  static const paymentPendingSectionUrgent = 'D+3 이상';
  static const paymentPendingSectionRecent = 'D+0 ~ D+2';
  static const paymentPendingResendLabel = '재발송';
  static const paymentPendingConfirmLabel = '입금 확인';
  static const paymentPendingRevokeLabel = '회수';
  static const paymentPendingResendSuccess = '알림 재발송 완료';
  static const paymentPendingResendCooldown = '30분 후 다시 시도해주세요.';
  static const paymentPendingResendFailed = '재발송에 실패했습니다.';
  static const paymentPendingRevokeSuccess = '제안을 회수했습니다.';
  static const paymentPendingRevokeFailed = '회수에 실패했습니다.';
  static const paymentPendingRevokeConfirmTitle = '제안을 회수하시겠습니까?';
  static const paymentPendingRevokeConfirmBody =
      '학생에게 보낸 입금 안내가 사라집니다. 같은 학생에게 다시 보내려면 새로 제안을 만들어야 합니다.';

  // #5 D-G3 Phase 2 — 초대 대기 대시보드
  static const invitePendingCardTitle = '초대 대기';
  static const invitePendingListTitle = '초대 대기';
  static const invitePendingEmpty = '대기 중인 초대가 없습니다.';
  static const invitePendingSectionImminent = '만료 임박 (D+5~)';
  static const invitePendingSectionUrgent = 'D+3 이상';
  static const invitePendingSectionRecent = 'D+0 ~ D+2';
  static const invitePendingResendLabel = '재발송';
  static const invitePendingResendSuccess = '초대를 다시 보냈습니다.';
  static const invitePendingResendCooldown = '10분 후 다시 시도해주세요.';
  static const invitePendingResendFailed = '재발송에 실패했습니다.';
  static const invitePendingCodeLabel = '코드';

  // ── Tip Template Management ──
  static const profileTipTemplateTitle = '템플릿 관리';
  static const profileTipTemplateAdd = '템플릿 추가';
  static const profileTipTemplateDeleted = '템플릿이 삭제되었습니다';
  static const profileTipTemplateUndo = '실행취소';
  static const profileTipTemplateDeleteTitle = '템플릿 삭제';
  static const profileTipTemplateDeleteConfirm = '이 템플릿을 삭제하시겠습니까?';
  static const profileTipTemplateAddDialogTitle = '새 템플릿 추가';
  static const profileTipTemplateContentHint = '템플릿 내용을 입력하세요';
  static const profileTipTemplateInstrumentHint = '예: 바이올린, 피아노';
  static const profileTipTemplateContentRequired = '내용을 입력해주세요';
  static const profileTipTemplateAdded = '템플릿이 추가되었습니다';
  static const profileTipTemplateEditDialogTitle = '템플릿 수정';
  static const profileTipTemplateUpdated = '템플릿이 수정되었습니다';

  // ── Feedback Template Management (profile) ──
  static const profileFeedbackTemplateAdd = '템플릿 추가';
  static const profileFeedbackTemplateDeleteTitle = '템플릿 삭제';
  static const profileFeedbackTemplateDeleteConfirm = '이 템플릿을 삭제하시겠습니까?';

  // ── Teacher Onboarding ──
  static const onboardingWelcomeTitle = '환영합니다!';
  static const onboardingInviteStudentTitle = '학생 초대하기';
  static const onboardingCreateLessonTitle = '레슨 일정 등록';
  static const onboardingWriteFeedbackTitle = '레슨 노트 작성';
  static const onboardingCompletedTitle = '준비 완료!';

  // ── Coach Mark ──
  static const coachMarkTimeTitle = '레슨 시간을 설정하세요';
  static const coachMarkTimeDescription = '학생이 이 시간에 레슨을 예약할 수 있어요';
  static const coachMarkTimeAction = '설정하러 가기';
  // Phase B step 2 — first_student_invite (감사 §4.4 B2).
  static const coachMarkFirstStudentInviteTitle = '첫 학생을 초대해보세요';
  static const coachMarkFirstStudentInviteDescription =
      '학생 탭에서 초대 코드를 만들어 학생과 연결할 수 있어요';
  static const coachMarkFirstStudentInviteAction = '학생 초대하기';
  // Phase B step 3 — first_lesson_register (감사 §4.4 B2).
  static const coachMarkFirstLessonRegisterTitle = '첫 레슨을 등록해보세요';
  static const coachMarkFirstLessonRegisterDescription =
      '스케줄 탭에서 학생 · 날짜 · 시간을 선택하면 첫 레슨이 등록돼요';
  static const coachMarkFirstLessonRegisterAction = '레슨 등록하기';
  // Legacy keys — 호환성 유지 (기존 코드 미사용 시 향후 제거).
  static const coachMarkStudentTitle = '첫 학생을 초대하세요';
  static const coachMarkStudentDescription = '초대 코드를 공유하여 학생과 연결하세요';
  static const coachMarkStudentAction = '학생 추가하기';

  // ── Students Feature (학생 관리) ──────────────────────────────────
  static const studentFormTitle = '학생 작성';
  static const studentAddLabel = '학생 추가';
  static const studentEditTitle = '학생 수정';
  static const studentNotFound = '학생을 찾을 수 없습니다';
  static const studentAddFailed = '학생 추가에 실패했습니다. 다시 시도해주세요.';
  static const studentDeleteFailed = '학생 삭제에 실패했습니다. 다시 시도해주세요.';
  static const studentSaveFailed = '학생 정보 저장에 실패했습니다. 다시 시도해주세요.';
  static const studentLoadError = '학생 정보를 불러올 수 없습니다';
  static const studentSelectInstrument = '악기를 선택해주세요';
  static const studentStatusChangeFailed = '상태 변경에 실패했습니다. 다시 시도해주세요.';
  static const studentDeleteTitle = '학생 삭제';
  static const studentArchiveTitle = '학생 보관';
  static const studentArchiveMessage = '보관된 학생은 목록에서 숨겨지며 언제든지 복원할 수 있습니다.';
  static const studentArchiveFailed = '학생 보관에 실패했습니다. 다시 시도해주세요.';
  static const studentArchivedSnack = '학생이 보관되었습니다';
  static const studentInviteTitle = '학생 초대';
  static const studentDirectRegister = '직접 등록';
  static const studentParentInviteCode = '학부모 초대 코드';
  static const studentInviteCodeFailed = '초대 코드 생성에 실패했습니다. 다시 시도해주세요.';
  static const studentParentInviteLabel = '학부모 초대';
  static const studentParentInviteHint = '연결을 위한 초대 코드 생성';
  static const studentEditInfoTitle = '학생 정보 수정';
  static const studentCallTitle = '전화하기';

  /// #779 신원 스트립 전화 단축 버튼 라벨.
  static const studentContactCallShort = '전화';

  /// #779 신원 스트립 문자 단축 버튼 라벨.
  static const studentContactMessageShort = '문자';

  /// #779 더보기 메뉴 상태 변경 섹션 헤더.
  static const studentStatusChangeSection = '상태 변경';
  static const studentViewLessonHistory = '레슨 기록 보기';
  static const studentConvertRegular = '정규 전환';
  static const studentConvertRegularHint = '체험 학생을 정규 학생으로';
  static const studentPauseTitle = '휴강 설정';
  static const studentPauseHint = '일시적으로 레슨을 중단';
  static const studentResumeTitle = '레슨 재개';
  static const studentResumeHint = '휴강 해제하고 레슨 재개';
  static const studentCopyLabel = '복사';
  static const studentShareLabel = '공유';
  static const studentUpcomingLessons = '다가오는 레슨';
  static const studentViewAll = '전체 보기';
  static const studentLessonLoadError = '레슨 정보를 불러올 수 없습니다';
  static const studentRecentLessons = '최근 레슨';
  static const studentLessonHistoryError = '레슨 기록을 불러올 수 없습니다';
  static const studentRosterMasthead = '수강 관리';
  static const studentFilterTitle = '필터';
  static const studentSortTitle = '정렬 기준';
  static const studentBulkSelectLabel = '학생 선택';
  static const studentBulkCancelLabel = '휴강 공지';
  static const studentSendMessage = '메시지 보내기';
  static const studentBulkMessageTitle = '일괄 메시지 보내기';
  static const studentBulkMessageBodyHint = '메시지 내용을 입력하세요';
  static const studentBulkMessageTitleHint = '예) 5월 연휴 일정 안내';
  static const studentSubscriptionStatus = '수강권 현황';
  static const studentSubscriptionIssue = '발급';
  static const studentLessonNotes = '레슨 노트';
  static const studentWeeklyPractice = '이번 주 연습';
  static const studentPracticeLoadError = '연습 정보를 불러올 수 없습니다';
  static const studentWeeklyPracticeSummary = '이번 주 연습 요약';
  static const studentPracticeDaysLabel = '연습 일수';
  static const studentTotalPracticeTime = '총 연습시간';
  static const studentSharedRecordings = '공유 녹음';
  static const studentWeeklyPracticeStatus = '주간 연습 현황';
  static const studentSharedRecordingsSection = '공유된 녹음';
  static const studentDetailTitle = '학생 상세';
  static const viewStudentDetail = '학생 상세 보기';
  static const studentDetailStatsPreparing = '상세 통계 기능은 준비 중입니다';
  static const studentDetailStatsButton = '상세 통계 보기';
  static const studentNoPhone = '전화번호 미등록';
  static const studentUpcomingLessonsEmpty = '예정된 레슨이 없습니다';
  static const studentRecentLessonsEmpty = '완료된 레슨이 없습니다';
  static const formSectionBasicInfo = '기본 정보';
  static const formSectionGuardianInfo = '보호자 정보';
  static const formSectionGuardianHint = '미성년 학생의 경우 입력해주세요';
  static const formSectionAddress = '주소';
  static const formSectionInstrument = '악기';
  static const formSectionLevelTuition = '레벨 및 수강료';
  static const formSectionSchedule = '레슨 일정';
  static const formSectionNotes = '메모';
  static const studentStatTotalLessons = '총 레슨';
  static const studentStatThisMonth = '이번 달';
  static const studentStatWeeklyPractice = '주간 연습';
  static const studentSearchByNameOrInstrument = '학생 이름 또는 악기로 검색';
  static const studentRenewalProposal = '갱신 제안';
  static const studentAddLesson = '레슨 추가';
  static const studentReregistrationProposal = '재등록 제안';
  static const studentStatusTrial = '체험';
  static const studentStatusActive = '수강중';
  static const studentStatusPaused = '휴강';
  static const studentStatusInactive = '종료';
  static const studentLevelBeginner = '입문';
  static const studentLevelElementary = '초급';
  static const studentLevelIntermediate = '중급';
  static const studentLevelAdvanced = '고급';
  static const studentPracticeStatusGood = '우수';
  static const studentPracticeStatusNormal = '보통';
  static const studentPracticeStatusPoor = '부족';
  static const studentPracticeStatusPaused = '기록없음';
  static const studentTriageExpiring = '만료임박';
  static const studentTriageUnpaid = '미수금';
  static const studentTriageTrial = '체험중';
  static const studentBulkCancelConfirmTitle = '휴강 공지 발송';
  static const studentBulkCancelReasonHint = '선생님 개인 사정으로 휴강합니다.';
  static const studentBulkCancelNotificationTitle = '휴강 안내';
  static const studentProfilePhotoTitle = '프로필 사진';
  static const studentBackgroundPhotoTitle = '배경 사진';
  static const studentAddCompleteTitle = '학생 추가 완료';
  static const studentImageGallery = '갤러리에서 선택';
  static const studentImageCamera = '카메라로 촬영';
  static const studentExitConfirmMessage = '변경한 내용이 저장되지 않습니다.\n정말 나가시겠습니까?';
  static const studentAddressSearchComingSoon = '주소 검색 기능이 곧 추가됩니다';
  static const studentAddressSearchLabel = '주소 검색';
  static const studentPostalCodeLabel = '우편번호';
  static const studentAddressLabel = '주소';
  static const studentAddressHint = '주소를 입력해주세요 (예: 서울시 강남구 역삼동)';
  static const studentAddressDetailLabel = '상세주소';
  static const studentAddressDetailHint = '동/호수를 입력하세요 (선택)';
  static const studentParentNameLabel = '보호자 이름';
  static const studentParentNameHint = '보호자 이름을 입력하세요';
  static const studentParentPhoneLabel = '보호자 연락처';
  static const studentNameLabel = '이름';
  static const studentNameHint = '학생 이름을 입력하세요';
  static const studentPhoneLabel = '연락처';
  static const studentEmailLabel = '이메일';
  static const studentFrequencyOnceTitle = '주 1회';
  static const studentFrequencyOnceSubtitle = '월 4회';
  static const studentFrequencyTwiceTitle = '주 2회';
  static const studentFrequencyTwiceSubtitle = '월 8회';
  static const studentManageSubscription = '수강권 관리';
  static const studentNotesLabel = '메모';
  static const studentNotesHint = '레슨 시 참고할 내용 (악기 상태, 연습 환경, 특이사항 등)';
  static const studentScheduleChange = '변경';
  static const studentAddMethodQuestion = '어떤 방법으로 학생을 등록할까요?';

  // ── Address Search Widget (공통) ──────────────────────────

  /// 주소 검색 버튼
  static const addressSearch = '주소 검색';

  /// 주소 검색 입력 힌트
  static const addressSearchHint = '도로명 또는 지번 주소를 검색하세요';

  /// 상세주소 입력 힌트
  static const addressDetailHint = '상세주소 (동/호수)';

  /// 주소 섹션 라벨
  static const addressLabel = '주소';

  // 주소 수기 입력 fallback
  static const addressManualInput = '직접 입력';
  static const addressPostalHint = '우편번호 (5자리)';
  static const addressManualHint = '주소를 직접 입력하세요';
  static const addressNoResults = '검색 결과가 없습니다';
  static const addressManualInputGuide = '주소를 직접 입력하려면 닫아주세요 →';

  // ── YouTube Player (인앱 플레이어 + 구간 반복) ───────────────────

  /// 구간 반복 (loop section label)
  static const loopSectionLabel = '구간 반복';

  /// 구간 반복 ON (loop section on)
  static const loopSectionOn = '구간 반복 ON';

  /// 구간 반복 OFF (loop section off)
  static const loopSectionOff = '구간 반복 OFF';

  /// 시작 (section start label)
  static const sectionStart = '시작';

  /// 끝 (section end label)
  static const sectionEnd = '끝';

  /// macOS에서는 외부 브라우저에서 재생됩니다
  static const youtubePlayerMacOsFallback = 'macOS에서는 외부 브라우저에서 재생됩니다';

  /// 외부 브라우저에서 열기
  static const youtubePlayerOpenExternal = '외부 브라우저에서 열기';

  // -- Subscription Post-Issuance Editing (수강권 발급 후 수정) --

  /// 수정 (공통 수정 버튼 라벨)
  static const edit = '수정';

  /// 시간 (시간 단위 접미사)
  static const hourSuffix = '시간';

  /// 장소 (레슨 장소 라벨)
  static const locationLabel = '장소';

  /// 유효기간 (라벨)
  static const validityLabel = '유효기간';

  /// 변경/취소권 추가 (바텀시트 제목)
  static const addRescheduleCredit = '변경/취소권 추가';

  /// 추가 횟수 (입력 필드 라벨)
  static const additionalCount = '추가 횟수';

  /// 사유 (입력 필드 라벨)
  static const addReason = '사유';

  /// 수정 불가 (재발급 필요) (섹션 헤더)
  static const subscriptionEditNotEditable = '수정 불가 (재발급 필요)';

  /// 레슨 횟수나 금액을 변경하시려면\n새 수강권을 발급해주세요. (안내 메시지)
  static const subscriptionEditNewRequired =
      '레슨 횟수나 금액을 변경하시려면\n새 수강권을 발급해주세요.';

  /// 새 수강권 발급 (링크 텍스트)
  static const issueNewSubscription = '새 수강권 발급';

  /// 이동시간 수정 (바텀시트 제목)
  static const editTravelTime = '이동시간 수정';

  /// 취소 기준시간 수정 (바텀시트 제목)
  static const editCancelDeadline = '취소 기준시간 수정';

  /// 장소 변경 (버튼 라벨)
  static const changeLocation = '장소 변경';

  // -- Receipt / Export (영수증 · 레슨 이력 내보내기) --

  /// 영수증 (스크린 타이틀)
  static const receiptTitle = '영수증';

  /// 영수증 번호 (라벨)
  static const receiptNumber = '영수증 번호';

  /// PDF 다운로드 (버튼 라벨)
  static const receiptDownload = 'PDF 다운로드';

  /// 레슨 이력 내보내기 (바텀시트 타이틀)
  static const exportTitle = '레슨 이력 내보내기';

  /// CSV (형식 선택 라벨)
  static const exportFormatCsv = 'CSV';

  /// PDF (형식 선택 라벨)
  static const exportFormatPdf = 'PDF';

  /// 내보내기 (버튼 라벨)
  static const exportButton = '내보내기';

  /// 기간 (내보내기 섹션 라벨)
  static const exportPeriod = '기간';

  /// 형식 (내보내기 섹션 라벨)
  static const exportFormat = '형식';

  // -- Preferred Location (희망 레슨 장소 선택 — 레슨 신청 폼) --

  /// 희망 레슨 장소 (섹션 제목)
  static const preferredLocationTitle = '희망 레슨 장소';

  /// 학생 희망 장소 변경 (경고 다이얼로그 제목)
  static const locationChangeWarningTitle = '학생 희망 장소 변경';

  /// 학생 희망 장소 변경 경고 본문
  static String locationChangeWarningBody(String original, String newLoc) =>
      '학생이 신청 시 "$original"을 희망했습니다.\n'
      '"$newLoc"으로 변경하시겠습니까?\n\n'
      '※ 학생에게 장소 변경이 안내됩니다.';

  // ── Notification Settings (알림 설정) ──────────────────────────────────

  /// 알림 설정 화면 제목
  static const notificationSettingsTitle = '알림 설정';

  /// 전체 알림 마스터 토글 라벨
  static const notificationMasterToggle = '전체 알림';

  /// 카테고리별 설정 섹션 헤더
  static const notificationCategoryHeader = '카테고리별 설정';

  /// 레슨 알림 카테고리 제목
  static const notificationLesson = '레슨 알림';

  /// 레슨 알림 카테고리 설명
  static const notificationLessonDesc = '레슨 시작, 완료 알림';

  /// 시간 변경 요청 카테고리 제목
  static const notificationSchedule = '시간 변경 요청';

  /// 시간 변경 요청 카테고리 설명
  static const notificationScheduleDesc = '레슨 시간 변경 요청·승인/거절 알림';

  /// 수강권 카테고리 제목
  static const notificationSubscription = '수강권';

  /// 수강권 카테고리 설명
  static const notificationSubscriptionDesc = '만료 임박, 갱신 제안, 입금';

  /// 공지 카테고리 제목
  static const notificationAnnouncement = '공지';

  /// 공지 카테고리 설명
  static const notificationAnnouncementDesc = '선생님 휴강, 일반 공지';

  /// 연습 리마인더 카테고리 제목
  static const notificationPractice = '연습 리마인더';

  /// 연습 리마인더 카테고리 설명
  static const notificationPracticeDesc = '연습 알림, 목표 달성';

  /// 마케팅 카테고리 제목
  static const notificationMarketing = '마케팅';

  /// 마케팅 카테고리 설명
  static const notificationMarketingDesc = '새 기능 안내, 이벤트';

  /// 방해금지 시간 섹션 제목
  static const quietHoursTitle = '방해금지 시간';

  /// 방해금지 활성화 토글 라벨
  static const quietHoursEnabledLabel = '방해금지 시간 설정';

  /// 방해금지 시작 시간 라벨
  static const quietHoursStartLabel = '시작';

  /// 방해금지 종료 시간 라벨
  static const quietHoursEndLabel = '끝';

  // Notification Settings — DND bypass hints
  /// 레슨 카테고리 DND 우회 안내 (spec §6.2)
  static const notifCategoryLessonBypassHint = '레슨 시작/취소 알림은 항상 수신됩니다';

  /// 방해금지 시간대 DND 우회 안내 (spec §6.2)
  static const notifQuietHoursBypassHint = '레슨 시작, 취소 알림은 방해금지 시간에도 수신됩니다';

  // ── App Rating Prompt (앱 평가 유도) ────────────────────────────────────

  // ── 마일스톤 축하 카드 (팝업 다이얼로그 폐기 → 인라인 카드) ──

  /// 마일스톤 축하 메시지
  static String milestoneCongrats(int count) => '$count회 레슨 달성!';

  /// 마일스톤 설명
  static const milestoneDescription = '선생님의 레슨이 쌓이고 있어요.\n앞으로도 좋은 레슨을 응원합니다!';

  /// 마일스톤 카드 내 소프트 리뷰 링크
  static const milestoneReviewLink = '앱이 마음에 드셨다면 평가를 남겨주세요 →';

  /// 프로필 하단 조용한 리뷰 링크
  static const profileRatingLink = '레슨앱 평가하기';

  // ── 레거시 (기존 팝업용, 참조 유지) ──
  static const ratingQuestion = '레슨앱이 도움이 되고 있나요?';
  static const ratingPromptBody = '레슨과 연습을 함께 관리하는\n경험이 어떠셨는지 알고 싶어요.';
  static const ratingYes = '네, 도움돼요!';
  static const ratingNo = '아니요, 별로예요';
  static const ratingFeedbackQuestion = '어떤 점을 개선하면 좋을까요?';
  static const ratingFeedbackBody = '소중한 의견을 개발팀에 직접 전달할게요.';
  static const ratingSendFeedback = '피드백 보내기';
  static const ratingLater = '나중에';

  // ── Announcement edit/delete ──
  static const announcementEditTitle = '공지 수정';
  static const announcementEditHint = '공지 내용을 수정하세요';
  static const announcementDeleteTitle = '공지 삭제';
  static const announcementDeleteConfirm =
      '이 공지를 삭제하시겠습니까?\n이미 발송된 알림은 취소되지 않습니다.';

  /// swipe destructive 확인 다이얼로그 — 공지 삭제 title
  static const swipeActionDeleteAnnouncementConfirmTitle = '공지 삭제';

  /// swipe destructive 확인 다이얼로그 — 공지 삭제 body
  static const swipeActionDeleteAnnouncementConfirmBody =
      '이 공지를 삭제하시겠습니까?\n이미 발송된 알림은 취소되지 않습니다.';

  /// swipe destructive 확인 다이얼로그 — 알림 삭제 title
  static const swipeActionDeleteNotificationConfirmTitle = '이 알림을 삭제할까요?';

  /// swipe destructive 확인 다이얼로그 — 알림 삭제 body
  static const swipeActionDeleteNotificationConfirmBody = '복구할 수 없습니다.';

  // ── Add student method screen ──
  static const studentAddMethodBadgeRecommended = '권장';
  static const studentAddMethodInviteDescription =
      '학생에게 초대 링크를 보내면\n학생 정보가 자동으로 등록됩니다.';
  static const studentAddMethodDirectDescription =
      '학생 정보를 직접 입력하여\n관리할 수 있습니다.';
  static const studentAddMethodInviteButton = '초대하기';
  static const studentAddMethodDirectButton = '작성하기';

  // ── Students tab empty state ──
  static const studentsEmptyTitle = '아직 등록된 학생이 없습니다';
  static const studentsEmptySubtitle = '학생을 초대하면 정보가 자동으로\n등록되어 편리하게 관리할 수 있어요';
  static const studentsSearchEmptyTitle = '검색 결과가 없습니다';

  // ── Parent profile menu ──
  static const parentProfileLanguageLabel = '언어';
  static const parentProfileRecordingBackupLabel = '녹음 백업';
  static const parentProfileSectionSettings = '설정';
  static const parentProfileSectionSupport = '지원';
  static const parentProfileSectionAccount = '계정';

  // ── Schedule change reason ──
  static const scheduleChangeReasonHint = '예: 이사 관련 일정 변경';

  // ── Onboarding / profile hints ──
  static const teacherNicknameHint = '예) 영희쌤, 바이올린 선생님';
  static const tutorialTeacherNameLabel = '선생님 이름';
  static const tutorialTeacherNameHint = '예) 김선생';
  static const tutorialLessonNoteHint = '예) 오늘 연습한 내용과 다음 과제를 적어주세요.';

  // ── Students tab ──
  static String selectedCount(int count) => '$count명 선택됨';
  static String totalStudentCount(int count) => '전체 $count명';
  static const studentNoSchedule = '스케줄 미등록';
  static const subscriptionExpiredLabel = '만료됨';
  static const sortByInstrument = '악기순';
  static const sortByPracticeStatus = '연습상태별';

  // ── Sync failures ──
  static String syncFailedBanner(int count) => '$count건의 동기화가 실패했습니다';
  static const syncRetryAction = '재시도';

  // ── Academy announcements ──
  static const announcementsTitle = '공지사항';
  static const announcementMarkAsRead = '읽음 처리';
  static const announcementNoContent = '공지사항이 없습니다';

  // ── Academy inquiry ──
  static const inquiryTitle = '1:1 문의';
  static const inquiryTabMyInquiries = '내 문의';
  static const inquiryTabAsk = '문의하기';
  static const inquirySenderRoleStudent = '학생';
  static const inquirySenderRoleParent = '학부모';
  static const inquiryAskButton = '문의 보내기';
  static const inquiryReplyPlaceholder = '답글을 입력하세요';
  static const inquiryReplySend = '답글 전송';
  static const inquirySLALabel = '보통 1~2일 내 답변';
  static const inquiryNoInquiries = '문의 내역이 없습니다';
  static const inquiryCreated = '문의가 접수되었습니다';
  static const inquiryFormNameLabel = '이름';
  static const inquiryFormNameHint = '예) 김철수';
  static const inquiryFormPhoneLabel = '연락처';
  static const inquiryFormPhoneHint = '예) 010-1234-5678';
  static const inquiryFormMessageLabel = '문의 내용';
  static const inquiryFormMessageHint = '문의 내용을 입력해주세요';
  static const inquiryFormSubmit = '문의 보내기';
  static const inquiryFormRelationLabel = '관계 선택';
  static const inquiryFormRelationParent = '학부모';
  static const inquiryFormPhoneRequired = '연락처를 입력해주세요';
  static String inquiryFormSubmitFailed(Object e) => '문의 전송 실패: $e';
  static String inquiryReplySubmitFailed(Object e) => '답변 전송 실패: $e';
  static String inquiryReplyCountLabel(int count) => '답변 ($count)';
  static const inquiryReplyFromAcademy = '학원 답변';
  static const inquiryReplyFromMe = '내 답변';
  static String inquiryLoadErrorWith(Object e) => '오류: $e';

  // ── Note Access Requests ───────────────────────────────────

  /// 노트 일시 접근 요청 화면 제목
  static const noteAccessRequestTitle = '노트 접근 동의';

  /// 학원명 라벨
  static const academyLabel = '학원';

  /// 요청 사유 라벨
  static const requestReasonLabel = '요청 사유';

  /// 동의 버튼
  static const consentButton = '동의';

  /// 거절 버튼
  static const rejectButton = '거절';

  /// 회수 버튼
  static const revokeButton = '회수';

  /// 동의 성공 메시지
  static const consentSuccess = '노트 접근을 동의했습니다';

  /// 거절 성공 메시지
  static const rejectSuccess = '노트 접근 요청을 거절했습니다';

  /// 회수 성공 메시지
  static const revokeSuccess = '노트 접근 권한을 회수했습니다';

  /// 노트 접근 권한 배너 제목
  static const noteAccessActiveBannerTitle = '노트 접근 권한';

  /// 노트 접근 권한 배너 설명 (N일 남음)
  static String noteAccessActiveBannerDays(int days) =>
      '학원의 노트 접근 권한이 $days일 남았습니다';

  /// 노트 접근 권한 배너 설명 (마지막 날)
  static const noteAccessActiveBannerLastDay = '학원의 노트 접근 권한이 오늘 종료됩니다';

  // ── Academy Activity Timeline ──────────────────────────────

  /// 학원 활동 타임라인 화면 제목
  static const academyActivityTimeline = '학원 활동 타임라인';

  /// 활동 없음 메시지
  static const noActivityFound = '활동 기록이 없습니다';

  /// 활동 로드 실패 메시지
  static const errorLoadingActivity = '활동 기록을 불러올 수 없습니다';

  /// 최근 변경됨 배지
  static const recentlyChanged = '12시간 이내';

  /// 활동 타입: 레슨 생성
  static const activityTypeLessonCreated = '레슨 생성';

  /// 활동 타입: 수강권 발급
  static const activityTypeSubscriptionIssued = '수강권 발급';

  /// 활동 타입: 학생 등록
  static const activityTypeStudentEnrolled = '학생 등록';

  /// 활동 타입: 레슨 완료
  static const activityTypeLessonCompleted = '레슨 완료';

  /// 활동 타입: 입금 확인
  static const activityTypePaymentConfirmed = '입금 확인';

  /// 활동 타입: 일정 변경
  static const activityTypeScheduleChanged = '일정 변경';

  /// 활동 타입: 노트 추가
  static const activityTypeNoteAdded = '노트 추가';

  /// 활동 타입: 레슨 요청 수락
  static const activityTypeLessonRequestAccepted = '요청 수락';

  /// 활동 타입: 보강 기록
  static const activityTypeMakeupRecorded = '보강 기록';

  /// 활동 타입: 알 수 없음
  static const activityTypeUnknown = '활동';

  // ── Cancellation Credit (G17) ─────────────────────────────

  /// 변경권 위젯 — 잔여 개수 표시 ("변경권 잔여: 2회")
  static String cancellationCreditRemaining(int count) => '변경권 잔여: $count회';

  /// 변경권 위젯 — 0회일 때 표시
  static const cancellationCreditNone = '변경권 없음';

  // ── Teacher Cancel Policy Banner (G16) ────────────────────

  /// 12시간 이내 취소 배너 — 제목
  static const teacherCancelWithin12hTitle = '12시간 이내 취소입니다';

  /// 12시간 이내 취소 안내 — 학생 변경권 자동 적립
  static const teacherCancelGrantsCredit = '학생 변경권 +1 자동 적립';

  /// 12시간 이내 취소 안내 — 사과 카톡 자동 발송
  static const teacherCancelSendsApology = '학생에게 사과 카톡 자동 발송';

  /// 12시간 이내 취소 안내 — 학원 관리자 알림 발송 (ownership=academy)
  static const teacherCancelNotifyAcademy = '학원 관리자에게 알림 발송';

  /// 12시간 이내 취소 안내 — 보강은 강사가 직접 안내
  static const teacherCancelTeacherReschedule = '보강 일정은 강사님이 직접 안내·재입력';

  /// 12시간 이내 취소 — 추가 시간 안내 라벨
  static const teacherCancelExtraMinutesLabel = '다음 레슨 추가 시간 안내';

  /// 12시간 이내 취소 — 추가 시간 안내 기본 문구
  static const teacherCancelExtraMinutesDefault = '다음 레슨 시 추가 시간을 안내드릴 예정입니다.';

  // ── Bulk Closure Makeup Input (G15) ───────────────────────

  /// 보강 입력 화면 — 헤더
  static String makeupInputTitle(String closureDateText) =>
      '보강 일정 입력 — $closureDateText 휴원 영향';

  /// 보강 입력 행 — 학생 이름 + 원래 시각
  static String makeupInputLessonRow(String studentName, String originalText) =>
      '$studentName ($originalText 휴강)';

  /// 보강 입력 — picker 라벨
  static const makeupInputPickerLabel = '보강 시각';

  /// 보강 입력 — picker 미선택 placeholder
  static const makeupInputPickerEmpty = '시각 선택';

  /// 보강 입력 — 저장 버튼
  static const makeupInputSaveAction = '저장';

  /// 보강 입력 — 안내 1
  static const makeupInputNoticeConfirm = '보강 시각은 강사가 직접 확정합니다.';

  /// 보강 입력 — 안내 2
  static const makeupInputNoticeNotify = '확정 즉시 학생/학부모에게 통보됩니다.';

  /// 보강 입력 — 임시 저장 버튼
  static const makeupInputDraftSave = '임시저장';

  /// 보강 입력 — 전체 확정 버튼
  static const makeupInputBulkConfirm = '전체 확정';

  /// 보강 입력 — 진행률 표기
  static String makeupInputProgress(int completed, int total) =>
      '$total건 중 $completed건 입력 완료';

  /// 보강 입력 — 빈 상태
  static const makeupInputEmptyState = '영향 받은 레슨이 없습니다.';

  /// 보강 입력 — 저장 성공 토스트
  static const makeupInputSavedToast = '보강 일정이 저장되었습니다.';

  // #768 ③ — 보강 시간 충돌 경고 + 최종 확인 요약
  /// 시간 겹침 (충돌 보강 행 배지)
  static const makeupInputConflictBadge = '시간 겹침';

  /// N건 보강 시각이 겹칩니다 (충돌 안내)
  static String makeupInputConflictNotice(int n) => '$n건 보강 시각이 겹칩니다. 확인해 주세요.';

  /// 보강 일정 확인 (최종 확인 요약 다이얼로그 제목)
  static const makeupInputSummaryTitle = '보강 일정 확인';

  /// {학생} · {보강시각} (요약 행)
  static String makeupInputSummaryRow(String student, String makeupText) =>
      '$student · $makeupText';

  // ── Closure Opinion Window (G15 §5.2) ─────────────────────

  /// 의견 위젯 — 헤더
  static const closureCommentTitle = '의견 입력 (학원 관리자에게 전달)';

  /// 의견 위젯 — placeholder
  static const closureCommentHint = '의견을 입력해주세요...';

  /// 의견 위젯 — 보내기 버튼
  static const closureCommentSend = '의견 보내기';

  /// 의견 위젯 — 자동 적용 안내
  static String closureCommentAutoApply(int minutes) => '$minutes분 후 자동 적용됩니다.';

  /// 의견 위젯 — 즉시 적용 가능 안내
  static const closureCommentImmediateApply = '학원 관리자가 즉시 적용할 수도 있습니다.';

  /// 의견 위젯 — 윈도우 만료
  static const closureCommentWindowClosed = '의견 윈도우가 종료되었습니다.';

  /// 의견 위젯 — 의견 전송됨
  static const closureCommentSubmitted = '의견이 전송되었습니다.';

  // ── Public Student Summary (R2 #318) ──────────────────────

  /// 공개 학생 요약 — 화면 제목
  static const studentSummaryAppBarTitle = '레슨 요약';

  /// 공개 학생 요약 — 백엔드 미연결 placeholder (Flutter-only scope)
  static const studentSummaryComingSoon = '곧 만나요!\n레슨 요약이 준비 중입니다.';

  /// 공개 학생 요약 — 토큰 정보 부가 설명
  static const studentSummaryTokenLabel = '공유 링크';

  // ── Paywall (R4 #415) ────────────────────────────────────
  // spec/paywall_spec.md §6.3.

  /// FreeLimitSheet 제목 — 학생 5명 한도 도달.
  static const paywallFreeLimitTitle = '학생 5명 한도에 도달했어요';

  /// FreeLimitSheet 본문 — Pro 업그레이드 안내.
  static const paywallFreeLimitSubtitle = '더 많은 학생을 관리하려면 Pro 로 업그레이드하세요.';

  /// PlanExpired 진입 차단 제목.
  static const paywallPlanExpiredTitle = '플랜이 만료되었어요';

  /// PlanExpired 본문 — 7일 유예 종료 후 Free 강등.
  static const paywallPlanExpiredSubtitle = '재결제하거나 Free 플랜으로 돌아가야 합니다.';

  /// Pro 월간 카드 제목.
  static const paywallProMonthlyTitle = 'Pro 월간';

  /// Pro 월간 카드 본문 (가격 + 혜택).
  static const paywallProMonthlyDescription = '₩9,900 / 월 · 학생 무제한';

  /// Pro 구매 CTA.
  static const paywallProBuyCta = '구매하기';

  /// Trial 카드 제목.
  static const paywallTrialTitle = '14일 무료 체험';

  /// Trial 본문 — 자동 결제 없음.
  static const paywallTrialNote = '자동 결제 없음. 만료 시 Free 복귀.';

  /// Trial 시작 CTA.
  static const paywallTrialStartCta = '체험 시작';

  /// Paywall 닫기.
  static const paywallLaterCta = '나중에';

  /// IAP 미연결 안내 (Phase B 임시) — Phase C 에서 제거.
  static const paywallComingSoonHint = '구매 기능은 곧 제공됩니다.';

  // ── Paywall Phase C (#415) ───────────────────────────────
  // IAP/Trial 처리 결과 안내.

  /// Pro 구매 시작 직전 — store 사용 불가 (디바이스 미지원/네트워크 차단).
  static const paywallStoreUnavailable = '결제 스토어에 연결할 수 없어요. 잠시 후 다시 시도해주세요.';

  /// Pro 상품 정보 조회 실패.
  static const paywallProductNotFound = '구매 정보를 찾을 수 없어요. 잠시 후 다시 시도해주세요.';

  /// Pro 구매 성공 — 영수증 검증까지 완료.
  static const paywallPurchaseSuccess = 'Pro 플랜이 활성화되었어요.';

  /// Pro 구매 — 영수증은 받았지만 검증 보류 (백엔드가 비동기 처리 중).
  static const paywallPurchasePending = '구매가 접수되었어요. 검증이 완료되면 자동으로 활성화됩니다.';

  /// Pro 구매 — 사용자가 store sheet 취소.
  static const paywallPurchaseCancelled = '구매를 취소했어요.';

  /// Pro 구매 실패 — store/network/검증 에러 (fallback / unclassified).
  static const paywallPurchaseFailed = '구매를 완료하지 못했어요. 잠시 후 다시 시도해주세요.';

  /// Pro 구매 실패 — 네트워크 단절 / store 응답 timeout. #415 Phase B3.
  static const paywallPurchaseFailedNetwork = '연결이 불안정해요. 다시 시도해주세요.';

  /// Pro 구매 실패 — Apple/Google 이 결제 거절 (카드 만료, 한도 초과 등). #415 Phase B3.
  static const paywallPurchaseFailedPaymentDeclined =
      '결제가 거절되었어요. 결제 수단을 확인해주세요.';

  /// Pro 구매 실패 — store 내부 에러 (StoreKit/PlayBilling). #415 Phase B3.
  static const paywallPurchaseFailedStore = '스토어 오류가 발생했어요. 잠시 후 다시 시도해주세요.';

  /// Trial 시작 성공.
  static const paywallTrialStarted = '14일 무료 체험이 시작되었어요.';

  /// Trial 시작 실패 — 이미 사용했거나 백엔드 거절.
  static const paywallTrialAlreadyUsed = '체험은 1회만 사용할 수 있어요.';

  /// Trial 시작 실패 — 네트워크/서버 에러.
  static const paywallTrialFailed = '체험을 시작하지 못했어요. 잠시 후 다시 시도해주세요.';

  // ── SubscriptionStatusCard Phase C2 (#415) ───────────────
  // spec/paywall_spec.md §6.2 — 프로필 구독 배지.

  /// Free 배지 라벨.
  static const billingBadgeFree = 'FREE';

  /// Pro 배지 라벨.
  static const billingBadgePro = 'PRO';

  /// Trial 배지 라벨.
  static const billingBadgeTrial = 'TRIAL';

  /// Studio 배지 라벨.
  static const billingBadgeStudio = 'STUDIO';

  /// Lifetime 배지 라벨.
  static const billingBadgeLifetime = 'LIFETIME';

  /// Pro 갱신까지 남은 일수 (D-N).
  static const billingStatusProRenew = 'D-{days} 갱신';

  /// Trial 종료까지 남은 일수.
  static const billingStatusTrialEnds = 'D-{days} 종료';

  /// Free 상태 — 학생 수 표시 ({used}/{limit}명).
  static const billingStatusFreeStudents = '학생 {used}/{limit}명 사용 중';

  /// Pro 상태 — 가격/혜택.
  static const billingStatusProDetail = '₩9,900 / 월 · 학생 무제한';

  /// Studio 상태 — 가격/혜택.
  static const billingStatusStudioDetail = '₩29,900 / 월 · 학원 다중 강사';

  /// Lifetime 상태 — 영구.
  static const billingStatusLifetimeDetail = '영구 사용 · 학생 무제한';

  /// Trial 상태 — 혜택.
  static const billingStatusTrialDetail = '체험 중 · 학생 무제한';

  /// Trial 만료 임박 (D-1 이하) — 추가 안내 한 줄. #415 Phase B1.
  static const billingStatusTrialUrgent = '곧 만료돼요. 지금 갱신하면 끊김 없이 이어집니다.';

  /// Free 사용자용 업그레이드 CTA.
  static const billingFreeUpgradeCta = 'Pro 업그레이드 → ₩9,900/월';

  /// Pro 사용자용 — 플랜 관리 CTA.
  static const billingManagePlanCta = '플랜 관리';

  /// Pro 사용자용 — 영수증 CTA.
  static const billingReceiptsCta = '영수증';

  /// Trial 사용자용 — Pro 전환 CTA.
  static const billingTrialConvertCta = 'Pro 전환';

  /// Expired 상태 라벨.
  static const billingBadgeExpired = 'EXPIRED';

  /// Expired 안내.
  static const billingStatusExpiredDetail =
      '플랜이 만료되었어요. 7일 이내 재결제하지 않으면 Free 로 전환됩니다.';

  // ── FeatureLockedSheet Phase C2 (#415) ───────────────────
  // spec/paywall_spec.md §3.1, §7 — Pro/Studio 전용 기능 차단.

  /// Pro 전용 기능 차단 sheet 제목.
  static const featureLockedProTitle = 'Pro 전용 기능이에요';

  /// Pro 전용 기능 차단 sheet 본문.
  static const featureLockedProSubtitle = 'Pro 로 업그레이드하면 모든 기능을 사용할 수 있어요.';

  /// Studio 전용 기능 차단 sheet 제목.
  static const featureLockedStudioTitle = 'Studio 전용 기능이에요';

  /// Studio 전용 기능 차단 sheet 본문.
  static const featureLockedStudioSubtitle = '학원 다중 강사 기능은 Studio 플랜에서 제공돼요.';

  /// Studio 업그레이드 CTA.
  static const billingStudioUpgradeCta = 'Studio 업그레이드';

  // ── FeatureLockedSheet 진입 기능명 (#415 Phase A1) ─────
  // dashboard analytics 에 가드 적용 시 sheet 본문에 "{featureName} — ..." 로 prefix 노출.

  /// 월간 통계 리포트 진입 차단 — 기능명.
  static const featureLockedMonthlyStats = '월간 통계 리포트';

  // ── 구독 관리/영수증 native store deep-link (#415 Phase A2) ──
  // SubscriptionStatusCard 의 "플랜 관리"/"영수증" 탭 시 Apple App Store / Google Play
  // 구독 관리 페이지로 이동. backend 자체 관리 화면이 준비되기 전까지 native store 가 SSOT.

  /// Apple/Google 구독 관리 페이지 진입 직전 안내.
  static const billingManageStoreOpening = '스토어 구독 관리 페이지를 열고 있어요…';

  /// 구독 관리 deep-link 실패 폴백.
  static const billingManageStoreFailed =
      '스토어 구독 관리 페이지를 열 수 없어요. 설정 → 구독에서 확인해주세요.';

  /// 영수증 deep-link 안내 — store 구독 화면이 영수증을 포함한다.
  static const billingReceiptStoreOpening = '스토어에서 영수증을 확인할 수 있어요. 페이지를 여는 중…';

  // ── LifetimePromoBanner Phase C2 (#415) ──────────────────
  // spec/paywall_spec.md §1, §6.2 — M5 출시 후 90일 한정 얼리어답터.

  /// Lifetime 프로모 배너 eyebrow.
  static const paywallLifetimePromoEyebrow = '얼리어답터 한정';

  /// Lifetime 프로모 배너 제목.
  static const paywallLifetimePromoTitle = '평생 무제한 — 1회 결제';

  /// Lifetime 프로모 배너 본문.
  static const paywallLifetimePromoSubtitle =
      '₩199,000 한 번 결제로 모든 Pro 기능 영구 사용.';

  /// Lifetime 종료까지 남은 일수 (D-N 카운트다운).
  static const paywallLifetimePromoCountdown = 'D-{days} 종료';

  /// Lifetime 구매 CTA.
  static const paywallLifetimeBuyCta = 'Lifetime 구매하기';

  /// Lifetime promo banner 닫기 — Semantics 라벨 (스크린리더 / a11y). #415 Phase B2.
  static const paywallLifetimePromoDismissLabel = '얼리어답터 프로모 배너 닫기';

  /// Lifetime 구매 — store 가용성 실패.
  static const paywallLifetimeStoreUnavailable =
      'Lifetime 결제 스토어에 연결할 수 없어요. 잠시 후 다시 시도해주세요.';

  /// Lifetime 상품 정보 조회 실패.
  static const paywallLifetimeProductNotFound =
      'Lifetime 구매 정보를 찾을 수 없어요. 잠시 후 다시 시도해주세요.';

  /// Lifetime 구매 성공 — 영수증 검증까지 완료.
  static const paywallLifetimePurchaseSuccess = 'Lifetime 플랜이 활성화되었어요.';

  /// Lifetime 구매 — 영수증 검증 보류.
  static const paywallLifetimePurchasePending =
      '구매가 접수되었어요. 검증이 완료되면 자동으로 Lifetime 으로 전환됩니다.';

  /// Lifetime 구매 — 사용자가 store sheet 취소.
  static const paywallLifetimePurchaseCancelled = 'Lifetime 구매를 취소했어요.';

  /// Lifetime 구매 실패 — store/network/검증 에러.
  static const paywallLifetimePurchaseFailed =
      'Lifetime 구매를 완료하지 못했어요. 잠시 후 다시 시도해주세요.';

  // ── 휴가 / Vacation Mode (#431) ─────────────────────────

  /// 휴가 진입 화면 제목 — 선생님이 다중 기간 휴가를 등록.
  static const vacationModeTitle = '휴가';

  /// 휴가 기간 섹션 제목.
  static const vacationPeriodSection = '휴가 기간';

  /// 시작일 라벨.
  static const vacationStartDateLabel = '시작일';

  /// 종료일 라벨.
  static const vacationEndDateLabel = '종료일';

  /// 휴가 사유 (선택) 라벨.
  static const vacationReasonLabel = '사유 (선택)';

  /// 휴가 사유 입력 힌트 — 예시.
  static const vacationReasonHint = '예: 여름방학';

  /// 영향 받는 레슨 미리보기 섹션 제목.
  static const vacationImpactSection = '영향 받는 레슨';

  /// 영향 미리보기 로딩 메시지.
  static const vacationImpactLoading = '영향 받는 레슨을 확인하는 중...';

  /// 영향 미리보기 빈 상태.
  static const vacationImpactEmpty = '해당 기간에 영향 받는 레슨이 없어요.';

  /// 휴가 진입 CTA — 가용성 화면 특수일정 섹션에서 휴가 등록 화면으로 이동.
  static const vacationModeEntry = '휴가';

  /// 휴가 진입 안내 — 이 기간 레슨 처리 방식 고지 (검토 #14).
  static const vacationModeGuide = '이 기간의 레슨은 모두 휴강 처리되고, 선택한 보상 방식이 적용됩니다.';

  /// 휴가 등록 액션 버튼.
  static const vacationRegisterButton = '휴가 등록';

  /// 휴가 등록 성공 스낵바.
  static const vacationRegisterSuccess = '휴가가 등록되었어요.';

  /// 휴가 등록 성공 확인 다이얼로그 제목.
  static const vacationNotifyDialogTitle = '통보 완료';

  /// 휴가 등록 성공 확인 다이얼로그 본문 — 영향 학생 수 포함.
  static String vacationNotifyDialogBody(int studentCount) => studentCount == 0
      ? '해당 기간에 영향 받는 학생이 없어요.'
      : '$studentCount명의 학생에게 휴가 일정이 통보되었어요.';

  /// 휴가 등록 성공 확인 다이얼로그 확인 버튼.
  static const vacationNotifyDialogConfirm = '확인';

  /// 휴가 등록 실패 스낵바.
  static const vacationRegisterFailed = '휴가 등록을 완료하지 못했어요. 잠시 후 다시 시도해주세요.';

  /// 종료일 < 시작일 검증 에러.
  static const vacationDateRangeInvalid = '종료일은 시작일 이후여야 해요.';

  /// 영향 미리보기 카운트 포맷 — "레슨 14건 · 학생 7명".
  static String vacationImpactSummary({
    required int lessonCount,
    required int studentCount,
  }) => '레슨 $lessonCount건 · 학생 $studentCount명';

  /// 영향 미리보기 새로고침 버튼.
  static const vacationImpactRefresh = '확인';

  /// 기간 미선택 안내.
  static const vacationRangeNeeded = '기간을 선택하면 영향 받는 레슨을 확인할 수 있어요.';

  /// 학생별 미리보기 항목 카운트 ("3건").
  static String vacationImpactStudentCount(int count) => '$count건';

  // ── 활성 휴가 카드 + 24h Recovery (H-001 FE Phase 3) ────────────────

  /// 활성 휴가 섹션 제목 (등록된 휴가 목록 표시).
  static const vacationActiveSection = '등록된 휴가';

  /// 활성 휴가 없음 (빈 상태).
  static const vacationActiveEmpty = '등록된 휴가가 없습니다.';

  /// 휴가 취소 버튼 (Recovery).
  static const vacationCancelLabel = '휴가 취소';

  /// 휴가 취소 확인 다이얼로그 제목.
  static const vacationCancelConfirmTitle = '휴가를 취소할까요?';

  /// 휴가 취소 확인 다이얼로그 본문 (24h Recovery 안내).
  static const vacationCancelConfirmBody =
      '등록 후 24시간 이내, 시작 전인 휴가만 취소할 수 있어요. 자동 연장된 수강권 만료일도 원래대로 돌아갑니다.';

  /// 취소 성공 SnackBar.
  static const vacationCancelSuccess = '휴가를 취소했어요.';

  /// 취소 실패 — 일반 (서버 4xx/5xx).
  static const vacationCancelFailed = '휴가를 취소하지 못했어요.';

  /// 취소 실패 — 24h 윈도우 초과 (서버 409).
  static const vacationCancelWindowExpired = '등록 후 24시간이 지나 취소할 수 없어요.';

  /// 취소 실패 — 이미 시작된 휴가 (서버 409).
  static const vacationCancelAlreadyStarted = '이미 시작된 휴가는 취소할 수 없어요.';

  /// 취소 실패 — 이미 취소된 휴가 (서버 400).
  static const vacationCancelAlreadyCancelled = '이미 취소된 휴가예요.';

  /// 활성 휴가 카드 — 기간 표시 helper (예: "8/1 ~ 8/5").
  static String vacationCardDateRange(String start, String end) =>
      '$start ~ $end';

  // ── 휴가 처리 옵션 (H-001 spec §4.1 step 3 / §5) ─────────────────────

  /// 처리 옵션 섹션 제목.
  static const vacationDispositionSection = '어떻게 처리할까요?';

  /// 보강 크레딧 적립 라벨.
  static const vacationDispositionMakeupCreditLabel = '보강 크레딧 적립';

  /// 보강 크레딧 적립 — 권장 표시 (suffix).
  static const vacationDispositionRecommended = '권장';

  /// 보강 크레딧 적립 설명.
  static const vacationDispositionMakeupCreditDescription = '학생이 나중에 보강 예약 가능';

  /// 무료 처리 라벨.
  static const vacationDispositionFreeCancelLabel = '무료 처리';

  /// 무료 처리 설명.
  static const vacationDispositionFreeCancelDescription = '수강권 차감 없이 취소';

  /// 이월 라벨.
  static const vacationDispositionRollForwardLabel = '다음 회차로 이월';

  /// 이월 설명 — 휴가 일수만큼 만료일 자동 연장.
  static const vacationDispositionRollForwardDescription =
      '수강권 만료일이 휴가 일수만큼 자동 연장';

  /// 이월 선택 시 예상 자동 연장 일수 안내 (autoExtendedDays).
  /// 계산은 BE 가 확정하며 FE 는 휴가 일수 기준 예상치만 표시. TODO(remote).
  static String vacationAutoExtendProjection(int days) =>
      '수강권 만료일이 약 $days일 자동 연장됩니다.';

  // ── 학생별 처리 옵션 (spec §4.2) ────────────────────────────────────

  /// 학생별 long-press BottomSheet 제목.
  static const vacationPerStudentSheetTitle = '이 학생만 다르게 처리';

  /// 학생별 long-press BottomSheet 부제 (안내).
  static const vacationPerStudentSheetHint = '꾹 눌러서 학생 한 명의 처리 방식을 바꿀 수 있어요.';

  /// "기본값 사용" 라벨 — override 제거 옵션.
  static const vacationPerStudentUseDefault = '기본값 사용';

  /// override 적용된 카드의 라벨 prefix (예: "다른 처리: 보강 크레딧 적립").
  static String vacationPerStudentOverrideLabel(String dispositionLabel) =>
      '다른 처리: $dispositionLabel';

  // ── 가용시간 화면 휴가 배너 (spec §4 캘린더 시각화) ─────────────────

  /// 가용시간 화면에 노출되는 휴가 구간 배너 제목.
  static const vacationBannerTitle = '등록된 휴가';

  /// 휴가 배너 안내 — 해당 기간 예약 불가.
  static const vacationBannerHint = '이 기간에는 학생 예약이 잡히지 않아요.';

  /// 배너 행: 다중일 휴가 라벨 (예: "8/1 ~ 8/5 휴가").
  static String vacationBannerRangeLabel(String range) => '$range 휴가';

  /// 배너 행: 1일 휴무 라벨 (예: "8/1 휴무").
  static String vacationBannerOneDayLabel(String date) => '$date 휴무';

  /// 배너 행: 휴가 취소 아이콘 버튼의 시맨틱 라벨.
  static const vacationBannerCancelTooltip = '휴가 취소';

  // 다구간 휴가 (#768 ②) — 구간 스택 + 확인 요약.
  /// 현재 편집 중인 기간을 구간으로 추가.
  static const vacationSegmentAddButton = '구간 추가';

  /// 추가한 구간 리스트 섹션 제목.
  static const vacationAddedSegmentsSection = '추가한 휴가 구간';

  /// 구간 삭제 아이콘 툴팁.
  static const vacationSegmentRemoveTooltip = '구간 삭제';

  /// 추가하려는 구간이 기존 구간과 겹칠 때.
  static const vacationSegmentOverlapError = '이미 추가한 기간과 겹쳐요. 다른 날짜를 선택해주세요.';

  /// 추가하려는 구간의 날짜가 유효하지 않을 때.
  static const vacationSegmentInvalidError = '시작일·종료일을 올바르게 선택해주세요.';

  /// 최종 확인 요약 다이얼로그 제목.
  static const vacationSummaryTitle = '이렇게 등록할까요?';

  /// 요약 다이얼로그 등록 버튼.
  static const vacationSummaryConfirm = '등록';

  /// 요약 한 구간 라벨: "7/15 ~ 7/17 · 다음 회차로 이월".
  static String vacationSummarySegmentLabel(String range, String disposition) =>
      '$range · $disposition';

  /// 요약 상단 구간 수 안내.
  static String vacationSummaryCount(int count) => '휴가 구간 $count개';

  // ── 가용시간 — 시간대 삭제/변경 영향 경고 (C3) ──────────────────────

  /// 시간대 삭제 확인 다이얼로그 — 기본 (영향 0건).
  static const weeklyScheduleDeleteConfirmTitle = '이 시간대를 삭제할까요?';

  /// 시간대 삭제 확인 다이얼로그 — 기본 본문 (영향 0건).
  static const weeklyScheduleDeleteConfirmBody =
      '학생이 새로 예약할 수 있는 시간대에서 제외됩니다. 이미 잡힌 예약에는 영향이 없어요.';

  /// 시간대 삭제 확인 다이얼로그 — 영향 받는 예약이 있을 때 본문.
  static String weeklyScheduleDeleteImpactWarning(int count) =>
      '이 시간대를 삭제하면 $count개 예약이 영향을 받습니다. 학생에게 자동 취소 알림이 전송됩니다.';

  /// 시간대 삭제 확인 다이얼로그 — 영향이 있을 때 제목.
  static const weeklyScheduleDeleteImpactTitle = '이 시간대를 삭제하면 예약이 영향을 받아요';

  // ── 가용시간 — 풀 / 간소 화면 흐름 (C5 명문화) ──────────────────────

  /// 풀 화면에서 시간대 행에 노출되는 swipe 안내.
  static const weeklyScheduleSwipeHint = '옆으로 밀어 삭제할 수 있어요.';

  /// 요일에 시간대를 처음 추가하는 행동을 설명하는 라벨 (CTA).
  static const weeklyScheduleAddSlotAction = '시간대 추가';

  /// 시간대 저장/삭제 실패 피드백 (2026-06-12 — silent fail 방지).
  static const weeklyScheduleSaveError = '시간대 저장에 실패했어요. 잠시 후 다시 시도해주세요';

  /// 수업 시간 설정 저장 실패 피드백 (#707 — silent fail 방지).
  static const lessonSettingsSaveError = '수업 시간 설정 저장에 실패했어요. 잠시 후 다시 시도해주세요';

  /// 예외 일정 추가 실패 피드백 (#707 — silent fail 방지).
  static const exceptionSaveError = '예외 일정 저장에 실패했어요. 잠시 후 다시 시도해주세요';

  /// 예외 일정 삭제 실패 피드백 (#707 — silent fail 방지).
  static const exceptionDeleteError = '예외 일정 삭제에 실패했어요. 잠시 후 다시 시도해주세요';

  // ── 보강 크레딧 / Makeup Credit (#432) ──────────────────────────────
  // Spec: docs/specs/subscription/makeup_credit_spec.md

  /// 보강 크레딧 카드/섹션 제목.
  static const makeupCreditTitle = '보강 크레딧';

  /// 보유 크레딧 라벨 (학생 카드).
  static String makeupCreditBalanceLabel(int count) => '보유: $count회';

  /// 가장 빠른 만료 라벨 (D-day 포함).
  static String makeupCreditEarliestExpiry(String date, int dDay) =>
      '가장 빠른 만료: $date(D-$dDay)';

  /// 보유 크레딧 0회 안내.
  static const makeupCreditEmpty = '보유한 보강 크레딧이 없어요.';

  /// 내역 섹션 헤더.
  static String makeupCreditHistoryHeader(int count) => '내역 ($count건)';

  /// 적립 내역 라벨 (예: "8/3 적립 — 선생님 휴가").
  static String makeupCreditAccruedLine(String date, String reason) =>
      '$date 적립 — $reason';

  /// 사용 내역 라벨 (예: "8/20 사용 — 정규 레슨").
  static String makeupCreditUsedLine(String date) => '$date 사용 — 보강 레슨';

  // 적립 사유 라벨 (MakeupCreditReason).
  static const makeupCreditReasonTeacherVacation = '선생님 휴가';
  static const makeupCreditReasonNoShowExempt = '노쇼 면제';
  static const makeupCreditReasonBulkChangeLoss = '일정 일괄 변경';
  static const makeupCreditReasonManualGrant = '선생님 지급';
  static const makeupCreditReasonFifthWeekBonus = '5주차 보너스';

  // 선생님 측 관리.

  /// 선생님 측 학생별 크레딧 관리 섹션 제목.
  static const makeupCreditManageTitle = '보강 크레딧 관리';

  /// 수동 지급 버튼.
  static const makeupCreditGrantButton = '수동 지급';

  /// 수동 지급 확인 다이얼로그 제목.
  static const makeupCreditGrantConfirmTitle = '보강 크레딧을 지급할까요?';

  /// 수동 지급 확인 본문.
  static const makeupCreditGrantConfirmBody = '학생에게 보강 1회 크레딧을 지급해요. (만료 30일)';

  /// 지급 성공 스낵바.
  static const makeupCreditGrantSuccess = '보강 크레딧을 지급했어요.';

  /// 지급 실패 스낵바.
  static const makeupCreditGrantFailed = '보강 크레딧 지급에 실패했어요.';

  /// 회수 버튼.
  static const makeupCreditRevokeButton = '회수';

  /// 회수 성공 스낵바.
  static const makeupCreditRevokeSuccess = '보강 크레딧을 회수했어요.';

  /// 회수 실패 스낵바 (이미 사용된 크레딧 등).
  static const makeupCreditRevokeFailed = '보강 크레딧을 회수하지 못했어요.';

  /// 사용 완료 배지.
  static const makeupCreditUsedBadge = '사용됨';

  /// 만료 배지.
  static const makeupCreditExpiredBadge = '만료';

  // 예약 시 크레딧 사용 선택 (spec §5.1).

  /// "정규 수강권 사용" 옵션 라벨.
  static const makeupCreditUseRegularLabel = '정규 수강권 사용';

  /// 정규 잔여 회차 라벨.
  static String makeupCreditRegularRemaining(int remaining, int total) =>
      '남은 회차: $remaining/$total회';

  /// "보강 크레딧 사용" 옵션 라벨.
  static const makeupCreditUseCreditLabel = '보강 크레딧 사용';

  /// 보유 크레딧 + 만료일 라벨.
  static String makeupCreditUseCreditSubtitle(int count, String expiry) =>
      '보유 크레딧: $count회 (만료: $expiry)';

  // ── First Availability Quest (#422) ─────────────────────────────────
  // Spec: docs/specs/onboarding/teacher_first_availability_setup.md

  /// 인터스티셜 모달 제목 — 가용시간 0개 상태로 홈 진입 시 강제 노출.
  static const firstAvailabilityInterstitialTitle = '레슨 가능 시간을 먼저 설정해주세요';

  /// 인터스티셜 모달 본문.
  static const firstAvailabilityInterstitialDescription =
      '학생이 예약할 수 있는 시간이 필요해요.';

  /// 인터스티셜 CTA — 스킵 불가.
  static const firstAvailabilityInterstitialAction = '지금 설정하기';

  /// 간소 가용시간 화면 제목.
  static const firstAvailabilitySetupTitle = '첫 가용시간 설정';

  /// 요일 선택 섹션 헤더.
  static const firstAvailabilityDaysLabel = '레슨 가능한 요일';

  /// 시간 선택 섹션 헤더.
  static const firstAvailabilityHoursLabel = '레슨 가능한 시간';

  /// 시작 시각 라벨.
  static const firstAvailabilityStartTimeLabel = '시작';

  /// 종료 시각 라벨.
  static const firstAvailabilityEndTimeLabel = '종료';

  /// 기본값 안내 헤더.
  static const firstAvailabilityDefaultsHeader = '기본값 (나중에 변경 가능)';

  /// 레슨 1회 시간 기본값 — 50분 (스펙 §2 통일).
  static const firstAvailabilityLessonDurationDefault = '레슨 1회 시간: 50분';

  /// 쉬는 시간 기본값.
  static const firstAvailabilityBreakTimeDefault = '쉬는 시간: 10분';

  /// 시작 간격 기본값.
  static const firstAvailabilityStartIntervalDefault = '시작 간격: 60분';

  /// 적용 버튼.
  static const firstAvailabilityApplyAction = '적용하기';

  /// 풀 설정 이관 버튼.
  static const firstAvailabilityAdvancedAction = '더 자세히 설정';

  /// 요일 미선택 검증 메시지.
  static const firstAvailabilityValidationDayMissing = '요일을 1개 이상 선택해주세요.';

  /// 시작/종료 시각 검증 메시지.
  static const firstAvailabilityValidationTimeInvalid =
      '종료 시각은 시작 시각보다 최소 1시간 이후여야 해요.';

  /// 저장 실패 메시지.
  static const firstAvailabilitySaveFailed = '가용시간을 저장하지 못했어요. 잠시 후 다시 시도해주세요.';

  /// 셀레브레이션 시트 제목.
  static const firstAvailabilityCelebrationTitle = '첫 가용시간 등록 완료!';

  /// 셀레브레이션 본문.
  static const firstAvailabilityCelebrationDescription =
      '이제 학생이 이 시간에 레슨을 예약할 수 있어요.';

  /// 셀레브레이션 다음 단계 안내.
  static const firstAvailabilityCelebrationNext = '다음 단계: 첫 학생 초대하기';

  /// 셀레브레이션 닫기 버튼.
  static const firstAvailabilityCelebrationAction = '다음 퀘스트으로';

  /// 잠금 안내 — quest_board 에서 가용시간 0개일 때 다른 퀘스트 비활성 상태.
  static const firstAvailabilityLockedHint = '가용시간 설정 후 진행 가능';

  // 요일 라벨 (월~일) — 간소 화면 chip 표시용.
  static const firstAvailabilityDayMon = '월';
  static const firstAvailabilityDayTue = '화';
  static const firstAvailabilityDayWed = '수';
  static const firstAvailabilityDayThu = '목';
  static const firstAvailabilityDayFri = '금';
  static const firstAvailabilityDaySat = '토';
  static const firstAvailabilityDaySun = '일';

  // -------------------------------------------------------------------------
  // 전화인증 게이트 (#430)
  // -------------------------------------------------------------------------

  /// 수강권 발급 직전 전화인증 게이트 다이얼로그 제목.
  static const phoneVerificationGateTitle = '전화인증이 필요해요';

  /// 게이트 본문 — 학부모 신뢰 보호 사유 설명.
  static const phoneVerificationGateBody =
      '첫 수강권을 발급하려면 전화인증이 필요해요. 학부모님께 안전한 선생님임을 알리기 위해 전화번호를 한 번만 확인할게요.';

  /// 보상 안내 — 인증 완료 시 인증 선생님 배지 부여.
  static const phoneVerificationGateRewardLine =
      '인증 완료 시 "인증 선생님 배지"가 프로필에 표시돼요.';

  /// 게이트 CTA — 즉시 인증.
  static const phoneVerificationGateCtaVerifyNow = '지금 인증하기';

  /// 게이트 CTA — 나중에 (다이얼로그만 닫기).
  static const phoneVerificationGateCtaLater = '나중에 하기';

  // ── Lesson Attendance Action (#473 미확인 레슨 액션) ──────────
  /// 액션 카드 제목 — 미확인 레슨 처리 안내.
  static const attendanceActionTitle = '레슨 처리가 필요해요';

  /// 액션 카드 설명 — 출석 확인 또는 휴강 선택 안내.
  static const attendanceActionDescription = '종료된 레슨입니다. 출석 확인 또는 휴강으로 처리해주세요.';

  /// 출석 확인 액션 라벨 (= 레슨 완료, 1회 차감).
  static const attendanceConfirmAction = '출석 확인';

  /// 출석 확인 보조 라벨 — 차감 안내.
  static const attendanceConfirmSubLabel = '수강권 1회 차감';

  /// 휴강 액션 라벨 (차감 없음).
  static const attendanceDayOffAction = '휴강';

  /// 휴강 보조 라벨 — 차감 없음 안내.
  static const attendanceDayOffSubLabel = '차감 없음';

  /// 출석 확인 다이얼로그 제목.
  static const attendanceConfirmDialogTitle = '출석 확인';

  /// 출석 확인 다이얼로그 본문 — 1회 차감 고지.
  static const attendanceConfirmDialogMessage =
      '이 레슨을 출석 확인 처리하시겠습니까?\n수강권 1회가 차감됩니다.';

  /// 휴강 다이얼로그 제목.
  static const attendanceDayOffDialogTitle = '휴강 처리';

  /// 휴강 다이얼로그 본문 — 차감 없음 고지.
  static const attendanceDayOffDialogMessage =
      '이 레슨을 휴강 처리하시겠습니까?\n수강권이 차감되지 않습니다.';

  /// 출석 확인 완료 스낵바.
  static const attendanceConfirmedSnack = '출석 확인 처리되었습니다';

  /// 휴강 처리 완료 스낵바.
  static const attendanceDayOffSnack = '휴강 처리되었습니다';

  /// 처리 실패 스낵바.
  static const attendanceActionFailed = '처리에 실패했습니다. 다시 시도해주세요.';

  // 다중선택 일괄 처리 (#768 ①).
  /// 일괄 완료 확인 다이얼로그 제목.
  static const batchCompleteDialogTitle = '선택한 레슨 완료';

  /// 일괄 완료 확인 다이얼로그 본문 (차감 고지).
  static String batchCompleteDialogMessage(int count) =>
      '$count건을 출석 확인해요. 수강권이 있는 레슨은 각 1회 차감돼요.';

  /// 일괄 휴강 확인 다이얼로그 제목.
  static const batchDayOffDialogTitle = '선택한 레슨 휴강';

  /// 일괄 휴강 확인 다이얼로그 본문 (차감 없음).
  static String batchDayOffDialogMessage(int count) =>
      '$count건을 휴강 처리해요. 수강권 차감은 없어요.';

  /// 일괄 완료 완료 스낵바.
  static String batchCompleteDoneSnack(int count) => '$count건을 완료했어요.';

  /// 일괄 휴강 완료 스낵바.
  static String batchDayOffDoneSnack(int count) => '$count건을 휴강 처리했어요.';

  /// 일괄 처리 부분 실패 스낵바.
  static String batchPartialSnack(int success, int failed) =>
      '$success건 처리, $failed건 실패';

  /// 선택 모드 — 선택 개수 라벨.
  static String selectionCountLabel(int count) => '$count개 선택';

  /// 선택 모드 — 전체 선택.
  static const selectAllAction = '전체 선택';

  /// 선택 모드 — 액션바 완료 버튼 (N건 완료).
  static String batchSelectionComplete(int count) => '$count건 완료';

  /// 선택 모드 — 액션바 휴강 버튼 (N건 휴강).
  static String batchSelectionDayOff(int count) => '$count건 휴강';

  /// 선택 모드 종료(선택 해제) 툴팁.
  static const selectionExitTooltip = '선택 해제';

  /// 사전 안내 배너 — 24시간 후 자동 출석 완료 + 1회 차감 고지.
  static const attendanceAutoCompleteNotice =
      '미확인 상태입니다. 종료 후 24시간이 지나면 자동으로 출석 완료 처리되며 수강권 1회가 차감됩니다.';

  /// 차감 결과 — 1회 차감됨 (completed).
  static const attendanceDeductedResult = '수강권 1회 차감됨';

  /// 차감 결과 — 차감 없음 (휴강/취소).
  static const attendanceNoDeductionResult = '차감 없음';

  // ============================================================
  // G15 학원장 일괄 휴강 (BulkClosure) — 강사 시점
  // 정책 SSOT: docs/specs/web/academy/owner_bulk_closure_spec.md §5
  // ============================================================

  /// 휴강 상세 화면 AppBar.
  static const bulkClosureDetailTitle = '학원 휴강 안내';
  static const bulkClosureNotFound = '휴강 정보를 찾을 수 없습니다';

  /// 학원 사유 / 강사 페이 보장 안내 (§5.2).
  static const bulkClosureAcademyReasonNote =
      '학원 사유 — 강사 페이 영향 없음 (정산은 학원에서 별도 처리)';

  /// 학생 변경권 미차감 안내 (§4.1).
  static const bulkClosureNoCreditNote = '학생 변경권은 차감되지 않습니다';

  /// 영향 레슨 카드 헤더.
  static String bulkClosureAffectedHeader(int count) => '내 영향 레슨 ($count건)';

  /// 상태 라벨 — proposed (의견 윈도우 진행).
  static const bulkClosureStatusProposed = '의견 입력 가능';

  /// 상태 라벨 — applied (보강 입력 대기).
  static const bulkClosureStatusApplied = '보강 일정 입력 대기';

  /// 상태 라벨 — makeupCompleted (강사 입력 완료).
  static const bulkClosureStatusMakeupCompleted = '보강 일정 완료';

  /// 상태 라벨 — cancelled.
  static const bulkClosureStatusCancelled = '취소됨';

  /// 의견 윈도우 카운트다운.
  static String bulkClosureWindowRemaining(int minutes) =>
      '유예 종료까지 $minutes분 남음';

  /// 의견 윈도우 만료 안내.
  static const bulkClosureWindowExpired = '의견 윈도우 종료';

  /// 의견 입력 섹션 제목.
  static const bulkClosureOpinionTitle = '의견 입력 (학원장에게 전달)';

  /// 의견 입력 placeholder.
  static const bulkClosureOpinionHint = '예: 발표회 리허설 일정과 겹칩니다.';

  /// 의견 보내기 버튼.
  static const bulkClosureOpinionSubmit = '의견 보내기';

  /// 의견 전송 성공 스낵바.
  static const bulkClosureOpinionSent = '의견이 전달되었습니다';

  /// 의견 전송 실패 스낵바.
  static const bulkClosureOpinionFailed = '의견 전송에 실패했습니다. 다시 시도해주세요.';

  /// 보강 입력 화면 진입 버튼.
  static const bulkClosureMakeupInputCta = '보강 일정 입력하기';

  /// 자동 적용 안내.
  static const bulkClosureAutoApplyHint =
      '1시간 후 자동 적용됩니다. 학원장이 즉시 적용할 수도 있습니다.';

  // ============================================================
  // App Rating Prompt — 만족도 → 스토어 평가 / 피드백
  // 정책 SSOT: docs/specs/settings/app_rating_prompt_spec.md §8–9
  // ============================================================

  /// 만족도 다이얼로그 제목.
  static const ratingPromptTitle = '레슨아자, 어떠세요?';

  /// 긍정 응답 (스토어 평가 요청).
  static const ratingPromptYes = '네, 도움돼요!';

  /// 부정 응답 (피드백 다이얼로그로 전환).
  static const ratingPromptNo = '아쉬워요';

  /// 피드백 다이얼로그 제목.
  static const ratingFeedbackTitle = '의견을 들려주세요';

  /// 피드백 전송 버튼.
  static const ratingFeedbackSend = '의견 보내기';

  /// 피드백 미입력/나중에 버튼.
  static const ratingFeedbackLater = '나중에';

  // ============================================================
  // §3.5 YouTube 구간 반복 연습 — practice/youtube_loop_practice_spec.md
  // ============================================================

  /// 진입점 시각 affordance — 영상 있는 섹션 라벨 ("영상 구간 0:42-1:15")
  static const youtubeLoopSectionLabel = '영상 구간';

  /// 진입점 카드 부제 — 영상으로 따라 연습.
  static const youtubeLoopAffordanceSubtitle = '영상 따라 연습';

  /// 섹션 상세 영상 영역 헤딩.
  static const youtubeLoopVideoHeading = '영상 따라 연습';

  /// 반복 토글 ON.
  static const youtubeLoopRepeatOn = '반복 ON';

  /// 반복 토글 OFF.
  static const youtubeLoopRepeatOff = '반복 OFF';

  /// 속도 선택 라벨.
  static const youtubeLoopSpeedLabel = '속도';

  /// 리셋 버튼 (선생님 디폴트 복원).
  static const youtubeLoopResetSegment = '리셋';

  /// 목표 횟수 라벨 ("반복: 3 / 5").
  static const youtubeLoopRepeatCountLabel = '반복';

  /// 카운트인 토글 라벨.
  static const youtubeLoopCountInToggle = '카운트인';

  /// 카운트인 소리 토글 라벨.
  static const youtubeLoopCountInSoundToggle = '카운트인 소리';

  /// 카운트인 ON 설명 ("3-2-1 후 재생").
  static const youtubeLoopCountInDescription = '3-2-1 후 재생';

  /// 연습 시작 버튼 — 섹션 상세 하단.
  static const youtubeLoopStartPractice = '연습 시작';

  /// 영상 비공개/삭제 빈 상태.
  static const youtubeLoopVideoUnavailable = '영상을 불러올 수 없습니다';

  /// 빈 상태 보조 액션 — 선생님에게 알리기.
  static const youtubeLoopNotifyTeacher = '선생님에게 알리기';

  /// 네트워크 오류 재시도.
  static const youtubeLoopRetry = '다시 시도';

  /// 외부 YouTube 앱 fallback.
  static const youtubeLoopOpenExternal = 'YouTube에서 열기';

  /// 미니 플레이어 확장 툴팁.
  static const youtubeLoopExpandFullscreen = '전체 화면';

  /// 풀스크린 닫기 툴팁.
  static const youtubeLoopExitFullscreen = '닫기';

  /// 목표 도달 알림.
  static const youtubeLoopTargetReached = '목표 횟수 달성! 잘했어요.';

  /// 마커 드래그 안내 (semantic).
  static const youtubeLoopMarkerSemanticStart = '시작 마커';

  /// 마커 드래그 안내 (semantic).
  static const youtubeLoopMarkerSemanticEnd = '끝 마커';

  /// 영상 미니 플레이어 진입점 (녹음 화면 상단).
  static const youtubeLoopMiniPlayerTitle = '영상 따라 연습';

  /// 카운트인 시작 안내 ("3-2-1 후 시작합니다").
  static const youtubeLoopCountInStarting = '3-2-1 후 시작합니다';

  // -- §3.5 #509 광고 검출 알림 --

  /// 광고 감지 시 표시되는 제목.
  static const youtubeAdDetected = '광고가 재생 중이에요';

  /// 광고 끝났을 때 다시 재생을 시작하는 버튼.
  static const youtubeAdResume = '재개';

  /// 광고 알림 보조 설명 — 반복 카운터 보호 안내.
  static const youtubeAdHint = '광고 중에는 반복 횟수가 올라가지 않아요';

  /// 광고 스킵 가능 시 안내 (best effort, 정확도 보장 X).
  static const youtubeAdSkippable = '광고가 끝나면 [재개]를 눌러 주세요';

  // -- §3.5 후속 (#510): 영상 구간별 손글씨 메모 --

  /// 메모 작성 모달 입력 힌트.
  static const loopMemoAddHint = '여기에 메모를 적어주세요';

  /// 메모 추가 버튼 / 액션 라벨.
  static const loopMemoAdd = '메모 추가';

  /// 메모 수정 액션 라벨.
  static const loopMemoEdit = '수정';

  /// 메모 삭제 액션 라벨.
  static const loopMemoDelete = '삭제';

  /// 메모 삭제 확인 다이얼로그.
  static const loopMemoDeleteConfirm = '이 메모를 삭제할까요?';

  /// 메모 저장 액션 라벨.
  static const loopMemoSave = '저장';

  /// 메모 취소 액션 라벨.
  static const loopMemoCancel = '취소';

  /// 메모 입력 길이 안내 (100자 제한).
  static const loopMemoMaxLength = '최대 100자';

  /// 메모 빈 상태 안내.
  static const loopMemoEmpty = '메모가 없습니다';

  /// 메모 마커 semantic.
  static const loopMemoMarkerSemantic = '메모 마커';

  // -- AudioMixMode 표시 라벨 (audio_mix_visuals.dart 에서 사용) --

  static const audioMixModeVideoOnlyTitle = '영상만';
  static const audioMixModeVideoOnlyDescription = '녹음 없이 영상만 봅니다.';
  static const audioMixModeRecordOnlyTitle = '녹음만';
  static const audioMixModeRecordOnlyDescription = '영상은 일시정지, 녹음만 진행합니다.';
  static const audioMixModeMixedTitle = '영상 + 녹음';
  static const audioMixModeMixedDescription = '영상과 녹음을 함께 진행합니다 (혼합 녹음).';
  static const audioMixModeVideoMutedTitle = '영상 음소거 + 녹음';
  static const audioMixModeVideoMutedDescription = '영상은 시각만, 소리는 끄고 녹음합니다.';
  static const audioMixModeHeadphoneOnlyTitle = '헤드폰 + 녹음 (권장)';
  static const audioMixModeHeadphoneOnlyDescription =
      '헤드폰으로 영상 소리를 듣고 마이크로 녹음합니다.';
  static const audioMixModeMetronomeMixedTitle = '영상 + 메트로놈 + 녹음';
  static const audioMixModeMetronomeMixedDescription =
      '세 가지가 동시에 진행됩니다. 헤드폰 사용을 권장합니다.';

  // -- AudioMixGuideDialog --

  static const audioMixGuideTitle = '녹음 모드 선택';
  static const audioMixGuideMessageNoHeadphone =
      '헤드폰을 권장합니다. 메트로놈/영상 소리가 녹음에 섞일 수 있어요.';
  static const audioMixGuideMessageWithHeadphone =
      '헤드폰이 연결되어 있어요. 안전하게 함께 녹음할 수 있어요.';
  static const audioMixGuideContinueAnyway = '그대로 진행';
  static const audioMixGuideMuteVideo = '영상 음소거';
  static const audioMixGuideHeadphonePrompt = '헤드폰 연결 안내';

  // -- 진입점 카운터 라벨 --

  static const youtubeLoopCounterOf = '/';

  // -- 풀스크린 토글 --

  static const youtubeLoopMiniPlayerOpen = '영상 열기';

  // -- §3.5 후속 (#511): 멀티 마커 북마크 N구간 --

  /// 북마크 추가 액션 라벨 — 현재 A-B 구간 저장.
  static const bookmarkAdd = '북마크 추가';

  /// 북마크 관리 버튼 (목록/추가/삭제 시트 열기).
  static const bookmarkManage = '북마크 관리';

  /// 북마크 선택 드롭다운 placeholder.
  static const bookmarkSelect = '구간 선택';

  /// 북마크 이름 입력 라벨/placeholder.
  static const bookmarkName = '이름';

  /// 북마크 삭제 액션 라벨.
  static const bookmarkDelete = '삭제';

  /// 북마크 삭제 확인 다이얼로그.
  static const bookmarkDeleteConfirm = '이 북마크를 삭제할까요?';

  /// 북마크 저장 액션 라벨.
  static const bookmarkSave = '저장';

  /// 북마크 취소 액션 라벨.
  static const bookmarkCancel = '취소';

  /// 북마크 5개 제한 도달 메시지 (UI 인지 부하 보호).
  static const bookmarkLimitReached = '북마크는 최대 5개까지 만들 수 있어요';

  /// 마이그레이션으로 생성된 기본 북마크 이름.
  static const bookmarkDefault = '기본';

  /// 북마크 빈 상태 안내 (관리 시트 첫 진입).
  static const bookmarkEmpty = '아직 북마크가 없어요. 구간을 정하고 추가해 보세요.';

  /// 타임라인 북마크 마커 semantic.
  static const bookmarkMarkerSemantic = '북마크 마커';

  // -- §3.5 후속 (#512): 선생님 측 학생별 반복 통계 --

  /// 선생님 통계 화면 제목.
  static const teacherStatsTitle = '학생별 연습 진척도';

  /// 1주 토글.
  static const teacherStatsWeekly = '1주';

  /// 1개월 토글.
  static const teacherStatsMonthly = '1개월';

  /// 빈 상태 — 영상 반복 기록이 없을 때.
  static const teacherStatsEmpty = '아직 반복 연습 기록이 없어요';

  /// 학생 단위 빈 상태 (드릴다운 화면).
  static const teacherStatsStudentEmpty = '이 기간 동안 영상 반복 기록이 없어요';

  /// 총 반복 횟수 라벨 (학생 카드/드릴다운 헤더).
  static const teacherStatsTotalRepeats = '총 반복';

  /// 어려운 구간 안내 — 히트맵 섹션 헤더.
  static const teacherStatsHardestSections = '어려운 구간 (반복이 많을수록 진해져요)';

  /// 차트 헤더 — 구간별 반복 횟수.
  static const teacherStatsChartTitle = '구간별 반복 횟수';

  /// 마지막 연습 시각 prefix (학생 카드).
  static const teacherStatsLastPlayed = '마지막 연습';

  /// 동기화 진행 중 안내 (백그라운드 배치).
  static const teacherStatsSyncing = '동기화 중...';

  /// 진입점 카드 제목 (대시보드 위젯).
  static const teacherStatsEntryTitle = '학생별 연습 진척도';

  /// 진입점 카드 부제 (대시보드 위젯).
  static const teacherStatsEntrySubtitle = '영상 구간 반복 통계를 확인하세요';

  /// 학생 선택 라벨 (드릴다운 화면 헤더).
  static const teacherStatsSelectStudent = '학생 선택';

  /// 단위 — 반복 횟수.
  static const teacherStatsRepeatsUnit = '회';

  // ── Profile 5묶음 카테고리 (W2 Task 2.3) ──────────────────────────
  // spec §11.1 카테고리 카드 라벨 규칙
  // 사용처: features/profile/presentation/extensions/category_status_visuals.dart

  /// 설정완료 (Complete 상태 라벨).
  static const categoryStatusComplete = '설정완료';

  /// 미설정 (Empty 상태 라벨).
  static const categoryStatusEmpty = '미설정';

  /// 기본값 (Neutral 상태 라벨 — 정책·알림 등 선택적 설정).
  static const categoryStatusNeutralDefault = '기본값';

  /// 쉬는시간 미설정 (운영시간 묶음 partial hint).
  static const categoryHintBreakTimeMissing = '쉬는시간 미설정';

  /// 계좌 미설정 (수강권·정산 묶음 partial hint).
  static const categoryHintBankAccountMissing = '계좌 미설정';

  /// 가격표 미설정 (수강권·정산 묶음 partial hint).
  static const categoryHintPriceTableMissing = '가격표 미설정';

  /// N/M 항목 (Partial 상태 — 부분 입력 라벨).
  static String categoryStatusPartialNOfM(int filled, int total) =>
      '$filled/$total 항목';

  /// NEW (W6 신규 메뉴 배지).
  static const categoryNewBadge = 'NEW';

  // ── Profile 5묶음 카테고리 라벨 (W2 Task 2.4) ─────────────────────
  // spec §3 (IA) + §7.2 (메인 홈) + §11.1 (카드 라벨 규칙)
  // 사용처: features/profile/presentation/screens/profile_tab.dart

  /// 🕐 운영시간 묶음 카드 제목.
  static const categoryOperatingHours = '운영시간';

  /// 🎓 수업방식 묶음 카드 제목.
  static const categoryLessonStyle = '레슨·예약 규칙';

  /// 💰 수강권·정산 묶음 카드 제목.
  static const categorySubscriptionBilling = '수강권·정산';

  /// 👤 내 프로필 묶음 카드 제목.
  static const categoryMyProfile = '내 프로필';

  /// ⚙️ 알림·소식·지원 묶음 카드 제목.
  static const categoryPolicyNotifications = '알림·소식·지원';

  /// 메인 홈 5묶음 메뉴 영역 섹션 헤더.
  static const categorySectionTitle = '설정';

  /// 💰 수강권·정산 BottomSheet 제목.
  static const categorySheetSubscriptionBillingTitle = '수강권·정산';

  /// 👤 내 프로필 BottomSheet 제목.
  static const categorySheetMyProfileTitle = '내 프로필';

  /// ⚙️ 알림·소식·지원 BottomSheet 제목.
  static const categorySheetPolicyNotificationsTitle = '알림·소식·지원';

  /// #805 알림·소식·지원 시트 섹션 헤더 — 템플릿(피드백/연습팁).
  static const categorySheetSectionTemplates = '템플릿';

  /// #805 알림·소식·지원 시트 섹션 헤더 — 알림·소식(알림/녹음/팔로잉/소식/공지).
  static const categorySheetSectionNotificationsNews = '알림·소식';

  /// #805 알림·소식·지원 시트 섹션 헤더 — 지원·계정(가이드/도움말/앱정보/약관/개인정보/로그아웃).
  static const categorySheetSectionSupportAccount = '지원·계정';

  /// "가이드 다시 보기" 메뉴 (알림·소식·지원 묶음 — W5 졸업 후 활성).
  ///
  /// UX 카피 원칙 (2026-06-12): 내부 용어 (퀘스트 졸업/5묶음) 대신 사용자
  /// 가치 언어. "완료한 설정 가이드" = 사용자가 이해하는 대상.
  static const categoryGuideReplayLabel = '가이드 다시 보기';
  static const categoryGuideReplaySubtitle = '완료한 설정 가이드를 언제든 다시 확인할 수 있어요';

  /// "가이드 다시 보기" 화면 — Step 2.5 카테고리 미리보기 재실행 버튼 (W5 Task 5.6).
  static const guideReshowCategoryPreviewButton = '설정 안내 다시 보기';

  // ── LessonStyleSettingsScreen (W3 Task 3.2) ─────────────────────
  // spec §6.2 — 수업방식 묶음 (3 항목: 레슨 1회 시간 + 사전예약 + 학생 안내)
  // 사용처: features/profile/presentation/screens/lesson_style_settings_screen.dart

  /// AppBar 제목 (5묶음 카테고리 카드 라벨과 동일).
  static const lessonStyleScreenTitle = '레슨·예약 규칙';

  /// 레슨 1회 시간 섹션 헤더.
  static const lessonStyleDurationSection = '레슨 1회 시간';

  /// 레슨 1회 시간 섹션 보조 설명 (한국 음악 레슨 표준 50분 컨벤션 안내).
  static const lessonStyleDurationHint = '한국 음악 레슨 표준은 50분입니다';

  /// 최소 사전 예약 시간 섹션 헤더.
  static const lessonStyleBookingSection = '최소 사전 예약 시간';

  /// 최소 사전 예약 시간 섹션 보조 설명.
  static const lessonStyleBookingHint = '학생이 이 시간 이전에는 예약할 수 없습니다';

  /// 학생 안내 메시지 섹션 헤더.
  static const lessonStyleGuidanceSection = '학생 안내 메시지';

  /// 학생 안내 메시지 섹션 보조 설명 (빈 입력 → 기본 메시지 fallback 안내).
  static const lessonStyleGuidanceHint =
      '예약 시 학생에게 보내는 안내입니다. 비우면 기본 메시지가 사용됩니다';

  // ── PriceTableScreen (W3 Task 3.3) ───────────────────────────────
  // spec §6.3 — 악기·레벨별 가격표 (LessonTimeSettingsScreen §6 에서 분리).
  // 사용처: features/profile/presentation/screens/price_table_screen.dart

  /// AppBar 제목.
  static const priceTableScreenTitle = '가격표';

  /// 섹션 헤더 (수강권·정산 BottomSheet ListTile 라벨과 동일).
  static const priceTableSection = '레슨 가격표';

  /// 섹션 보조 설명 (가격 입력 안내).
  static const priceTableDescription = '악기별 레벨에 따른 1회 레슨 가격을 설정하세요.';

  /// 악기 미등록 시 empty 안내 (선등록 유도).
  static const priceTableEmptyInstruments = '악기를 먼저 설정하면 가격표를 입력할 수 있습니다.';

  /// 가격 입력 다이얼로그 필드 라벨.
  static const priceTableDialogFieldLabel = '1회 레슨 가격 (원)';

  /// 가격 입력 다이얼로그 제목 — "$instrument $levelLabel 가격".
  static String priceTableDialogTitle(String instrument, String levelLabel) =>
      '$instrument $levelLabel 가격';

  /// BottomSheet 내 가격표 진입 ListTile 부제목.
  static const priceTableMenuSubtitle = '악기별 레벨에 따른 1회 레슨 가격';

  // ── OnboardingCategoryPreviewScreen (W4 Task 4.2) ────────────────
  // spec §9.2 — Step 2.5 5묶음 카테고리 미리보기 1회 화면.
  // 사용처: features/onboarding/presentation/screens/onboarding_category_preview_screen.dart
  //
  // UX 카피 원칙 (2026-06-12): "5가지 묶음/퀘스트" 같은 내부 설계 용어 대신
  // 사용자 가치 언어 ("레슨 운영 설정", "차근차근 안내"). 같은 화면이 두
  // 청중에게 노출되므로 신규/기존 문구 분리 — 기존 사용자(W6 마이그레이션
  // overlay)는 migrationCategoryPreview* 사용.

  /// 화면 상단 환영 타이틀 (신규 가입 Step 2.5).
  static const onboardingCategoryPreviewTitle = '환영합니다! 레슨 운영 설정을 한눈에 정리했어요';

  /// 카테고리 그리드 아래 보조 안내 (신규 가입 Step 2.5).
  static const onboardingCategoryPreviewSubtitle =
      '지금 다 하지 않아도 괜찮아요. 하나씩 차근차근 안내해드릴게요';

  /// 화면 상단 타이틀 (기존 사용자 — W6 마이그레이션 overlay 변경 공지).
  static const migrationCategoryPreviewTitle = '설정 메뉴가 새로워졌어요';

  /// 보조 안내 (기존 사용자 — 기능 보존 안심 메시지).
  static const migrationCategoryPreviewSubtitle =
      '자주 쓰는 설정을 다섯 가지로 정리했어요. 쓰시던 기능은 모두 그대로예요';

  /// [시작하기] CTA — markShown() + 메인 진입.
  static const onboardingCategoryPreviewStart = '시작하기';

  /// [건너뛰기] CTA — markShown() + 메인 진입 (1회 노출 정책 동일).
  static const onboardingCategoryPreviewSkip = '건너뛰기';

  // ── NextMissionSpotlight (W4 Task 4.4) ───────────────────────────
  // spec §9.1 Step 3 — 가입 후 메인 첫 진입 1회 spotlight.
  // 사용처: features/home/presentation/widgets/next_mission_spotlight.dart

  /// 카드 타이틀.
  static const nextMissionSpotlightTitle = '여기부터 시작하시면 끝나요';

  /// 보조 안내.
  static const nextMissionSpotlightHint = '다음 미션 카드를 따라가면 설정이 완료됩니다';

  /// [시작] CTA — markShown() + 미션 화면 push.
  static const nextMissionSpotlightStart = '시작';

  /// [나중에] CTA — markShown() + spotlight 종료만.
  static const nextMissionSpotlightLater = '나중에';

  // ── Proposal Draft (#695) ──────────────────────────────────────────────────
  // 사용처: features/subscription/presentation/widgets/proposal_draft_banner.dart
  //        features/auth/presentation/widgets/phone_verification_gate_modal.dart

  /// 복구 배너 본문 (spec §4.5).
  static const proposalDraftBannerTitle = '작성 중이던 제안이 있어요';

  /// 복구 배너 액션 CTA (spec §4.5).
  static const proposalDraftBannerResume = '이어서 발급하기';

  /// 드래프트 삭제 확인 다이얼로그 제목.
  static const proposalDraftDiscardTitle = '작성 중이던 제안을 삭제할까요?';

  /// 드래프트 삭제 확인 다이얼로그 본문.
  static const proposalDraftDiscardBody = '삭제하면 되돌릴 수 없어요.';

  /// 드래프트 삭제 확인 버튼.
  static const proposalDraftDiscardConfirm = '삭제';

  /// 드래프트 삭제 취소 버튼.
  static const proposalDraftDiscardCancel = '취소';

  // ── Duplicate Proposal Guard (#696) ────────────────────────────────────────
  // 사용처: features/subscription/presentation/screens/issue_subscription_actions.dart

  /// 중복 제안 다이얼로그 제목 (spec §3.1.5).
  static const duplicateProposalDialogTitle = '대기 중인 제안이 있어요';

  /// 중복 제안 다이얼로그 본문 포맷.
  static String duplicateProposalDialogBody(String studentName) =>
      '$studentName 님에게 아직 확정되지 않은 제안이 있어요. '
      '기존 제안을 취소하고 새로 보내거나, 기존 제안을 확인하세요.';

  /// [기존 제안 보기] 버튼.
  static const duplicateProposalViewExisting = '기존 제안 보기';

  /// [기존 제안 취소 후 재제안] 버튼.
  static const duplicateProposalCancelAndResend = '기존 제안 취소 후 재제안';

  // ── Phone Verification (#709) ──────────────────────────────────────────────
  // 사용처: features/onboarding/presentation/screens/phone_verification_screen.dart
  // 서버측 SMS OTP 검증 실패 사유별 메시지 (쿨다운/시도초과/만료 구분).

  /// 쿨다운 중 재요청 — 남은 초 포함.
  static String phoneOtpCooldownFormat(int seconds) =>
      '인증번호를 이미 발송했어요. $seconds초 후 다시 시도해주세요.';

  /// 쿨다운 중 재요청 — 남은 초 정보가 없을 때.
  static const phoneOtpCooldown = '인증번호를 이미 발송했어요. 잠시 후 다시 시도해주세요.';

  /// 번호당 일일 발송 한도(5회) 초과.
  static const phoneOtpDailyLimit = '오늘 인증 시도 횟수를 초과했어요. 내일 다시 시도해주세요.';

  /// 인증번호 TTL(3분) 만료.
  static const phoneOtpExpired = '인증번호가 만료됐어요. 다시 요청해주세요.';

  /// 검증 시도 5회 초과.
  static const phoneOtpAttemptsExceeded = '시도 횟수를 초과했어요. 인증번호를 다시 요청해주세요.';

  /// 잘못된 코드 — 남은 시도 횟수 포함.
  static String phoneOtpInvalidFormat(int attemptsRemaining) =>
      '인증번호가 일치하지 않아요. (남은 시도 $attemptsRemaining회)';

  /// 잘못된 코드 — 남은 시도 정보가 없을 때.
  static const phoneOtpInvalid = '인증번호가 일치하지 않아요.';

  /// 발송된 코드 없음 (요청 전 검증 시도).
  static const phoneOtpNotFound = '인증번호를 먼저 요청해주세요.';

  /// SMS 벤더 발송 실패.
  static const phoneOtpSendFailed = 'SMS 발송에 실패했어요. 잠시 후 다시 시도해주세요.';

  /// 네트워크/기타 오류.
  static const phoneOtpNetworkError = '네트워크 연결을 확인해주세요. 잠시 후 다시 시도해주세요.';

  // ========================================================================
  // 학생 게이미피케이션 P3 — Spotlight prompt (스펙 §7.4)
  // ========================================================================
  // 사용처: features/gamification/presentation/widgets/spotlight_slot.dart

  /// teacherRec 타입 헤더 (§7.4 — 권유형, "꼭 해야" 금지).
  static const spotlightHeaderTeacherRec = '선생님이 추천했어요';

  /// seasonEvent 타입 헤더.
  static const spotlightHeaderSeasonEvent = '이번 달 추천';

  /// routineSuggestion 타입 헤더.
  static const spotlightHeaderRoutineSuggestion = '이거 어때요?';

  /// 수락 버튼 — "지금 볼래" / "다음에" 와 동등 비중 (§7.4).
  static const spotlightAcceptButton = '지금 볼래';

  /// 거절 버튼 — 페널티 메시징 0.
  static const spotlightDeclineButton = '다음에';

  // ========================================================================
  // 연습장(Practice Journal) P1 — 연령 톤 라벨 (표준/어린이 2종)
  // ========================================================================
  // 사용처: features/practice_journal/presentation/extensions/journal_tone.dart

  /// 표준 톤 제목.
  static const journalTitleStandard = '연습장';

  /// 어린이 톤 제목.
  static const journalTitleChild = '도장판';

  /// 연습 도장 — 표준 톤.
  static const journalMarkStandard = '연습 도장';

  /// 연습 도장 — 어린이 톤.
  static const journalMarkChild = '연습 도장';

  /// 자가 검인(부모 미연결 학생의 한 줄 회고).
  static const journalSelfEndorse = '자가 검인';

  /// 부모 주간 응원·확인 도장.
  static const journalGuardianSeal = '확인 도장';

  /// 선생님 검인(과제 한정).
  static const journalTeacherEndorse = '선생님 인증';

  /// 도장 찍기 보상 CTA.
  static const journalStampPressCta = '도장 꾹!';

  /// 빈 날(비처벌) 라벨.
  static const journalRestLabel = '쉼표';

  // 연습장(Practice Journal) P2 — 제본/완성본 책장.
  // 사용처: features/practice_journal/presentation/screens/bound_shelf_screen.dart 등
  /// 완성본 책장 화면 제목 + 진입 라벨.
  static const boundShelfTitle = '완성본 책장';

  /// 연습장 본문 부제 (용도 안내)
  static const practiceJournalSubtitle = '월별 연습 기록 확인용';

  // ── UX 검토 wave4 (#780~#783) ──
  /// 홈 고정 퀵액션 FAB 툴팁
  static const homeQuickActionFabTooltip = '빠른 추가';
  static const studentFilterSectionPractice = '연습 상태';
  static const studentFilterSectionEnrollment = '수강·결제 상태';
  static const sortByNextLesson = '다음 레슨순';
  static const sortBySubscriptionExpiry = '수강권 만료순';
  static const studentSearchExtended = '이름, 악기, 학부모명, 메모로 검색';

  /// 알림 필터 — 전체
  static const notifFilterAll = '전체';

  /// 알림 필터 — 안읽음
  static const notifFilterUnread = '안읽음';

  /// 알림 없음 (안읽음 필터 적용 시)
  static const notifNoUnread = '읽지 않은 알림이 없습니다';
  static const trophyCollectionTitleTeacher = '학생 트로피';
  static const badgeTierCommon = '일반';
  static const badgeTierRare = '희귀';
  static const badgeTierEpic = '특급';
  static const badgeTierLegendary = '전설';

  /// 완성본 섹션 헤더.
  static const boundShelfCompletedSection = '완성본';

  /// 연습중(미완성) 섹션 헤더 + 책등 라벨.
  static const boundShelfInProgress = '연습중';

  /// 빈 책장 — 제목/부제.
  static const boundShelfEmptyTitle = '아직 완성본이 없어요';
  static const boundShelfEmptySubtitle = '곡을 끝내면 완성본 한 권으로 제본돼요';

  /// 곡 완성(제본) 축하.
  static const boundVolumeCelebration = '완성본으로 제본되었어요 · 책장에서 확인하세요';

  // [검토 #19] UX wave5
  static const String vacationDispositionMakeupCreditHint =
      '보강 1회를 적립해 나중에 사용해요 (환불 아님)';
  static const String vacationDispositionFreeCancelHint =
      '수강권 차감 없이 휴강 처리해요 (환불 아님)';
  static const String vacationDispositionRollForwardHint =
      '다음 회차로 밀리고, 수강권 유효기간이 자동 연장돼요';
  static const String vacationDispositionRecommendedHint =
      '학생에게 유연성이 가장 높은 방식이에요';

  // [검토 #41] UX wave5
  static const String priceListRoleSubtitle = '악기·레벨별 단가 (수강권 상품과 별개)';

  // [검토 #49] UX wave5
  /// 기간 만료 (날짜 경과로 만료)
  static const statusPeriodExpired = '기간 만료';

  /// 회차 소진 (횟수 소진으로 만료)
  static const statusDepleted = '회차 소진';

  /// 소진 임박 — 잔여 N회 (회차 기반)
  static String statusExpiringSoonSessions(int remaining) =>
      '소진 임박 · 잔여 $remaining회';

  /// 임박 — D-N일 (날짜 기반)
  static String statusExpiringSoonDays(int days) =>
      days <= 0 ? 'D-day' : 'D-$days';

  // [검토 #51] UX wave5
  /// 추가 증정 회차 (섹션 제목, #787 — 보너스 → 추가 증정 회차)
  static const String bonusSessionLabel = '추가 증정 회차';

  /// 총 N회 (정규 X + 증정 Y) — 보너스 미리보기
  static String bonusTotalPreview(int regular, int bonus) =>
      '총 ${regular + bonus}회 (정규 $regular + 증정 $bonus)';

  /// 증정 회차 사유 선택 안내 (사유 칩 섹션 설명)
  static const bonusReasonHint = '서비스 회차는 정규 회차와 동일하게 사용됩니다.';

  // [검토 #52] UX wave5
  /// 수강권 정책 우선순위 안내 배너 — 기본 정책에서 가져온 값임을 고지
  static const String policySourceNotice = '기본 정책(전역)에서 가져온 값 · 이 수강권만 변경됩니다';

  /// 수강권 정책 적용 우선순위 1줄 고지
  static const String policyPriorityNotice = '개별 > 템플릿 > 전역 순으로 적용됩니다';

  // [검토 #53] UX wave5
  /// 노쇼 정책 선택 시 학생 측 결과 미리보기 레이블
  static const noShowStudentPreviewLabel = '학생 측:';

  /// 노쇼 정책 - 회차 차감 시 학생 미리보기
  static const noShowStudentPreviewDeduct = '회차 1 차감';

  /// 노쇼 정책 - 차감 없음 시 학생 미리보기
  static const noShowStudentPreviewNoDeduct = '회차 차감 없음';

  // [검토 #55] UX wave5
  /// 연습장 도장 actor 범례 — 카드/화면 내 텍스트 설명.
  static const journalLegendStudent = '학생';
  static const journalLegendGuardian = '보호자';
  static const journalLegendTeacher = '선생님';

  /// 범례 제목 (연습장 상세 화면).
  static const journalActorLegendTitle = '도장 의미';

  /// 학생 자가기록 설명.
  static const journalActorStudentDesc = '학생 자가기록';

  /// 보호자 확인 설명.
  static const journalActorGuardianDesc = '보호자 확인';

  /// 선생님 인증 설명.
  static const journalActorTeacherDesc = '선생님 인증';

  // [검토 #60] UX wave5
  static const String inquiryStatusUnanswered = '미답변';
  static const String inquiryStatusAnswered = '답변완료';
  static const String inquiryReplySla = '보통 1~2일 내 답변';

  // [검토 #8] UX wave6
  static String urgentAlertMoreOfType(int n) => '외 $n건';

  // [검토 #10] UX wave6
  static String unreadBadgeCount(int n) => n > 9 ? '9+' : '$n';

  // [검토 #29] UX wave7
  static const String registerDirectPrimary = '직접 등록';
  static const String registerInviteSecondary = '초대로 등록';

  // [검토 #32] UX wave7
  static const String studentFormAdditionalInfo = '추가 정보';

  // [검토 #40] UX wave7
  static const String profilePreviewAndPublic = '미리보기 · 공개 설정';

  // [검토 #96] UX 0619 — 학생/학부모 i18n (하드코딩 한국어 → AppStrings)
  // 학생 대시보드
  static const studentPracticeRecordMore = '연습 기록 더보기';
  // 수강권 갱신 배너 (subscription_renewal_banner)
  static const renewalBannerProposalArrivedTitle = '갱신 제안이 도착했어요!';
  static const subscriptionExpiringSoonTitle = '수강권이 곧 만료됩니다';
  static const renewalBannerProposalSubtitle = '선생님이 수강권 갱신을 제안했습니다';
  static const renewalBannerSendRequestSubtitle = '갱신 요청을 보내 레슨을 이어가세요';
  static String renewalBannerRemainingSubtitle(int remaining, int days) =>
      '남은 횟수 $remaining회 · $days일 남음';
  static const renewalBannerCheckCta = '확인하기';
  // 수강권 제안 배너 (pending_proposals_banner)
  static const pendingProposalDefaultReason = '지금 확인하고 혜택 받으세요';
  static const pendingProposalDefaultMessage = '선생님이 수강권을 제안했습니다';
  // 알림 목록 (notification_list_screen)
  static const notifMarkAllRead = '모두 읽음';
  static const notifEmptyTitle = '알림이 없습니다';
  static const notifEmptySubtitle = '새로운 소식이 있으면 알려드릴게요';
  static String notifNoUnreadSubtitle(String filterName) =>
      '$filterName 탭에서 전체 알림을 확인하세요';
  static const notifLoadError = '알림을 불러올 수 없습니다';
  // 학생 요약 공유 (student_summary_screen)
  static const summaryLessonDateLabel = '수업일';
  static const summaryKeyPointsLabel = '핵심 포인트';
  // 팔로우 피드 (follow_feed_screen)
  static const followFeedLoadError = '소식을 불러올 수 없습니다';
  static const followFeedEmptySubtitle = '팔로우한 선생님의 소식이 표시됩니다';

  // [검토 #84·#87] UX 0619 (c)
  /// 받은 수강권 제안 (학생 측 제안 상세 AppBar, 검토 #82)
  // #846 수강권 발급 학생 선택(무인자 진입 dead-end 방지)
  static const issueSelectStudentTitle = '수강권을 발급할 학생 선택';
  static const issueSelectStudentEmpty = '연결된 학생이 없습니다';
  // #847 입금 계좌 미등록 발급/제안 가드
  static const bankAccountRequiredTitle = '입금 계좌를 먼저 등록하세요';
  static const bankAccountRequiredBody =
      '수강권 결제 안내를 위해 입금 계좌가 필요합니다. 계좌를 등록한 뒤 다시 발급해주세요.';
  static const bankAccountRequiredCta = '계좌 등록';
  static const proposalReceivedAppBarTitle = '받은 수강권 제안';

  // ── Notebook masthead signature (검토 #90/#91 — 브랜드 시그니처 중앙화) ──
  /// Programme eyebrow — English brand line, e.g. 'Programme for Thursday'.
  static String studentHomeProgrammeFor(String dayLabel) =>
      'Programme for $dayLabel';

  /// Notebook masthead date — Hanja style, e.g. '6月 19日'.
  static String studentHomeMastheadHanjaDate(int month, int day) =>
      '$month月 $day日';

  // 내 선생님 카드 실데이터 폴백 문구 (검토 #94)
  static const myTeachersUnknownTeacher = '선생님';
  static const myTeachersInstrumentLoading = '불러오는 중…';
  static const myTeachersInstrumentUnset = '악기 미정';

  static const paymentPendingProcessingEstimate = '보통 1영업일 소요됩니다';
  static const subscriptionEmptyRequestLessonCta = '레슨 신청하기';

  /// 오프라인 배너 문구 (#868)
  static const offlineBannerMessage = '오프라인 — 저장된 데이터를 표시 중';

  // ── Issue #920 i18n bundle ──

  // Role Select
  static String roleSelectWelcome(String name) => '$name님, 환영합니다!';
  static const roleSelectSubtitle = '약관에 동의하고 사용할 역할을 선택해 주세요.';
  static const roleSelectTeacher = '선생님';
  static const roleSelectTeacherDesc = '학생 관리, 레슨 일정, 피드백 작성';
  static const roleSelectStudent = '학생';
  static const roleSelectStudentDesc = '레슨 확인, 연습 기록, 피드백 확인';
  static const roleSelectParent = '학부모';
  static const roleSelectParentDesc = '자녀의 레슨과 연습을 확인';
  static const roleSelectConsentRequired = '필수 약관에 동의하면 역할을 선택할 수 있어요.';

  // Student Invite Code
  static const inviteCodeScreenDesc = '선생님으로부터 받은\n초대 코드를 입력해주세요';
  static const inviteCodeValidationEmpty = '초대 코드를 입력해주세요';
  static const inviteCodeSubmitButton = '코드 확인하기';
  static const inviteCodeHelpInfo =
      '초대 코드는 선생님이 학생 등록 후 제공합니다.\n아직 코드가 없다면 아래에서 바로 시작할 수 있어요.';
  static const inviteCodeSkipButton = '코드 없이 시작하기';
  static const inviteCodeCheckError = '코드 확인 중 오류가 발생했습니다';

  // Phone Verification
  static const phoneVerifyPhoneLabel = '휴대폰 번호';
  static const phoneVerifyCodeLabel = '인증번호';
  static const phoneVerifyCodeHint = '6자리 인증번호';
  static const phoneVerifyStepTitlePhone = '휴대폰 인증';
  static const phoneVerifyStepTitleCode = '인증번호 입력';
  static String phoneVerifyStepDescCode(String phone) =>
      '$phone으로 전송된\n인증번호 6자리를 입력해주세요';
  static const phoneVerifyStepDescPhone = '레슨 관리와 학생 초대를 위해\n휴대폰 인증이 필요합니다';
  static const phoneVerifyButtonVerify = '인증 완료';
  static const phoneVerifyButtonSend = '인증번호 받기';
  static const phoneVerifyButtonResend = '인증번호 다시 받기';
  static const phoneVerifyButtonChangePhone = '휴대폰 번호 변경';
  static const phoneVerifyErrorInvalidPhone = '올바른 휴대폰 번호를 입력해주세요';
  static const phoneVerifyErrorInvalidCode = '6자리 인증번호를 입력해주세요';

  // Onboarding Profile Setup (teacher)
  static const profileSetupSubtitle = '학생들에게 보여질 기본 정보를 설정해주세요';
  static const profileSetupDeletePhoto = '사진 삭제';
  static const profileSetupNameLabel = '이름';
  static const profileSetupInstrumentLabel = '악기';
  static const profileSetupInstrumentHint = '악기를 선택해주세요';
  static String profileSetupMissingFields(String fields) => '필수 항목: $fields';

  // Student Profile Setup
  static const studentProfileSetupSubtitle = '기본 정보를 설정해주세요';
  static const studentProfileSetupNameLabel = '이름';
  static const studentProfileSetupNameHint = '이름을 입력해주세요';
  static const studentProfileSetupInstrumentLabel = '악기';
  static const studentProfileSetupInstrumentHint = '악기를 선택해주세요';

  // Common instrument list (SSOT — shared between teacher and student selectors)
  static const List<String> instrumentList = [
    '바이올린',
    '피아노',
    '첼로',
    '플루트',
    '클라리넷',
    '비올라',
    '기타',
    '성악',
    '드럼',
    '작곡',
  ];

  // Bank Account Edit
  static const bankAccountNoAccount = '등록된 계좌가 없습니다';
  static const bankAccountAddPrompt = '학생의 수강료 입금을 위한 계좌를 추가하세요.';
  static const bankAccountDefaultNote = '기본 계좌가 수강권 제안 시 학생에게 표시됩니다.';
  static const bankAccountDefaultBadge = '기본';
  static const bankAccountDirectInput = '직접입력';
  static const List<String> bankNames = [
    '국민은행',
    '신한은행',
    '우리은행',
    '하나은행',
    '농협은행',
    'SC제일은행',
    '한국씨티은행',
    '기업은행',
    '카카오뱅크',
    '토스뱅크',
    '케이뱅크',
    '새마을금고',
    '신협',
    '우체국',
    '수협은행',
    '대구은행',
    '부산은행',
    '경남은행',
    '광주은행',
    '전북은행',
    '제주은행',
  ];
  static const bankAccountConsentContent =
      '[개인정보(계좌정보) 수집·이용 동의]\n\n'
      '1. 수집 항목\n  - 은행명, 계좌번호, 예금주\n\n'
      '2. 수집 목적\n  - 수강료 입금 안내를 위해 학생에게 계좌 정보를 표시\n\n'
      '3. 보유 기간\n  - 회원탈퇴 시까지 (탈퇴 후 30일 이내 파기)\n'
      '  - 계좌 변경이력: 전자상거래법에 따라 5년 보관\n\n'
      '4. 동의 거부 시 불이익\n  - 동의를 거부할 수 있으나, 계좌 등록이 불가합니다.\n';
  static const bankAccountConsentSheetTitle = '개인정보 수집·이용 동의';
  static const bankAccountConsentCheckboxLabel = '개인정보(계좌정보) 수집·이용 동의';
  static const bankAccountConsentRequired = '필수';
  static const bankAccountConsentViewContent = '내용보기';
  static const bankAccountValidationBank = '은행명을 입력해주세요';
  static const bankAccountValidationNumber = '계좌번호를 입력해주세요';
  static const bankAccountValidationNumberFormat = '올바른 계좌번호를 입력해주세요';
  static const bankAccountValidationHolder = '예금주를 입력해주세요';

  // Lesson Style Settings
  static String lessonStyleMinutes(int minutes) => '$minutes분';
  static const lessonStyleNoLimit = '제한 없음';
  static const lessonDurationManagedInStyle = '수업방식에서 변경';
  static String lessonStyleHoursBefore(int hours) => '$hours시간 전';
  static String lessonStyleDaysBefore(int days) => '$days일 전';

  // Pending Bookings
  static const pendingBookingsEmpty = '대기 중인 신청이 없습니다';
  static const pendingBookingsEmptyDesc = '새로운 레슨 신청이 들어오면 여기에 표시돼요';

  // #930 — Onboarding UX polish
  // #111 Profile setup back confirmation dialog
  static const profileSetupBackDialogTitle = '작성을 그만두실건가요?';
  static const profileSetupBackDialogMessage = '입력한 내용이 저장되지 않습니다.';
  static const profileSetupBackDialogConfirm = '나가기';
  static const profileSetupBackDialogCancel = '계속 작성';
  // #112 Student role invite badge
  static const roleSelectStudentInviteBadge = '초대 필요';
  // #118 Social login coming soon badge
  static const authComingSoonBadge = '준비중';

  // #939 — 이모지 제거 + 한글 → AppStrings (연습/게이미피케이션)
  // PracticeStartCard
  static String practiceStartHeader(String name) => '$name의 연습';
  static String practiceStartStreak(int days) => '$days일';
  static const practiceStartButton = '연습 시작';
  static String practiceStartYesterdayMinutes(int minutes) =>
      '어제 $minutes분 했어요';

  // CompletionToggle (standard mode)
  static const practiceCompleteLabel = '연습 완료!';
  static const practiceCompleteMarkLabel = '연습 완료로 표시';
  static const practiceCompleteUndoLabel = '탭하여 완료 취소';
  static const practiceCompleteHintLabel = '탭하여 이 섹션을 완료로 표시하세요';

  // CompletionToggle (N회 반복 mode)
  static String practiceRepeatAllDone(int done, int total) =>
      '오늘 연습 완료! ($done/$total회)';
  static String practiceRepeatTap(int done, int total) =>
      '탭하여 연습 기록 ($done/$total회)';
  static const practiceRepeatReset = '탭하여 초기화';
  static String practiceRepeatDailyCount(int total) => '하루 $total회 반복';

  // BadgeCollectionScreen
  static String badgeLevelTotalPoints(int points) => '총 ${points}P';
  static String badgeLevelNextPoints(int points) => '다음 레벨까지 ${points}P';
  static const badgeRarityNotEarned = '미획득';
  static const badgePointHistoryEmpty = '포인트 기록이 없습니다';
  static const badgeRarityCommon = '일반';
  static const badgeRarityRare = '희귀';
  static const badgeRarityEpic = '영웅';
  static const badgeRarityLegendary = '전설';

  // StudentLessonCard
  static const studentLessonDefaultTeacher = '선생님';
  static const studentLessonCancelled = '휴강';
  static const studentLessonToday = '오늘';
  static const studentLessonTomorrow = '내일';

  // NextLessonCard
  static const nextLessonLabel = '다음 레슨';
  static const lessonTypeRegular = '정기';
  static const lessonTypeTrial = '체험';
  static const weekdayMon = '월';
  static const weekdayTue = '화';
  static const weekdayWed = '수';
  static const weekdayThu = '목';
  static const weekdayFri = '금';
  static const weekdaySat = '토';
  static const weekdaySun = '일';

  // StudentLessonsTab
  static String studentLessonsCount(int count) => '$count개 레슨';

  // StudentGamificationOnboardingScreen
  static const gamificationOnboardingGreeting = '안녕! 무슨 악기 해?';
  static const gamificationOnboardingRecommendationLabel = '오늘 한 가지 추천해줄게:';
  static const gamificationOnboardingAccept = '좋아! 시작하기';
  static const gamificationOnboardingDecline = '내가 정할래';

  // C1 empty-state consts (#634·#637)
  static const practiceRecordingEmpty = '녹음이 없습니다';
  static const practiceRecordingEmptyHint = '위의 마이크 버튼을 눌러 녹음을 시작하세요';
  static const sectionPickerEmpty = '섹션이 없습니다';
  static const sectionPickerEmptyHint = '먼저 레퍼토리와 섹션을 만들어주세요.';
  static const repertoireArchiveEmpty = '아카이브된 레퍼토리가 없습니다';
  static const studentPracticeTodayEmpty = '오늘 연습할 레퍼토리가 없습니다';
  static const studentPracticeDateEmpty = '이 날짜에 연습 기록이 없습니다';
  static const scheduleWeekEmpty = '이번 주는 레슨이 없습니다';
  static const settingsBackupEmpty = '저장된 백업이 없습니다';

  // C1 hybrid empty-state consts (#634 wave2)
  static const studentHomeAppTeacherEmpty = '연결된 앱 선생님이 없습니다';
  static const noSubscriptionsRegisteredHint = '선생님에게 수강권 발급을 요청하세요';
  static const parentChildNotLinkedSuffix = '은(는) 아직 선생님과 연결되지 않았습니다';
  static const parentChildNotLinkedDesc = '선생님 연결 후 수강권 정보가 표시됩니다';
  static const instrumentManagementEmpty = '등록된 악기가 없습니다';
}
