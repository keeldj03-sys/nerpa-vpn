import 'package:flutter/material.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/features/stats/notifier/stats_notifier.dart';
import 'package:nerpa_vpn/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:nerpa_vpn/utils/number_formatters.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Nerpa VPN — Traffic counters under the power button.
///
/// The core only reports traffic while the tunnel is up, so the row reads
/// zero when nothing is running rather than showing a stale value from the
/// previous session.
class ConnectionStatsRow extends HookConsumerWidget {
  const ConnectionStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsNotifierProvider).asData?.value ?? SystemInfo.create();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Counter(
          arrow: '↑',
          color: AppTheme.nerpaSuccess,
          value: stats.uplinkTotal.toInt().size(),
        ),
        const SizedBox(width: 18),
        _Counter(
          arrow: '↓',
          color: AppTheme.nerpaAccent,
          value: stats.downlinkTotal.toInt().size(),
        ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.arrow, required this.color, required this.value});

  final String arrow;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          arrow,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.nerpaTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
