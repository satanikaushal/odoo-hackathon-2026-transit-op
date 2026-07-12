import 'package:flutter/material.dart';

Future<bool?> showConflictDialog(
  BuildContext context, {
  required String message,
  String confirmLabel = 'OK',
  VoidCallback? onConfirm,
  String? secondaryLabel,
  VoidCallback? onSecondary,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Action blocked'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          if (secondaryLabel != null && onSecondary != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                onSecondary();
              },
              child: Text(secondaryLabel),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm?.call();
            },
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

void showSnackBarMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
