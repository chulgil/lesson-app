# Spec — group-lesson (P1+P2)

> 날짜: 2026-07-31 | 상태: **locked** (2026-07-31 사용자 승인)
> 기획 SSOT: 옵시디언 `10 Projects/레슨앱/45-그룹레슨-기획-2026-07-30.md` — **§9 최종 확정(D1~D8)이 본 스펙의 절대 기준**
> 기존 마스터 스펙: `docs/specs/lesson/group_lesson_spec.md` (767줄, 2026-01) — 본 스펙 기준으로 재정렬, Phase 6 후 머지
> 기준 코드: origin/main `b8b1ddbc`

## 1. 목표 (한 문장)

개별 교사가 앱에서 그룹 클래스(고정 반 우선, 드롭인 보조)를 생성·운영하고, 학생·학부모가 통합 수강권으로 등록·출석·차감·알림을 신뢰할 수 있게 P1(MVP)+P2(운영 완성)를 전부 구현한다.

## 2. 성공 기준 (측정 가능)

### P1 — MVP
- [ ] **P1-0 배선 정합**: `GroupClassSchedule.group_class_id` 가 정원·노쇼정책을 보유한 `GroupClass` 를 실참조 (현재 `LessonClass` 오참조 = 죽은 모델). 마이그레이션 + pytest 로 FK 정합 검증
- [ ] **P1-1 클래스 CRUD**: BE `POST/PATCH/GET /group-classes` (+비활성화) + 교사 클래스 생성·수정 화면. 생성 폼은 **반(코호트) 기본, 드롭인은 폼 내 옵션** (분기 질문 금지 — D1)
  - 반(regular) 생성·수정 시 **반복 `GroupClassSchedule` 자동 생성·연장** 포함 (시나리오 1 "매주 자동 스케줄" 의 담당 — plan-check 반영). pytest: 생성 후 N주 스케줄 존재
