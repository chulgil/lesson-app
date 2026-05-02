# lesson-app 문서

> 마지막 업데이트: 2026-05-02

음악 레슨 예약 및 연습 관리 앱 문서입니다.

---

## 핵심 문서

| 문서 | 설명 |
|------|------|
| [SPEC_ROUTING.md](SPEC_ROUTING.md) | **AI 작업 지시용** — 작업 유형별 필수/보조/금지 문서 라우팅 |
| [DOCUMENT_INDEX.md](DOCUMENT_INDEX.md) | 전체 문서 인덱스 (사람용) |
| [architecture.md](architecture.md) | 앱 아키텍처 가이드 (폴더 구조, Provider 패턴) |
| [../CLAUDE.md](../CLAUDE.md) | 프로젝트 가이드 (명령어, 규칙, 작업 우선순위) |

> **Claude 작업 시작 시**: `CLAUDE.md` → `SPEC_ROUTING.md` → 해당 도메인 마스터 스펙

---

## 문서 구조

```
docs/
├── SPEC_ROUTING.md           # AI 작업 지시용 라우팅
├── DOCUMENT_INDEX.md         # 전체 인덱스
├── architecture.md           # 앱 아키텍처
├── requirement/              # ⚠️ HISTORICAL (2025-12 기준)
├── proposal/                 # 기획 제안서
├── reference/                # 참고 자료
├── research/                 # 시장 조사
├── schema/entities/          # 엔티티 스키마
├── specs/                    # 기능 명세서
│   ├── [domain]/             # 도메인별 마스터 + 하위 스펙
│   │   └── [domain]_master.md  ← SSOT
│   ├── design/notebook/      # Notebook × Score 디자인 시스템
│   ├── lesson/invite/        # 초대/관계 시스템 (정식 경로)
│   ├── backend/              # 백엔드 스펙
│   └── _archive/             # ❌ 사용 금지 (폐기된 문서)
└── registry.md               # 토큰/컴포넌트 의존성
```

---

## SSOT 규칙

1. **도메인 정책** → `specs/[domain]/[domain]_master.md`가 최종 기준
2. **디자인 시스템** → `specs/design/notebook/README.md`가 최종 기준
3. **초대/관계** → `specs/lesson/invite/`가 정식 경로
4. **마스터와 하위 문서 충돌 시** → 마스터가 우선
5. **`_archive/` 문서** → 참고 금지
6. **`requirement/`** → HISTORICAL (현재 정책은 각 도메인 마스터 참조)

---

## 마스터 스펙 (13개)

전체 목록: [DOCUMENT_INDEX.md](DOCUMENT_INDEX.md) 또는 [specs/feature_hub.md](specs/feature_hub.md)
