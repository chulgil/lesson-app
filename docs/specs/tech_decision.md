# 기술 의사결정 문서

> 음악 레슨/연습 관리 앱의 플랫폼 및 기술 스택 결정

---

## 1. 플랫폼 선택

### 1.1 선택지 비교

| 기준 | 네이티브 앱 | Flutter | PWA |
|------|------------|---------|-----|
| **백그라운드 녹음** | ✅ 완벽 | ✅ 완벽 | ❌ iOS 불가 |
| **푸시 알림** | ✅ | ✅ | ⚠️ iOS 제한 |
| **네이티브 UX** | 100% | 95% | 80% |
| **오프라인 사용** | ✅ | ✅ | ⚠️ 제한적 |
| **개발 비용** | 💰💰💰 (2개 앱) | 💰💰 (1개 코드) | 💰 |
| **코드 재사용** | 0% | 95% | 100% |
| **웹 지원** | 별도 개발 | Flutter Web | 기본 |
| **배포** | 스토어 심사 | 스토어 심사 | 즉시 |

### 1.2 결정: Flutter

**선택 이유:**

1. **녹음 기능 완벽 지원**: iOS/Android 백그라운드 녹음 가능 → 킬러 피처 구현
2. **네이티브 수준 UX**: 음악 앱에 필요한 반응성과 부드러운 애니메이션
3. **단일 코드베이스**: Dart 하나로 iOS/Android/Web 모두 커버
4. **Supabase 호환**: Flutter SDK 공식 지원
5. **성숙한 생태계**: 오디오/녹음 관련 패키지 풍부

**PWA 대비 장점:**
- iOS 백그라운드 녹음 가능 (PWA는 불가)
- 푸시 알림 완벽 지원
- 더 나은 오프라인 경험

---

## 2. 기술 스택

### 2.1 전체 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                          │
│              (iOS / Android / Web)                      │
└─────────────────────┬───────────────────────────────────┘
                      │ REST API
                      ▼
┌─────────────────────────────────────────────────────────┐
│                 Python FastAPI                          │
│            (Backend API Server)                         │
│               [codenavi 서버]                            │
└─────────────────────┬───────────────────────────────────┘
                      │
    ┌─────────────────┼─────────────────┐
    ▼                 ▼                 ▼
┌─────────┐   ┌─────────────┐   ┌───────────┐
│  MySQL  │   │    Vultr    │   │  AI APIs  │
│ (codenavi)│   │   Object    │   │ (Whisper/ │
│         │   │   Storage   │   │  Claude)  │
└─────────┘   └─────────────┘   └───────────┘
```

### 2.2 프론트엔드 (Flutter)

```yaml
Framework: Flutter 3.x
Language: Dart
State Management: Riverpod 또는 Bloc
UI Components: Material 3 + Custom Widgets
Audio: record, just_audio 패키지
Local Storage: Hive 또는 sqflite
HTTP Client: Dio
```

### 2.3 백엔드 (Python FastAPI)

```yaml
Framework: FastAPI
ORM: SQLAlchemy 2.0
Validation: Pydantic v2
Auth: 직접 구현 (OAuth2 + JWT)
File Upload: Vultr Object Storage (S3 호환)
Task Queue: Celery + Redis (녹음 처리용)
```

### 2.4 데이터베이스/인프라

```yaml
Database: MySQL 8.0 (codenavi 서버 - 기존 인프라 활용)
Auth: Google/Kakao OAuth 직접 구현
Storage: Vultr Object Storage (녹음 파일)
Hosting: codenavi 서버 (기존 인프라)
```

**기존 인프라 활용 장점:**
- 추가 비용 없음 (이미 운영 중인 서버)
- stock-alert 프로젝트와 동일한 환경
- 운영 노하우 재사용

### 2.5 AI 서비스

```yaml
음성→텍스트: OpenAI Whisper API
텍스트 요약: Anthropic Claude API
```

---

## 3. UX/UI 디자인 전략

### 3.1 디자인 도구 비교

| 도구 | 비용 | Flutter 연동 | 협업 | 추천 |
|------|------|-------------|------|------|
| **Figma** | 무료/유료 | 플러그인 있음 | ✅ 우수 | ⭐ 추천 |
| FlutterFlow | $30/월 | 코드 export | ✅ | 빠른 프로토타입 |
| Adobe XD | 유료 | 제한적 | ✅ | - |
| Sketch | $12/월 | 제한적 | ⚠️ | Mac 전용 |

### 3.2 추천 전략: Figma + AI 활용 (개발자용)

> **디자인 경험 없는 개발자를 위한 실용적 접근법**

#### Figma 시작하기 (30분이면 충분)

**필수 학습 (유튜브 15분):**
- "Figma 기초 튜토리얼" 검색
- 알아야 할 것: 프레임, 도형, 텍스트, 컴포넌트

**꿀팁:**
- 복잡하게 생각하지 말고 **박스 + 텍스트**로 시작
- 예쁘게 안 해도 됨, **기능 배치만 확인**
- 템플릿 복사해서 수정하는 게 빠름

#### 작업 흐름 (순차적)

```
[1단계] 와이어프레임 (Figma)
    │   - 흑백, 박스와 텍스트만
    │   - "여기 버튼", "여기 목록" 수준
    │   - 30분~1시간/화면
    ▼
