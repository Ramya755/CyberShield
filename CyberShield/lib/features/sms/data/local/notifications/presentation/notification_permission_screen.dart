import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scam_detector/core/theme/app_colors.dart';

import '../providers/notification_listener_provider.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationListenerProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.primaryNeonGreen.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.primaryNeonGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable notification access',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Allow Scam Detector to read WhatsApp, Messages, and Messenger alerts so we can detect scams locally.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Steps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryNeonGreen,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              _StepTile(
                index: '01',
                title: 'Open notification access',
                subtitle: 'We will take you to Android settings.',
              ),
              const SizedBox(height: 12),
              _StepTile(
                index: '02',
                title: 'Enable Scam Detector',
                subtitle: 'Toggle the permission for this app.',
              ),
              const SizedBox(height: 12),
              _StepTile(
                index: '03',
                title: 'Return to the app',
                subtitle: 'We will start capturing notifications.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await provider.openNotificationAccessSettings();
                    await Future<void>.delayed(const Duration(milliseconds: 600));
                    await provider.refreshPermission();
                  },
                  icon: const Icon(Icons.settings_rounded),
                  label: const Text('Open notification access'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                provider.permissionEnabled
                    ? 'Permission is enabled. You can go back.'
                    : 'Permission is still disabled. Please enable it.',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String index;
  final String title;
  final String subtitle;

  const _StepTile({
    required this.index,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarker.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryNeonGreen.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              index,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primaryNeonGreen,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
