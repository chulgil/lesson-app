# Implementation Roadmap v2

> 작성일: 2026-03-07
> 상태: 로드맵 확정, Phase별 순차 진행
> 기반: 스펙 문서 전체 검토, 경쟁사 분석, UX 리뷰 (#63~#73)

---

## 1. 현재 상태 요약

### 1.1 구현 완료

| 도메인 | 화면 | Provider | Widget | 완성도 |
|--------|:----:|:--------:|:------:|:------:|
| Auth (로그인/온보딩) | 5 | 3 | 0 | 100% |
| Home (선생님 대시보드) | 1 | 1 | 1 | 80% |
| Lessons (레슨 CRUD) | 4 | 13 | 23 | 95% |
| Practice (연습/녹음/메트로놈/튜너) | 15 | 24 | 63 | 95% |
| Students (학생 관리) | 5 | 8 | 21 | 90% |
| Schedule (예약/가용시간) | 15 | 4 | 22 | 90% |
| Subscription (수강권/결제) | 9 | 5 | 4 | 90% |
| Profile (프로필/설정) | 11 | 3 | 10 | 90% |
| Parent Home (학부모) | 8 | 5 | 7 | 85% |
| Student Home (학생) | 5 | 0 | 7 | 85% |
| Notifications (알림) | 1 | 1 | 2 | 40% |
| Search (검색) | 3 | 2 | 0 | 70% |
| Invite (초대/연결) | 7 | 0 | 0 | 80% |

### 1.2 미구현 (스펙 완료)

| 기능 | 스펙 | 경쟁사 대비 | 우선순위 |
|------|------|-----------|:--------:|
| ~~통계/리포트 대시보드~~ | analytics_dashboard_spec.md | StudioMate, Modacity | ✅ Phase 1+2 done |
| 출석 관리 | attendance_spec.md | StudioMate | HIGH |
| ~~게이미피케이션~~ | gamification_spec.md | Tonara (+68%), Practice Space | ⚠️ Phase 1 UI done |
| 팔로우 피드 | follow_master.md | 인스타그램형 | LOW |

### 1.3 경쟁사 대비 강점/약점

**강점 (유지/강화)**:
- 한국어 네이티브 (유일)
- 통합 앱 (선생님+학생+학부모)
- 무료 (경쟁사 $12~30/월)
- 메트로놈+튜너+스마트녹음
- 학부모 포털

**약점 (해소 필요)**:
- 게이미피케이션 부재 (Tonara/Practice Space 대비)
- 통계/리포트 없음 (StudioMate 대비)
- 출석 관리 없음 (StudioMate 대비)
- 인앱 메시징 없음 (Tonara 대비)

---

## 2. Phase 정의

### Phase 1: MVP 완성 (현재 ~ 2주)

> 목표: 베타 테스트 가능한 완전한 앱

| # | 작업 | 관련 이슈 | 스펙 | 예상 규모 | 상태 |
|---|------|----------|------|:---------:|:----:|
| 1-1 | 학생 탭 클래스별 그룹화 | #42 | student_class_system.md | S | done |
| 1-2 | 프로필 탭 미수금 관리 | #43 | subscription_master.md | M | done |
| 1-3 | 기존 정기레슨 앱 전환 플로우 | #59 | flow_with_app.md | M | done |
| 1-4 | 약관 동의 화면 | - | terms_agreement | S | ✅ done |
| 1-5 | Google SSO 연동 마무리 | - | google_sso_setup_guide.md | M | ✅ done |
| 1-6 | Mock → Backend 전환 준비 | - | architecture.md | L | todo |

### Phase 2: 핵심 차별화 (2~6주)

> 목표: 경쟁사 대비 핵심 약점 해소 + 차별화 강화

| # | 작업 | 스펙 | 예상 규모 | 우선순위 |
|---|------|------|:---------:|:--------:|
| 2-1 | **통계/리포트 대시보드** | analytics_dashboard_spec.md | L | ✅ done |
| 2-2 | **출석 관리 (Quick Action)** | attendance_spec.md Phase 1 | M | ✅ done |
| 2-3 | **게이미피케이션 Phase 1** (포인트+레벨) | gamification_spec.md Phase 1 | L | ✅ done |
| 2-4 | 대시보드 정보 계층화 | design_master.md 5.3 | M | ✅ done |
| 2-5 | 수강권 카드 UI 개선 (프로그레스 바) | subscription_master.md | S | ✅ done |
| 2-6 | 예약 색상 체계 적용 | design_master.md 5.3 | S | ✅ done |

### Phase 3: 고급 기능 (6~12주)

> 목표: 완전한 경쟁력 확보 + 학생/학부모 참여 강화

| # | 작업 | 스펙 | 예상 규모 | 우선순위 |
|---|------|------|:---------:|:--------:|
| 3-1 | **출석 관리 Phase 2** (통계 + 그룹 출석) | attendance_spec.md Phase 2 | M | ✅ done |
| 3-2 | **게이미피케이션 Phase 2** (뱃지 + 리더보드) | gamification_spec.md Phase 2 | L | ✅ done |
| 3-3 | 학생 연습 현황 상세 조회 | practice_master.md | M | ✅ done |
| 3-4 | **알림 시스템 고도화 (FCM)** | notification_master.md | L | ⚠️ 코드 완료, Firebase 설정 대기 |
| 3-5 | **팔로우/소식 피드** | follow_master.md Phase 3 | M | ✅ done |
| 3-6 | 인앱 메시징 (기본) | 스펙 미작성 | XL | LOW |

### Phase 4: 확장 (12주+)

> 목표: 학원 시장 진출 + 프리미엄 기능

| # | 작업 | 스펙 | 우선순위 |
|---|------|------|:--------:|
| 4-1 | 학원 웹 대시보드 | 스펙 미작성 | MEDIUM |
| 4-2 | 영상 피드백 (녹화 비교) | recording_comparison_spec.md | MEDIUM |
| 4-3 | 게이미피케이션 Phase 3 (포인트 상점) | gamification_spec.md Phase 3 | LOW |
| 4-4 | AI 연습 분석 (피치/리듬) | 스펙 미작성 | LOW |
| 4-5 | 결제 시스템 연동 (PG) | 스펙 미작성 | LOW |
| 4-6 | 출석 Phase 3 (알림 + 자동화) | attendance_spec.md Phase 3 | LOW |

---

## 3. Phase별 우선순위 판단 기준

| 기준 | 가중치 | 설명 |
|------|:------:|------|
| 사용자 임팩트 | 40% | 선생님 일상 워크플로우에 미치는 영향 |
| 경쟁사 대비 갭 | 25% | 경쟁사가 이미 제공하는데 우리가 없는 기능 |
| 구현 복잡도 | 20% | 투입 대비 효과 (ROI) |
| 학부모 가시성 | 15% | 학부모가 직접 확인 가능한 기능 (결제 의사결정) |

---

## 4. 스펙 문서 현황

### 4.1 마스터 스펙 (13개) - 전체 검토 완료

| # | 마스터 스펙 | Enum 정의 | 구현 파일 매핑 | 경쟁사 비교 | 상태 |
|---|-----------|:---------:|:------------:|:----------:|:----:|
| 1 | lesson_master.md | 8종 | 32개 파일 | O | 완료 |
| 2 | practice_master.md | 2종 | 참조 | O | 완료 |
| 3 | subscription_master.md | 5종 | 참조 | O | 완료 |
| 4 | user_master.md | 2종 | 10개 Provider | O | 완료 |
| 5 | design_master.md | - | - | O | 완료 |
| 6 | schedule_master.md | 13종 | 34개 파일 | O | 완료 |
| 7 | metronome_master.md | 5종 | 참조 | - | 완료 |
| 8 | notification_master.md | - | 14개 파일 | - | 완료 |
| 9 | calendar_master.md | 2종 | 3개 파일 | - | 완료 |
| 10 | onboarding_master.md | 2종 | 9개 파일 | - | 완료 |
| 11 | student_home_master.md | 1종 | 15개 파일 | - | 완료 |
| 12 | follow_master.md | - | Phase 3 | - | 완료 |
| 13 | settings_master.md | - | 13개 파일 | - | 완료 |

### 4.2 신규 스펙 (3개)

| # | 스펙 | 도메인 | 상태 |
|---|------|--------|:----:|
| 1 | analytics_dashboard_spec.md | analytics | 보강 완료 |
| 2 | attendance_spec.md | lesson | 보강 완료 |
| 3 | gamification_spec.md | practice | 신규 작성 |

### 4.3 일관성 수정 (6건)

| # | 문제 | 파일 | 상태 |
|---|------|------|:----:|
| 1 | SubscriptionStatus enum 미정의 | subscription_master.md | 수정 |
| 2 | 깨진 링크 (subscription_system_spec) | design_master.md | 수정 |
| 3 | ConnectionStatus 용어 혼동 | glossary.md | 수정 |
| 4 | 프로필 탭 20→10 미반영 | design_master.md | 수정 |
| 5 | BookingStatus 코드 불일치 | lesson_master.md | 수정 |
| 6 | 각종 깨진 링크 | 다수 | 수정 |

---

## 5. Claude 작업 순서 가이드

### 새 기능 구현 시 체크리스트

```
1. 이 로드맵에서 Phase와 우선순위 확인
2. 해당 마스터 스펙 읽기 (Enum 정의, Provider 설계 포함)
3. 구현 파일 매핑 섹션에서 파일 위치 확인
4. Mock Repository 먼저 구현
5. Entity → Repository → Provider → Widget → Screen 순서
6. flutter analyze 통과 확인
7. 관련 스펙 변경 이력 업데이트
```

### 스펙 참조 우선순위

```
1순위: 마스터 스펙 (lesson_master, practice_master, ...)
2순위: 도메인별 상세 스펙 (attendance_spec, gamification_spec, ...)
3순위: 디자인 스펙 (design_master, ux_guidelines)
4순위: 스키마 (schema/entities/)
5순위: 이 로드맵 (implementation_roadmap_v2.md)
```

---

## 6. 관련 문서

| 문서 | 역할 |
|------|------|
| [feature_hub.md](../feature_hub.md) | 기능 매트릭스 + Pain Point 매핑 |
| [DOCUMENT_INDEX.md](../../DOCUMENT_INDEX.md) | 문서 네비게이션 |
| [teacher_ux_review.md](../design/teacher_ux_review.md) | UX 검토 보고서 (#63~#73) |
| [gamification_spec.md](../practice/gamification_spec.md) | 게이미피케이션 스펙 (신규) |
| [analytics_dashboard_spec.md](../analytics/analytics_dashboard_spec.md) | 통계 대시보드 스펙 |
| [attendance_spec.md](../lesson/attendance_spec.md) | 출석 관리 스펙 |
| [beta_readiness.md](beta_readiness.md) | 베타 출시 준비 체크리스트 |

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-03-11 | Phase 2-1(통계), 2-3(게이미피케이션) 구현 완료 반영 |
| 2026-03-07 | v2 작성 — 전체 스펙 검토 기반, 4 Phase 로드맵, 경쟁사 분석 반영 |
