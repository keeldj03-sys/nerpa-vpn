import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/notification/in_app_notification_controller.dart';
import 'package:nerpa_vpn/features/presets/model/preset.dart';
import 'package:nerpa_vpn/features/presets/notifier/presets_notifier.dart';
import 'package:nerpa_vpn/features/route_rules/notifier/rules_notifier.dart';
import 'package:nerpa_vpn/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Routing presets bottom sheet: ready-made bundles of routing rules
/// (v2RayTun parity). Applying a preset adds all of its rules.
class PresetsModal extends HookConsumerWidget {
  const PresetsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final presets = ref.watch(presetsProvider);

    final initialSize = PlatformUtils.isDesktop ? .50 : .35;
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: initialSize,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  t.pages.settings.routing.presets.title,
                  style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface),
                ),
              ),
              Expanded(
                child: presets.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        t.pages.settings.routing.presets.loadError,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ),
                  data: (list) => list.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              t.pages.settings.routing.presets.empty,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, indent: 16, endIndent: 16),
                          controller: scrollController,
                          itemBuilder: (context, index) {
                            final preset = list[index];
                            return _PresetTile(
                              preset: preset,
                              onApply: () => _applyPreset(ref, preset),
                              rulesCountLabel: t.pages.settings.routing.presets.rulesCount(
                                count: preset.rules.length,
                              ),
                            );
                          },
                          itemCount: list.length,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyPreset(WidgetRef ref, Preset preset) async {
    final notifier = ref.read(rulesNotifierProvider.notifier);
    for (final rule in preset.rules) {
      await notifier.addRule(rule.toRule());
    }
    final t = ref.read(translationsProvider).requireValue;
    ref
        .read(inAppNotificationControllerProvider)
        .showSuccessToast(t.pages.settings.routing.presets.applied(name: preset.name));
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({required this.preset, required this.onApply, required this.rulesCountLabel});

  final Preset preset;
  final Future<void> Function() onApply;
  final String rulesCountLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: () async {
        await onApply();
        if (context.mounted) context.pop();
      },
      leading: preset.isCustom
          ? Icon(Icons.cloud_download_rounded, color: theme.colorScheme.secondary)
          : Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
      title: Row(
        children: [
          Flexible(
            child: Text(
              preset.name,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rulesCountLabel,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      subtitle: preset.description.isEmpty
          ? null
          : Text(
              preset.description,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
    );
  }
}
