# 레슨 앱 개발 태스크

> 음악 레슨/연습 관리 앱 개발 태스크 목록
> 최종 업데이트: 2026-01-24

---

## 현재 상태

```
Phase 0: UI 설계 & 검증 ✅ 완료
    ↓
Phase 1: Flutter 구현 ✅ 완료
    ↓
Phase 2: 기능 고도화 🔄 진행중
    ↓
Phase 3: 백엔드 연동 (FastAPI) 📋 예정
    ↓
Phase 4: 배포 & 고도화 📋 예정
```

---

## 최근 완료 작업 (2026-01-24)

### 코드 품질 개선 ✅

| 작업 | 상태 | 내용 |
|------|:----:|------|
| Flutter Analyze 경고 수정 | ✅ | 미사용 코드 삭제 |
| 인증 하드코딩 제거 | ✅ | `currentUserIdProvider` 통합 |
| StateNotifier → @riverpod | ✅ | `ReportDate`, `StreakNotifier` 마이그레이션 |
| 엔티티 색상 통합 | ✅ | 11개 enum → AppColors |
| 대형 파일 분리 | ✅ | lesson_form_widgets, student_form_widgets, practice_repertoire_repository |

### 파일 구조 변경

**lesson_form/ (신규)**
```
lib/features/lessons/presentation/widgets/
├── lesson_form_widgets.dart          # Barrel file
└── lesson_form/                      # 11개 위젯 파일
```

**student_form/ (신규)**
```
lib/features/students/presentation/widgets/
├── student_form_widgets.dart         # Barrel file
└── student_form/                     # 12개 위젯 파일
```

**repositories/impl/ (신규)**
```
lib/repositories/
├── practice_repertoire_repository.dart  # Interface
└── impl/
    ├── practice_repository_base.dart
    ├── mock_practice_repertoire_impl.dart
    └── mixins/                          # 6개 mixin 파일
```

---

## 개발 순서 (원본)

---

## Phase 0: UI 설계 & 검증 (2주)

> **디자인 경험 없어도 OK** - 박스와 텍스트로 기능 배치만 하면 됨

### Week 1: 와이어프레임 & 프로토타입

#### Figma 시작하기 (1시간)
- [ ] Figma 계정 생성 (figma.com)
- [ ] 유튜브 "Figma 기초" 15분 시청
- [ ] 새 프로젝트 생성: "Lesson App"
- [ ] Figma Community에서 "Mobile App UI Kit" 검색 → 복사

#### 핵심 화면 와이어프레임 (7개)

> **팁**: 예쁘게 안 해도 됨. 박스 + 텍스트로 "여기 버튼", "여기 목록" 수준으로

- [ ] **1. 로그인/회원가입** (30분)
  ```
  ┌─────────────┐
  │   로고      │
  │             │
  │ [Google 로그인] │
  │ [Kakao 로그인]  │
  └─────────────┘
  ```
- [ ] **2. 메인 대시보드 (선생님용)** (1시간)
  ```
  ┌─────────────┐
  │ 오늘의 레슨  │
  │ ┌─────────┐ │
  │ │학생A 3시│ │
  │ │학생B 5시│ │
  │ └─────────┘ │
  │ [학생관리] [일정] │
  └─────────────┘
  ```
- [ ] **3. 메인 대시보드 (학생용)** (1시간)
  - 다음 레슨 카드
  - 이번 주 연습 현황 (원형 프로그레스)
  - [연습 시작] 버튼
- [ ] **4. 학생 관리 목록** (1시간)
  - 학생 카드 리스트
  - 검색바
  - [+] 학생 추가 버튼
- [ ] **5. 레슨 캘린더** (1시간)
  - 월간 캘린더 (날짜에 점 표시)
  - 선택한 날짜의 레슨 목록
- [ ] **6. 레슨 상세** (1시간)
  - 레슨 정보 헤더
  - 🔴 큰 녹음 버튼
  - 레슨 노트 텍스트 영역
  - 연습 과제 체크리스트
