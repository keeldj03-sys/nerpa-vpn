import 'package:circle_flags/circle_flags.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:nerpa_vpn/core/haptic/haptic_service.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/utils/ip_utils.dart';
import 'package:nerpa_vpn/gen/fonts.gen.dart';
import 'package:nerpa_vpn/utils/riverpod_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// simple_icons replaced with Material Icons for Flutter 3.44.8 compatibility

final _showIp = StateProvider.autoDispose((ref) {
  ref.disposeDelay(const Duration(seconds: 20));
  ref.listenSelf((previous, next) {
    if (previous == false && next == true) {
      ref.read(hapticServiceProvider.notifier).mediumImpact();
    }
  });
  return false;
});

class IPText extends HookConsumerWidget {
  const IPText({required this.ip, required this.onLongPress, this.constrained = false, super.key});

  final String ip;
  final VoidCallback onLongPress;
  final bool constrained;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final isVisible = ref.watch(_showIp);
    final textTheme = Theme.of(context).textTheme;
    final ipStyle = (constrained ? textTheme.labelMedium : textTheme.labelLarge)?.copyWith(
      fontFamily: FontFamily.emoji,
    );

    return Semantics(
      label: t.pages.proxies.ipInfo.address,
      child: InkWell(
        onTap: () {
          ref.read(_showIp.notifier).state = !isVisible;
        },
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedCrossFade(
            firstChild: Text(ip, style: ipStyle, textDirection: TextDirection.ltr, overflow: TextOverflow.ellipsis),
            secondChild: Padding(
              padding: constrained ? EdgeInsets.zero : const EdgeInsetsDirectional.only(end: 48),
              child: Text(
                obscureIp(ip),
                semanticsLabel: t.common.hidden,
                style: ipStyle,
                textDirection: TextDirection.ltr,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            crossFadeState: isVisible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ),
      ),
    );
  }
}

class UnknownIPText extends HookConsumerWidget {
  const UnknownIPText({required this.text, required this.onTap, this.constrained = false, super.key});

  final String text;
  final VoidCallback onTap;
  final bool constrained;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final textTheme = Theme.of(context).textTheme;
    final style = constrained ? textTheme.bodySmall : textTheme.labelMedium;

    return Semantics(
      label: t.pages.proxies.ipInfo.address,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(text, style: style, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

class IPCountryFlag extends HookConsumerWidget {
  const IPCountryFlag({
    required this.countryCode,
    this.organization,
    this.size = 16,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final String? countryCode;
  final double size;

  final EdgeInsetsGeometry padding;

  final String? organization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return Semantics(
      label: t.pages.proxies.ipInfo.country,
      child: Padding(
        padding: padding,
        child: (countryCode?.isEmpty ?? true)
            ? Icon(FluentIcons.question_circle_20_regular, size: size)
            : SizedBox(
                width: size,
                height: size,
                child: Stack(
                  textDirection: Directionality.of(context),
                  alignment: Alignment.center,
                  children: [
                    CircleFlag(
                      // key: ValueKey(countryCode),
                      countryCode!.toLowerCase() == "ir" ? "ir-shir" : countryCode!,
                      size: size - 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded effect
                      ),
                    ),
                    if (organization != null)
                      Positioned.directional(
                        textDirection: Directionality.of(context),
                        bottom: 0,
                        end: 0,
                        child: OrganisationFlag(organization: organization!, size: size / 2.5),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class OrgIconData {
  final IconData icon;
  final Color color;

  const OrgIconData(this.icon, this.color);
}

const Map<String, OrgIconData> organizationData = {
  "cloudflare": OrgIconData(Icons.cloud, Color(0xFFF6821F)),
  "hetzner": OrgIconData(Icons.dns, Color(0xFFD50C2D)),
  "ovh": OrgIconData(Icons.storage, Color(0xFF123F6D)),
  "azure": OrgIconData(Icons.cloud_queue, Color(0xFF0078D4)),
  "amazon": OrgIconData(Icons.cloud_done, Color(0xFFFF9900)),
  "oracle": OrgIconData(Icons.storage, Color(0xFFF80000)),
  "fastly": OrgIconData(Icons.flash_on, Color(0xFFFF282D)),
  "digitalocean": OrgIconData(Icons.water_drop, Color(0xFF0080FF)),
  "alibaba": OrgIconData(Icons.cloud_circle, Color(0xFFFF6A00)),
  "google": OrgIconData(Icons.cloud_outlined, Color(0xFF4285F4)),
  "starlink": OrgIconData(Icons.satellite_alt, Color(0xFF000000)),
};

class OrganisationFlag extends HookConsumerWidget {
  const OrganisationFlag({required this.organization, this.size = 24, super.key});

  final String organization;
  final double size;

  // Function to create flag widget with icon and color
  Widget getFlagWidget({
    required Widget widget,
    required String organization,
    required double size,
    required String label,
    required Color color,
  }) {
    return Semantics(
      label: "$label $organization",
      child: Container(
        width: size,
        height: size,

        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(100)),
        // padding: const ,
        child: widget,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    for (final entry in organizationData.entries) {
      if (organization.toLowerCase().contains(entry.key)) {
        return getFlagWidget(
          widget: Icon(entry.value.icon, color: Colors.white, size: size - 6),
          color: entry.value.color,
          organization: organization,
          size: size,
          label: t.pages.proxies.ipInfo.organization,
        );
      }
    }

    // Return empty widget if no match is found
    return const SizedBox.shrink();
  }
}
