import 'package:flutter/material.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/notification/in_app_notification_controller.dart';
import 'package:nerpa_vpn/core/preferences/general_preferences.dart';
import 'package:nerpa_vpn/features/connection/notifier/connection_notifier.dart';
import 'package:nerpa_vpn/features/profile/notifier/active_profile_notifier.dart';
import 'package:nerpa_vpn/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:nerpa_vpn/utils/custom_loggers.dart';
import 'package:nerpa_vpn/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ConnectionWrapper extends StatefulHookConsumerWidget {
  const ConnectionWrapper(this.child, {super.key});

  final Widget child;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ConnectionWrapperState();
}

class _ConnectionWrapperState extends ConsumerState<ConnectionWrapper> with AppLogger {
  @override
  Widget build(BuildContext context) {
    ref.listen(connectionNotifierProvider, (_, _) {});

    ref.listen(configOptionNotifierProvider, (previous, next) async {
      if (next case AsyncData(value: true)) {
        final t = ref.read(translationsProvider).requireValue;
        ref
            .read(inAppNotificationControllerProvider)
            .showInfoToast(
              t.connection.reconnectMsg,
              // actionText: t.connection.reconnect,
              // callback: () async {
              //   await ref
              //       .read(connectionNotifierProvider.notifier)
              //       .reconnect(await ref.read(activeProfileProvider.future));
              // },
            );
        await ref.read(connectionNotifierProvider.notifier).reconnect(await ref.read(activeProfileProvider.future));
      }
    });

    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    // Nerpa: on desktop, if the user previously connected (startedByUser),
    // reconnect automatically after a restart instead of sitting disconnected.
    Future.delayed(const Duration(seconds: 2)).then((_) async {
      if (!mounted) return;
      if (ref.read(Preferences.startedByUser) && PlatformUtils.isDesktop) {
        loggy.debug("previously started by user, trying to connect");
        return ref.read(connectionNotifierProvider.notifier).mayConnect();
      }
    });
  }
}
