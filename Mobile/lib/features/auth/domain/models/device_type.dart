import 'package:flutter/foundation.dart';

// ignore_for_file: constant_identifier_names

enum DeviceType {
  ANDROID,
  IOS;

  String get value => name;

  static DeviceType get current {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => DeviceType.IOS,
      _ => DeviceType.ANDROID,
    };
  }
}
