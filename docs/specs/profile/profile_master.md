# 프로필 마스터 스펙

> 마지막 업데이트: 2026-03-12
> 구현 상태: ✅ 구현 완료
> 관련 코드: `features/profile/`

---

## 1. 개요

선생님 프로필 관리, 확장 프로필(경력/자격/학력), 초대 시스템, 리뷰, 결제 관리 화면 제공.

## 2. 주요 기능

### 2.1 선생님 프로필 탭
- 프로필 헤더 (이름, 사진, 악기, 소개)
- 확장 프로필 (경력, 자격증, 학력)
- 레슨 시간 설정
- 팁 템플릿 관리
- 결제 관리 (미수금, 입금 확인)

### 2.2 초대 시스템
- QR/URL/코드 기반 초대 발송
- 초대 상태 추적

### 2.3 리뷰 시스템 (설계)
- 학생 → 선생님 리뷰 작성
- 선생님 응답

## 3. 코드 위치

| 레이어 | 파일 |
|--------|------|
| 엔티티 | `features/profile/domain/entities/` (invite, review, teacher, teacher_profile 등) |
| Provider | `features/profile/presentation/providers/` (invite, profile, extended_profile) |
| 화면 | `features/profile/presentation/screens/` (profile_tab, extended_profile 등 12개) |

## 4. 관련 마스터 스펙

- 초대: [user_master.md](../user/user_master.md) §3
- 리뷰: [user_master.md](../user/user_master.md) §6
