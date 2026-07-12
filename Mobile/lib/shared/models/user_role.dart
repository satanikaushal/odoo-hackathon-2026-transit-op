// ignore_for_file: constant_identifier_names

enum UserRole {
  ADMIN,
  FLEET_MANAGER,
  DRIVER,
  SAFETY_OFFICER,
  FINANCIAL_ANALYST;

  String get value => name;

  String get label {
    return switch (this) {
      UserRole.ADMIN => 'Admin',
      UserRole.FLEET_MANAGER => 'Fleet Manager',
      UserRole.DRIVER => 'Dispatcher',
      UserRole.SAFETY_OFFICER => 'Safety Officer',
      UserRole.FINANCIAL_ANALYST => 'Financial Analyst',
    };
  }

  static UserRole? fromString(String? value) {
    if (value == null) {
      return null;
    }

    for (final role in UserRole.values) {
      if (role.name == value) {
        return role;
      }
    }
    return null;
  }
}
