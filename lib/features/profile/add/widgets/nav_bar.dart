import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/model/constants.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/core/router/dialog/dialog_notifier.dart';
import 'package:nerpa_vpn/features/profile/notifier/profile_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NavBar extends ConsumerWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final freeSwitch = ref.watch(freeSwitchNotifierProvider);

    final textColor = AppTheme.nerpaTextSecondary;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.nerpaCard,
        border: Border(top: BorderSide(color: AppTheme.nerpaBorder.withOpacity(0.35))),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          AddProfileModalConst.navBarGap,
        ).copyWith(bottom: AddProfileModalConst.navBarBottomGap),
        child: Row(
          children: [
            Row(
              key: const ValueKey('free'),
              children: [
                Text(t.common.free, style: theme.textTheme.titleMedium!.copyWith(color: textColor)),
                const Gap(8),
                Switch(value: freeSwitch, onChanged: ref.read(freeSwitchNotifierProvider.notifier).onChange),
              ],
            ),
            const Spacer(),
            ActionChip(
              key: const ValueKey("help"),
              label: Text(t.common.help, style: theme.textTheme.labelLarge!.copyWith(color: textColor)),
              avatar: Icon(Icons.help_outline, color: theme.colorScheme.onSurfaceVariant),
              onPressed: () async => await ref.read(dialogNotifierProvider.notifier).showNoActiveProfile(),
            ),
          ],
        ),
      ),
    );
  }
}
