enum InquirySenderRole { student, parent }

class AcademyInquiry {
  const AcademyInquiry({
    required this.id,
    required this.academyId,
    required this.senderRole,
    required this.senderName,
    required this.body,
    required this.createdAt,
    this.replies = const [],
  });

  final String id;
  final String academyId;
  final InquirySenderRole senderRole;
  final String senderName;
  final String body;
  final DateTime createdAt;
  final List<AcademyInquiryReply> replies;

  AcademyInquiry copyWith({
    String? id,
    String? academyId,
    InquirySenderRole? senderRole,
    String? senderName,
    String? body,
    DateTime? createdAt,
    List<AcademyInquiryReply>? replies,
  }) {
    return AcademyInquiry(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      senderRole: senderRole ?? this.senderRole,
      senderName: senderName ?? this.senderName,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      replies: replies ?? this.replies,
    );
  }
}

class AcademyInquiryReply {
  const AcademyInquiryReply({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.isFromAcademy,
  });

  final String id;
  final String body;
  final DateTime createdAt;
  final bool isFromAcademy;
}
