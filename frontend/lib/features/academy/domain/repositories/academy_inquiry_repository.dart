import 'package:lessonaza/features/academy/domain/entities/academy_inquiry.dart';

abstract class AcademyInquiryRepository {
  Future<List<AcademyInquiry>> listByAcademy(String academyId);
  Future<AcademyInquiry> getById(String inquiryId);
  Future<void> reply(String inquiryId, String body);
  Future<String> create({
    required String academyId,
    required InquirySenderRole senderRole,
    required String senderName,
    required String body,
  });
}
