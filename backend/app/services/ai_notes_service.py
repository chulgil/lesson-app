"""AI lesson notes service — Whisper STT + GPT structuring pipeline."""

from __future__ import annotations

import json
import uuid
from datetime import UTC, datetime
from typing import Any

from fastapi import HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.ai_notes import AiNoteResponse, SuggestedAssignment


class AiNotesService:
    """Handle AI-powered lesson note generation."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def generate_from_upload(
        self,
        *,
        file: UploadFile,
        lesson_id: str,
        student_name: str | None = None,
        instrument: str | None = None,
        level: str | None = None,
        pieces: list[str] | None = None,
        current_user: Any,
    ) -> AiNoteResponse:
        """Full pipeline: upload audio → STT → GPT → structured notes."""
        from app.models.lesson import Lesson

        # Verify lesson exists
        lesson = await self.db.get(Lesson, lesson_id)
        if lesson is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Lesson not found",
            )

        # Read audio content
        audio_content = await file.read()
        if len(audio_content) > 50 * 1024 * 1024:  # 50MB limit
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Audio file too large. Maximum 50MB.",
            )

        # Step 1: Speech-to-Text (Whisper)
        transcription = await self._transcribe(audio_content)

        # Step 2: Structure with GPT
        structured = await self._structure_notes(
            transcription=transcription,
            student_name=student_name or lesson.student_name,
            instrument=instrument or lesson.instrument,
            level=level or "intermediate",
            pieces=pieces or [],
        )

        # Step 3: Save to lesson
        lesson.feedback = structured.get("feedback")
        lesson.key_points = structured.get("keyPoints", [])
        lesson.practice_tips = structured.get("practiceTips")
        await self.db.flush()
        await self.db.refresh(lesson)

        return AiNoteResponse(
            id=str(uuid.uuid4()),
            lesson_id=lesson_id,
            feedback=structured.get("feedback"),
            key_points=structured.get("keyPoints", []),
            practice_tips=structured.get("practiceTips"),
            suggested_assignments=[SuggestedAssignment(**a) for a in structured.get("suggestedAssignments", [])],
            transcription=transcription,
            status="completed",
            created_at=datetime.now(UTC),
        )

    async def get_by_lesson_id(self, lesson_id: str) -> AiNoteResponse | None:
        """Get existing AI notes for a lesson."""
        from app.models.lesson import Lesson

        lesson = await self.db.get(Lesson, lesson_id)
        if lesson is None:
            return None

        # Check if lesson has AI-generated content
        if not lesson.feedback and not lesson.key_points:
            return None

        return AiNoteResponse(
            id=lesson.id,
            lesson_id=lesson_id,
            feedback=lesson.feedback,
            key_points=list(lesson.key_points) if isinstance(lesson.key_points, list) else [],
            practice_tips=lesson.practice_tips,
            suggested_assignments=[],
            status="completed",
            created_at=lesson.created_at,
        )

    async def _transcribe(self, audio_content: bytes) -> str:
        """Transcribe audio using OpenAI Whisper API."""
        try:
            import openai

            client = openai.AsyncOpenAI()

            # Create a temporary file-like object for the API
            import io

            audio_file = io.BytesIO(audio_content)
            audio_file.name = "lesson_recording.m4a"

            response = await client.audio.transcriptions.create(
                model="whisper-1",
                file=audio_file,
                language="ko",
                response_format="text",
            )
            return response
        except ImportError:
            # OpenAI not installed — return placeholder
            return "[OpenAI SDK not installed — transcription unavailable]"
        except Exception:
            # OpenAI SDK raw 에러 (API key 등 인프라 정보) 가 응답에 노출되지 않도록 로그만 남긴다.
            import logging

            logging.getLogger(__name__).exception("Whisper transcription failed")
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Transcription failed",
            )

    async def _structure_notes(
        self,
        *,
        transcription: str,
        student_name: str,
        instrument: str,
        level: str,
        pieces: list[str],
    ) -> dict:
        """Structure transcription into lesson notes using GPT."""
        pieces_str = ", ".join(pieces) if pieces else "미정"

        prompt = f"""당신은 음악 레슨 노트 작성 전문가입니다.
아래는 {instrument} 레슨의 녹취록입니다.
학생: {student_name} ({level})
곡목: {pieces_str}

이 녹취록을 바탕으로 다음 항목을 작성하세요:
1. feedback: 레슨 전체 피드백 (2-3문장, 긍정적 + 개선점)
2. keyPoints: 핵심 포인트 (3-5개, 짧은 문장)
3. practiceTips: 구체적 연습 방법 (메트로놈 템포, 반복 횟수 포함)
4. suggestedAssignments: 과제 제안 (2-4개, 각각 title + description)

JSON 형식으로 응답하세요.

녹취록:
{transcription[:8000]}"""

        try:
            import openai

            client = openai.AsyncOpenAI()
            response = await client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                response_format={"type": "json_object"},
                temperature=0.3,
                max_tokens=2000,
            )
            content = response.choices[0].message.content
            return json.loads(content) if content else {}
        except ImportError:
            # OpenAI not installed — return placeholder
            return {
                "feedback": f"{student_name} 학생의 {instrument} 레슨 피드백입니다.",
                "keyPoints": ["AI 노트 생성을 위해 OpenAI SDK 설치가 필요합니다"],
                "practiceTips": "OpenAI SDK를 설치하세요: pip install openai",
                "suggestedAssignments": [],
            }
        except Exception:
            # GPT SDK raw 에러 (API key 등 인프라 정보) 가 응답에 노출되지 않도록 로그만 남긴다.
            import logging

            logging.getLogger(__name__).exception("Note generation via GPT failed")
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Note generation failed",
            )
