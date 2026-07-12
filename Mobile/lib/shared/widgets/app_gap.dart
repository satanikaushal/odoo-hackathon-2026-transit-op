import 'package:flutter/material.dart';

import '../utils/responsive.dart';

class AppGap extends StatelessWidget {
  const AppGap(this.value, {super.key, this.axis = Axis.vertical});

  final double value;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    if (axis == Axis.horizontal) {
      return Responsive.horizontalGap(value);
    }
    return Responsive.verticalGap(value);
  }
}
