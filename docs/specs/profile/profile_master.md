# 프로필 마스터 스펙

> 마지막 업데이트: 2026-04-15
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

### 2.4 계좌 관리 (2026-03 추가)
- **BankAccountEditScreen**: 강사 입금 계좌 목록 관리 (추가/삭제/기본계좌 설정)
- **OutstandingPaymentsScreen**: 미수금 관리 — 학생별 미수금 현황 조회 및 입금 확인 처리
- **BasicInfoEditScreen**: 기본 정보 (이름, 연락처 등) 수정
- **ProfilePreviewScreen**: 공개 프로필 미리보기 (학생에게 보이는 화면)

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
