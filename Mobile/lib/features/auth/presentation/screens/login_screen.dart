import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_text.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AppText(
          'Login',
          size: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