- [ ] **7. 연습 체크리스트** (1시간)
  - 체크박스 리스트
  - 각 항목에 메모 버튼
  - [완료] 버튼

#### 프로토타입 연결 (1시간)
- [ ] 화면 간 네비게이션 연결 (버튼 클릭 → 다음 화면)
- [ ] 프로토타입 링크 생성 (공유용)

### Week 2: 사용자 테스트 & UI 다듬기

#### 사용자 테스트 (가능하면)
- [ ] 선생님 1명에게 프로토타입 보여주기
- [ ] 학생 1명에게 프로토타입 보여주기
- [ ] 피드백 메모

#### 피드백 반영 & UI 다듬기
- [ ] 큰 문제점 수정
- [ ] Material Design 컴포넌트로 교체
  - Figma Community "Material 3 Design Kit" 검색
- [ ] 색상 통일 (3색 이내)
- [ ] 폰트 통일

#### 최종 정리
- [ ] 화면 확정
- [ ] 화면별 필요한 데이터 목록 정리 (→ API 설계용)

**예시:**
```
로그인 화면 → POST /auth/google, POST /auth/kakao
학생 목록 → GET /teachers/students
레슨 상세 → GET /lessons/{id}, POST /lessons/{id}/records
```

---

## Phase 1: API 설계 & 백엔드 (3-4주)

### Week 3: 프로젝트 셋업 & 설계

#### API 명세 작성
- [ ] 화면별 필요 API 목록 정리
- [ ] OpenAPI 명세 작성 (`docs/api_spec.yaml`)
- [ ] API 엔드포인트 설계
  - `/auth/*` - 인증
  - `/users/*` - 사용자
  - `/lessons/*` - 레슨
  - `/templates/*` - 템플릿
  - `/practices/*` - 연습

#### DB 스키마 설계
- [ ] ERD 작성
- [ ] 테이블 설계
  - `users` - 사용자 (선생님/학생)
  - `teacher_student` - 선생님-학생 관계
  - `lessons` - 레슨 일정
  - `lesson_records` - 레슨 기록
  - `lesson_templates` - 레슨 템플릿
  - `template_items` - 템플릿 항목
  - `practices` - 연습 기록
  - `practice_items` - 연습 항목
  - `recordings` - 녹음 파일
- [ ] SQL 스키마 작성 (`schema/lesson_app_schema.sql`)

#### 프로젝트 셋업
- [ ] FastAPI 프로젝트 생성 (`uv init lesson-api`)
- [ ] 의존성 추가
  ```
  fastapi, uvicorn, sqlalchemy, pymysql,
  python-jose, passlib, authlib, boto3
  ```
- [ ] 프로젝트 구조 설정
  ```
  lesson-api/
  ├── src/
  │   ├── api/           # API 라우터
  │   ├── core/          # 설정, 보안
  │   ├── db/            # DB 연결, 모델
  │   ├── schemas/       # Pydantic 스키마
  │   └── services/      # 비즈니스 로직
  ├── tests/
  └── docs/
  ```
- [ ] MySQL 연결 설정 (codenavi 서버)
- [ ] Vultr Object Storage 연결 설정

### Week 4: 인증 & 사용자 API

#### OAuth 인증 구현
- [ ] Google OAuth 설정
  - [ ] Google Cloud Console 프로젝트 생성
  - [ ] OAuth 클라이언트 ID 발급
  - [ ] 콜백 URL 설정
- [ ] Kakao OAuth 설정
  - [ ] Kakao Developers 앱 등록
  - [ ] REST API 키 발급
  - [ ] 콜백 URL 설정
- [ ] JWT 토큰 발급/검증 구현
- [ ] 인증 API 구현
  - `POST /auth/google` - Google 로그인
  - `POST /auth/kakao` - Kakao 로그인
  - `POST /auth/refresh` - 토큰 갱신
  - `POST /auth/logout` - 로그아웃

