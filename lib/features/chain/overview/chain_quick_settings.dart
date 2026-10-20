import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/model/constants.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/features/chain/overview/chain_mode_button.dart';
import 'package:nerpa_vpn/features/common/custom_text_scroll.dart';
import 'package:nerpa_vpn/features/profile/notifier/active_profile_notifier.dart';
import 'package:nerpa_vpn/features/settings/data/config_option_repository.dart';

class ChainQuickSettings extends HookConsumerWidget {
  const ChainQuickSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final onSurfaceVariant = AppTheme.nerpaTextSecondary.withValues(alpha: 0.92);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ChainNodeLabel(
                    icon: ChainConst.iconByPlatform(),
                    title: t.pages.settings.chain.levels.app.title,
                    color: onSurfaceVariant,
                  ),
                  const Gap(10),
                  Icon(Icons.arrow_downward_rounded, size: 20, color: AppTheme.nerpaAccent.withValues(alpha: 0.92)),
                  const Gap(10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      t.pages.settings.chain.levels.extraSecurity.title,
                      style: theme.textTheme.labelSmall?.copyWith(color: onSurfaceVariant, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Gap(6),
                  const ChainModeButton.extraSecurity(showConfiguration: true),
                  const Gap(6),
                  AnimatedOpacity(
                    duration: ChainConst.finalIpDuration,
                    opacity: ref.watch(ConfigOptions.chainStatus).isExtraSecurity() ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        t.pages.settings.chain.finalIp,
                        style: theme.textTheme.labelSmall?.copyWith(color: ChainConst.finalIpColor(theme)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.topCenter,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: () {
                            context.pop();
                            context.goNamed('chainOptions');
                          },
                          child: Ink(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: AppTheme.nerpaAccent.withValues(alpha: 0.22)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Gap(2),
                                const Icon(Icons.webhook_rounded, size: 18, color: AppTheme.nerpaAccent),
                                const Gap(6),
                                Flexible(
                                  child: Text(
                                    t.pages.settings.chain.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.nerpaAccent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Gap(2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: AppTheme.nerpaAccent.withValues(alpha: 0.92),
                        ),
                      ),
                      Flexible(
                        child: Column(
                          children: [
                            Text(
                              t.pages.settings.chain.levels.mainProfile.title,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const Gap(6),
                            Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              alignment: Alignment.center,
                              child: CustomTextScroll(
                                ref.watch(activeProfileProvider).value?.name ?? t.common.notSet,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            AnimatedOpacity(
                              duration: ChainConst.finalIpDuration,
                              opacity: ref.watch(ConfigOptions.chainStatus).isExtraSecurity() ? 0 : 1,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  t.pages.settings.chain.finalIp,
                                  style: theme.textTheme.labelSmall?.copyWith(color: ChainConst.finalIpColor(theme)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: AppTheme.nerpaAccent.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ChainNodeLabel(
                    icon: Icons.wifi_rounded,
                    title: t.pages.settings.chain.levels.filtering.title,
                    color: onSurfaceVariant,
                  ),
                  const Gap(10),
                  Icon(Icons.arrow_upward_rounded, size: 20, color: AppTheme.nerpaAccent.withValues(alpha: 0.92)),
                  const Gap(10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      t.pages.settings.chain.levels.unblocker.title,
                      style: theme.textTheme.labelSmall?.copyWith(color: onSurfaceVariant, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Gap(6),
                  const ChainModeButton.unblocker(showConfiguration: true),
                  const Gap(6),
                  // For equal height
                  Opacity(
                    opacity: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        t.pages.settings.chain.finalIp,
                        style: theme.textTheme.labelSmall?.copyWith(color: ChainConst.finalIpColor(theme)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainNodeLabel extends StatelessWidget {
  const _ChainNodeLabel({required this.icon, required this.title, required this.color});

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const Gap(6),
          Flexible(
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