[2단계] 사용자 테스트
    │   - 클릭 가능한 프로토타입
    │   - 선생님/학생에게 보여주고 피드백
    ▼
[3단계] UI 디자인 입히기
    │   - Material Design 컴포넌트 적용
    │   - 색상/폰트만 통일
    │   - AI 도구로 아이디어 참고
    ▼
[4단계] Flutter 구현
        - Figma 보면서 코딩
```

#### 디자인 못해도 되는 이유

| 방법 | 설명 |
|------|------|
| **Material Design** | 구글이 만든 디자인 시스템, Flutter 기본 제공 |
| **Figma Community** | 무료 UI Kit 복사해서 사용 |
| **AI 참고** | 막힐 때 Galileo AI로 아이디어 얻기 |

**Figma Community 검색어:**
- "Mobile App UI Kit"
- "Music App UI"
- "Calendar UI Kit"

#### AI 도구 (참고용)

| 도구 | 용도 | 사용 시점 |
|------|------|----------|
| **Galileo AI** | 프롬프트 → UI 생성 | 디자인 막힐 때 |
| **v0.dev** | 프롬프트 → React UI | 레이아웃 참고 |

**Galileo AI 프롬프트 예시:**
```
"Simple music lesson app. Teacher dashboard with
student list and calendar. Minimal, clean design."
```

#### Flutter 구현 시

| 방법 | 추천도 | 설명 |
|------|--------|------|
| **직접 코딩** | ⭐⭐⭐ | Figma 보면서 Flutter 위젯으로 구현 |
| **Material 3** | ⭐⭐⭐ | Flutter 기본 컴포넌트 활용 |
| **Figma 플러그인** | ⭐ | 참고만 (코드 품질 낮음) |

### 3.3 디자인 시스템

```dart
// 컬러 팔레트 (음악 앱 - 따뜻한 톤)
primary: #6B5B95      // 보라 (클래식 느낌)
secondary: #F4A460    // 샌디브라운 (바이올린 나무색)
background: #FFFAF5   // 아이보리
accent: #2E8B57       // 녹색 (성공/완료)
error: #DC143C        // 크림슨

