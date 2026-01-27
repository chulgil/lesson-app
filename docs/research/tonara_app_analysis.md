# Tonara 앱 분석

> 작성일: 2026-01-23
> 상태: 서비스 종료 (2023년 12월 8일)

---

## 개요

| 항목 | 내용 |
|------|------|
| 회사명 | Tonara Ltd. |
| 설립 | 2008년 |
| 본사 | 텔아비브, 이스라엘 |
| 창업자 | Evgeni Begelfor, Yair Lavi |
| 총 투자 | $9.75M (3회 라운드) |
| 서비스 종료 | 2023년 12월 8일 |

---

## 회사 연혁

| 연도 | 이벤트 |
|------|--------|
| 2008 | 회사 설립 |
| 2011.09 | TechCrunch Disrupt에서 iPad 앱 런칭 |
| 2011.10 | Apple "App of the Week" 선정 (중국, 독일, 오스트리아, 스위스) |
| 2012.07 | Series A $4M 투자 유치 (Index Ventures, Lool Ventures, Viola Group) |
| 2015.04 | $5M 투자 유치 (Baidu 주도, Carmel Ventures) |
| 2018.07 | AI 기반 튜터링 서비스 런칭 |
| 2023.09 | 서비스 종료 발표 |
| 2023.12.08 | 완전 서비스 종료 |

---

## 주요 제품

### 1. Tonara Studio

선생님과 학생을 연결하는 올인원 플랫폼

**선생님 기능:**
- 디지털 대시보드에서 모든 학생 관리
- 개인화된 과제 생성 및 연습 목표 설정
- 학생 연습 현황 실시간 추적
- 애니메이션 연습 알림 전송
- 뱃지, 스티커로 학생 동기 부여

**학생 기능:**
- 과제 확인 및 연습 기록
- 실시간 피드백 받기
- 리더보드 순위 확인
- 포인트 및 뱃지 수집

### 2. Tonara Connect

음악 교육 마켓플레이스

- 전 세계 선생님-학생 매칭
- 선생님 프로필 (경력, 수업 방식, 가능 시간, 미디어)
- 학생 니즈에 맞는 선생님 검색
- 언어, 악기, 위치 무관 매칭

---

## 핵심 기술 (특허)

### Compare Recording Technology

선생님이 업로드한 원본 녹음과 학생의 실시간 연주를 비교 분석

**분석 항목:**
| 항목 | 설명 |
|------|------|
| Pitch (음정) | 정확한 음 높이 |
| Rhythm (리듬) | 박자 정확도 |
| Tempo (템포) | 속도 일관성 |
| Fluency (유창성) | 전체적인 흐름 |

**지원 악기:**
- 피아노, 바이올린, 첼로, 플룻
- 기타, 비올라, 오보에, 클라리넷
- 색소폰, 트럼펫, 트롬본, 프렌치 호른
- 리코더, 드럼

### Interactive Sheet Music (자동 악보 넘김)

- 연주를 실시간 인식
- 악보에서 현재 위치 표시
- 자동 페이지 넘김

---

## 게이미피케이션 시스템

### 보상 체계

| 요소 | 설명 |
|------|------|
| 포인트 | 연습 완료 시 획득 |
| 뱃지 | 목표 달성 시 수여 |
| 스티커 | 애니메이션 스티커로 격려 |
| 리더보드 | 스튜디오 내 순위 경쟁 |

### 동기 부여 요소

- 일일 연습 스트릭
- 주간 목표 달성 보상
- 선생님 피드백 알림
- 귀여운 이모티콘/스티커 메시지

---

## 커뮤니케이션 기능

- 인앱 메시징 (선생님 ↔ 학생)
- 연습 리마인더 (애니메이션 알림)
- 피드백 코멘트
- 이모티콘/스티커 전송

---

## 역할 통합 구조

