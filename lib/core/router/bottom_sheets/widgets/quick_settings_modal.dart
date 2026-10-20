import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/features/chain/overview/chain_quick_settings.dart';
import 'package:nerpa_vpn/features/settings/data/config_option_repository.dart';
import 'package:nerpa_vpn/features/settings/widget/lan_sharing_tile.dart';
import 'package:nerpa_vpn/singbox/model/singbox_config_enum.dart';

class QuickSettingsModal extends HookConsumerWidget {
  const QuickSettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return SafeArea(
      minimum: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            color: Color(0xFF0E171A),
            boxShadow: [
              BoxShadow(color: Color(0x99000000), blurRadius: 30, offset: Offset(0, 12)),
            ],
          ),
          child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                        ),
                        const Gap(18),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.white.withValues(alpha: 0.05),
                                border: Border.all(color: AppTheme.nerpaAccent.withValues(alpha: 0.24)),
                              ),
                              child: const Icon(Icons.tune_rounded, color: AppTheme.nerpaAccent),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.pages.home.quickSettings,
                                    style: const TextStyle(
                                      color: AppTheme.nerpaTextPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const Gap(4),
                                  Text(
                                    'Быстрый доступ к режиму сервиса, LAN и цепочкам',
                                    style: TextStyle(
                                      color: AppTheme.nerpaTextSecondary.withValues(alpha: 0.92),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.045),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: _ServiceModeSelector(
                        selected: ref.watch(ConfigOptions.serviceMode),
                        onChanged: (mode) => ref.read(ConfigOptions.serviceMode.notifier).update(mode),
                        labelOf: (mode) => mode.presentShort(t),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.045),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Column(
                        children: [
                          _GlassSectionHeader(
                            icon: Icons.router_rounded,
                            title: 'LAN sharing',
                            subtitle: 'Доступ к локальному прокси и обмен ссылкой',
                          ),
                          Divider(height: 1, indent: 20, endIndent: 20),
                          LanSharingPreferenceWidget(),
                        ],
                      ),
                    ),
                  ),
                  const Gap(12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.045),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Column(
                        children: [
                          _GlassSectionHeader(
                            icon: Icons.alt_route_rounded,
                            title: 'Цепочка подключения',
                            subtitle: 'Приоритет фильтрации, профиля и дополнительной защиты',
                          ),
                          Divider(height: 1, indent: 20, endIndent: 20),
                          ChainQuickSettings(),
                        ],
                      ),
                    ),
                  ),
                  // const Gap(12),
                  // ListTile(
                  //   leading: const Icon(Icons.cloud_rounded),
                  //   title: Text(ref.watch(ConfigOptions.warpDetourMode).presentExplain(t)),
                  //   onLongPress: () {
                  //     context.pop();
                  //     context.goNamed('warpOptions');
                  //   },
                  //   onTap: () async {
                  //     final value = ref.watch(ConfigOptions.enableWarp);
                  //     await ref.read(ConfigOptions.enableWarp.notifier).update(!value);
                  //   },
                  //   trailing: Switch.adaptive(
                  //     value: ref.watch(ConfigOptions.enableWarp),
                  //     onChanged: (value) async {
                  //       await ref.read(ConfigOptions.enableWarp.notifier).update(value);
                  //       // await ref.read(warpOptionNotifierProvider.notifier).genWarps();
                  //     },
                  //   ),
                  // ),
                  // ListTile(
                  //   leading: const Icon(Icons.content_cut_rounded),
                  //   title: Text(t.pages.settings.tlsTricks.title),
                  //   onTap: () {
                  //     context.pop();
                  //     context.goNamed('tlsTricks');
                  //   },
                  //   trailing: Switch.adaptive(
                  //     value: ref.watch(ConfigOptions.enableTlsFragment),
                  //     onChanged: ref.read(ConfigOptions.enableTlsFragment.notifier).update,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

class _GlassSectionHeader extends StatelessWidget {
  const _GlassSectionHeader({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.nerpaAccent.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: AppTheme.nerpaAccent, size: 18),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppTheme.nerpaTextPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const Gap(2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.nerpaTextSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Выбор режима сервиса в виде «пилюль», которые переносятся на новую
/// строку вместо переполнения — в отличие от SegmentedButton.
class _ServiceModeSelector extends StatelessWidget {
  const _ServiceModeSelector({
    required this.selected,
    required this.onChanged,
    required this.labelOf,
  });

  final ServiceMode selected;
  final ValueChanged<ServiceMode> onChanged;
  final String Function(ServiceMode) labelOf;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final mode in ServiceMode.choices)
          _ServiceModePill(
            label: labelOf(mode),
            selected: mode == selected,
            onTap: () => onChanged(mode),
          ),
      ],
    );
  }
}

class _ServiceModePill extends StatelessWidget {
  const _ServiceModePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.nerpaAccent.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppTheme.nerpaAccent.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? AppTheme.nerpaTextPrimary : AppTheme.nerpaTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
