import 'package:flutter/material.dart';

import '../../../shared/widgets/app_text.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppText(
        title,
        size: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
