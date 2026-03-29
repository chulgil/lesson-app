# 시나리오 테스트 규칙

## 시나리오 테스트 작성 시 필수 참조

백엔드 시나리오 테스트 작성 요청 시:

1. **가이드 문서**: `docs/specs/backend/scenario_testing_guide.md` 참조
2. **프레임워크 사용**: `TeacherActions`, `StudentActions` 헬퍼 클래스 사용
3. **파일 위치**: `backend/tests/test_scenarios_framework.py` 또는 `backend/tests/test_scenario_schedule_integration.py`에 추가
4. **fixture**: `teacher`, `student` fixture 사용 (conftest.py에 정의)

## 작성 패턴

```python
@pytest.mark.asyncio
async def test_fw_시나리오이름(teacher: TeacherActions, student: StudentActions):
    """시나리오 설명."""
    sid = await teacher.create_student("학생이름")
    lid = await teacher.create_lesson(sid, date="2026-04-01")
    await teacher.complete_lesson(lid)
```

## 작성 후 체크리스트

- [ ] `python -m pytest tests/test_scenarios_framework.py -v` 통과
- [ ] `docs/specs/backend/scenario_testing_guide.md` 시나리오 목록 업데이트
- [ ] 필요 시 `tests/scenarios/helpers.py`에 새 메서드 추가
