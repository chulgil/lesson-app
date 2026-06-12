# 출시 준비도 스펙 감사 — 가입 → 설정 → 수강권 → 스케줄

> 감사일: 2026-06-12
> 범위: 선생님/학생/학부모 가입·온보딩, 설정·프로필, 수강권 발급·입금, 일정 변경
> 방법: 4개 도메인 병렬 스펙 리뷰 → 주장별 코드/스펙 대조 스팟체크 → 확정/기각 분류
> 목적: 실제 출시 시 사용자 호응(전환·리텐션) 저해 요인 식별

## 판정 요약

| 영역 | 흐름 완결성 | 출시 호응 리스크 | 판정 |
|------|------------|----------------|------|
| 가입/온보딩 | 선생님 v3 높음 / 학생·학부모 보통 | 전화인증 게이트 시점 | 조건부 Go |
| 설정/프로필 | 높음 (95% 구현) | 알림 설정 UI 미구현 | 조건부 Go |
| 수강권 | 높음 (E2E 정의됨) | 입금 대기 가시성 (→ 본 감사로 스펙 보강) | Go |
| 스케줄 | 높음 (턴 기반) | 요청 만료 부재 (→ 본 감사로 스펙 보강) | Go |

## 본 감사에서 스펙 반영 완료 (2건)

| # | 이슈 | 반영 위치 |
|---|------|----------|
| 1 | **일정 변경 요청 만료 정책 부재** (P0) — 무응답 시 영구 대기 가능. grep 검증: 스펙 내 만료/timeout 0건 | [subscription_schedule_change_spec.md §8](../schedule/subscription_schedule_change_spec.md) — 72h 만료 + 24h 리마인드 + 변경권 복원 |
| 2 | **입금 확인 대기 가시성 부재** (P1) — `paymentNotified` 상태에 선생님 액션만 정의, 학생/학부모 대기 화면 미명세 | [subscription_master.md §3.2.4](../subscription/subscription_master.md) — 즉시 피드백 + 3단계 프로그레스 + 24h 선생님 리마인드 |

## 검증 후 기각된 주장 (2건)

리뷰 에이전트 발견 중 코드/스펙 대조에서 사실과 다른 것으로 확인:

| 주장 | 기각 근거 |
|------|----------|
| "초대 재발송/회수 UI 구현 0건" | `invite_pending_list_screen.dart`, `invite_pending_card.dart`, `pending_invite.dart` 존재 + `AppStrings.invitePendingResendLabel` 정의됨. 스펙(invite_lifecycle_spec.md)과 구현 모두 존재 |
| "학부모 빈 화면에 초대코드 경로 없음" | user_master.md L339 "자녀를 등록해주세요 + [초대 코드 입력하기] 버튼", L1261 자녀 0명 빈 상태 정의됨 |

## 미반영 발견 — 후속 이슈 권장 (우선순위순)

### P1 — 출시 전 결정 필요 (2026-06-12 전건 스펙 반영 완료)

> 4개 병렬 worktree 로 분담 처리 후 main 병합. 구현은 별도 (스펙만 확정).

| # | 이슈 | 반영 결과 |
|---|------|----------|
| 1 | **알림 설정 화면 미구현** — 설정 메뉴는 존재하나 기능 없음 (#15 플레이스홀더 위반 가능) | 반영 완료 — 마스터+6카테고리 토글 Phase 1.5 승격 (notification_master.md §6, push_notification_settings_spec.md §10) |
| 2 | **전화인증 E3 게이트 마찰** — "나중에" 선택 시 제안 중단 후 복구 경로 미명세 | 반영 완료 — 제안 draft 임시저장(7일) + 복구 배너 + 계측 이벤트 5종 (phone_verification_policy.md v1.2) |
| 3 | **변경권 정책 3개 문서 산재** — 차감/복원 규칙 분산 | 반영 완료 — SSOT 신설 [reschedule_credit_spec.md](../subscription/reschedule_credit_spec.md), 기존 문서는 포인터. 단 **모순 1건 결정 필요**: 마감 24h 고정 vs `rescheduleDeadlineHours` 수강권별 재정의 (SSOT §3 표시) |
| 4 | **수강권 중복 제안 차단 미명세** | 반영 완료 — 동일 학생 활성 제안 1개 제약 + 경고 다이얼로그 (subscription_master.md §3.1.5) |
| 5 | **설정 진입점 이중화** — 레슨 시간 설정 양쪽 노출 가능성 | 반영 완료 — 조사 결과 LessonTimeSettingsScreen 은 이미 해체됨(W2 Task 2.5), 스펙 서술만 어긋남 → 현황 정정 (profile_master.md §G, settings_master.md §6) |

### P2 — 출시 후 개선

| # | 이슈 | 위치 |
|---|------|------|
| 6 | 제안 만료(7일) 후 학생 화면에 "만료되었어요" 상태 표시 미명세 | subscription_master.md §3.2.2 |
| 7 | 학생 직접 가입 차단(StudentSignupBlockedScreen) 해제 조건/기한 미명시 | phone_verification_policy.md §3.4 |
| 8 | 역제안 라운드 제한 미정의 — 초기 신청은 2라운드 제한, 일정 변경은 무제한 | subscription_schedule_change_spec.md §3.2 |
| 9 | 일괄 변경 시 슬롯 동시성(2학생 동일 슬롯 경쟁) 잠금 전략 미명세 | subscription_schedule_change_spec.md |
| 10 | 차감 복원 감사 로그 (usedLessons 수동 보정 이력) 부재 | subscription_master.md §5.1 |
| 11 | 알림 일일 한도(master §2.5.2)와 카테고리 기본 ON(push_settings §3.2) 상호 참조 누락 | notification/ 양쪽 |
| 12 | 백업 복원 마이너 버전 역호환 규칙 미명시 | settings_master.md |
| 13 | 프로필 완성도 알림의 "신규 선생님" 정의가 두 스펙에서 상이 | profile_master.md §2.2 vs notification_master.md §2.2 |

## 출시 호응 관점 종합 — Top 3 행동 권고

1. **대기 상태에 침묵 금지** (본 감사 반영 완료): 일정 변경 무응답 만료(§8) + 입금 확인 대기 피드백(§3.2.4). 양면 마켓 앱에서 "상대방 액션 대기" 구간의 무피드백은 이탈 1순위 — 두 곳 모두 시간 상한 + 진행 표시 + 종료 알림으로 보강.
2. **첫 가치 도달 전 마찰 최소화**: 전화인증을 첫 수강권 발급 순간(동기 최고점)에 두는 현 정책은 유지하되, "나중에" 이탈 경로의 복구를 명시해 제안 유실을 막을 것 (P1-2).
3. **기능 없는 메뉴 제거**: 알림 설정 메뉴가 빈 화면이면 "앱이 깨졌다" 인상 → 별점 하락 직결. 토글 최소셋 출시 또는 진입점 숨김 중 택일 (P1-1).

## 후속 작업

- [ ] P1 5건 → GitHub 이슈 생성 (`domain:` 라벨별)
- [ ] §8 / §3.2.4 구현 (BE 만료 배치 + FE 상태 UI)
- [ ] P2 13건 → 다음 분기 스펙 정리 사이클에 포함