- [ ] **P1-2 진입점 배선**: 교사 홈→"내 클래스" 진입 + 학생 레슨탭 아젠다에 등록된 반 행 표시 + 교사 상세에 개설 클래스 섹션(탐색 표면 — D3) + 기존 상세·출석 화면 라우트 연결 (고아 0)
- [ ] **P1-3 실차감**: 출석 확정 시 기존 `add_usage`(row lock·idempotent) 경로로 실제 차감. pytest: 잔여 감소 + 중복 차감 멱등 + `subscription_deducted` flag-only 경로 제거
  - 차감 대상 선택 규칙 (Phase 3 시각화에서 발견된 갭): 학생이 복수 수강권 보유 시 `appliesTo=group` **우선** → `universal` 폴백, 동순위면 만료 임박 우선. 기존 1:1 차감 호출부의 선택 로직이 있으면 그 규칙에 정렬(이중 규칙 금지) — 구현 시 확인 후 pytest 케이스 포함
  - **노쇼 4값 BE 집행** (plan-check 반영): 노쇼 처리 시 클래스 노쇼정책 4값 분기 — `deductCredit`(1회 차감)/`halfCredit`/`noDeduction`/`reschedule`(MakeupCredit 적립 경로 재사용). **기존 1:1 노쇼 SSOT(#239) 분기 시맨틱 재사용, 신규 발명 금지**. pytest 4분기 전부
- [ ] **P1-4 적용범위 필드**: `Subscription.appliesTo`(oneToOne/group/universal, **null=universal 비파괴 마이그레이션** — `disciplineId` 선례) + 차감 시 범위 검증(그룹 수업에 1:1 전용권 사용 시 4xx) + 그룹 전용 `SubscriptionTemplate` (가격 앵커: 1:1 의 60~70%, D8)
- [ ] **P1-5 표시 정합**: 학부모 결제 탭·수강권 목록에서 그룹 수강권이 **클래스명 + 그룹 배지**로 표시 ("개인레슨" 폴백 0건 — `subscription_membership_card`·`parent_payments_tab` 회귀 테스트). **만료 임박 알림·카드에도 수강권 종류(클래스명/그룹 라벨) 명시** (시나리오 2 Then 정합 — plan-check rev2)
- [ ] **P1-6 이모지 정리 (선행)**: `group_class_detail_screen.dart`(`_getInstrumentEmoji`)·`group_class_attendance_screen.dart` 이모지 0건 → `InstrumentColors`/Material Icons (HARD-GATE)

### P2 — 운영 완성
- [ ] **P2-1 마감 집행**: `booking/cancel_deadline_minutes` BE 검증 (마감 후 예약/취소 → 4xx + 정책 메시지), FE 표시 유지
- [ ] **P2-2 알림 6종 BE emit**: 예약확정 · 리마인더(전일·당일) · 드롭인 오픈 · 노쇼 경고 · 반 공지 발행 (대기승급·자동취소는 기존). FE 로컬 오발화 금지(#1191). pytest 로 5전이 emit 검증(#1207 패턴)
- [ ] **P2-3 노쇼 정합**: FE `NoShowPolicy` 2값 → BE SSOT 4값(deductCredit/halfCredit/noDeduction/reschedule) 통일
- [ ] **P2-4 코호트 멤버 관리**: 교사 직접 배정 + 학생 신청→챗형 승인(기존 lesson_request 재사용 — D4). 정원 초과 시 배정 차단
- [ ] **P2-5 반 공지**: `TeacherAnnouncement` 에 대상 스코프(전체/특정 클래스) 확장 — ClassNote 신설 금지(D5). 개인 피드백은 기존 1:1 노트 경로
- [ ] **P2-6 예약 확인 다이얼로그**: 드롭인 즉시예약 전 확인(차감될 수강권 + 마감·노쇼 정책 명시), 정책 박스를 액션 버튼 위로(D4 조건)

### 공통 게이트
- [ ] `flutter analyze` 0 에러 · `flutter test`(architecture 포함) 전체 green · backend pytest 전체 green
- [ ] 스펙 §8 위험 완화의 **머지 순서 제약** 준수 (P1-3 실차감은 P2-2 알림과 같은 릴리스 이전 머지 금지)

## 3. 사용자 시나리오 (Given/When/Then)

### 시나리오 1: 교사 반 개설·운영 (코호트)
- Given 교사가 학생 15명 보유, 주 1회 앙상블반 개설 희망
- When 홈 → 내 클래스 → 생성(이름·정원·요일시간·노쇼정책) → 학생 4명 배정
- Then 매주 스케줄 자동 생성, 배정 학생 레슨탭 아젠다에 반 행 표시, 출석 확정 시 각 학생 그룹 수강권에서 1회 차감

### 시나리오 2: 학부모 그룹 수강권 구매·확인
- Given 자녀가 1:1 레슨 + 앙상블반 동시 수강
- When 교사가 그룹 전용 수강권 발급 → 학부모 결제 탭 확인
- Then 그룹 수강권이 **앙상블반 이름 + 그룹 배지**로 표시(개인레슨 아님), 잔여 횟수가 1:1 과 구분되어 보임, 만료 임박 알림에 어느 수강권인지 명시

### 시나리오 3: 성인 학생 드롭인 특강
- Given 교사가 원데이 특강(드롭인) 오픈, 정원 6
- When 학생이 교사 상세에서 발견 → 예약 탭 → **확인 다이얼로그**(차감 수강권·마감·노쇼 정책) → 확정
- Then 예약확정 알림 수신. 정원 초과 시 대기열 → 자동승격 시 **즉시 알림**. 마감 후 취소 시도는 4xx + 정책 안내

### 시나리오 4: 노쇼·마감 집행
- Given 반 수업 당일, 학생 1명 무단 결석
- When 교사가 출석 체크에서 노쇼 처리
- Then 클래스의 노쇼정책(4값 중 하나)대로 차감/보존, 학생·학부모에게 노쇼 경고 알림

## 4. 스키마 / 인터페이스

### 변경 엔티티 (신규 발명 금지 — 기존 확장)
```
Subscription        += appliesTo: enum(oneToOne|group|universal)?  # null=universal, 비파괴
Subscription        += groupClassId?                               # 그룹 발급 시 대상 반 지정(선택).
                                                                   # 표시 규칙: groupClassId 有→클래스명+그룹 배지 /
                                                                   # 無+appliesTo=group→"그룹 수강권" 라벨 (개인레슨 폴백 금지)
SubscriptionTemplate += appliesTo + groupClassId (동일)             # 그룹 전용 템플릿 행 — 템플릿이 반을 지정하면 발급 시 전파 (J2 구현 반영)
GroupClassSchedule  .group_class_id → GroupClass FK 정합 (마이그레이션)
GroupClass          += cohort 멤버 목록 (교사 배정/승인)             # 반=고정 로스터
TeacherAnnouncement += scope: enum(all|class) + classId?           # 반 공지
NoShowPolicy(FE)    2값 → 4값 (BE SSOT 정렬)
NotificationType    += 그룹 6종 (BE enum + FE 매핑)
```

### API (BE FastAPI — 기존 schedule_ext 라우터 확장)
| Method | Path | 용도 |
|---|---|---|
| POST/PATCH/DELETE | `/groups/classes` | 클래스 정의 CRUD (교사) — 기존 FE `/groups/*` prefix 승계 (J3 확정) |
| GET | `/groups/classes?teacher_id=` | 교사 상세·내 클래스 목록 |
| POST/DELETE | `/groups/classes/{id}/members` | 코호트 배정/제외 (정원 검증) |
| 기존 | booking/attendance/waitlist | 재사용 (§2.1 구현 자산) — 차감만 add_usage 로 교체 |

- 라우터에 DB 쿼리 직접 금지(서비스 레이어) · ownership 은 서비스 raise → 라우터 403

### FE (feature: `features/schedule/` 기존 group_class* 확장 + `features/subscription/` 필드)
- 신규 화면: `group_classes_screen.dart`(교사 내 클래스), `group_class_form_screen.dart`(생성·수정)
- 기존 재사용: `group_class_detail_screen`·`group_class_attendance_screen`(이모지 정리 후)
- 아젠다 행: `student_lessons_tab` 에 등록 반 렌더 (날짜 매칭 — 탐색 슬롯 아님)

## 5. 비기능 요구사항

- 성능: 클래스 목록·아젠다 추가 쿼리 N+1 금지 (기존 리스트 패턴 준수)
- 보안: 클래스 CRUD·멤버 배정은 소유 교사만(서비스 레이어 ownership) · 학생은 본인 예약만 취소
- 관측성: 차감·마감 거부·자동승격은 BE 로그 (uvicorn 로거 정합 #1180 패턴)
- 오프라인: **P3 로 명시 이월** — FE Hive 미부착 상태 유지 (TypeId 3중 불일치는 P3 에서 해소)

## 6. 아키텍처 결정 (커밋 trailer 로 기록)

- **채택**: 통합 수강권 + `appliesTo` 스코프 필드 (D2) — `disciplineId` nullable 선례, 차감 SSOT `add_usage` 단일 경로 유지
- **채택**: 코호트(반) 우선 + 드롭인 보조, 카테고리 파라미터화 설계 (D1)
- **채택**: 반 공지 = `TeacherAnnouncement` 스코프 확장 (D5)
- **거절**: 별도 그룹 수강권 체계 — 시장 7/8 반대 패턴 + 학부모 화면 "개인레슨" 폴백 + 잔여횟수 SSOT 이중화
- **거절**: ClassNote 신규 모델 — 공지 시스템 3개 난립
- **거절**: 신규 차감 로직 — `use_lesson`/`deduct_lesson` legacy 침전 전례
- **거절**: 학생 탐색 신규 탭 — Hick's Law, 레슨탭은 아젠다 전용

## 7. 품질 계약

- TDD: BE 서비스(차감·마감·정원·노쇼) pytest 선행 · FE 신규 화면 widget smoke (HARD-GATE) + 실라우터 렌더
- 회귀: "개인레슨 폴백 0건" 위젯 테스트 · 5전이 알림 emit 테스트(#1207 패턴) · 차감 멱등 테스트
- 아키텍처: `flutter test test/architecture` — facade 경유, domain 순수성, l10n 경계
- 커버리지: 신규 BE 서비스 로직 80%+
- Lint 예외: 없음
- glossary: `GroupClass`(반/드롭인)·`appliesTo`·`코호트` 를 `.harness/knowledge/glossary.md` 에 등록 후 코드 착수

## 8. 위험과 완화

| 위험 | 영향도 | 완화 |
|---|---|---|
| **실차감이 알림보다 먼저 릴리스** → 자동승격 학생이 모른 채 결석·차감 | HIGH | **머지 순서 제약: P1-3 은 예약·승격 알림 5종(J10)과 같은 릴리스 이전 배포 금지** (반 공지 발행 알림은 제외 — 리스크 메커니즘 무관. DAG J5←J10 으로 강제) |
| appliesTo 마이그레이션이 기존 수강권 파괴 | HIGH | null=universal 비파괴 + alembic 실PG 검증(throwaway PG — SQLite 은폐 함정) |
| GroupClass 배선 정합이 기존 대기열·출석 API 를 깸 | MED | P1-0 을 최우선 단독 job 으로, 기존 pytest 회귀 전체 실행 |
| 출시 인프라 일정(11~12월 OAuth·IAP·prod)과 경합 | MED | **사용자 인지·수용 완료(D7 §9)** — P0 게이트 작업 요청 시 그룹레슨 중단하고 양보 |
| 이중 차감(출석 재확정·동시 요청) | MED | add_usage 멱등 + row lock 재사용, 재확정 시 기존 usage 확인 |
| 학부모 화면 개인레슨 폴백 재발 | MED | P1-5 회귀 테스트 + 그룹 배지 |

## 9. 범위 외 (하지 말 것)

- 발표회·합주 이벤트·시간충돌 감지 (D6 — P3 백로그)
- FE Hive 오프라인 (P3)
- academy-console 입력 UI (학원 반편성·정산 — 컨테이너 분담 불변)
- 헬스/필라테스 등 타 카테고리 실구현 (Discipline Phase 4 별도 트랙 — 설계 파라미터화만)
- 구체 가격 금액 확정 (06-수익화 개정에서 — 본 스펙은 60~70% 앵커만)
- 드롭인 신규 발견 표면(마케팅·외부 공유) — 기존 자산 연결 수준까지만
