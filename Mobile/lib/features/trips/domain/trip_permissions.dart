import '../../../shared/models/user_role.dart';

extension TripPermissions on UserRole {
  bool get canManageTrips {
    return this == UserRole.ADMIN ||
        this == UserRole.FLEET_MANAGER ||
        this == UserRole.DRIVER;
  }
}
