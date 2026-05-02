# Feature Hub - 기능 x 역할 x 스펙 매트릭스

> Last updated: 2026-05-02
> 상태: 관리 중
> 목적: 전체 기능의 스펙/코드/상태를 한눈에 파악하는 중앙 허브

---

## 1. 마스터 스펙 인덱스

> 전면 재작성 완료 (2026-03-06). 각 도메인별 단일 마스터 문서가 **Single Source of Truth**.

| # | 도메인 | 마스터 스펙 | 통합된 기존 스펙 수 | 비고 |
|---|--------|-----------|:-----------------:|------|
| 1 | 레슨 | [lesson_master.md](lesson/lesson_master.md) | 16개 | 플로우 7개 + 예약 + 노트 + 그룹 등 |
| 2 | 연습 | [practice_master.md](practice/practice_master.md) | 18개 | 녹음 5개 + 레퍼토리 4개 + 시스템 등 |
| 3 | 구독/결제 | [subscription_master.md](subscription/subscription_master.md) | 9개 | 결제 + 정책 + 법적문서 포함 |
| 4 | 사용자 | [user_master.md](user/user_master.md) | 10개 | 인증/초대/학생/학부모/리뷰/체험 통합 |
| 5 | 스케줄 | [schedule_master.md](schedule/schedule_master.md) | 2개 | 가용시간 + 확인카드 |
| 6 | 메트로놈 | [metronome_master.md](metronome/metronome_master.md) | 4개 | 시스템 + 사운드 + 서브디비전 |
| 7 | 알림 | [notification_master.md](notification/notification_master.md) | 1개 보강 | 기존 스펙 + 구현 코드 통합 |
| 8 | 디자인 | [notebook/README.md](design/notebook/README.md) | — | Notebook × Score 디자인 시스템 (**SSOT**) |
| 9 | 캘린더 | [calendar_master.md](calendar/calendar_master.md) | 신규 | 코드 역공학 |
| 10 | 온보딩 | [onboarding_master.md](onboarding/onboarding_master.md) | 신규 | 코드 역공학 |
| 11 | 학생홈 | [student_home_master.md](student_home/student_home_master.md) | 신규 | 코드 역공학 |
| 12 | 팔로우 | [follow_master.md](follow/follow_master.md) | 신규 | Phase 1,3 완료 / Phase 2 미구현 |
| 13 | 설정 | [settings_master.md](settings/settings_master.md) | 신규 | 코드 역공학 |
| 14 | 홈 | [home_master.md](home/home_master.md) | 신규 | 선생님 홈 대시보드 |
| 15 | 프로필 | [profile_master.md](profile/profile_master.md) | 신규 | 프로필 편집/사진 |
| 16 | 게이미피케이션 | [gamification_master.md](gamification/gamification_master.md) | 신규 | 포인트/레벨/뱃지 |
| 17 | 관계 | [relationship_master.md](relationship/relationship_master.md) | 신규 | 선생님-학생 관계 관리 |

### 기타 루트 문서

| 문서 | 역할 |
|------|------|
| [glossary.md](glossary.md) | 용어집 |
| [tech_decision.md](tech_decision.md) | 기술 스택 결정 |

### 참고 자료 (docs/ 루트)

| 폴더 | 내용 |
|------|------|
| [reference/](../../reference/) | 아키텍처 참고 (student_centered_architecture, metronome_timing_analysis 등) |
| [research/](../../research/) | 시장 조사 (competitive_analysis, figma_templates 등) |

---

## 2. Pain Point A~H - 기능 매핑

> 출처: lesson_master.md (App vs Non-App Flow Comparison)
> "오래된 수강생에게 앱의 가치는 편리함이 아니라 **성장 증명**이다."

