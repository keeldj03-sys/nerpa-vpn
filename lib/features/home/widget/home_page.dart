import 'dart:ui';

import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:loggy/loggy.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:nerpa_vpn/core/app_info/app_info_provider.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:nerpa_vpn/core/router/dialog/dialog_notifier.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/features/chain/model/chain_enum.dart';
import 'package:nerpa_vpn/features/connection/model/connection_status.dart';
import 'package:nerpa_vpn/features/connection/notifier/connection_notifier.dart';
import 'package:nerpa_vpn/features/home/widget/connection_button.dart';
import 'package:nerpa_vpn/features/profile/data/selected_outbound_store.dart';
import 'package:nerpa_vpn/features/profile/model/profile_entity.dart';
import 'package:nerpa_vpn/features/profile/notifier/active_profile_notifier.dart';
import 'package:nerpa_vpn/features/profile/overview/active_profile_outbound_model.dart';
import 'package:nerpa_vpn/features/profile/overview/active_profile_outbounds_provider.dart';
import 'package:nerpa_vpn/features/profile/widget/profile_tile.dart';
import 'package:nerpa_vpn/features/proxy/active/active_proxy_card.dart';
import 'package:nerpa_vpn/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:nerpa_vpn/features/proxy/active/active_proxy_notifier.dart';
import 'package:nerpa_vpn/features/settings/data/config_option_repository.dart';
import 'package:nerpa_vpn/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:nerpa_vpn/hiddifycore/hiddify_core_service_provider.dart';
import 'package:nerpa_vpn/singbox/model/singbox_config_enum.dart';
import 'package:sliver_tools/sliver_tools.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final activeProfile = ref.watch(activeProfileProvider);
    // App bar лежит поверх видео, поэтому контент сдвигаем вручную.
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      body: Stack(
        children: [
          // ── Nerpa hero video background ──
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _HomeVideoBackground(),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF02070A).withValues(alpha: 0.34),
                          const Color(0xFF07131A).withValues(alpha: 0.2),
                          const Color(0xFF0C0C0E).withValues(alpha: 0.55),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.15),
                        radius: 1.1,
                        colors: [
                          const Color(0xFF000000).withValues(alpha: 0.08),
                          const Color(0xFF000000).withValues(alpha: 0.34),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Main content ──
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: CustomScrollView(
                slivers: [
                  MultiSliver(
                    children: [
                      // Отступ под app bar, лежащий поверх видео
                      SliverToBoxAdapter(child: SizedBox(height: topInset + 8)),

                      // Active profile card
                      switch (activeProfile) {
                        AsyncData(value: final profile?) => _ProfileHeader(profile: profile, ref: ref, t: t),
                        _ => const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      },

                      // Connection button + stats
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Power button
                              ConnectionButton(),

                              Gap(28),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Quick Settings bottom bar ──
          if (ref.watch(hasAnyProfileProvider).value ?? false)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _QuickSettingsBar(t: t, ref: ref),
            ),

          // ── App bar поверх видео ──
          Positioned(top: 0, left: 0, right: 0, child: _NerpaAppBar(t: t, ref: ref, theme: theme)),
        ],
      ),
    );
  }
}

// ── App Bar ──
class _NerpaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _NerpaAppBar({required this.t, required this.ref, required this.theme});

  final Translations t;
  final WidgetRef ref;
  final ThemeData theme;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final statusMeta = _buildStatusMeta(t, connectionStatus);

    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppTheme.nerpaBorder.withValues(alpha: 0.3)),
      ),
      title: const SizedBox.shrink(),
      actions: [
        _StatusPill(meta: statusMeta),
        const Gap(8),
        // Пинг активного узла — рядом со статусом, чтобы не болтался под кнопкой
        const ActiveProxyDelayIndicator(),
        const Gap(8),
        Semantics(
          key: const ValueKey('profile_add_button'),
          label: t.pages.profiles.add,
          child: IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.nerpaAccent),
            tooltip: t.pages.profiles.add,
            onPressed: () => ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(),
          ),
        ),
        const Gap(4),
      ],
    );
  }
}

