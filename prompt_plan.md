# 수강 관리 탭 UX 재설계 계획 (Status Triage 모델)

> 작성일: 2026-04-24
> 모드: `/plan --ceo` → `--eng` 전환
> 상태: 스펙 완료 — 사용자 승인 대기
> 스펙 문서: [docs/specs/student/enrollment_management_ux_spec.md](docs/specs/student/enrollment_management_ux_spec.md)

## 요구사항 (확정)

1. 설계 방향: **A (Status Triage)** — 학생 primary, 수강권 visual layer
2. 범위: **A + B + 자동 갱신 알림** (10x Vision minus AI 이탈 예측)
3. 배너 3칸: 만료임박 / 미결제 / 체험중
4. 보관 정책: 영구 보관 (삭제 없음)
5. 인라인 CTA: [갱신 제안] [레슨 추가] (추가 없음)

## Phase 실행 계획

| Phase | 내용 | 파일 | 복잡도 | 상태 |
|------|------|-----|--------|------|
| 1. Foundation | `StudentRosterSummary` provider + `RosterSummary` 엔티티 + 필터 enum 확장 | 3 | L | ⏸️ 대기 |
| 2. Triage Banner | `RosterTriageBanner` 위젯 + students_tab 통합 + 탭→필터 연결 | 2 | M | ⏸️ |
| 3. Filter Chip 확장 | expiring/unpaid/trial/archive 필터 로직 | 2 | L | ⏸️ |
| 4. Card 재설계 | 진행 bar + D-day chip + 인라인 CTA + archive 모드 | 1 | M | ⏸️ |
| 5. 자동 갱신 알림 | `SubscriptionExpiryNotificationService` + 설정 토글 | 3-4 | M | ⏸️ |
| 6. 문서 동기화 | 스펙 완료 처리 + notebook §7.117 기록 | 2 | XS | ⏸️ |

**총 예상 파일**: 10-12 / **총 공수**: 12-16h

## Phase 순서 논리

```
Phase 1 (데이터)
   ↓
Phase 2 (배너 가시화) ← 첫 가시 가치
   ↓
Phase 3 (필터 연결) ← 배너 클릭 동작 완성
   ↓
Phase 4 (카드 재설계) ← 디테일 완성
   ↓
Phase 5 (알림 시스템) ← 화면 밖으로 확장
   ↓
Phase 6 (문서)
```

## 리스크

| 리스크 | 등급 | 완화 |
|-------|------|------|
| 카운트 계산 성능 | MED | 기존 Provider 재사용, 로컬 계산 |
| 카드 높이 증가 | MED | 카드 +12px 이내 유지 |
| 영구 보관 리스트 비대화 | LOW | archive 기본 숨김 |
| 알림 권한 미부여 | MED | in-app 뱃지 fallback |

## 예상 복잡도: HIGH (12-16시간)

## 게이트 정책

- Phase 1~4 (UI 중심) 완료 후 사용자 실기 확인
- Phase 5 (알림) 는 별도 세션 분리 가능
- 각 Phase 완료 = 단일 커밋 + analyze 통과

## Lore (비가역 결정)

- **Lore-directive**: 학생 = primary entity. 리스트 행 단위는 절대 수강권으로 전환하지 않음.
- **Lore-constraint**: 만료 학생 영구 보관 — 자동 삭제 없음.
- **Lore-rejected**: Two-tab 완전 분리 — 필터 chip 으로 충분.
- **Lore-rejected**: AI 이탈 예측 — 데이터 부족.

---

## 이전 계획

학생 화면 Notebook × Score 전수 감사 (2026-04-23~24) — Phase 1~5 전부 반영 완료. `git log prompt_plan.md` 로 추적.