| # | Pain Point | 해결 기능 | 마스터 스펙 섹션 | 구현 상태 |
|---|------------|----------|----------------|:--------:|
| A | 2년간 뭘 배웠는지 기록 없음 | 레슨 노트 타임라인, 레퍼토리 히스토리 | lesson_master #5, practice_master #3.4 | 부분 구현 |
| B | 연습 진도 블랙박스 | 연습 기록 실시간 공유 | practice_master #5.1 | 설계 완료 |
| C | 실력 성장 체감 불가 | 녹음 A/B 비교 재생 | practice_master #4.5 | 설계 완료 |
| D | 학부모에게 보여줄 근거 없음 | 학부모 대시보드 실데이터 | user_master #5.2, practice_master #5.1 | 부분 구현 |
| E | 레슨 시간 최적화 근거 없음 | 레슨별 진도 데이터 | (Phase 2 - 백엔드 필요) | 미착수 |
| F | 발표회/콩쿠르 준비 관리 | 섹션별 완성도 추적 | practice_master #2.2 | 설계 완료 |
| G | 선생님 부재 시 대체 레슨 | 레슨 노트 + 레퍼토리 공유 | lesson_master #5 | 구현 완료 |
| H | 수강료 인상 근거 | 성장 데이터 기반 협의 | practice_master #5.2 | 설계 완료 |

---

## 3. 기능 x 역할(T/S/P) x 구현 상태 매트릭스

> T = 선생님, S = 학생, P = 학부모
> 상태: 완료 | 설계 | 미착수

### 3.1 레슨 도메인 → [lesson_master.md](lesson/lesson_master.md)

| 기능 | T | S | P | 상태 |
|------|:-:|:-:|:-:|:----:|
| 레슨 캘린더 (월/주) | O | O | 읽기 | 완료 |
| 레슨 노트 (피드백/포인트/팁) | 편집 | 읽기 | 읽기 | 완료 |
| 통합 레슨 예약 | O | O | - | 완료 |
| 체험 레슨 플로우 | O | O | - | 완료 |
| 빠른 레슨 추가 | O | - | - | 설계 |
| 그룹 레슨 (GX) | O | O | - | 설계 |
| 레슨 장소 선택 | O | - | - | 완료 |
| 3자 관계 (학원) | O | O | - | 설계 |

### 3.2 연습 도메인 → [practice_master.md](practice/practice_master.md)

| 기능 | T | S | P | 상태 |
|------|:-:|:-:|:-:|:----:|
| 연습 화면 (주간 캘린더) | 조회 | O | - | 완료 |
| 연습 스트릭 | - | O | 읽기 | 완료 |
| 연습 목표 | 설정 | O | - | 설계 |
| 연습 노트 | - | O | - | 설계 |
| 레퍼토리 관리 | O | O | - | 완료 |
| 섹션 상세 | O | O | - | 완료 |
| 녹음 (시작/정지/저장) | O | O | - | 완료 |
| 녹음 재생 (A-B루프/속도) | O | O | - | 완료 |
| 스마트 녹음 (무음 트리밍) | - | O | - | 완료 |
| 녹음 비교 재생 (A/B) | - | O | - | 설계 |
| 연습 공유 | 수신 | 전송 | 읽기 | 설계 |
| 레퍼토리 히스토리 | 조회 | O | - | 설계 |
| 연습 통계 리포트 | 조회 | O | 읽기 | 설계 |
| 바로 녹음 | - | O | - | 설계 |
| 백업 시스템 | - | O | - | 설계 |

### 3.3 메트로놈/튜너 → [metronome_master.md](metronome/metronome_master.md)

| 기능 | T | S | P | 상태 |
|------|:-:|:-:|:-:|:----:|
| 메트로놈 (커스텀 네이티브) | O | O | - | 완료 |
| 서브디비전 (12패턴) | - | O | - | 완료 |
| 튜너 (YIN 피치 감지) | - | O | - | 완료 |
| 중앙 연습 버튼 (FAB) | - | O | - | 완료 |

### 3.4 수강권/입금 상태 → [subscription_master.md](subscription/subscription_master.md)

| 기능 | T | S | P | 상태 |
|------|:-:|:-:|:-:|:----:|
| 수강권 시스템 | O | O | - | 완료 |
| 수강권 제안 플로우 | O | O | - | 완료 |
| 수강권 입금 상태 | O | O | - | 완료 |
| 수강권 상태 컬러 | O | O | - | 완료 |
| 취소/변경 정책 | O | O | - | 완료 |
| 레슨 정책 설정 | O | - | - | 설계 |
| 레슨 요청 (재등록) | O | O | - | 완료 |

### 3.5 스케줄 → [schedule_master.md](schedule/schedule_master.md)

| 기능 | T | S | P | 상태 |
|------|:-:|:-:|:-:|:----:|
| 선생님 가용시간 (슬롯) | O | 조회 | - | 완료 |
| 레슨 예약/확정 | O | O | - | 완료 |
| 예약 변경/취소 | O | O | - | 완료 |
| 스케줄 확인 카드 | - | O | - | 완료 |
| 그룹 클래스 출석 | O | O | - | 설계 |

