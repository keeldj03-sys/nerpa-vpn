import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/features/proxy/active/active_proxy_notifier.dart';
import 'package:nerpa_vpn/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Nerpa VPN — Ping delay pill badge below the power button
class ActiveProxyDelayIndicator extends HookConsumerWidget with InfraLogger {
  const ActiveProxyDelayIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final activeProxy = ref.watch(activeProxyNotifierProvider);

    if (activeProxy is! AsyncData) return const SizedBox.shrink();

    final proxy = activeProxy.value!;
    final delay = proxy.urlTestDelay;
    final timeout = delay > 65000;

    // Color based on delay quality
    Color delayColor;
    if (delay <= 0) {
      delayColor = AppTheme.nerpaTextMuted;
    } else if (timeout) {
      delayColor = AppTheme.nerpaError;
    } else if (delay < 150) {
      delayColor = AppTheme.nerpaSuccess;  // green — fast
    } else if (delay < 400) {
      delayColor = AppTheme.nerpaWarning;  // amber — medium
    } else {
      delayColor = AppTheme.nerpaError;    // red — slow
    }

    return InkWell(
      onTap: () async {
        try {
          await ref.read(activeProxyNotifierProvider.notifier).urlTest('');
        } catch (e) {
          loggy.error('Error during URL test: $e');
        }
      },      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: delayColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: delayColor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FluentIcons.wifi_1_24_regular,
              size: 14,
              color: delayColor,
            ),
            const Gap(6),
            if (delay > 0)
              Text.rich(
                semanticsLabel: timeout
                    ? t.pages.proxies.delay.timeout
                    : t.pages.proxies.delay.result(delay: delay),
                TextSpan(
                  children: [
                    if (timeout)
                      TextSpan(
                        text: t.common.timeout,
                        style: TextStyle(
                          color: delayColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else ...[
                      TextSpan(
                        text: delay.toString(),
                        style: TextStyle(
                          color: delayColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' ms',
                        style: TextStyle(
                          color: delayColor.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              Semantics(
                label: t.pages.proxies.delay.testing,
                child: Text(
                  '—',
                  style: TextStyle(color: delayColor, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
