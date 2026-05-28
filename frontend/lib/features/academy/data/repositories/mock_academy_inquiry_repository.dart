import 'package:lessonaza/features/academy/domain/entities/academy_inquiry.dart';
import 'package:lessonaza/features/academy/domain/repositories/academy_inquiry_repository.dart';

class MockAcademyInquiryRepository implements AcademyInquiryRepository {
  final Map<String, AcademyInquiry> _inquiries = {
    'inq_001': AcademyInquiry(
      id: 'inq_001',
      academyId: 'acad_001',
      senderRole: InquirySenderRole.parent,
      senderName: '김철수',
      body: '8월 수강권 발급은 언제 가능한가요?',
      createdAt: DateTime.now().subtract(const Duration(hours: 24)),
      replies: [
        AcademyInquiryReply(
          id: 'reply_001',
          body: '안녕하세요. 수강권은 매월 1일에 발급되며, 8월 수강권은 7월 31일 발급 예정입니다.',
          createdAt: DateTime.now().subtract(const Duration(hours: 20)),
          isFromAcademy: true,
        ),
      ],
    ),
    'inq_002': AcademyInquiry(
      id: 'inq_002',
      academyId: 'acad_001',
      senderRole: InquirySenderRole.student,
      senderName: '이지은',
      body: '레슨 시간을 변경할 수 있나요?',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      replies: [],
    ),
    'inq_003': AcademyInquiry(
      id: 'inq_003',
      academyId: 'acad_001',
      senderRole: InquirySenderRole.parent,
      senderName: '박민준',
      body: '결제 확인서를 받고 싶습니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      replies: [
        AcademyInquiryReply(
          id: 'reply_002',
          body: '결제 확인서는 학원에 방문하여 요청하시거나 메일로 받으실 수 있습니다.',
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
          isFromAcademy: true,
        ),
      ],
    ),
  };

  int _nextId = 1004;

  @override
  Future<List<AcademyInquiry>> listByAcademy(String academyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final list =
        _inquiries.values.where((i) => i.academyId == academyId).toList();
    return list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<AcademyInquiry> getById(String inquiryId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final inquiry = _inquiries[inquiryId];
    if (inquiry == null) {
      throw Exception('Inquiry not found: $inquiryId');
    }
    return inquiry;
  }

  @override
  Future<void> reply(String inquiryId, String body) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final inquiry = _inquiries[inquiryId];
    if (inquiry == null) {
      throw Exception('Inquiry not found: $inquiryId');
    }

    final newReply = AcademyInquiryReply(
      id: 'reply_${_nextId++}',
      body: body,
      createdAt: DateTime.now(),
      isFromAcademy: true,
    );

    _inquiries[inquiryId] = inquiry.copyWith(
      replies: [...inquiry.replies, newReply],
    );
  }

  @override
  Future<String> create({
    required String academyId,
    required InquirySenderRole senderRole,
    required String senderName,
    required String body,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final id = 'inq_${_nextId++}';
    final inquiry = AcademyInquiry(
      id: id,
      academyId: academyId,
      senderRole: senderRole,
      senderName: senderName,
      body: body,
      createdAt: DateTime.now(),
      replies: [],
    );
    _inquiries[id] = inquiry;
    return id;
  }
}
