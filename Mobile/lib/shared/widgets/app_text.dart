import 'package:flutter/material.dart';

import '../utils/responsive.dart';

class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    required this.size,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final double size;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: Responsive.getF(size),
        color: color ?? Theme.of(context).colorScheme.onSurface,
        fontWeight: fontWeight,
      ),
    );
  }
}
