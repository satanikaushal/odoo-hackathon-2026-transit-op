import 'package:flutter/material.dart';

/// Responsive scaling based on a 375 x 812 design reference.
///
/// Call [init] once via `MaterialApp.builder` before using any helper.
class Responsive {
  Responsive._();

  static const double designWidth = 375;
  static const double designHeight = 812;

  static late double _screenWidth;
  static late double _screenHeight;
  static bool _initialized = false;

  static void init(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    _screenWidth = size.width;
    _screenHeight = size.height;
    _initialized = true;
  }

  static double get _widthScale {
    _checkInit();
    return _screenWidth / designWidth;
  }

  static double get _heightScale {
    _checkInit();
    return _screenHeight / designHeight;
  }

  static double get _fontScale => _widthScale.clamp(0.85, 1.2);

  static double get _sizeScale =>
      _widthScale < _heightScale ? _widthScale : _heightScale;

  static void _checkInit() {
    assert(
      _initialized,
      'Responsive.init(context) must be called in MaterialApp.builder.',
    );
  }

  static double getW(double value) => value * _widthScale;

  static double getH(double value) => value * _heightScale;

  static double getF(double value) => value * _fontScale;

  static double getR(double value) => value * _sizeScale;

  static double getSize(double value) => value * _sizeScale;

  static EdgeInsets getPadding(double value) {
    return EdgeInsets.all(getW(value));
  }

  static EdgeInsets getPaddingSymmetric({
    required double horizontal,
    required double vertical,
  }) {
    return EdgeInsets.symmetric(
      horizontal: getW(horizontal),
      vertical: getH(vertical),
    );
  }

  static EdgeInsets getPaddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(
      left: getW(left),
      top: getH(top),
      right: getW(right),
      bottom: getH(bottom),
    );
  }

  static EdgeInsets getMargin(double value) => getPadding(value);

  static EdgeInsets getMarginSymmetric({
    required double horizontal,
    required double vertical,
  }) {
    return getPaddingSymmetric(horizontal: horizontal, vertical: vertical);
  }

  static SizedBox verticalGap(double value) {
    return SizedBox(height: getH(value));
  }

  static SizedBox horizontalGap(double value) {
    return SizedBox(width: getW(value));
  }
}
