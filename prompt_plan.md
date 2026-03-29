# 레슨요청 개편 — 전체 진행 상황

> 마지막 업데이트: 2026-03-29
> PAD: docs/proposal/lesson-request-ux-improvement.pad.md
> API 스펙: docs/specs/schedule/lesson_request_api_spec.md

## 이슈 상태

| 이슈 | 제목 | 상태 | 커밋 |
|------|------|------|------|
| #215 | 엔티티 & 상세화면 코어 | ✅ Closed | 7 |
| #216 | 홈 리스트 & 바텀시트 & 레거시 제거 | ✅ Closed | 4 |
| #217 | 전체 화면 (달력+필터) & API 스펙 | 🔧 In Progress | 3 |
| #218 | 학생 측 전체 (2차) | 🔧 In Progress | 2 |
| #220 | 리스트 아이템 — 선생님 판단 순서 재배치 | ✅ Done | 1 |
| #221 | 상세 화면 — 체험/정규 프로필 카드 분기 | ✅ Done | 1 |

## 이번 세션 완료 항목 (2026-03-29)

### 리스트 & 상세 화면 UX 개선 (#220, #221)
- [x] 리스트 아이템 3줄 재배치 (학원뱃지+타입+경과시간 / 이름·악기·레벨 / 1순위시간)
- [x] 상세 화면 프로필 카드 체험/정규 분기 → **채팅 스타일로 전면 재구성**
- [x] AppBar: 상대방 아바타+이름+타입+상태 (카카오톡 스타일)
- [x] 채팅 히스토리: 시간순(최신=아래), 전체 화면 스크롤
- [x] 하단 고정: 컴팩트 슬롯 칩 + 캘린더 아이콘 + 수락 버튼

### 일정비교 화면 강화
- [x] 학생 희망 시간 카드 표시 + 선택 시 확정 버튼
- [x] 선택 시 캘린더 해당 주로 자동 이동 + 그리드 하이라이트
- [x] 기존 레슨 통일 색상 (희망 시간 강조를 위해)
- [x] 프리뷰 레슨 점선 표시 복원 + Mock 데이터 추가
- [x] 일정 충돌 감지 (확정 겹침=수락 차단, 프리뷰 겹침=안내)

### 결정 변경 (withdrawApproval)
- [x] 수락 후 결정 변경 → pending 롤백 (히스토리 유지)
- [x] 선생님/학생 모두 theirTurn에서 결정 변경 가능
- [x] 히스토리에 결정 변경 이벤트 + 이전 시간 취소선 표시

### 학생 뷰 동기화
- [x] 학생 프로필에 레슨 요청 메뉴 추가
- [x] 학생 수락 → acceptAlternative 이벤트 (학생 버블에 표시)
- [x] 학생 뷰 프로필 카드 + 이름 비공개 (hideStudentNames)
- [x] 채팅 버블 색상 역할 기준 고정 (뷰어 무관)

### 품질 & 정합성
- [x] 시간 표시 포맷 통일: "4/5(토) 14:00 ~ 15:00"
- [x] TimeSlotOption에 date 필드 추가 (HiveField 5)
- [x] 히스토리에 날짜 정보 표시 (preferredSlots 직접 사용)
- [x] 수락 히스토리에 선택 시간 기록 (selectedSlotIndex)
- [x] 하드코딩 UI 텍스트 → AppStrings (30+ 건)
- [x] 리스트 여백 카드형 통일 (3개 화면)

## 미완료 항목

- [ ] 무한 스크롤 페이지네이션 (서버 API 필요)
- [ ] 푸시 알림 + 만료 타이머 (서버 필요)
- [ ] 학생 전체 화면 라우팅 (AllLessonRequestsScreen 학생용)
- [x] AppBar 이름 탭 → 프로필 바텀시트 (메트로놈 스타일)
- [x] 채팅 아바타 탭 → 프로필 바텀시트
- [x] 수락 시 메시지 입력 → 히스토리 기록
- [x] 거절 메시지 부드럽게 → "요청이 종료되었습니다"
- [x] 종료 상태 하단바 회색 통일
- [x] 첫 진입 가이드 (시스템 메시지 + 슬롯 힌트)
- [ ] 무한 스크롤 페이지네이션 (서버 API 필요)
- [ ] 푸시 알림 + 만료 타이머 (서버 필요)
- [ ] 학생 전체 화면 라우팅 (AllLessonRequestsScreen 학생용)

## 백엔드 통합 (2026-03-29)

### 완료
- [x] Docker PostgreSQL 17 기동 + Alembic 9개 마이그레이션
- [x] dev-login JWT 인증 플로우 검증
- [x] Entity ↔ API 스키마 정합성 5개 도메인 비교/수정
- [x] Subscription 스키마 12개 결제 필드 추가
- [x] Student 모델 주소 4필드 추가
- [x] LessonRequest withdrawApproval 백엔드 지원 (pending 상태 전환)
- [x] RemoteUnifiedLessonRequestRepository 생성 (Mock/Remote 자동 전환)
- [x] E2E 시나리오 테스트 8건 작성 (176/176 통과)
- [x] 시나리오 테스트 가이드 업데이트

### 미완료
- [ ] Beta 서버 배포 (ssh codenavi → docker compose up)
- [ ] USE_MOCK=false 앱 시뮬레이터 테스트
- [ ] 선생님 5명 실사용자 온보딩

## 세션 통계

- 총 커밋: 55개+
- 수정 파일: 40개+
- 백엔드 테스트: 176개 (전부 통과, 38초)
- 신규 마이그레이션: 2개 (bank_accounts, schema_alignment_phase2)
- 신규 시나리오: 8건 (SI-01~08)
- 신규 이벤트 타입: withdrawApproval (HiveField 12)
- 신규 엔티티 필드: TimeSlotOption.date (HiveField 5)
