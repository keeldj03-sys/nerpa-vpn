import 'package:flutter/material.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/features/stats/notifier/stats_notifier.dart';
import 'package:nerpa_vpn/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:nerpa_vpn/utils/number_formatters.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Nerpa VPN — Traffic counters under the power button.
///
/// The core reports the current rate (`uplink` / `downlink`) next to the
/// totals (`uplinkTotal` / `downlinkTotal`). The rate is what the user feels
/// right now, the total is what the provider bills for, so both are shown.
///
/// The core only reports traffic while the tunnel is up, so the row reads
/// zero when nothing is running rather than showing a stale value from the
/// previous session.
class ConnectionStatsRow extends HookConsumerWidget {
  const ConnectionStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsNotifierProvider).asData?.value ?? SystemInfo.create();
    final t = ref.watch(translationsProvider).requireValue;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Counter(
          arrow: '↑',
          color: AppTheme.nerpaSuccess,
          speed: stats.uplink.toInt().speed(),
          total: stats.uplinkTotal.toInt().size(),
          speedLabel: '${t.components.stats.uplink}: ${t.components.stats.speed}',
        ),
        const SizedBox(width: 18),
        _Counter(
          arrow: '↓',
          color: AppTheme.nerpaAccent,
          speed: stats.downlink.toInt().speed(),
          total: stats.downlinkTotal.toInt().size(),
          speedLabel: '${t.components.stats.downlink}: ${t.components.stats.speed}',
        ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.arrow,
    required this.color,
    required this.speed,
    required this.total,
    required this.speedLabel,
  });

  final String arrow;
  final Color color;
  final String speed;
  final String total;

  /// Spoken description of the pair, so a screen reader does not read two
  /// bare numbers one after the other.
  final String speedLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: speedLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            arrow,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 5),
          // The current rate, in the accent colour: it is the live number.
          Text(
            speed,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 6),
          // The total for this session, dimmed: context for the rate.
          Text(
            total,
            style: TextStyle(
              color: AppTheme.nerpaTextSecondary.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
