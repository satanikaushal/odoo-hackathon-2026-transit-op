import '../../../shared/models/user_role.dart';

extension ExpensesPermissions on UserRole {
  bool get canReadFuelLogs {
    return this == UserRole.ADMIN ||
        this == UserRole.FLEET_MANAGER ||
        this == UserRole.FINANCIAL_ANALYST ||
        this == UserRole.DRIVER;
  }

  bool get canCreateFuelLogs {
    return this == UserRole.ADMIN ||
        this == UserRole.FLEET_MANAGER ||
        this == UserRole.DRIVER;
  }

  bool get canReadExpenses {
    return this == UserRole.ADMIN ||
        this == UserRole.FLEET_MANAGER ||
        this == UserRole.FINANCIAL_ANALYST;
  }

  bool get canCreateExpenses {
    return this == UserRole.ADMIN || this == UserRole.FLEET_MANAGER;
  }
}
