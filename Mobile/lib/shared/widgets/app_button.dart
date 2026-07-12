import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'app_text.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(Responsive.getH(48)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.getR(10)),
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: Responsive.getH(20),
              width: Responsive.getW(20),
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : AppText(
              label,
              size: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
    );

    if (!expand) {
      return button;
    }

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }
}
