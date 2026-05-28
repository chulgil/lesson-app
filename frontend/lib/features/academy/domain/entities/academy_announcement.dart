class AcademyAnnouncement {
  const AcademyAnnouncement({
    required this.id,
    required this.academyId,
    required this.title,
    required this.body,
    required this.sentAt,
    this.isRead = false,
  });

  final String id;
  final String academyId;
  final String title;
  final String body;
  final DateTime sentAt;
  final bool isRead;

  AcademyAnnouncement copyWith({
    String? id,
    String? academyId,
    String? title,
    String? body,
    DateTime? sentAt,
    bool? isRead,
  }) {
    return AcademyAnnouncement(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      title: title ?? this.title,
      body: body ?? this.body,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
