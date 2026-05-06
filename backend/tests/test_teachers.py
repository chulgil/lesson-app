"""Teacher endpoint tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_list_teachers(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/teachers returns a paginated list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/teachers", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data


@pytest.mark.asyncio
async def test_list_teachers_includes_user_for_frontend_search_cards(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """Remote teacher search maps list items through json['user']['name']."""
    await create_test_user(user_id="test-user-id", role="teacher", name="검색 선생님")

    response = await client.get("/api/v1/teachers", headers=auth_headers)

    assert response.status_code == 200
    item = response.json()["items"][0]
    assert item["user"] is not None
    assert item["user"]["name"] == "검색 선생님"


@pytest.mark.asyncio
async def test_list_teachers_keyword_search_matches_user_name(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """Frontend keyword search sends q and expects teacher names to match."""
    await create_test_user(
        user_id="test-user-id",
        role="teacher",
        name="김바이올린",
    )
    await create_test_user(
        user_id="other-teacher",
        role="teacher",
        name="박피아노",
        email="other@test.com",
    )

    response = await client.get(
        "/api/v1/teachers",
        headers=auth_headers,
        params={"q": "바이올린"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert data["items"][0]["user"]["name"] == "김바이올린"


@pytest.mark.asyncio
async def test_list_teachers_accepts_frontend_per_page_pagination(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Remote teacher search sends per_page, while backend pagination uses size internally."""
    from app.models.teacher import Teacher
    from app.models.user import User, UserRole

    await create_test_user(user_id="test-user-id", role="teacher")
    db_session.add_all(
        [
            User(
                id="second-teacher-user",
                email="second-teacher@test.com",
                name="두번째 선생님",
                role=UserRole.teacher,
            ),
            Teacher(id="second-teacher-prof", user_id="second-teacher-user", instruments=[]),
        ]
    )
    await db_session.flush()

    response = await client.get(
        "/api/v1/teachers",
        params={"page": 1, "per_page": 1},
        headers=auth_headers,
    )

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 2
    assert len(data["items"]) == 1
    assert data["size"] == 1


