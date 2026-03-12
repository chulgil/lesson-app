# 게이미피케이션 마스터 스펙

> 마지막 업데이트: 2026-03-12
> 구현 상태: ✅ Phase 1 완료 (포인트/레벨/뱃지)
> 관련 PR: #98

---

## 1. 개요

연습/레슨 활동에 대한 포인트 적립, 레벨업, 뱃지 획득 시스템.
학생의 연습 동기 부여와 성취감 제공이 목적.

## 2. 주요 기능

### 2.1 포인트 시스템
- 연습 완료, 스트릭 유지, 레슨 참석 등 활동별 포인트 적립
- 일일/주간 포인트 집계

### 2.2 레벨 시스템
- 누적 포인트 기반 레벨업
- 레벨별 칭호 부여

### 2.3 뱃지 시스템
- 특정 조건 달성 시 뱃지 획득
- 뱃지 컬렉션 화면에서 조회

## 3. 코드 위치

| 레이어 | 파일 |
|--------|------|
| 엔티티 | `features/gamification/domain/entities/gamification.dart` |
| Provider | `features/gamification/presentation/providers/gamification_provider.dart` |
| 화면 | `features/gamification/presentation/screens/badge_collection_screen.dart` |

## 4. 엔티티 스키마

→ [docs/schema/entities/gamification.md](../../schema/entities/gamification.md)

## 5. 향후 계획

- Phase 2: 리더보드 (선생님 내 학생 랭킹)
- Phase 3: 도전 과제 (주간/월간 미션)