/// Компактный статус подключения в верхней панели.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.meta});

  final _TopBarStatusMeta meta;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${meta.title}: ${meta.caption}',
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: meta.color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: meta.color.withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: meta.color, shape: BoxShape.circle),
            ),
            const Gap(7),
            Text(
              meta.value,
              style: TextStyle(color: meta.color, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeVideoBackground extends StatefulWidget {
  const _HomeVideoBackground();

  @override
  State<_HomeVideoBackground> createState() => _HomeVideoBackgroundState();
}

class _HomeVideoBackgroundState extends State<_HomeVideoBackground> {
  static const _videoAsset = 'asset:///assets/videos/nerpa.mp4';

  late final Player _player;
  late final VideoController _videoController;
  bool _hasFirstFrame = false;

  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized();
    _player = Player();
    _videoController = VideoController(_player);
    _listenForFirstFrame();
    _initializeVideo();
  }

  void _listenForFirstFrame() {
    _player.stream.position.listen((position) {
      if (_hasFirstFrame || !mounted) {
        return;
      }
      if (position > Duration.zero) {
        setState(() {
          _hasFirstFrame = true;
        });
      }
    });
  }

  Future<void> _initializeVideo() async {
    try {
      await _player.setPlaylistMode(PlaylistMode.loop);
      await _player.setVolume(0);
      await _player.open(Media(_videoAsset));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _hasFirstFrame = false;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: _hasFirstFrame ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: Video(controller: _videoController, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
          ),
          if (!_hasFirstFrame) const ColoredBox(color: Color(0xFF050608)),
        ],
      ),
    );
  }
}

// ── Profile Header ──
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.ref, required this.t});

  final ProfileEntity profile;
  final WidgetRef ref;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: _TopProfileBar(profile: profile, ref: ref, t: t),
      ),
    );
  }
}

// ── Quick Settings Bar ──
class _QuickSettingsBar extends StatelessWidget {
  const _QuickSettingsBar({required this.t, required this.ref});

