import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum VehicleStatusBucket {
  available,
  onTrip,
  inShop,
  retired,
}

class VehicleStatusBreakdownItem {
  const VehicleStatusBreakdownItem({
    required this.bucket,
    required this.count,
  });

  final VehicleStatusBucket bucket;
  final int count;

  String get label {
    return switch (bucket) {
      VehicleStatusBucket.available => 'Available',
      VehicleStatusBucket.onTrip => 'On Trip',
      VehicleStatusBucket.inShop => 'In Shop',
      VehicleStatusBucket.retired => 'Retired',
    };
  }

  Color get color {
    return switch (bucket) {
      VehicleStatusBucket.available => AppColors.available,
      VehicleStatusBucket.onTrip => AppColors.onTrip,
      VehicleStatusBucket.inShop => AppColors.inShop,
      VehicleStatusBucket.retired => AppColors.retired,
    };
  }
}

class VehicleStatusBreakdown {
  const VehicleStatusBreakdown({required this.items});

  final List<VehicleStatusBreakdownItem> items;

  int get total => items.fold(0, (sum, item) => sum + item.count);
}
