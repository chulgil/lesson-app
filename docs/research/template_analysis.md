# Music App UI Kit 템플릿 분석

> **참조 템플릿**: [Music App UI Kit - Community](https://www.figma.com/design/xydMYjbMvpS1o89KMXtNKZ/Music-App-UI-Kit---Community--Community-)
>
> **목표**: 이 템플릿의 디자인 스타일을 참고하여 Lesson App UI 제작

---

## 1. 템플릿 구조

### 1.1 페이지 구성

| 페이지 | 내용 | 활용 방안 |
|--------|------|-----------|
| **Showcase** | 커뮤니티 커버 이미지 | 앱스토어 스크린샷 참고 |
| **💎 Design System** | 색상, 타이포그래피, 아이콘, 버튼 | **그대로 활용** (커스텀 색상만 변경) |
| **🎨 Design** | Light/Dark Mode 각 29개 화면 | **화면 구조 참고** |

### 1.2 디자인 시스템 구성요소

```
💎 Design System
├── Color Setup          # 색상 팔레트
├── Typography Setup     # 폰트 스타일
├── Icon Setup           # 아이콘 세트
├── Buttons              # 버튼 컴포넌트
└── System Defaults      # iOS 시스템 UI (Status Bar, Home Indicator)
```

---

## 2. 템플릿 화면 목록 (29개)

### 2.1 인증 플로우 (9개)

| # | 화면명 | 설명 | Lesson App 매핑 |
|---|--------|------|-----------------|
| 01 | Splash Screen | 앱 시작 화면 | ✅ 스플래시 |
| 02 | Onboarding 1 | 온보딩 첫 번째 | ✅ 온보딩 1 |
| 03 | Onboarding 2 | 온보딩 두 번째 | ✅ 온보딩 2 |
| 04 | Onboarding 3 | 온보딩 세 번째 | ✅ 온보딩 3 |
| 05 | Login | 로그인 | ✅ **로그인** |
| 06 | Signup | 회원가입 | ✅ **회원가입** |
| 07 | Confirm Phone Number | 전화번호 확인 | ❌ 불필요 (소셜 로그인) |
| 08 | Enter OTP | OTP 입력 | ❌ 불필요 |
| 09 | Account Create Successfully | 가입 완료 | ✅ 가입 완료 |

### 2.2 메인 기능 (14개)

| # | 화면명 | 설명 | Lesson App 매핑 |
|---|--------|------|-----------------|
| 10 | Home Page | 홈 대시보드 | ✅ **메인 대시보드** |
| 11 | Favourite Artists | 아티스트 목록 | → **학생 관리 목록** |
| 12 | Arman Malik | 아티스트 상세 | → **학생 상세 정보** |
| 13 | Popular Songs | 인기곡 목록 | → **레슨 기록 목록** |
| 14 | Top Playlists | 플레이리스트 목록 | → **연습 과제 목록** |
| 15 | Open Playlist | 플레이리스트 상세 | → **레슨 상세** |
| 16 | Play Song | 음악 재생 | → **녹음 재생** |
| 17 | Song Minimise | 미니 플레이어 | → 미니 녹음 플레이어 |
| 18 | Search | 검색 | ✅ 검색 |
| 19 | Playlists | 플레이리스트 관리 | → **레슨 캘린더** |
| 20 | Add New Playlist | 새 플레이리스트 | → 새 레슨 추가 |
| 21 | My Playlist | 내 플레이리스트 | → **연습 체크리스트** |
| 22 | Add Songs | 곡 추가 | → 연습 항목 추가 |
| 23 | My Profile | 프로필 | ✅ 프로필 |

### 2.3 결제/설정 (6개)

| # | 화면명 | 설명 | Lesson App 매핑 |
|---|--------|------|-----------------|
| 24 | Premium Plans | 구독 플랜 | → 선생님 구독 (Phase 4) |
| 25 | Payment Method | 결제 수단 | → Phase 4 |
| 26 | Order Review | 주문 확인 | → Phase 4 |
| 27 | Payment Complete | 결제 완료 | → Phase 4 |
| 28 | Terms & Conditions | 이용약관 | ✅ 이용약관 |
| 29 | Privacy Policy | 개인정보처리방침 | ✅ 개인정보처리방침 |

---

## 3. Lesson App 화면 매핑

### 3.1 Phase 0 핵심 화면 (7개)

| # | Lesson App 화면 | 템플릿 참조 | 주요 변경점 |
|---|-----------------|------------|------------|
| 1 | 로그인/회원가입 | 05 Login, 06 Signup | Google/Kakao 버튼 추가 |
| 2 | 선생님 대시보드 | 10 Home Page | 레슨 일정, 학생 현황 카드 |
| 3 | 학생 대시보드 | 10 Home Page 변형 | 다음 레슨, 연습 현황 |
| 4 | 학생 관리 목록 | 11 Favourite Artists | 학생 카드 + 레슨 상태 |
| 5 | 레슨 캘린더 | 19 Playlists | 캘린더 뷰 추가 |
| 6 | 레슨 상세 (녹음) | 15 Open Playlist + 16 Play Song | 녹음 버튼, 메모 영역 |
| 7 | 연습 체크리스트 | 21 My Playlist | 체크박스 추가 |

### 3.2 추가 화면 (Phase 0)

| # | 화면 | 템플릿 참조 | 비고 |
|---|------|------------|------|
| 8 | 스플래시 | 01 Splash Screen | 앱 로고 |
| 9 | 온보딩 (3개) | 02-04 Onboarding | 앱 소개 |
| 10 | 프로필 | 23 My Profile | 사용자 정보 |
| 11 | 검색 | 18 Search | 학생/레슨 검색 |

---

## 4. 디자인 시스템 커스터마이징

### 4.1 색상 팔레트 (Lesson App)

```
Primary (보라)      : #6B5B95  → 클래식 음악 느낌
Secondary (샌디)    : #F4A460  → 바이올린 나무색
Background (아이보리): #FFFAF5  → 부드러운 배경
Accent (녹색)       : #2E8B57  → 완료/성공
Error (크림슨)      : #DC143C  → 에러/경고

Dark Mode:
Primary            : #8B7BB5  → 밝은 보라
Background         : #1A1A2E  → 어두운 배경
Surface            : #252540  → 카드 배경
```

### 4.2 폰트

```
Heading : Pretendard Bold
Body    : Pretendard Regular
Music   : Noto Music (음악 기호용)
```

### 4.3 컴포넌트 재사용

| 템플릿 컴포넌트 | Lesson App 용도 |
|----------------|-----------------|
| Song Card | 레슨 카드, 연습 항목 카드 |
| Artist Card | 학생 카드 |
| Playlist Card | 레슨 일정 카드 |
| Play Button | 녹음 재생 버튼 |
| Progress Bar | 연습 진행률 |
| Tab Bar | 하단 네비게이션 |

---

## 5. 작업 순서

### Step 1: Design System 복제
1. 템플릿의 💎 Design System 페이지 복사
2. 색상 팔레트 커스터마이징
3. 아이콘 세트 검토 (음악 → 레슨 관련 추가)

### Step 2: 화면 프레임 생성
1. 핵심 7개 화면 프레임 생성 (iPhone 14 Pro - 393x852)
2. 템플릿 화면 구조 참고하여 레이아웃 배치

### Step 3: 컴포넌트 조립
1. 템플릿 컴포넌트 복사
2. 텍스트/아이콘만 Lesson App 용도로 수정

### Step 4: 프로토타입 연결
1. 화면 간 플로우 연결
2. 클릭 가능한 프로토타입 제작

---

## 참고 문서

- [요구사항 정의](../requirement.md)
- [기술 의사결정](../tech_decision.md)
- [화면별 상세 명세서](./screen_specs.md)