  final Translations t;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF16292F),
              const Color(0xFF101E23),
              const Color(0xFF0A1316),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 30, offset: const Offset(0, 16)),
            BoxShadow(color: AppTheme.nerpaAccent.withValues(alpha: 0.05), blurRadius: 30, spreadRadius: -10),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () => ref.read(bottomSheetsNotifierProvider.notifier).showQuickSettings(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withValues(alpha: 0.055),
                          border: Border.all(color: AppTheme.nerpaAccent.withValues(alpha: 0.24)),
                        ),
                        child: const Icon(Icons.tune_rounded, size: 20, color: AppTheme.nerpaAccent),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t.pages.home.quickSettings,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.nerpaTextPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Gap(3),
                            Text(
                              'Сервис · LAN · цепочки',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.nerpaTextSecondary.withValues(alpha: 0.92),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(8),
                      Icon(Icons.arrow_forward_rounded, size: 19, color: AppTheme.nerpaAccent.withValues(alpha: 0.9)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopProfileBar extends HookConsumerWidget {
  const _TopProfileBar({required this.profile, required this.ref, required this.t});

  final ProfileEntity profile;
  final WidgetRef ref;
  final Translations t;

  /// Пинг активного узла: ошибки гасим, чтобы не вылетали в зону.
  Future<void> _handleUrlTest() async {
    try {
      await ref.read(activeProxyNotifierProvider.notifier).urlTest('');
    } catch (error) {
      logWarning('url test failed: $error');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProxy = ref.watch(activeProxyNotifierProvider.select((value) => value.valueOrNull));
    final coreGroups =
        ref.watch(activeGroupsSnapshotProvider).valueOrNull ?? ref.read(hiddifyCoreServiceProvider).latest;
    OutboundInfo? coreSelection;
    for (final group in coreGroups) {
      final selectedTag = group.selected;
      coreSelection = selectedTag.isNotEmpty
          ? group.items.where((item) => item.tag == selectedTag).firstOrNull ??
                group.items.where((item) => item.isSelected).firstOrNull
          : group.items.where((item) => item.isSelected).firstOrNull;
      if (coreSelection != null) break;
    }
    final displayedProxy = activeProxy?.tag.isNotEmpty == true ? activeProxy : coreSelection;

    // Узел, выбранный в приложении: видно сразу, даже без подключения.
    final savedTag = ref.watch(activeProfileSavedOutboundProvider);
    final configNodes = ref.watch(activeProfileConfigOutboundsProvider).valueOrNull ?? const <ActiveProfileOutbound>[];

    final chainStatus = ref.watch(ConfigOptions.chainStatus);
    final serviceMode = ref.watch(ConfigOptions.serviceMode);
    final modeLabel = _buildModeLabel(ref, t, chainStatus);
    final locationLabel = _resolveLocationLabel(profile, displayedProxy);
    final node = _resolveHomeNode(displayedProxy, savedTag, configNodes);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.03),
            const Color(0xFF142429).withValues(alpha: 0.08),
            const Color(0xFF0D1518).withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.24), blurRadius: 32, offset: const Offset(0, 18)),
          BoxShadow(color: AppTheme.nerpaAccent.withValues(alpha: 0.05), blurRadius: 28, spreadRadius: -8),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // ── Строка 1: профиль ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'АКТИВНЫЙ ПРОФИЛЬ',
                      style: TextStyle(
                        color: AppTheme.nerpaTextSecondary.withValues(alpha: 0.92),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Gap(8),
                    ProfileTile(
                      profile: profile,
                      isMain: true,
                      color: Colors.transparent,
                      showBorder: false,
                      showActionButton: false,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const Gap(14),
                const _CardDivider(),
                const Gap(14),
                // ── Строка 2: выбранный узел ──
                ActiveServerInfoRow(
                  name: node.name,
                  type: node.type,
                  ip: node.ip,
                  countryCode: node.countryCode,
                  organization: node.organization,
                  onTap: () => context.goNamed('proxies'),
                  onFlagTap: displayedProxy == null
                      ? null
                      : () => ref.read(dialogNotifierProvider.notifier).showProxyInfo(outboundInfo: displayedProxy),
                  onIpLongPress: _handleUrlTest,
                ),
                const Gap(14),
                const _CardDivider(),
                const Gap(14),
                // ── Строка 3: режимы ──
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (locationLabel != null) _TopBarMetaChip(icon: Icons.public_rounded, label: locationLabel),
                    _TopBarMetaChip(icon: Icons.tune_rounded, label: serviceMode.presentShort(t)),
                    if (modeLabel != null) _TopBarMetaChip(icon: Icons.shield_outlined, label: modeLabel),
                  ],
                ),
              ],
            ),
          ),
      ),
    );
  }
}

/// Разделитель внутри стеклянной карточки.
class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Colors.white.withValues(alpha: 0.08));
  }
}

/// Узел, показанный на главной: живой (при подключении) либо выбранный в приложении.
class _HomeNodeInfo {
  const _HomeNodeInfo({required this.name, required this.type, this.ip = '', this.countryCode = '', this.organization});

  final String name;
  final String type;
  final String ip;
  final String countryCode;
  final String? organization;
}

