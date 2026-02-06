import '../entities/subscription_proposal.dart';

/// Repository interface for subscription proposals.
abstract class SubscriptionProposalRepository {
  /// Get all proposals created by a teacher
  Future<List<SubscriptionProposal>> getByTeacher(String teacherId);

  /// Get all proposals received by a student
  Future<List<SubscriptionProposal>> getByStudent(String studentId);

  /// Get active proposals for a teacher (pending or paymentNotified)
  Future<List<SubscriptionProposal>> getActiveByTeacher(String teacherId);

  /// Get active proposals for a student (pending or paymentNotified)
  Future<List<SubscriptionProposal>> getActiveByStudent(String studentId);

  /// Get pending proposals awaiting student action
  Future<List<SubscriptionProposal>> getPendingByStudent(String studentId);

  /// Get proposals awaiting teacher payment confirmation
  Future<List<SubscriptionProposal>> getAwaitingConfirmation(String teacherId);

  /// Get a proposal by ID
  Future<SubscriptionProposal?> getById(String id);

  /// Create a new proposal
  Future<SubscriptionProposal> create(SubscriptionProposal proposal);

  /// Student notifies payment completion
  Future<SubscriptionProposal> notifyPayment(String id);

  /// Teacher confirms payment and issues subscription
  Future<SubscriptionProposal> confirmPayment(
      String id, String subscriptionId);

  /// Student rejects the proposal
  Future<SubscriptionProposal> reject(String id, String? reason);

  /// Teacher cancels the proposal
  Future<SubscriptionProposal> cancel(String id);

  /// Mark expired proposals as expired (called periodically)
  Future<void> expireOldProposals();

  /// Get proposal between a specific teacher and student
  Future<SubscriptionProposal?> getActiveProposal(
      String teacherId, String studentId);

  /// Student selects a template from multi-choice proposal (v4)
  Future<SubscriptionProposal> selectTemplate(String id, String templateId);
}
