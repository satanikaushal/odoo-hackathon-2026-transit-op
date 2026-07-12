import '../../../shared/models/user_role.dart';

extension DriverPermissions on UserRole {
  bool get canManageDrivers {
    return this == UserRole.ADMIN ||
        this == UserRole.SAFETY_OFFICER ||
        this == UserRole.FLEET_MANAGER;
  }
}