#### 사용자 API 구현
- [ ] 사용자 CRUD
  - `GET /users/me` - 내 정보
  - `PUT /users/me` - 내 정보 수정
  - `GET /users/{id}` - 사용자 조회
- [ ] 선생님-학생 관계
  - `POST /teachers/students` - 학생 연결
  - `GET /teachers/students` - 학생 목록
  - `DELETE /teachers/students/{id}` - 학생 연결 해제

### Week 5: 레슨 API

#### 레슨 일정 API
- [ ] 레슨 CRUD
  - `POST /lessons` - 레슨 생성
  - `GET /lessons` - 레슨 목록 (필터: 날짜, 학생)
  - `GET /lessons/{id}` - 레슨 상세
  - `PUT /lessons/{id}` - 레슨 수정
  - `DELETE /lessons/{id}` - 레슨 삭제
- [ ] 레슨 기록
  - `POST /lessons/{id}/records` - 레슨 기록 저장
  - `GET /lessons/{id}/records` - 레슨 기록 조회

#### 레슨 템플릿 API
- [ ] 템플릿 CRUD
  - `POST /templates` - 템플릿 생성
  - `GET /templates` - 템플릿 목록
  - `GET /templates/{id}` - 템플릿 상세
  - `PUT /templates/{id}` - 템플릿 수정
  - `DELETE /templates/{id}` - 템플릿 삭제
- [ ] 템플릿 항목
  - `POST /templates/{id}/items` - 항목 추가
  - `PUT /templates/{id}/items/{item_id}` - 항목 수정
  - `DELETE /templates/{id}/items/{item_id}` - 항목 삭제

### Week 6: 연습 API & 문서화

#### 연습 체크리스트 API
- [ ] 연습 기록 CRUD
  - `POST /practices` - 연습 기록 생성
  - `GET /practices` - 연습 목록 (필터: 날짜, 레슨)
  - `GET /practices/{id}` - 연습 상세
  - `PUT /practices/{id}` - 연습 수정
- [ ] 연습 항목
  - `PUT /practices/{id}/items/{item_id}` - 항목 완료 체크
  - `POST /practices/{id}/items/{item_id}/memo` - 메모 추가

#### API 문서화 & 테스트
- [ ] Swagger UI 설정
- [ ] API 문서 자동 생성
- [ ] Postman 컬렉션 생성
- [ ] API 테스트 작성 (pytest)
- [ ] codenavi 서버 배포

---

## Phase 2: Flutter 구현 (3-4주)

### Week 7: 프로젝트 셋업 & 인증

#### Flutter 프로젝트 셋업
- [ ] Flutter 프로젝트 생성
- [ ] 의존성 추가
  ```yaml
  dependencies:
    dio: ^5.x
    riverpod: ^2.x
    go_router: ^x.x
    flutter_secure_storage: ^x.x
    google_sign_in: ^x.x
    kakao_flutter_sdk: ^x.x
  ```
- [ ] 프로젝트 구조 설정
  ```
  lib/
  ├── core/           # 설정, 테마, 유틸
  ├── data/           # API, 모델
  ├── presentation/   # 화면, 위젯
  ├── providers/      # 상태관리
  └── main.dart
  ```

#### 인증 화면 구현
- [ ] 로그인 화면
  - Google 로그인 버튼
  - Kakao 로그인 버튼
- [ ] 역할 선택 화면 (첫 로그인 시)
- [ ] 토큰 저장/관리
- [ ] 인증 상태 관리 (Riverpod)

### Week 8: 대시보드 & 학생 관리

#### 대시보드 화면
- [ ] 선생님 대시보드
  - 오늘의 레슨 목록
  - 학생 요약
  - 빠른 액션
- [ ] 학생 대시보드
  - 다음 레슨 카드
  - 이번 주 연습 현황
  - 연습 시작 버튼

