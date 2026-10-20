import 'dart:convert';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/model/constants.dart';
import 'package:nerpa_vpn/core/model/trusted_links.dart';
import 'package:nerpa_vpn/core/model/failures.dart';
import 'package:nerpa_vpn/core/notification/in_app_notification_controller.dart';
import 'package:nerpa_vpn/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:nerpa_vpn/core/router/dialog/dialog_notifier.dart';
import 'package:nerpa_vpn/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/core/widget/adaptive_menu.dart';
import 'package:nerpa_vpn/features/profile/model/profile_entity.dart';
import 'package:nerpa_vpn/features/profile/notifier/profile_notifier.dart';
import 'package:nerpa_vpn/features/profile/overview/profiles_notifier.dart';
import 'package:nerpa_vpn/features/profile/widget/active_profile_nodes.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:nerpa_vpn/gen/fonts.gen.dart';
import 'package:nerpa_vpn/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileTile extends HookConsumerWidget {
  const ProfileTile({
    super.key,
    required this.profile,
    this.isMain = false,
    this.margin = EdgeInsets.zero,
    this.color,
    this.showActiveOutbounds = false,
    this.showBorder = true,
    this.showActionButton = true,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 16),
  });

  final ProfileEntity profile;

  /// home screen active profile card
  final bool isMain;
  final EdgeInsets margin;
  final Color? color;
  final bool showActiveOutbounds;

  /// Рисовать ли рамку карточки (на главной карточка вложена в общую — рамка лишняя).
  final bool showBorder;

  /// Рисовать ли кнопку действий справа (на главной она лишняя и ломает вёрстку).
  final bool showActionButton;

  /// Внутренние отступы карточки (на главной карточка вложена в общую — отступы лишние).
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final showInlineOutbounds = showActiveOutbounds && profile.active && !isMain;

    final selectActiveMutation = useMutation(
      initialOnFailure: (err) {
        ref.read(inAppNotificationControllerProvider).showErrorToast(t.presentShortError(err));
      },
      initialOnSuccess: () {
        if (context.mounted && context.canPop()) context.pop();
      },
    );

    final subInfo = switch (profile) {
      RemoteProfileEntity(:final subInfo) => subInfo,
      _ => null,
    };

    final hasActionButton = showActionButton && (profile is RemoteProfileEntity || !isMain);

    // final effectiveMargin = isMain ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8) : const EdgeInsets.only(left: 12, right: 12, bottom: 12);
    // final double effectiveElevation = profile.active ? 12 : 4;
    // final effectiveOutlineColor = profile.active ? theme.colorScheme.outline : Colors.transparent;
    final borderColor = profile.active
        ? AppTheme.nerpaAccent.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.06);
    final backgroundColor = profile.active ? const Color(0xFF121C20) : const Color(0xFF11161A);
    final titleColor = profile.active ? AppTheme.nerpaTextPrimary : AppTheme.nerpaTextSecondary.withValues(alpha: 0.96);

    // Links the provider offers (website / support), rendered below the main card.
    final remote = profile is RemoteProfileEntity ? profile as RemoteProfileEntity : null;
    final showLinks =
        ProfileTileConst.showProviderLinks &&
        isMain &&
        remote != null &&
        ((remote.webPageUrl?.isNotEmpty ?? false) || (remote.supportUrl?.isNotEmpty ?? false));

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? backgroundColor,
        borderRadius: ProfileTileConst.cardBorderRadius,
        border: showBorder ? Border.all(color: borderColor, width: profile.active ? 1.2 : 1) : null,
      ),
      child: IntrinsicHeight(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: isMain ? 72 : 92),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  sortKey: isMain ? const OrdinalSortKey(0) : null,
                  focused: isMain,
                  liveRegion: isMain,
                  namesRoute: isMain,
                  label: isMain ? t.pages.profiles.viewAllProfiles : null,
                  child: InkWell(
                    borderRadius: hasActionButton
                        ? ProfileTileConst.startBorderRadius(Directionality.of(context))
                        : ProfileTileConst.cardBorderRadius,
                    onTap: () {
                      if (isMain) {
                        if (Breakpoint(context).isMobile()) {
                          ref.read(bottomSheetsNotifierProvider.notifier).showProfilesOverview();
                        } else {
                          context.goNamed('profiles');
                        }
                      } else {
                        if (selectActiveMutation.state.isInProgress) return;
                        selectActiveMutation.setFuture(
                          ref.read(profilesNotifierProvider.notifier).selectActiveProfile(profile.id),
                        );
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.goNamed('home');
                        }
                      }
                    },
                    child: Padding(
                      padding: padding,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMain) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              profile.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                color: titleColor,
                                                fontWeight: profile.active ? FontWeight.w700 : FontWeight.w600,
                                                height: 1.18,
                                                fontFamily: PlatformUtils.isWindows ? FontFamily.emoji : null,
                                              ),
                                              semanticsLabel: profile.active
                                                  ? t.pages.profiles.activeProfileName(name: profile.name)
                                                  : t.pages.profiles.nonActiveProfileName(name: profile.name),
                                            ),
                                          ),
                                          if (profile.active) ...[
                                            const Gap(12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.nerpaAccent.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: const Text(
                                                'ACTIVE',
                                                style: TextStyle(
                                                  color: AppTheme.nerpaAccent,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const Gap(6),
                                      Text(
                                        profile is RemoteProfileEntity ? 'Remote subscription' : 'Local configuration',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppTheme.nerpaTextSecondary.withValues(alpha: 0.86),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    profile.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: titleColor,
                                      fontWeight: FontWeight.w700,
                                      height: 1.15,
                                      fontFamily: PlatformUtils.isWindows ? FontFamily.emoji : null,
                                    ),
                                    semanticsLabel: t.pages.profiles.activeProfileName(name: profile.name),
                                  ),
                                ),
                                if (profile.active) ...[
                                  const Gap(12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.nerpaAccent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        color: AppTheme.nerpaAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          if (subInfo != null) ...[
                            Gap(isMain ? 12 : 10),
                            RemainingTrafficIndicator(subInfo.ratio),
                            const Gap(10),
                            ProfileSubscriptionInfo(subInfo),
                          ],
                          if (profile.populatedHeaders?['announce'] is String) ...[
                            const Gap(10),
                            ProfileAnnounceBanner(profile.populatedHeaders!),
                          ],
                          if (showInlineOutbounds) ...[
                            const Gap(14),
                            const ActiveProfileNodesBlock(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (hasActionButton)
                Container(
                  width: isMain ? 68 : 64,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: profile.active
                            ? AppTheme.nerpaAccent.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: Semantics(sortKey: const OrdinalSortKey(1), child: ProfileActionButton(profile, !isMain)),
                ),
            ],
          ),
        ),
      ),
    );

    if (!showLinks) return card;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        card,
        ProfileLinkButtons(webPageUrl: remote.webPageUrl, supportUrl: remote.supportUrl),
      ],
    );
  }
}

