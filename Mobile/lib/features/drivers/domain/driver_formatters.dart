import 'package:intl/intl.dart';

import 'models/driver.dart';

abstract final class DriverFormatters {
  static final _expiryDisplay = DateFormat('MM/yyyy');
  static final _expiryDetail = DateFormat('dd MMM yyyy');

  static String formatExpiry(Driver driver) {
    return _expiryDisplay.format(driver.licenseExpiryDate);
  }

  static String formatExpiryDetail(Driver driver) {
    return _expiryDetail.format(driver.licenseExpiryDate);
  }

  static String formatSafetyScore(double score) {
    return '${score.round()}%';
  }

  static String maskContact(String contact) {
    if (contact.length <= 5) {
      return contact;
    }
    final visible = contact.substring(0, contact.length - 5);
    return '$visible${'X' * 5}';
  }
}
