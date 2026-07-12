import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFFD35400);
  static const primaryDark = Color(0xFFA04000);

  static const success = Color(0xFF2ECC71);
  static const info = Color(0xFF3498DB);
  static const warning = Color(0xFFF39C12);
  static const error = Color(0xFFE74C3C);

  static const available = success;
  static const onTrip = info;
  static const inShop = warning;
  static const retired = Color(0xFFE84393);
  static const offDuty = Color(0xFF95A5A6);
  static const suspended = warning;
  static const draft = Color(0xFF636E72);
  static const dispatched = info;
  static const completed = success;
  static const cancelled = error;

  // Dark
  static const darkBackground = Color(0xFF0A0A0A);
  static const darkSurface = Color(0xFF141414);
  static const darkSurfaceVariant = Color(0xFF1E1E1E);
  static const darkBorder = Color(0xFF2A2A2A);
  static const darkTextPrimary = Color(0xFFF5F5F5);
  static const darkTextSecondary = Color(0xFFB0B0B0);
  static const darkTextMuted = Color(0xFF707070);

  // Light
  static const lightBackground = Color(0xFFF5F6F8);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF0F2F5);
  static const lightBorder = Color(0xFFE1E4E8);
  static const lightTextPrimary = Color(0xFF1A1A1A);
  static const lightTextSecondary = Color(0xFF5C5C5C);
  static const lightTextMuted = Color(0xFF8A8A8A);
}
