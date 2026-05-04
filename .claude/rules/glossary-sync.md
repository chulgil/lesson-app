# Glossary Sync — 유비쿼터스 언어 강제

> DDD Ubiquitous Language 패턴. 코드·스펙·대화에서 같은 용어를 사용한다.
> SSOT: `.harness/knowledge/glossary.md`

## 원칙

1. **하나의 개념 = 하나의 이름** — glossary에 정의된 용어만 코드/스펙에서 사용
2. **FE-BE 동일 이름** — 신규 엔티티는 프론트/백엔드 클래스명을 동일하게. 역사적 불일치는 glossary §9에 매핑 유지
3. **glossary 먼저** — 새 용어가 필요하면 glossary에 추가한 후 코드/스펙에 사용

## 적용 시점

| 시점 | 체크 |
|------|------|
| Phase 1 (interview) | 신규 용어 후보를 glossary에 기록 |
| Phase 2 (spec) | 스펙 본문의 엔티티/상태명이 glossary와 동일한지 확인 |
| Phase 5 (coding) | 클래스명/변수명이 glossary의 영문명과 일치하는지 확인 |
| `/code-review` | glossary 불일치 위반 보고 |

## 위반 패턴

```
# BAD: glossary에 "Schedule Exception"인데 코드에서 다른 이름
class TimeException    # FE — glossary 불일치
class ScheduleBlock    # 새 이름 무단 생성

# GOOD: glossary 그대로
class ScheduleException  # glossary §3
```

## 검증

```bash
# 신규 엔티티가 glossary에 등록되었는지 확인
# (새 class 정의 후 glossary에 없으면 경고)
grep -rn "class [A-Z]" frontend/lib/features/*/domain/entities/*.dart | \
  awk -F: '{print $2}' | grep -oP 'class \K\w+' | sort -u > /tmp/fe_classes.txt
grep -rn "class [A-Z]" backend/app/models/*.py | \
  awk -F: '{print $2}' | grep -oP 'class \K\w+' | sort -u > /tmp/be_classes.txt
# 수동: /tmp 파일과 glossary 대조
```

## 스펙 체계 통합

| 위치 | 역할 | 수명 |
|------|------|------|
| `docs/specs/{domain}/` | 도메인 마스터 스펙 (영구 SSOT) | 프로젝트 전체 |
| `.harness/spec/{feature}.md` | feature 작업 스펙 (임시) | feature 완료까지 |
| `.harness/knowledge/glossary.md` | 유비쿼터스 언어 (영구) | 프로젝트 전체 |

- `.harness/spec/` 작업 스펙은 Phase 6 PASS 후 `docs/specs/` 마스터에 머지
- glossary는 양쪽 모두의 SSOT — 마스터 스펙과 작업 스펙 모두 glossary 용어를 사용

## 금지

- glossary에 없는 용어로 새 엔티티/enum 생성
- FE-BE 클래스명을 다르게 만들기 (역사적 불일치 6건 외)
- `docs/specs/glossary.md`를 직접 수정 — `.harness/knowledge/glossary.md`가 SSOT, docs 쪽은 동기화 대상
