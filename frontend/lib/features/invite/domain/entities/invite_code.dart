// Invite domain entities - additional types for invite feature

/// Invite type for different connection types
enum InviteType {
  teacherToStudent,
  teacherToParent,
  parentToStudent;

  String get label {
    switch (this) {
      case InviteType.teacherToStudent:
        return '학생 초대';
      case InviteType.teacherToParent:
        return '학부모 초대';
      case InviteType.parentToStudent:
        return '자녀 연결';
    }
  }
}