#### 학생 관리 화면
- [ ] 학생 목록 화면
  - 학생 카드 컴포넌트
  - 검색/필터
- [ ] 학생 추가 (초대 코드 또는 검색)
- [ ] 학생 상세 화면

### Week 9: 레슨 캘린더 & 상세

#### 캘린더 화면
- [ ] 캘린더 컴포넌트 (table_calendar 패키지)
- [ ] 월간/주간 뷰 전환
- [ ] 레슨 일정 표시 (dot indicator)
- [ ] 일정 추가/수정 모달

#### 레슨 상세 화면
- [ ] 레슨 정보 표시
- [ ] 레슨 노트 작성
- [ ] 연습 과제 목록
- [ ] (녹음 UI는 Phase 3에서)

### Week 10: 연습 체크리스트 & 오프라인

#### 연습 체크리스트 화면
- [ ] 체크리스트 화면
  - 템플릿 기반 항목 표시
  - 체크박스 토글
  - 간단 메모 입력
- [ ] 연습 기록 목록
- [ ] 연습 상세/수정

#### 오프라인 지원
- [ ] 로컬 DB 설정 (Hive)
- [ ] 데이터 캐싱
- [ ] 오프라인 상태 감지
- [ ] 동기화 로직

---

## Phase 3: 녹음 + AI 기능 (3-4주)

### Week 11: 녹음 기능

#### Flutter 녹음 구현
- [ ] record 패키지 설정
- [ ] 녹음 UI
  - 큰 원형 녹음 버튼
  - 녹음 시간 표시
  - 파형 시각화 (optional)
- [ ] 녹음 파일 로컬 저장
- [ ] 녹음 파일 업로드 (Vultr)

#### 백엔드 녹음 API
- [ ] 파일 업로드 API
  - `POST /recordings/upload` - Presigned URL 발급
  - `POST /lessons/{id}/recordings` - 녹음 메타데이터 저장
- [ ] 파일 조회 API
  - `GET /recordings/{id}` - 녹음 파일 URL

### Week 12: AI 연동

#### Whisper 연동
- [ ] OpenAI Whisper API 연동
- [ ] 음성→텍스트 변환 서비스
- [ ] 비동기 처리 (Celery)
- [ ] 변환 결과 저장

#### Claude 연동
- [ ] Anthropic Claude API 연동
- [ ] 텍스트 요약 프롬프트 설계
- [ ] 연습 과제 추출 프롬프트
- [ ] AI 결과 저장

### Week 13-14: AI 결과 표시 & 연습 과제

#### AI 결과 UI
- [ ] 레슨 상세에 AI 요약 표시
- [ ] 추출된 연습 과제 표시
- [ ] 연습 과제 수정/확정

#### 자동 연습 과제 생성
- [ ] AI 추출 결과 → 템플릿 항목 자동 생성
- [ ] 선생님 확인/수정
- [ ] 학생에게 푸시

#### 테스트 & 버그 수정
- [ ] 전체 플로우 테스트
- [ ] 버그 수정
- [ ] 성능 최적화

---

## Phase 4: 고도화 & 배포 (이후)

### 푸시 알림
- [ ] Firebase Cloud Messaging 설정
- [ ] 레슨 리마인더
- [ ] 연습 알림

### 통계/리포트
- [ ] 연습 통계 대시보드
- [ ] 주간/월간 리포트
- [ ] 진도 차트

### 앱스토어 배포
- [ ] Apple Developer 등록
- [ ] App Store 심사 준비
- [ ] Google Play 심사 준비
- [ ] 베타 테스트 (TestFlight, 내부 테스트)

### 결제 시스템 (선택)
- [ ] 구독 모델 설계
- [ ] 결제 연동 (Stripe 또는 인앱결제)

---

## 참고 문서

- [요구사항 정의](requirement.md)
- [경쟁사 분석](competitive_analysis.md)
- [기술 의사결정](tech_decision.md)