```
┌─────────────────────────────────────────────┐
│              Tonara App (통합)               │
├─────────────────┬─────────────────┬─────────┤
│     선생님      │      학생       │  학부모  │
├─────────────────┼─────────────────┼─────────┤
│ • 스튜디오 관리  │ • 과제 확인     │ • 연습  │
│ • 학생 목록     │ • 연습 녹음     │   현황  │
│ • 과제 생성     │ • AI 피드백     │   확인  │
│ • 연습 모니터링  │ • 뱃지 수집     │         │
│ • 결제 관리     │ • 리더보드      │         │
└─────────────────┴─────────────────┴─────────┘
```

---

## 서비스 종료 분석

### 종료 타임라인

1. **2023년 9월**: 갑작스러운 서비스 종료 발표
2. **2023년 12월 8일**: 완전 종료
3. 사용자들에게 약 2개월의 이전 기간 제공

### 추정 원인

- 수익화 모델의 한계
- AI 기반 연주 분석 기술의 높은 유지 비용
- 음악 교육 시장의 제한된 규모
- 경쟁 심화

### 사용자 반응

> "피아노 교사 커뮤니티에 충격파가 퍼졌다. Tonara는 최초의 전용 온라인 과제 앱 중 하나였다."
> — Piano Pantry Podcast

---

## 대안 앱으로의 이동

### 주요 대안

| 앱 | 특징 | Tonara 사용자 평가 |
|-----|------|------------------|
| **Practice Space** | 과제 관리 + 게이미피케이션 | 가장 많이 이동, 과제 이전 지원 |
| **Vivid Practice** | Vibrant Music Teaching 연계 | 커뮤니티 사용자 선호 |
| **My Music Staff** | 웹 기반 스튜디오 관리 | 종합 관리 필요 시 |

### 이전 경험

> "Practice Space로의 과제 이전은 정말 수월했고, 학습 곡선도 크지 않았다."
> — Leila Viss

---

## lesson-app과의 비교

| 기능 | Tonara | lesson-app |
|------|--------|------------|
| AI 연주 분석 | ✅ 핵심 기능 | ❌ |
| 실시간 피드백 | ✅ | ❌ |
| 메트로놈 | ❌ | ✅ 내장 (Subdivision 지원) |
| 튜너 | ❌ | ✅ 내장 (12음계, 콤보) |
| 녹음 | ✅ | ✅ (스마트 트리밍, A-B 루프) |
| 수강료 관리 | ❌ | ✅ (2단계 입금확인) |
| 레슨 캘린더 | ❌ | ✅ (월/주 뷰) |
| 레슨 노트 | ❌ | ✅ |
| 게이미피케이션 | ✅ 강력 | 🔜 예정 (뱃지) |
| 학부모 연동 | ✅ | ✅ (QR/코드 초대) |
| 역할 통합 | ✅ | ✅ |

### 차별점

**Tonara의 강점:**
- AI 기반 연주 분석 (특허 기술)
- 자동 악보 넘김
- 강력한 게이미피케이션

**lesson-app의 강점:**
- 레슨 운영 전체 관리 (일정, 결제, 노트)
- 내장 연습 도구 (메트로놈, 튜너)
- 고급 녹음 기능 (트리밍, 파형, 속도 조절)

---

## 참고 자료

- [Tonara 공식 사이트](https://www.tonara.com/)
- [Tonara Wikipedia](https://en.wikipedia.org/wiki/Tonara_(company))
- [TechCrunch - Tonara $5M Funding](https://techcrunch.com/2015/04/14/music-education-startup-tonara-scores-5m-led-by-baidu-chinas-largest-search-engine/)
- [Piano Pantry - Life After Tonara](https://pianopantry.com/podcast/episode132/)
- [Leila Viss - Transition from Tonara](https://www.leilaviss.com/blog/transition-from-tonara-to-practice-space)
- [VentureBeat - Tonara AI Tutoring](https://venturebeat.com/2018/07/02/tonara-launches-an-ai-powered-tutoring-service-for-budding-musicians/)
- [Startup Nation Finder - Tonara](https://finder.startupnationcentral.org/company_page/tonara)
- [Crunchbase - Tonara](https://www.crunchbase.com/organization/tonara)
