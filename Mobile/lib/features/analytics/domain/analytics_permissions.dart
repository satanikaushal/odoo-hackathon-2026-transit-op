import '../../../shared/models/user_role.dart';

extension AnalyticsPermissions on UserRole {
  bool get canAccessReports {
    return this == UserRole.ADMIN ||
        this == UserRole.FLEET_MANAGER ||
        this == UserRole.FINANCIAL_ANALYST ||
        this == UserRole.SAFETY_OFFICER;
  }
}
