import 'package:flutter/material.dart';

/// Ensures pushed sub-routes fully cover the previous screen during transitions.
class OpaqueRouteBackground extends StatelessWidget {
  const OpaqueRouteBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}

/// Scaffold wrapper for shell sub-routes with a guaranteed opaque background.
class SubRouteScaffold extends StatelessWidget {
  const SubRouteScaffold({
    super.key,
    required this.body,
  });

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: body,
    );
  }
}
