import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:nerpa_vpn/core/app_info/app_info_provider.dart';
import 'package:nerpa_vpn/core/directories/directories_provider.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/model/constants.dart';
import 'package:nerpa_vpn/core/model/failures.dart';
import 'package:nerpa_vpn/core/notification/in_app_notification_controller.dart';
import 'package:nerpa_vpn/core/router/dialog/dialog_notifier.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/core/widget/adaptive_icon.dart';
import 'package:nerpa_vpn/features/app_update/notifier/app_update_notifier.dart';
import 'package:nerpa_vpn/features/app_update/notifier/app_update_state.dart';
import 'package:nerpa_vpn/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AboutPage extends HookConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final appInfo = ref.watch(appInfoProvider).requireValue;
    final appUpdate = ref.watch(appUpdateNotifierProvider);

    ref.listen(appUpdateNotifierProvider, (_, next) async {
      if (!context.mounted) return;
      switch (next) {
        case AppUpdateStateAvailable(:final versionInfo) || AppUpdateStateIgnored(:final versionInfo):
          return await ref
              .read(dialogNotifierProvider.notifier)
              .showNewVersion(currentVersion: appInfo.presentVersion, newVersion: versionInfo, canIgnore: false);
        case AppUpdateStateError(:final error):
          return ref.read(inAppNotificationControllerProvider).showErrorToast(t.presentShortError(error));
        case AppUpdateStateNotAvailable():
          return ref.read(inAppNotificationControllerProvider).showSuccessToast(t.pages.about.notAvailableMsg);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.nerpaBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.nerpaSurface,
        title: Text(
          t.pages.about.title,
          style: const TextStyle(color: AppTheme.nerpaTextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(AdaptiveIcon(context).more, color: AppTheme.nerpaTextMuted),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: appInfo.format()));
              ref.read(inAppNotificationControllerProvider).showSuccessToast(t.common.addToClipboard);
            },
          ),
          const Gap(8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App Hero Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.nerpaAccent.withOpacity(0.08), AppTheme.nerpaAccentBlue.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.nerpaBorder.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.nerpaAccent, AppTheme.nerpaAccentBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.nerpaAccent.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.waves_rounded, color: Colors.white, size: 38),
                  ),
                  const Gap(16),
                  const Text(
                    'Nerpa VPN',
                    style: TextStyle(
                      color: AppTheme.nerpaTextPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    '${t.common.version} ${appInfo.presentVersion}',
                    style: const TextStyle(color: AppTheme.nerpaAccent, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Gap(4),
                  const Text(
                    'Fast & Secure Multi-Protocol VPN',
                    style: TextStyle(color: AppTheme.nerpaTextMuted, fontSize: 12),
                  ),
                ],
              ),
            ),

            const Gap(24),

            // ── Actions ──
            if (appInfo.release.allowCustomUpdateChecker) ...[
              _AboutTile(
                icon: FluentIcons.arrow_sync_24_regular,
                title: t.pages.about.checkForUpdate,
                trailing: appUpdate is AppUpdateStateChecking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.nerpaAccent),
                      )
                    : null,
                onTap: () async => await ref.read(appUpdateNotifierProvider.notifier).check(),
              ),
              const Gap(8),
            ],
            if (PlatformUtils.isDesktop) ...[
              _AboutTile(
                icon: FluentIcons.folder_open_24_regular,
                title: t.pages.about.openWorkingDir,
                onTap: () async {
                  final path = ref.watch(appDirectoriesProvider).requireValue.workingDir.uri;
                  await UriUtils.tryLaunch(path);
                },
              ),
              const Gap(8),
            ],

            const Gap(8),

            // ── Section: Links ──
            const Text(
              'LINKS',
              style: TextStyle(
                color: AppTheme.nerpaTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const Gap(10),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121215),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.nerpaBorder.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _AboutListItem(
                    icon: FluentIcons.code_24_regular,
                    title: t.pages.about.sourceCode,
                    subtitle: 'GitHub',
                    isFirst: true,
                    onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.githubUrl)),
                  ),
                  _Divider(),
                  _AboutListItem(
                    icon: FluentIcons.send_24_regular,
                    title: t.pages.about.telegramChannel,
                    subtitle: '@nerpa_vpn',
                    onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.telegramChannelUrl)),
                  ),
                  _Divider(),
                  _AboutListItem(
                    icon: FluentIcons.shield_24_regular,
                    title: t.pages.about.privacyPolicy,
                    subtitle: 'nerpa-vpn.app',
                    onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.privacyPolicyUrl)),
                  ),
                  _Divider(),
                  _AboutListItem(
                    icon: FluentIcons.document_24_regular,
                    title: t.pages.about.termsAndConditions,
                    subtitle: 'nerpa-vpn.app',
                    isLast: true,
                    onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.termsAndConditionsUrl)),
                  ),
                ],
              ),
            ),

            const Gap(24),

            // ── Core attribution ──
            Center(
              child: Text(
                'Powered by Nerpa VPN core & sing-box',
                style: const TextStyle(color: AppTheme.nerpaTextMuted, fontSize: 11),
              ),
            ),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({required this.icon, required this.title, this.trailing, required this.onTap});
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF121215),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.nerpaBorder.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.nerpaAccent, size: 20),
            const Gap(12),
            Expanded(
              child: Text(title, style: const TextStyle(color: AppTheme.nerpaTextPrimary, fontSize: 14)),
            ),
            trailing ?? const Icon(FluentIcons.chevron_right_24_regular, color: AppTheme.nerpaTextMuted, size: 16),
          ],
        ),
      ),
    );
  }
}

class _AboutListItem extends StatelessWidget {
  const _AboutListItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    BorderRadius? radius;
    if (isFirst) radius = const BorderRadius.vertical(top: Radius.circular(14));
    if (isLast) radius = const BorderRadius.vertical(bottom: Radius.circular(14));

    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.nerpaTextMuted, size: 18),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppTheme.nerpaTextPrimary, fontSize: 14)),
                  if (subtitle != null) ...[
                    const Gap(2),
                    Text(subtitle!, style: const TextStyle(color: AppTheme.nerpaTextMuted, fontSize: 12)),
                  ],
                ],
              ),
            ),
            const Icon(FluentIcons.open_24_regular, color: AppTheme.nerpaTextMuted, size: 14),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 46, color: AppTheme.nerpaBorder.withOpacity(0.3));
  }
}
