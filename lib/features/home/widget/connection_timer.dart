import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/features/connection/model/connection_status.dart';
import 'package:nerpa_vpn/features/connection/notifier/connection_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Nerpa VPN — How long the tunnel has been up.
///
/// The counter starts when the core reports the connection as established
/// and stops on the first disconnect, so a hot reload (which keeps the
/// tunnel up) does not restart it.
class ConnectionTimer extends HookConsumerWidget {
  const ConnectionTimer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionNotifierProvider).valueOrNull;

    // The moment the tunnel came up. `null` while the core is not connected.
    final connectedAt = useMemoized<DateTime?>(() {
      if (status is Connected) return DateTime.now();
      return null;
    }, [status is Connected]);

    // One tick per second, only while the tunnel is up.
    final tick = useState(0);
    useEffect(() {
      if (connectedAt == null) return null;
      final timer = Timer.periodic(const Duration(seconds: 1), (_) => tick.value++);
      return timer.cancel;
    }, [connectedAt != null]);

    if (connectedAt == null) return const SizedBox.shrink();

    final elapsed = DateTime.now().difference(connectedAt);
    final label = '${_two(elapsed.inHours)}:${_two(elapsed.inMinutes % 60)}:${_two(elapsed.inSeconds % 60)}';

    return Text(
      label,
      style: TextStyle(
        color: AppTheme.nerpaTextMuted,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
