"""Constant-backed help manual service."""

from __future__ import annotations

from app.schemas.help import HelpFaqResponse, HelpRole

HELP_FAQS: tuple[HelpFaqResponse, ...] = (
    HelpFaqResponse(
        id="student-metronome-open",
        role="student",
        category="연습 도구",
        question="메트로놈은 어떻게 켜나요?",
        answer="연습 화면의 센터 버튼을 탭하면 메트로놈을 열 수 있습니다.",
        search_keywords=["메트로놈", "센터 버튼", "박자", "BPM"],
        related_quest_id="student.metronome",
    ),
    HelpFaqResponse(
        id="student-metronome-bpm",
        role="student",
        category="연습 도구",
        question="메트로놈 BPM을 바꾸려면?",
        answer="메트로놈 화면에서 슬라이더나 +/- 버튼으로 BPM을 조절합니다.",
        search_keywords=["메트로놈", "BPM", "템포", "슬라이더"],
        related_quest_id="student.metronome",
    ),
    HelpFaqResponse(
        id="student-tuner-open",
        role="student",
        category="연습 도구",
        question="튜너는 어떻게 사용하나요?",
        answer="연습 화면의 센터 버튼을 길게 누른 뒤 악기로 소리를 내면 음과 센트가 표시됩니다.",
        search_keywords=["튜너", "센터 버튼", "롱프레스", "음정", "센트"],
    ),
    HelpFaqResponse(
        id="student-recording-start",
        role="student",
        category="연습 도구",
        question="녹음은 어떻게 시작하나요?",
        answer="연습 화면에서 녹음 버튼을 눌러 시작하고, 다시 누르면 정지합니다.",
        search_keywords=["녹음", "연습 기록", "정지", "시작"],
        related_quest_id="student.firstRecording",
    ),
    HelpFaqResponse(
        id="student-recording-backup",
        role="student",
        category="연습/녹음",
        question="녹음 파일은 어떻게 백업하나요?",
        answer="설정의 백업 메뉴에서 전체 백업을 만들고 클라우드 저장소에 보관할 수 있습니다.",
        search_keywords=["녹음", "백업", "클라우드", "파일"],
    ),
    HelpFaqResponse(
        id="teacher-recurring-lessons",
        role="teacher",
        category="레슨 관련",
        question="정기 레슨은 어떻게 설정하나요?",
        answer="레슨 등록 화면에서 반복 일정을 선택하면 매주 같은 시간의 정기 레슨을 만들 수 있습니다.",
        search_keywords=["정기 레슨", "반복", "스케줄", "캘린더"],
        related_quest_id="teacher.firstLesson",
    ),
    HelpFaqResponse(
        id="teacher-lesson-note",
        role="teacher",
        category="레슨 관련",
        question="레슨 노트는 어디서 작성하나요?",
        answer="레슨 상세 화면에서 피드백과 과제를 입력해 학생에게 공유할 수 있습니다.",
        search_keywords=["레슨 노트", "피드백", "과제", "학생"],
        related_quest_id="teacher.firstNote",
    ),
    HelpFaqResponse(
        id="teacher-subscription-issue",
        role="teacher",
        category="결제/수강권",
        question="수강권은 어떻게 발급하나요?",
        answer="수강권 메뉴에서 학생과 정책을 선택해 새 수강권을 발급합니다.",
        search_keywords=["수강권", "발급", "결제", "학생"],
    ),
    HelpFaqResponse(
        id="parent-connect-child",
        role="parent",
        category="자녀 연결",
        question="자녀는 어떻게 연결하나요?",
        answer="선생님이나 자녀에게 받은 초대 코드로 자녀 프로필을 연결할 수 있습니다.",
        search_keywords=["자녀", "연결", "초대 코드", "프로필"],
    ),
    HelpFaqResponse(
        id="parent-lesson-status",
        role="parent",
        category="레슨 현황",
        question="자녀의 레슨 현황은 어디서 보나요?",
        answer="학부모 대시보드에서 예정 레슨, 출결, 선생님 피드백을 확인합니다.",
        search_keywords=["자녀", "레슨", "출결", "대시보드", "피드백"],
    ),
    HelpFaqResponse(
        id="parent-payment-status",
        role="parent",
        category="결제/수강권",
        question="수강권 잔여 횟수는 어디서 확인하나요?",
        answer="자녀 상세의 결제 영역에서 수강권 잔여 횟수와 결제 내역을 확인합니다.",
        search_keywords=["수강권", "잔여 횟수", "결제", "자녀"],
    ),
)


class HelpService:
    def list_faqs(self, role: HelpRole, query: str | None = None) -> list[HelpFaqResponse]:
        faqs = [faq for faq in HELP_FAQS if faq.role == role]
        if not query:
            return faqs

        normalized_query = query.casefold()
        return [faq for faq in faqs if self._matches_query(faq, normalized_query)]

    def _matches_query(self, faq: HelpFaqResponse, normalized_query: str) -> bool:
        searchable_text = [faq.question, faq.answer, *faq.search_keywords]
        return any(normalized_query in text.casefold() for text in searchable_text)
