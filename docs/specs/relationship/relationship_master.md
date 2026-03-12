# 선생님-학생 관계 마스터 스펙

> 마지막 업데이트: 2026-03-12
> 구현 상태: ✅ 구현 완료
> 관련 코드: `features/relationship/`

---

## 1. 개요

선생님-학생 간 연결(relationship) 상태 관리. 수강권 기반 관계 모델(V2)로 전환 완료.

## 2. 주요 기능

### 2.1 관계 생성
- 초대 시스템을 통한 연결 (QR/URL/코드)
- 수강권 발급 시 자동 연결

### 2.2 관계 상태 관리
- 연결 상태: pending, active, inactive, blocked
- 관계 해제/차단

### 2.3 데이터 구조
- Mock + Remote Repository 이중 구현

## 3. 코드 위치

| 레이어 | 파일 |
|--------|------|
| 엔티티 | `features/relationship/domain/entities/` |
| Repository | `features/relationship/data/repositories/` (mock + remote) |
| Provider | `features/relationship/presentation/providers/` |

## 4. 관련 마스터 스펙

- 초대: [follow_master.md](../follow/follow_master.md)
- 수강권 기반 관계: [subscription_master.md](../subscription/subscription_master.md) §관계 모델
- 사용자 관리: [user_master.md](../user/user_master.md) §4
