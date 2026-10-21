import 'package:flutter/material.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/features/connection/model/connection_status.dart';
import 'package:nerpa_vpn/features/connection/notifier/connection_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Nerpa VPN — Why the connection did not come up.
///
/// The core already reports the reason for a failed start (no privileges,
/// another VPN holding the TUN address, a broken config, a missing
/// license). It used to be visible only in the logs, so the home screen
/// showed a plain "couldn't connect" and the user had to guess.
///
/// The text is the one the failure itself produces, so it is already
/// translated.
class ConnectionFailureReason extends HookConsumerWidget {
  const ConnectionFailureReason({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final status = ref.watch(connectionNotifierProvider).asData?.value;

    final failure = switch (status) {
      Disconnected(:final connectionFailure?) => connectionFailure,
      _ => null,
    };
    if (failure == null) return const SizedBox.shrink();

    final presented = failure.present(t);
    final message = presented.message;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            presented.type,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.nerpaError,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.nerpaTextSecondary.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
