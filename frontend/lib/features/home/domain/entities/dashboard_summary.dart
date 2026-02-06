/// Dashboard summary stats for teacher home
class DashboardSummary {
  final int todayLessons;
  final int weeklyLessons;
  final int pendingPayments;
  final int unreadNotifications;

  const DashboardSummary({
    this.todayLessons = 0,
    this.weeklyLessons = 0,
    this.pendingPayments = 0,
    this.unreadNotifications = 0,
  });

  DashboardSummary copyWith({
    int? todayLessons,
    int? weeklyLessons,
    int? pendingPayments,
    int? unreadNotifications,
  }) {
    return DashboardSummary(
      todayLessons: todayLessons ?? this.todayLessons,
      weeklyLessons: weeklyLessons ?? this.weeklyLessons,
      pendingPayments: pendingPayments ?? this.pendingPayments,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
    );
  }
}