### 3.6 사용자 → [user_master.md](user/user_master.md)

| 기능 | T | S | P | 상태 |
|------|:-:|:-:|:-:|:----:|
| 소셜 로그인 (Google/Kakao/Apple) | O | O | O | 완료 |
| 선생님 등록/온보딩 | O | - | - | 완료 |
| 초대 시스템 (QR/URL/코드) | O | O | O | 완료 |
| 수강권 기반 관계 모델 | O | O | - | 완료 |
| 학생/클래스 관리 | O | - | - | 완료 |
| 학부모 대시보드 (4탭) | - | - | O | 완료 |
| 선생님 프로필 & 검색 | O | O | - | 완료 |
| 리뷰 시스템 | 응답 | O | - | 설계 |
| 체험 레슨 시스템 | O | O | - | 설계 |

### 3.7 기타 도메인

| 기능 | 마스터 스펙 | 상태 |
|------|-----------|:----:|
| 알림 시스템 | [notification_master.md](notification/notification_master.md) | 기본 구현 |
| 캘린더 탭 | [calendar_master.md](calendar/calendar_master.md) | 완료 |
| 온보딩 플로우 | [onboarding_master.md](onboarding/onboarding_master.md) | 완료 |
| 학생홈 대시보드 | [student_home_master.md](student_home/student_home_master.md) | 완료 |
| 팔로우 시스템 | [follow_master.md](follow/follow_master.md) | 데이터만 |
| 설정/백업/녹음관리 | [settings_master.md](settings/settings_master.md) | 완료 |
| 게이미피케이션 (포인트/레벨/뱃지) | (practice_master #6 참조) | 완료 |
| 분석 대시보드 (월별 통계/차트) | (lesson_master 참조) | 완료 |
| 과제 대시보드 (전체 학생 현황) | (lesson_master 참조) | 완료 |

---

## 4. 문서 구조

```
docs/specs/
├── feature_hub.md              ← 이 문서 (중앙 허브)
├── glossary.md                 # 용어집
├── tech_decision.md            # 기술 스택 결정
│
├── lesson/                     # 레슨 도메인
│   ├── lesson_master.md        ← Master Spec
│   └── invite/                 # 초대/관계 시스템 (정식 경로)
│
├── practice/                   # 연습 도메인
│   └── practice_master.md      ← Master Spec
│
├── subscription/               # 구독/결제 도메인
│   └── subscription_master.md  ← Master Spec
│
├── user/                       # 사용자 도메인
│   └── user_master.md          ← Master Spec
│
├── schedule/                   # 스케줄 도메인
│   └── schedule_master.md      ← Master Spec
│
├── design/                     # 디자인 도메인
│   ├── notebook/README.md      ← ⭐ 디자인 SSOT (Notebook × Score)
│   └── ux_guidelines.md        # UX 원칙
│
├── notification/               # 알림 도메인
│   └── notification_master.md  ← Master Spec
│
├── metronome/                  # 메트로놈 도메인
│   └── metronome_master.md     ← Master Spec
│
├── calendar/                   # 캘린더
│   └── calendar_master.md      ← Master Spec
│
├── onboarding/ | student_home/ | follow/ | settings/
│   └── [domain]_master.md      ← Master Spec
│
├── backend/                    # 백엔드 스펙
├── dev/                        # 개발 참고 (roadmap_v2, test_data 등)
└── _archive/                   # ❌ 사용 금지 (폐기된 문서)
```

---

## 5. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 2.2 | 2026-04-15 | 스펙 경량화 — 마스터 통합 완료 56개 파일 old/ 이동 (144→88개), 빈 폴더 5개 제거, 신규 14개 화면 마스터 반영 |
| 2.1 | 2026-03-12 | PR #135~#142 반영 — 레슨 요청 완료, 게이미피케이션/분석/과제 대시보드 추가, UX 점검 10회 성과 반영 |
| 2.0 | 2026-03-06 | 전면 재작성 - 13개 도메인 마스터 스펙 기반으로 재구성. 누락 스펙 6개 신규 작성. old/ 참고자료 reference/research/ 분리. |
| 1.0 | 2026-03-02 | 초안 작성 - 전체 매트릭스 + Pain Point 매핑 + 의존성 그래프 |
