import 'package:flutter/material.dart';
import 'package:nerpa_vpn/features/profile/model/profile_entity.dart';
import 'package:nerpa_vpn/features/profile/widget/profile_tile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Nerpa VPN — Remaining subscription traffic and time, on the home screen.
///
/// The provider sends the subscription limits in the `subscription-userinfo`
/// header, so the numbers are known without asking the provider. An expired
/// or exhausted subscription is the first thing worth noticing, and it used
/// to be visible only on the profile details page.
class SubscriptionStatusBar extends HookConsumerWidget {
  const SubscriptionStatusBar({required this.profile, super.key});

  final ProfileEntity profile;

  @override
 Widget build(BuildContext context, WidgetRef ref) {
    final subInfo = switch (profile) {
      RemoteProfileEntity(:final subInfo?) => subInfo,
      _ => null,
    };
    if (subInfo == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: ProfileSubscriptionInfo(subInfo),
    );
  }
}
