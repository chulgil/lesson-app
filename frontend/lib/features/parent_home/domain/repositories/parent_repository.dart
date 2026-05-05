import '../entities/parent.dart';
import '../entities/parent_child_relation.dart';
import '../entities/parent_visibility_settings.dart';
import '../entities/parent_notification_settings.dart';

/// Repository for managing parent data and relationships
abstract class ParentRepository {
  // Parent CRUD
  Future<List<Parent>> getParents();
  Future<Parent?> getParent(String id);
  Future<Parent?> getParentByUserId(String userId);
  Future<Parent> createParent(Parent parent);
  Future<Parent> updateParent(Parent parent);
  Future<void> deleteParent(String id);

  // Parent Invitation
  Future<ParentInvitation> createInvitation(ParentInvitation invitation);
  Future<ParentInvitation?> getInvitationByCode(String code);
  Future<void> markInvitationUsed(String invitationId);
  Future<List<ParentInvitation>> getPendingInvitationsForStudent(
    String studentId,
  );

  // Parent-Child Relations
  Future<List<ParentChildRelation>> getRelationsForParent(String parentId);
  Future<List<ParentChildRelation>> getRelationsForStudent(String studentId);
  Future<ParentChildRelation?> getRelation(String parentId, String studentId);
  Future<ParentChildRelation> createRelation(ParentChildRelation relation);
  Future<ParentChildRelation> updateRelation(ParentChildRelation relation);
  Future<void> deleteRelation(String relationId);

  // Visibility Settings
  Future<ParentVisibilitySettings?> getVisibilitySettings(
    String teacherId,
    String studentId,
  );
  Future<ParentVisibilitySettings> saveVisibilitySettings(
    ParentVisibilitySettings settings,
  );

  // Notification Settings
  Future<ParentNotificationSettings?> getNotificationSettings(String parentId);
  Future<ParentNotificationSettings> saveNotificationSettings(
    ParentNotificationSettings settings,
  );

  // Billing
  Future<Parent?> getBillingTargetForStudent(String studentId);
}
