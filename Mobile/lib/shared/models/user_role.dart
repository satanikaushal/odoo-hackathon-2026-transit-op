enum UserRole {
  fleetManager('fleet_manager', 'Fleet Manager'),
  dispatcher('dispatcher', 'Dispatcher'),
  safetyOfficer('safety_officer', 'Safety Officer'),
  financialAnalyst('financial_analyst', 'Financial Analyst');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  static UserRole? fromString(String? value) {
    if (value == null) {
      return null;
    }
    for (final role in UserRole.values) {
      if (role.value == value) {
        return role;
      }
    }
    return null;
  }
}
