# 제품 기획 갭 감사 (2026-05-07)

> CEO + 20년차 기획전문가 관점 전체 검토
> 상태: 코드-스펙 정합성 95%, 베타 준비 80%

## 1. 코드-스펙 정합성 검증 결과 ✅

| 기능 | 코드 | 스펙 | 상태 |
|------|------|------|------|
| 공지 시스템 v3 (휴강/일반) | ✅ | ✅ | 정합 |
| 이동시간 자동 측정 | ✅ | ✅ | 정합 |
| 주소 검색 (서버 경유) | ✅ | ✅ | 정합 |
| 유튜브 인앱 플레이어 + 구간 반복 | ✅ | ✅ | 정합 |
| 수강권 발급 후 수정 | ✅ | ✅ | 정합 |
| 학생 희망 장소 → 수강권 디폴트 | ✅ | ✅ | 정합 |
| 선생님 프로필 주소 | ✅ | ✅ | 정합 |

## 2. 기획 방향 누락 (P0 — 즉시 해결)

### P0 — 상세 스펙 완료 ✅

| 항목 | 스펙 문서 | 핵심 내용 |
|------|----------|----------|
| 학생 진도 분석 대시보드 | [`student_progress_dashboard_spec.md`](../analytics/student_progress_dashboard_spec.md) | 월간 요약 / 학생별 성장 차트 / 수입 분석 / 리텐션. API 5개, Phase A~G |
| 결제 영수증/인보이스 PDF | [`payment_receipt_spec.md`](../subscription/payment_receipt_spec.md) | WeasyPrint PDF / Vultr S3 저장 / 자동 영수증 + 청구서 발송. API 9개, Phase 1~2 |
| 레슨 추가 수강권 안내 | [`lesson_master.md §10`](../lesson/lesson_master.md) | 수강권 유무별 배너 (녹색/회색) — **구현 완료** |

### P1 — 상세 스펙 완료 ✅

| 항목 | 스펙 문서 | 핵심 내용 |
|------|----------|----------|
| 레슨 이력 내보내기 | [`lesson_history_export_spec.md`](../lesson/lesson_history_export_spec.md) | CSV (UTF-8 BOM) + PDF. 비동기 job, 최대 3년 |
| 세분화 푸시 알림 설정 | [`push_notification_settings_spec.md`](../notification/push_notification_settings_spec.md) | 6카테고리 토글 + DND + 우회 알림 4종 |
| 앱스토어 리뷰 프롬프트 | [`app_rating_prompt_spec.md`](../settings/app_rating_prompt_spec.md) | 2단계 (만족→리뷰, 불만→피드백). Hive 로컬 |

## 4. 장기 과제 (P2-P3)

| 항목 | 설명 | 예상 공수 |
|------|------|----------|
| 다국어 지원 (i18n) | .arb 파일 + Intl 패키지 | 2-3주 |
| 접근성 (a11y) | Semantic labels 전체 추가 | 4-5주 |
| 다크 모드 | ThemeData.dark() 추가 | 1-2주 |
| 태블릿 레이아웃 | 반응형 멀티 컬럼 | 3-4주 |

## 5. Mock → Remote 전환 현황

- 전체 40개 리포지토리 중 **13개가 Mock 전용**
- 백엔드 API는 존재하나 프론트 Remote adapter 미연결
- **베타 전 필수**: LessonClass, Membership, Invite, Practice Logs

## 6. 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-05-07 | 초판 — CEO 관점 전체 감사 (코드-스펙 정합성 + 기획 누락 + 경쟁사 분석) |
