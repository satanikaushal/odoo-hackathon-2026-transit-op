import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_dialogs.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/auth_session_provider.dart';
import '../../domain/auth_constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialCredentials());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loadInitialCredentials() {
    final preferences = ref.read(preferencesServiceProvider);
    final useDevDefaults = !kReleaseMode;

    setState(() {
      _rememberMe = preferences.rememberMe;

      final savedEmail = preferences.savedEmail;
      if (_rememberMe && savedEmail != null && savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
      } else if (useDevDefaults) {
        _emailController.text = DevAuthCredentials.email;
      }

      if (useDevDefaults) {
        _passwordController.text = DevAuthCredentials.password;
      }
    });
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final failure = await ref.read(authSessionProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (failure != null) {
      showSnackBarMessage(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = AppEnvironment.current;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: Responsive.getPaddingSymmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.getW(420)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: Responsive.getSize(56),
                      color: colorScheme.primary,
                    ),
                    const AppGap(20),
                    AppText(
                      config.appName,
                      size: 28,
                      fontWeight: FontWeight.w700,
                      textAlign: TextAlign.center,
                    ),
                    const AppGap(8),
                    AppText(
                      'Sign in to manage your fleet operations',
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                      textAlign: TextAlign.center,
                    ),
                    const AppGap(32),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !_isLoading,
                      validator: _validateEmail,
                    ),
                    const AppGap(16),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter Password',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      enabled: !_isLoading,
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _submit(),
                      suffixIcon: IconButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    const AppGap(12),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _rememberMe = !_rememberMe;
                                    });
                                  },
                            child: AppText(
                              'Remember me',
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const AppGap(24),
                    AppButton(
                      label: 'Sign in',
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required';
    }

    final emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailPattern.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }
}