class ProfileActionButton extends HookConsumerWidget {
  const ProfileActionButton(this.profile, this.showAllActions, {super.key});

  final ProfileEntity profile;
  final bool showAllActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    if (profile case RemoteProfileEntity() when !showAllActions) {
      return Semantics(
        button: true,
        enabled: !ref.watch(updateProfileNotifierProvider(profile.id)).isLoading,
        child: InkWell(
          borderRadius: ProfileTileConst.endBorderRadius(Directionality.of(context)),
          onTap: () {
            if (ref.read(updateProfileNotifierProvider(profile.id)).isLoading) {
              return;
            }
            ref.read(updateProfileNotifierProvider(profile.id).notifier).updateProfile(profile as RemoteProfileEntity);
          },
          child: Center(
            child: Text(
              t.pages.profiles.update,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.nerpaAccent, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }
    return ProfileActionsMenu(profile, (context, toggleVisibility, _) {
      return Semantics(
        button: true,
        child: InkWell(
          borderRadius: ProfileTileConst.endBorderRadius(Directionality.of(context)),
          onTap: toggleVisibility,
          child: Center(
            child: Text(
              MaterialLocalizations.of(context).showMenuTooltip,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.nerpaTextSecondary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    });
  }
}

class ProfileActionsMenu extends HookConsumerWidget {
  const ProfileActionsMenu(this.profile, this.builder, {super.key, this.child});

  final ProfileEntity profile;
  final AdaptiveMenuBuilder builder;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final menuItems = [
      if (profile case RemoteProfileEntity())
        AdaptiveMenuItem(
          title: t.common.update,
          onTap: () {
            if (ref.read(updateProfileNotifierProvider(profile.id)).isLoading) {
              return;
            }
            ref.read(updateProfileNotifierProvider(profile.id).notifier).updateProfile(profile as RemoteProfileEntity);
          },
        ),
      AdaptiveMenuItem(
        title: t.common.share,
        subItems: [
          if (profile case RemoteProfileEntity(:final url, :final name)) ...[
            AdaptiveMenuItem(
              title: t.pages.profiles.share.urlToClipboard,
              onTap: () async {
                final link = LinkParser.generateSubShareLink(url, name);
                if (link.isNotEmpty) {
                  await Clipboard.setData(ClipboardData(text: link));
                  if (context.mounted) {
                    ref
                        .read(inAppNotificationControllerProvider)
                        .showSuccessToast(t.common.msg.export.clipboard.success);
                  }
                }
              },
            ),
            AdaptiveMenuItem(
              title: t.pages.profiles.share.showUrlQr,
              onTap: () async {
                final link = LinkParser.generateSubShareLink(url, name);
                if (link.isNotEmpty) {
                  await ref.read(dialogNotifierProvider.notifier).showQrCode(link, title: name);
                }
              },
            ),
          ],
          AdaptiveMenuItem(
            title: t.pages.profiles.share.jsonToClipboard,
            onTap: () async => await ref.read(profilesNotifierProvider.notifier).exportConfigToClipboard(profile),
          ),
        ],
      ),
      AdaptiveMenuItem(
        title: t.common.edit,
        onTap: () {
          if (Breakpoint(context).isMobile()) context.pop();
          context.goNamed('profileDetails', pathParameters: {'id': profile.id});
        },
      ),
      // if (!profile.active)
      AdaptiveMenuItem(
        title: t.common.delete,
        onTap: () async => await ref
            .read(dialogNotifierProvider.notifier)
            .showConfirmation(
              title: t.dialogs.confirmation.profile.delete.title,
              message: t.dialogs.confirmation.profile.delete.msg,
            )
            .then((deleteConfirmed) async {
              if (!deleteConfirmed) return;
              await ref.read(profilesNotifierProvider.notifier).deleteProfile(profile);
            }),
      ),
    ];

    return AdaptiveMenu(builder: builder, items: menuItems, child: child);
  }
}

// TODO add support url

/// v2RayTun parity: shows the provider's `announce` subscription header.
/// Providers (e.g. 3ApesVPN) send base64-encoded notices here — maintenance
/// info, "try servers marked LTE", tariff expiry warnings. Also honored in
/// v2RayTun; Nerpa shows it as a dismissible-looking banner on the profile card.
class ProfileAnnounceBanner extends HookConsumerWidget {
  const ProfileAnnounceBanner(this.headers, {super.key});

  final Map<String, dynamic> headers;

  static String? _decodeHeader(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    if (raw.startsWith('base64:')) {
      try {
        return utf8.decode(base64.decode(raw.replaceFirst('base64:', '')));
      } catch (_) {
        return raw;
      }
    }
    return raw;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = _decodeHeader(headers['announce']);
    if (text == null || text.trim().isEmpty) return const SizedBox.shrink();
    final url = _decodeHeader(headers['announce-url']);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: (url == null || url.isEmpty) ? null : () => launchUrl(Uri.parse(url)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.nerpaAccent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.nerpaAccent.withValues(alpha: 0.16)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(FluentIcons.alert_16_regular, size: 15, color: AppTheme.nerpaAccent),
            const Gap(8),
            Expanded(
              child: Text(
                text.trim(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.nerpaTextPrimary.withValues(alpha: 0.88),
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  fontFamily: PlatformUtils.isWindows ? FontFamily.emoji : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSubscriptionInfo extends HookConsumerWidget {
  const ProfileSubscriptionInfo(this.subInfo, {super.key});

  final SubscriptionInfo subInfo;

  (String, Color?) remainingText(TranslationsEn t, ThemeData theme) {
    if (subInfo.isExpired) {
      return (t.components.subscriptionInfo.expired, theme.colorScheme.error);
    } else if (subInfo.ratio >= 1) {
      return (t.components.subscriptionInfo.noTraffic, theme.colorScheme.error);
    } else if (subInfo.remaining.inDays > 365) {
      return (t.components.subscriptionInfo.remainingUnlimited, null);
    } else {
      return (t.components.subscriptionInfo.remainingDuration(days: subInfo.remaining.inDays), null);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final remaining = remainingText(t, theme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.nerpaAccent.withValues(alpha: 0.14),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 7,
                      height: 7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: AppTheme.nerpaAccent, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
                const Gap(10),
                Flexible(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      subInfo.total >
                              10 *
                                  1099511627776 //10TB
                          ? "∞ GiB"
                          : subInfo.consumption.sizeOf(subInfo.total),
                      semanticsLabel: t.components.subscriptionInfo.remainingTrafficSemanticLabel(
                        consumed: subInfo.consumption.sizeGB(),
                        total: subInfo.total.sizeGB(),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.nerpaTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),
          Flexible(
            child: Text(
              remaining.$1,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                color: remaining.$2 ?? AppTheme.nerpaTextSecondary,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// TODO add support url
class NewTrafficSubscriptionInfo extends HookConsumerWidget {
  const NewTrafficSubscriptionInfo(this.subInfo, {super.key});

  final SubscriptionInfo subInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return Column(
      children: [
        const Icon(Icons.assessment_rounded, color: Colors.blue),
        Text(t.components.subscriptionInfo.remainingTraffic),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                subInfo.total >
                        10 *
                            1099511627776 //10TB
                    ? "∞ GiB"
                    : subInfo.consumption.sizeOf(subInfo.total),
                semanticsLabel: t.components.subscriptionInfo.remainingTrafficSemanticLabel(
                  consumed: subInfo.consumption.sizeGB(),
                  total: subInfo.total.sizeGB(),
                ),
                // style: theme.textTheme.body,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// TODO add support url
class NewDaySubscriptionInfo extends HookConsumerWidget {
  const NewDaySubscriptionInfo(this.subInfo, {super.key});

  final SubscriptionInfo subInfo;

  (String, Color?) remainingText(TranslationsEn t, ThemeData theme) {
    if (subInfo.isExpired) {
      return (t.components.subscriptionInfo.expired, theme.colorScheme.error);
    } else if (subInfo.ratio >= 1) {
      return (t.components.subscriptionInfo.noTraffic, theme.colorScheme.error);
    } else if (subInfo.remaining.inDays > 365) {
      return (t.components.subscriptionInfo.remainingUnlimited, null);
    } else {
      return (t.components.subscriptionInfo.remainingDuration(days: subInfo.remaining.inDays), null);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final remaining = remainingText(t, theme);
    return Column(
      children: [
        const Icon(Icons.timer, color: Colors.blue),
        Text(t.components.subscriptionInfo.remainingTime),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                remaining.$1,
                // style: theme.textTheme.bodySmall?.copyWith(color: remaining.$2),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// TODO add support url
class NewDayTrafficSubscriptionInfo extends HookConsumerWidget {
  const NewDayTrafficSubscriptionInfo(this.subInfo, {super.key});

  final SubscriptionInfo subInfo;

  (String, Color?) remainingText(TranslationsEn t, ThemeData theme) {
    if (subInfo.isExpired) {
      return (t.components.subscriptionInfo.expired, theme.colorScheme.error);
    } else if (subInfo.ratio >= 1) {
      return (t.components.subscriptionInfo.noTraffic, theme.colorScheme.error);
    } else if (subInfo.remaining.inDays > 365) {
      return (t.components.subscriptionInfo.remainingUnlimited, null);
    } else {
      return (t.components.subscriptionInfo.remainingDuration(days: subInfo.remaining.inDays), null);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final remaining = remainingText(t, theme);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.assessment_rounded, color: Colors.blue),
        Text(t.components.subscriptionInfo.remainingUsage),
        const SizedBox(height: 4),
        Text(
          remaining.$1,
          // style: theme.textTheme.bodySmall?.copyWith(color: remaining.$2),
          overflow: TextOverflow.ellipsis,
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            subInfo.total >
                    10 *
                        1099511627776 //10TB
                ? "∞ GiB"
                : subInfo.consumption.sizeOf(subInfo.total),
            semanticsLabel: t.components.subscriptionInfo.remainingTrafficSemanticLabel(
              consumed: subInfo.consumption.sizeGB(),
              total: subInfo.total.sizeGB(),
            ),
            // style: theme.textTheme.body,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// TODO change colors
class RemainingTrafficIndicator extends StatelessWidget {
  const RemainingTrafficIndicator(this.ratio, {super.key});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final progress = ratio.clamp(0.0, 1.0);
    final color = progress >= 0.9
        ? AppTheme.nerpaError
        : progress >= 0.7
        ? AppTheme.nerpaWarning
        : AppTheme.nerpaAccent;

    return Stack(
      children: [
        Container(
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.03)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class ProfileLinkButtons extends HookConsumerWidget {
  const ProfileLinkButtons({super.key, this.webPageUrl, this.supportUrl});

  final String? webPageUrl;
  final String? supportUrl;

  /// Top-line label:
  /// - Telegram (`t.me` / `telegram.me`): the path after the host, which covers
  ///   every form — `hiddify`, `c/2681822178/1`, `joinchat/xxx`, `+xxx`.
  /// - GitHub: the provider (repo owner) — e.g. `barry-far`.
  /// - anything else: the domain.
  static String _value(String url) {
    final uri = Uri.parse(url);
    final host = uri.host.startsWith("www.") ? uri.host.substring(4) : uri.host;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if (const ["t.me", "telegram.me"].contains(host)) {
      return segments.isEmpty ? host : segments.join("/");
    }
    if (host == "github.com" && segments.isNotEmpty) {
      return segments.first;
    }
    return host;
  }

  /// Brand icon for the link's platform (leading), or null for a generic site.
  static IconData? _leadingIcon(String url) {
    final host = Uri.parse(url).host;
    final bare = host.startsWith("www.") ? host.substring(4) : host;
    if (const ["t.me", "telegram.me"].contains(bare)) return SimpleIcons.telegram;
    if (bare == "github.com") return SimpleIcons.github;
    return null;
  }

  /// Confirm before opening a subscription-provided link. Curated/trusted links
  /// (see [TrustedLinks]) get a light confirmation; anything else gets a serious
  /// anti-impersonation warning with a countdown, so scammers can't pass off a
  /// look-alike channel/site as an official one.
  static Future<void> _confirmAndOpen(WidgetRef ref, TranslationsEn t, String url) async {
    final notifier = ref.read(dialogNotifierProvider.notifier);
    final bool confirmed;
    if (TrustedLinks.isTrusted(url)) {
      confirmed = await notifier.showConfirmation(
        title: t.components.subscriptionInfo.openLinkTitle,
        message: url,
        positiveBtnTxt: t.components.subscriptionInfo.openLinkAction,
      );
    } else {
      confirmed = await notifier.showUnknownDomainsWarning(url: url);
    }
    if (confirmed) await UriUtils.tryLaunch(Uri.parse(url));
  }

  static const _chipRadius = BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12));

  static Widget _chip(ThemeData theme, VoidCallback onTap, String url, String title) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: _chipRadius,
      border: Border(
        left: BorderSide(color: theme.colorScheme.outline),
        right: BorderSide(color: theme.colorScheme.outline),
        bottom: BorderSide(color: theme.colorScheme.outline),
      ),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: _chipRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              if (_leadingIcon(url) case final icon?) ...[
                Icon(icon, size: 24, color: theme.colorScheme.onSurfaceVariant),
                const Gap(8),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    // const Gap(1),
                    Text(
                      _value(url),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              const Gap(4),
              Icon(Icons.open_in_new_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final items = [
      if (webPageUrl case final url? when url.isNotEmpty) (url, t.components.subscriptionInfo.openWebPage),
      if (supportUrl case final url? when url.isNotEmpty) (url, t.components.subscriptionInfo.support),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    if (items.length == 1) {
      final (url, title) = items.single;
      return SizedBox(
        width: double.infinity,
        child: _chip(Theme.of(context), () => _confirmAndOpen(ref, t, url), url, title),
      );
    }
    return _LinkChipCarousel(items: items);
  }
}

class _LinkChipCarousel extends HookConsumerWidget {
  const _LinkChipCarousel({required this.items});

  final List<(String url, String title)> items;

  static const _holdDuration = Duration(seconds: 10);
  static const _slideDuration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final index = useState(0);
    final offset = useState(Offset.zero);
    // Paused while the confirmation dialog is open, so the chip doesn't swap
    // out from under the URL the user is reviewing.
    final paused = useState(false);

    useEffect(() {
      var active = true;
      Future<void> loop() async {
        while (active) {
          await Future.delayed(_holdDuration);
          while (active && paused.value) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
          if (!active) return;
          offset.value = const Offset(0, -1);
          await Future.delayed(_slideDuration);
          if (!active) return;
          index.value = (index.value + 1) % items.length;
          offset.value = Offset.zero;
        }
      }

      loop();
      return () => active = false;
    }, [items.length]);

    final (url, title) = items[index.value];
    return SizedBox(
      width: double.infinity,
      child: ClipRect(
        child: AnimatedSlide(
          offset: offset.value,
          duration: _slideDuration,
          curve: Curves.easeInOut,
          child: ProfileLinkButtons._chip(
            theme,
            () async {
              paused.value = true;
              await ProfileLinkButtons._confirmAndOpen(ref, t, url);
              if (context.mounted) paused.value = false;
            },
            url,
            title,
          ),
        ),
      ),
    );
  }
}