@pytest.mark.asyncio
async def test_list_teachers_filters_by_lesson_type_before_pagination(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Teacher search filter sheet expects lesson type to be server-filtered."""
    from app.models.teacher import Teacher
    from app.models.user import User, UserRole

    await create_test_user(user_id="test-user-id", role="teacher")
    db_session.add_all(
        [
            User(
                id="online-teacher-user",
                email="online-teacher@test.com",
                name="온라인 선생님",
                role=UserRole.teacher,
            ),
            Teacher(
                id="online-teacher-prof",
                user_id="online-teacher-user",
                instruments=["piano"],
                lesson_types=["online"],
                experience_years=8,
            ),
            User(
                id="visit-teacher-user",
                email="visit-teacher@test.com",
                name="방문 선생님",
                role=UserRole.teacher,
            ),
            Teacher(
                id="visit-teacher-prof",
                user_id="visit-teacher-user",
                instruments=["piano"],
                lesson_types=["visit"],
                experience_years=8,
            ),
        ]
    )
    await db_session.flush()

    response = await client.get(
        "/api/v1/teachers",
        params={"lesson_type": "online", "page": 1, "per_page": 1},
        headers=auth_headers,
    )

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert data["items"][0]["id"] == "online-teacher-prof"


@pytest.mark.asyncio
async def test_list_teachers_filters_by_min_experience_before_pagination(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Frontend minExperience filter must not be applied after a truncated page."""
    from app.models.teacher import Teacher
    from app.models.user import User, UserRole

    await create_test_user(user_id="test-user-id", role="teacher")
    db_session.add_all(
        [
            User(
                id="junior-teacher-user",
                email="junior-teacher@test.com",
                name="주니어 선생님",
                role=UserRole.teacher,
            ),
            Teacher(
                id="junior-teacher-prof",
                user_id="junior-teacher-user",
                instruments=["piano"],
                experience_years=2,
            ),
            User(
                id="senior-teacher-user",
                email="senior-teacher@test.com",
                name="시니어 선생님",
                role=UserRole.teacher,
            ),
            Teacher(
                id="senior-teacher-prof",
                user_id="senior-teacher-user",
                instruments=["piano"],
                experience_years=7,
            ),
        ]
    )
    await db_session.flush()

    response = await client.get(
        "/api/v1/teachers",
        params={"min_experience": 5, "page": 1, "per_page": 1},
        headers=auth_headers,
    )

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert data["items"][0]["id"] == "senior-teacher-prof"


@pytest.mark.asyncio
async def test_list_teachers_filters_by_approved_certificate_before_pagination(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Certified-teachers-only search maps to an approved certificate record."""
    from app.models.teacher import (
        CertificateStatus,
        CertificateType,
        Teacher,
        TeacherCertificate,
    )
    from app.models.user import User, UserRole

    await create_test_user(user_id="test-user-id", role="teacher")
    db_session.add_all(
        [
            User(
                id="certified-teacher-user",
                email="certified-teacher@test.com",
                name="인증 선생님",
                role=UserRole.teacher,
            ),
            Teacher(
                id="certified-teacher-prof",
                user_id="certified-teacher-user",
                instruments=["piano"],
            ),
            TeacherCertificate(
                teacher_id="certified-teacher-prof",
                type=CertificateType.degree,
                name="음악학 학위",
                status=CertificateStatus.approved,
            ),
            User(
                id="pending-teacher-user",
                email="pending-teacher@test.com",
                name="대기 선생님",
                role=UserRole.teacher,
            ),
            Teacher(
                id="pending-teacher-prof",
                user_id="pending-teacher-user",
                instruments=["piano"],
            ),
            TeacherCertificate(
                teacher_id="pending-teacher-prof",
                type=CertificateType.degree,
                name="심사중 학위",
                status=CertificateStatus.pending,
            ),
        ]
    )
    await db_session.flush()

    response = await client.get(
        "/api/v1/teachers",
        params={"has_verified_certificate": "true", "page": 1, "per_page": 1},
        headers=auth_headers,
    )

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert data["items"][0]["id"] == "certified-teacher-prof"


@pytest.mark.asyncio
async def test_get_teacher_dashboard(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/teachers/{id}/dashboard returns dashboard data."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get(
        "/api/v1/teachers/test-user-id/dashboard",
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert "total_students" in data
    assert "upcoming_lessons" in data


@pytest.mark.asyncio
async def test_get_teacher_students(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/teachers/{id}/students returns student list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get(
        "/api/v1/teachers/test-user-id/students",
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert data["total"] >= 0


@pytest.mark.asyncio
async def test_get_my_teacher_students_route_is_not_captured_by_teacher_id(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """GET /api/v1/teachers/me/students uses the authenticated teacher profile."""
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher")
    student = Student(
        teacher_id="test-user-id",
        name="Route Order Student",
        instrument="piano",
    )
    db_session.add(student)
    await db_session.flush()

    response = await client.get("/api/v1/teachers/me/students", headers=auth_headers)

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert data["items"][0]["name"] == "Route Order Student"


@pytest.mark.asyncio
async def test_get_my_teacher_dashboard_route_is_not_captured_by_teacher_id(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """GET /api/v1/teachers/me/dashboard uses the authenticated teacher ID."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/teachers/me/dashboard", headers=auth_headers)

    assert response.status_code == 200
    data = response.json()
    assert data["total_students"] == 0
    assert "upcoming_lessons" in data


@pytest.mark.asyncio
async def test_update_my_teacher_profile_uses_authenticated_teacher_profile(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """PUT /api/v1/teachers/me/profile updates the profile owned by the current user."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.put(
        "/api/v1/teachers/me/profile",
        headers=auth_headers,
        json={
            "instruments": ["piano", "violin"],
            "introduction": "레슨 소개",
            "experience_years": 7,
            "fee_min": 50000,
            "fee_max": 90000,
            "background_image": "https://cdn.example/bg.jpg",
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == "test-user-id-prof"
    assert data["instruments"] == ["piano", "violin"]
    assert data["introduction"] == "레슨 소개"
    assert data["experience_years"] == 7
    assert data["fee_min"] == 50000
    assert data["background_image"] == "https://cdn.example/bg.jpg"


@pytest.mark.asyncio
async def test_put_my_teacher_profile_creates_profile_when_missing(
    client: AsyncClient,
    auth_headers,
    db_session,
):
    """Frontend onboarding createProfile also uses PUT /teachers/me/profile."""
    from app.models.user import User, UserRole

    db_session.add(
        User(
            id="test-user-id",
            email="teacher@test.com",
            name="신규 선생님",
            role=UserRole.teacher,
            locale="ko",
            country="KR",
            timezone="Asia/Seoul",
            currency="KRW",
        )
    )
    await db_session.flush()

    response = await client.put(
        "/api/v1/teachers/me/profile",
        headers=auth_headers,
        json={
            "instruments": ["cello"],
            "introduction": "신규 프로필",
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert data["user_id"] == "test-user-id"
    assert data["instruments"] == ["cello"]
    assert data["introduction"] == "신규 프로필"
