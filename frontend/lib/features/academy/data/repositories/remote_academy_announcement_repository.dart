import '../../../../core/network/api_client.dart';
import '../../domain/entities/academy_announcement.dart';
import '../../domain/repositories/academy_announcement_repository.dart';

/// REST client for academy announcements (members receive + read) — issue #554 영역 4.
///
/// 백엔드 엔드포인트 (baseUrl 에 `/api/v1` 포함):
/// - `GET /academies/{academyId}/announcements`
///   → AcademyAnnouncementListResponse (학원 멤버 — owner/teacher)
/// - `PATCH /academies/announcements/{id}/recipients/me/read`
///   → 수신자 본인 읽음 마킹 (멱등)
///
/// 주의: 학원→멤버 단방향 `academy_announcement` 시스템. 강사→학생
/// `teacher_announcement` 와는 별개 (issue #554 영역 4).
///
/// BE 의 `AcademyAnnouncementResponse` 는 집계 `read_count` 만 노출하고
/// 수신자 본인 읽음 여부(`is_read`)는 제공하지 않는다. 따라서 목록/상세에서
/// `isRead` 는 `false` 로 매핑한다. 읽음 마킹은 markAsRead 가 BE 에 반영한다.
class RemoteAcademyAnnouncementRepository
    implements AcademyAnnouncementRepository {
  final ApiClient _apiClient;

  RemoteAcademyAnnouncementRepository(this._apiClient);

  @override
  Future<List<AcademyAnnouncement>> listByAcademy(String academyId) async {
    final response = await _apiClient.get(
      '/academies/$academyId/announcements',
    );
    final map = response.data as Map<String, dynamic>;
    final items = (map['announcements'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final announcements = items.map(_fromJson).toList();
    // 계약(최신순) 방어적 보장 — BE 는 created_at desc 정렬.
    announcements.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return announcements;
  }

  @override
  Future<void> markAsRead(String announcementId) async {
    await _apiClient.patch(
      '/academies/announcements/$announcementId/recipients/me/read',
    );
  }

  static AcademyAnnouncement _fromJson(Map<String, dynamic> json) {
    // 발송 시각(sent_at) 우선, 없으면 생성 시각(created_at) 으로 폴백.
    final sentRaw = (json['sent_at'] as String?) ?? json['created_at'] as String;
    return AcademyAnnouncement(
      id: json['id'] as String,
      academyId: json['academy_id'] as String,
      title: json['title'] as String,
      body: json['body_markdown'] as String,
      sentAt: DateTime.parse(sentRaw),
      // BE 응답에 수신자 본인 읽음 필드 없음 — 항상 false (위 클래스 주석 참조).
      isRead: false,
    );
  }
}
