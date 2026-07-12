import '../../../shared/models/user_role.dart';

extension MaintenancePermissions on UserRole {
  bool get canManageMaintenance {
    return this == UserRole.ADMIN || this == UserRole.FLEET_MANAGER;
  }
}
