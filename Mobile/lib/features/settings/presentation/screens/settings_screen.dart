import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_session_provider.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_dialogs.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_text.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionProvider);
    final themeMode = ref.watch(themeModeProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return ListView(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
      children: [
        if (user != null) ...[
          _SettingsCard(
            borderColor: borderColor,
            surfaceColor: surfaceColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText(
                  'ACCOUNT',
                  size: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const AppGap(16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: Responsive.getR(24),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: AppText(
                        _initials(user.name),
                        size: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Responsive.horizontalGap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            user.name,
                            size: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          Responsive.verticalGap(4),
                          AppText(
                            user.email,
                            size: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          Responsive.verticalGap(10),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(Responsive.getR(20)),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Padding(
                              padding: Responsive.getPaddingSymmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: AppText(
                                user.role.label,
                                size: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const AppGap(16),
        ],
        _SettingsCard(
          borderColor: borderColor,
          surfaceColor: surfaceColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                'APPEARANCE',
                size: 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const AppGap(12),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto, size: 18),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined, size: 18),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (selection) {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(selection.first);
                },
              ),
            ],
          ),
        ),
        const AppGap(16),
        _SettingsCard(
          borderColor: borderColor,
          surfaceColor: surfaceColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                'ABOUT',
                size: 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const AppGap(12),
              _InfoRow(
                label: 'App',
                value: AppEnvironment.current.appName,
              ),
              const AppGap(8),
              _InfoRow(
                label: 'Version',
                value: _appVersion,
              ),
              if (!kReleaseMode) ...[
                const AppGap(8),
                _InfoRow(
                  label: 'Environment',
                  value: AppEnvironment.current.env.name,
                ),
              ],
            ],
          ),
        ),
        const AppGap(24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: user == null ? null : () => _signOut(context, ref),
            style: OutlinedButton.styleFrom(
              minimumSize: Size.fromHeight(Responsive.getH(48)),
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.getR(10)),
              ),
            ),
            child: AppText(
              'Sign Out',
              size: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),
        ),
        const AppGap(16),
      ],
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign out',
      message: 'You will need to sign in again to access TransitOps.',
      confirmLabel: 'Sign out',
      isDestructive: true,
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    await ref.read(authSessionProvider.notifier).signOut();
    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    final letters = parts.map((part) => part[0]).take(2).join();
    return letters.isEmpty ? '?' : letters.toUpperCase();
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.borderColor,
    required this.surfaceColor,
    required this.child,
  });

  final Color borderColor;
  final Color surfaceColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(Responsive.getR(12)),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: AppText(
            label,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        AppText(
          value,
          size: 14,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}
