enum ExpenseCategory {
  toll,
  misc;

  String get apiValue {
    return switch (this) {
      ExpenseCategory.toll => 'TOLL',
      ExpenseCategory.misc => 'MISC',
    };
  }

  String get label {
    return switch (this) {
      ExpenseCategory.toll => 'Toll',
      ExpenseCategory.misc => 'Misc',
    };
  }

  static ExpenseCategory? fromString(String? value) {
    if (value == null) {
      return null;
    }
    for (final category in ExpenseCategory.values) {
      if (category.apiValue == value) {
        return category;
      }
    }
    return null;
  }
}