_HomeNodeInfo _resolveHomeNode(
  OutboundInfo? liveProxy,
  String? savedTag,
  List<ActiveProfileOutbound> configNodes,
) {
  if (liveProxy != null && liveProxy.tagDisplay.trim().isNotEmpty) {
    return _HomeNodeInfo(
      name: liveProxy.tagDisplay.trim(),
      type: liveProxy.type,
      ip: liveProxy.ipinfo.ip,
      countryCode: liveProxy.ipinfo.countryCode,
      organization: liveProxy.ipinfo.org,
    );
  }

  // Подключения нет: показываем узел, выбранный в приложении, иначе — узел по умолчанию.
  ActiveProfileOutbound? fallback;
  if (savedTag != null && savedTag.isNotEmpty) {
    fallback = configNodes.where((node) => node.tag == savedTag).firstOrNull;
  }
  fallback ??= configNodes.where((node) => node.isSelected).firstOrNull;
  if (fallback == null) return const _HomeNodeInfo(name: '', type: '');

  return _HomeNodeInfo(name: fallback.displayName, type: fallback.type);
}

class _TopBarMetaChip extends StatelessWidget {
  const _TopBarMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.nerpaAccent),
          const Gap(6),
          Text(
            label,
            style: const TextStyle(color: AppTheme.nerpaTextPrimary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TopBarStatusMeta {
  const _TopBarStatusMeta({required this.title, required this.value, required this.caption, required this.color});

  final String title;
  final String value;
  final String caption;
  final Color color;
}

String? _resolveLocationLabel(ProfileEntity profile, OutboundInfo? activeProxy) {
  final proxyRegion = activeProxy?.ipinfo.region;
  if (proxyRegion != null && proxyRegion.trim().isNotEmpty) {
    return proxyRegion.trim();
  }

  final proxyCountryCode = activeProxy?.ipinfo.countryCode;
  if (proxyCountryCode != null && proxyCountryCode.trim().isNotEmpty) {
    return proxyCountryCode.toUpperCase();
  }

  final profileName = profile.name.trim();
  final parts = profileName
      .split(RegExp(r'[•|•/\\()\[\]\-_,]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return parts[1];
  }
  return null;
}

String? _buildModeLabel(WidgetRef ref, Translations t, ChainStatus chainStatus) {
  if (chainStatus.isOff()) {
    return null;
  }

  final type = chainStatus.isExtraSecurity() ? ChainType.extraSecurity : ChainType.unblocker;
  final mode = chainStatus.isExtraSecurity()
      ? ref.watch(ConfigOptions.extraSecurityMode)
      : ref.watch(ConfigOptions.unblockerMode);
  return '${type.present(t)} · ${mode.present(t)}';
}

_TopBarStatusMeta _buildStatusMeta(
  Translations t,
  AsyncValue<ConnectionStatus> connectionStatus,
) {
  final status = connectionStatus.valueOrNull;

  // Статус показывает состояние туннеля. Задержка вынесена в отдельную
  // соседнюю пилюлю ActiveProxyDelayIndicator, чтобы значения не дублировались.
  if (status is Connected) {
    return const _TopBarStatusMeta(
      title: 'Статус',
      value: 'Online',
      caption: 'Подключение активно',
      color: AppTheme.nerpaSuccess,
    );
  }

  if (status is Connecting) {
    return const _TopBarStatusMeta(
      title: 'Статус',
      value: 'Старт',
      caption: 'Подключение запускается',
      color: AppTheme.nerpaWarning,
    );
  }

  if (status is Disconnecting) {
    return const _TopBarStatusMeta(
      title: 'Статус',
      value: 'Стоп',
      caption: 'Отключение выполняется',
      color: AppTheme.nerpaWarning,
    );
  }

  return const _TopBarStatusMeta(
    title: 'Статус',
    value: 'Offline',
    caption: 'Нет активного подключения',
    color: AppTheme.nerpaTextMuted,
  );
}

// ── Version Label ──
class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final version = ref.watch(appInfoProvider).requireValue.presentVersion;
    if (version.isBlank) return const SizedBox.shrink();

    return Semantics(
      label: t.common.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.nerpaAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppTheme.nerpaAccent.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: AppTheme.nerpaAccent,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
