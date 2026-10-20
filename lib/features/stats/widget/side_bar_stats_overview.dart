import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/model/constants.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/core/utils/preferences_utils.dart';
import 'package:nerpa_vpn/core/widget/animated_text.dart';
import 'package:nerpa_vpn/features/stats/notifier/stats_notifier.dart';
import 'package:nerpa_vpn/features/stats/widget/stats_card.dart';
import 'package:nerpa_vpn/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:nerpa_vpn/utils/number_formatters.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final showAllSidebarStatsProvider = PreferencesNotifier.createAutoDispose('show_all_sidebar_stats', false);

/// Nerpa VPN — Sidebar traffic stats (shown in desktop NavigationRail trailing)
class SideBarStatsOverview extends HookConsumerWidget {
  const SideBarStatsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final stats = ref.watch(statsNotifierProvider).asData?.value ?? SystemInfo.create();
    final showAll = ref.watch(showAllSidebarStatsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Expand/Collapse toggle ──
          InkWell(
            onTap: () => ref.read(showAllSidebarStatsProvider.notifier).update(!showAll),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedText(
                    showAll ? t.common.showLess : t.common.showMore,
                    style: const TextStyle(
                      color: AppTheme.nerpaTextMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AnimatedRotation(
                    turns: showAll ? 0.0 : 0.5,
                    duration: kAnimationDuration,
                    child: const Icon(
                      FluentIcons.chevron_down_16_regular,
                      size: 14,
                      color: AppTheme.nerpaTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(8),

          // ── Stats content ──
          AnimatedCrossFade(
            crossFadeState: showAll ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: kAnimationDuration,
            firstChild: StatsCard(
              title: t.components.stats.traffic,
              stats: [
                (
                  label: Icon(
                    FluentIcons.arrow_download_16_regular,
                    color: AppTheme.nerpaAccent,
                  ),
                  data: Text(
                    stats.downlink.toInt().speed(),
                    style: const TextStyle(color: AppTheme.nerpaAccent),
                  ),
                  semanticLabel: t.components.stats.speed,
                ),
                (
                  label: const Icon(
                    FluentIcons.arrow_bidirectional_up_down_16_regular,
                    color: AppTheme.nerpaTextMuted,
                  ),
                  data: Text(stats.downlinkTotal.toInt().size()),
                  semanticLabel: t.components.stats.totalTransferred,
                ),
              ],
            ),
            secondChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatsCard(
                  title: t.components.stats.trafficLive,
                  stats: [
                    (
                      label: const Text('↑', style: TextStyle(color: AppTheme.nerpaSuccess, fontSize: 13)),
                      data: Text(stats.uplink.toInt().speed()),
                      semanticLabel: t.components.stats.uplink,
                    ),
                    (
                      label: const Text('↓', style: TextStyle(color: AppTheme.nerpaError, fontSize: 13)),
                      data: Text(stats.downlink.toInt().speed()),
                      semanticLabel: t.components.stats.downlink,
                    ),
                  ],
                ),
                const Gap(8),
                StatsCard(
                  title: t.components.stats.trafficTotal,
                  stats: [
                    (
                      label: const Text('↑', style: TextStyle(color: AppTheme.nerpaSuccess, fontSize: 13)),
                      data: Text(stats.uplinkTotal.toInt().size()),
                      semanticLabel: t.components.stats.uplink,
                    ),
                    (
                      label: const Text('↓', style: TextStyle(color: AppTheme.nerpaError, fontSize: 13)),
                      data: Text(stats.downlinkTotal.toInt().size()),
                      semanticLabel: t.components.stats.downlink,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