// 폰트
heading: Pretendard Bold
body: Pretendard Regular
music: Noto Music (음악 기호용)
```

### 3.4 UX 원칙 (음악인 타겟)

1. **최소 입력**: 탭/스와이프로 대부분 조작
2. **큰 터치 영역**: 연주 직후 손가락 피로 고려
3. **다크 모드**: 연습실 조명 환경 대응
4. **빠른 녹음 시작**: 메인 화면에서 1탭으로 녹음

---

## 4. 개발 로드맵

### 개발 순서: UI First

```
Figma 프로토타입 → 사용자 검증 → API 명세 도출 → 백엔드 개발 → Flutter 구현
```


**이유:**
- 타겟 사용자가 "IT에 관심 없는 음악인" → UX가 성공 요인
- 개발 전 실제 사용자 피드백으로 검증 가능
- 화면 기준으로 API 설계 → 불필요한 개발 방지
- "이 기능 필요 없네?" 조기 발견 → 낭비 최소화

---

### Phase 0: UI 설계 & 검증 (2주)

| 주차 | 태스크 | 산출물 |
|------|--------|--------|
| 1 | Figma 와이어프레임 | 핵심 화면 7개 |
| 1 | 클릭 가능한 프로토타입 | Figma Prototype |
| 2 | 사용자 테스트 (선생님/학생 2-3명) | 피드백 정리 |
| 2 | 피드백 반영, 화면 확정 | 최종 UI 명세 |

**핵심 화면 (7개):**
1. 로그인/회원가입
2. 메인 대시보드 (선생님용)
3. 메인 대시보드 (학생용)
4. 학생 관리 목록
5. 레슨 캘린더
6. 레슨 상세 (녹음 포함)
7. 연습 체크리스트

### Phase 1: API 설계 & 백엔드 (3-4주)

| 주차 | 태스크 | 산출물 |
|------|--------|--------|
| 3 | 화면 기반 API 명세 도출 | `docs/api_spec.md` (OpenAPI) |
| 3 | DB 스키마 설계 | `schema/lesson_app_schema.sql` |
| 3 | FastAPI 프로젝트 셋업, MySQL 연동 | - |
| 3 | Vultr Object Storage 설정 | - |
| 4 | 인증 API (Google/Kakao OAuth) | `POST /auth/*` |
| 4 | 사용자 API (선생님/학생) | `GET/POST /users/*` |
| 5 | 레슨 일정 API | `GET/POST/PUT/DELETE /lessons/*` |
| 5 | 레슨 템플릿 API | `GET/POST /templates/*` |
| 6 | 연습 체크리스트 API | `GET/POST/PUT /practices/*` |
| 6 | API 문서화, 테스트 | Swagger UI |

### Phase 2: Flutter 구현 (3-4주)

| 주차 | 태스크 | 화면 |
|------|--------|------|
| 7 | 프로젝트 셋업, 인증 연동 | 로그인, 회원가입 |
| 7 | 라우팅, 상태관리 구조 | - |
| 8 | 메인 대시보드 | 홈 (선생님/학생 분기) |
| 8 | 학생 목록 (선생님용) | 학생 관리 화면 |
| 9 | 레슨 캘린더 | 일정 화면 |
| 9 | 레슨 상세 | 레슨 기록 화면 |
| 10 | 연습 체크리스트 | 연습 기록 화면 |
| 10 | 오프라인 지원, 로컬 캐싱 | - |

### Phase 3: 녹음 + AI 기능 (3-4주)

| 주차 | 태스크 |
|------|--------|
| 11 | 녹음 기능 구현 (Flutter) |
| 11 | 녹음 파일 업로드 API |
| 12 | Whisper 연동 (음성→텍스트) |
| 12 | Claude 연동 (요약/추출) |
| 13 | AI 결과 표시 UI |
| 13 | 연습 과제 자동 생성 |
| 14 | 테스트, 버그 수정 |

### Phase 4: 고도화 (이후)

- 푸시 알림
- 연습 통계/리포트
- 결제 시스템 (선생님 구독)
- 앱스토어 배포

---

## 5. 핵심 기능별 기술 상세

### 5.1 레슨 녹음 + AI 회의록

```
[녹음] → [업로드] → [Whisper] → [Claude] → [연습과제]
  │         │          │           │           │
Flutter   FastAPI   음성→텍스트   요약/추출    DB 저장
```

#### 비용 (30분 레슨 기준)
| 서비스 | 비용 |
|--------|------|
| Whisper | $0.18 (30분 × $0.006) |
| Claude | $0.06 (약 2,000토큰) |
| **합계** | **$0.24 (약 330원)** |

#### Flutter 녹음 구현

```dart
// record 패키지 사용
final recorder = AudioRecorder();

// 녹음 시작
await recorder.start(
  const RecordConfig(encoder: AudioEncoder.aacLc),
  path: 'lesson_recording.m4a',
);

// 녹음 중지 및 업로드
final path = await recorder.stop();
await api.uploadRecording(lessonId, File(path));
```

### 5.2 인증 플로우

```
Flutter App → FastAPI → Google/Kakao OAuth
     │            │
     │      [인증 처리]
     │            │
     └─── JWT ────┘
           │
    [토큰 저장/갱신]
```

**OAuth 구현:**
- Google: `authlib` 라이브러리
- Kakao: REST API 직접 호출
- JWT: `python-jose` 라이브러리

---

## 6. 예상 비용

### 개발 단계 (MVP)

| 항목 | 월 비용 | 비고 |
|------|--------|------|
| codenavi 서버 (MySQL + API) | $0 | 기존 인프라 |
| Vultr Object Storage | $5 | 250GB 기준 |
| Apple Developer | $8 | $99/년 |
| Google Play | $2 | $25 1회 |
| **합계** | **$15/월** | |

### 운영 단계 (사용자 100명 가정)

| 항목 | 월 비용 | 비고 |
|------|--------|------|
| codenavi 서버 | $0 | 기존 인프라 |
| Vultr Object Storage | $10 | 500GB 기준 |
| Whisper API | $50 | 200회 레슨 |
| Claude API | $20 | 요약/추출 |
| **합계** | **$80/월** | Supabase 대비 $35 절감 |

---

## 7. 리스크 및 대응

| 리스크 | 영향 | 대응 |
|--------|------|------|
| Dart 학습 곡선 | 개발 지연 | 공식 문서, 강의 활용 (1-2주 적응) |
| 앱스토어 심사 리젝 | 출시 지연 | 가이드라인 사전 확인, 베타 테스트 |
| 녹음 품질 이슈 | AI 인식률 저하 | 노이즈 제거 처리, 마이크 권장 |
| API 비용 증가 | 수익성 악화 | 무료 티어 제한, 구독 모델 |

---

## 8. 결론

### 최종 결정

| 항목 | 결정 |
|------|------|
| **플랫폼** | Flutter (iOS/Android/Web) |
| **백엔드** | Python FastAPI (codenavi 서버) |
| **DB** | MySQL 8.0 (codenavi 서버) |
| **Auth** | Google/Kakao OAuth 직접 구현 |
| **Storage** | Vultr Object Storage (녹음 파일) |
| **AI** | OpenAI Whisper + Claude API |
| **디자인** | Figma + AI 도구 (Galileo) |
| **개발 순서** | UI First |

### 다음 단계 체크리스트 (Phase 0)

- [ ] Figma 계정 생성 및 프로젝트 셋업
- [ ] 핵심 화면 7개 와이어프레임 작성
- [ ] 클릭 가능한 프로토타입 제작
- [ ] 선생님/학생 2-3명 사용자 테스트
- [ ] 피드백 반영 및 화면 확정
- [ ] 화면 기반 API 명세 도출

---

## 참고 문서

- [요구사항 정의](requirement.md)
- [경쟁사 분석](competitive_analysis.md)
