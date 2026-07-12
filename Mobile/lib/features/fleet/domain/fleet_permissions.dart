import '../../../shared/models/user_role.dart';

extension FleetPermissions on UserRole {
  bool get canManageFleet {
    return this == UserRole.ADMIN || this == UserRole.FLEET_MANAGER;
  }
}
