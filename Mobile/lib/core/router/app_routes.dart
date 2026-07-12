import 'package:flutter/material.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
}
