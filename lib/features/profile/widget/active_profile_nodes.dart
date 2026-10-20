import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/features/profile/data/selected_outbound_store.dart';
import 'package:nerpa_vpn/features/profile/overview/active_profile_outbound_model.dart';
import 'package:nerpa_vpn/features/profile/overview/active_profile_outbounds_provider.dart';

/// Сколько узлов показываем прямо в карточке профиля.
/// Остальные — на экране «Серверы», куда ведёт кнопка «Все узлы».
const int kActiveProfileInlineNodesLimit = 6;

/// Ширина колонки с задержкой — чтобы значения стояли ровно друг под другом.
const double _kDelayColumnWidth = 46;

/// Блок «Узлы» в карточке активного профиля.
class ActiveProfileNodesBlock extends ConsumerWidget {
  const ActiveProfileNodesBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Узлы из живого снимка ядра — с текущим выбором и задержками.
    final liveNodes = ref.watch(activeProfileOutboundsProvider);
    // Узлы из конфига профиля — пока ядро ещё не отдало снимок (VPN не подключён).
    final configAsync = ref.watch(activeProfileConfigOutboundsProvider);
    final configNodes = configAsync.valueOrNull ?? const <ActiveProfileOutbound>[];

    final hasLiveNodes = liveNodes.isNotEmpty;
    final nodes = hasLiveNodes ? liveNodes : configNodes;
    final selection = ref.watch(activeProfileNodeSelectionProvider);
    // Выбор, сохранённый в приложении: показываем его, пока ядро выключено.
    final savedTag = ref.watch(activeProfileSavedOutboundProvider);

    final visibleNodes = nodes.take(kActiveProfileInlineNodesLimit).toList(growable: false);

    return GestureDetector(
      // Поглощаем тапы по блоку: иначе они долетают до InkWell карточки профиля,
      // который выбирает профиль и уводит на главный экран.
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: double.infinity, height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const Gap(12),
          Row(
            children: [
              Text(
                'Узлы',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.nerpaTextSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              if (nodes.isNotEmpty)
                Text(
                  '${nodes.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.nerpaTextSecondary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const Gap(6),
              _PingButton(
                isPinging: selection.isPinging,
                onTap: () => ref.read(activeProfileNodeSelectionProvider.notifier).ping(),
              ),
            ],
          ),
          const Gap(10),
          if (nodes.isEmpty)
            _NodesHint(
              text: configAsync.isLoading ? 'Загрузка узлов…' : 'Нет доступных узлов.',
              showProgress: configAsync.isLoading,
            )
          else ...[
            for (final node in visibleNodes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ActiveProfileNodeRow(
                  node: node,
                  isSelected: selection.isSelectedFor(node, offlineSelectedTag: hasLiveNodes ? null : savedTag),
                  isPending: selection.pendingTag == node.tag,
                ),
              ),
            // Экран «Серверы» работает только с запущенным ядром.
            if (hasLiveNodes) _AllNodesButton(total: nodes.length),
          ],
        ],
      ),
    );
  }
}

/// Строка одного узла.
class ActiveProfileNodeRow extends ConsumerWidget {
  const ActiveProfileNodeRow({super.key, required this.node, required this.isSelected, required this.isPending});

  final ActiveProfileOutbound node;
  final bool isSelected;
  final bool isPending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final delay = node.delayMs;

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: !isPending,
      label: node.displayName,
      child: Material(
        color: isSelected ? AppTheme.nerpaAccent.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          // onTap всегда не null: иначе тап провалится в InkWell карточки профиля.
          onTap: () {
            if (isPending) return;
            ref.read(activeProfileNodeSelectionProvider.notifier).select(node);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.nerpaAccent : AppTheme.nerpaAccent.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: node.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? AppTheme.nerpaTextPrimary
                                : AppTheme.nerpaTextPrimary.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        TextSpan(
                          text: '  ${node.type}',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.nerpaTextSecondary, height: 1.3),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Gap(8),
                if (isPending)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: AppTheme.nerpaAccent, strokeWidth: 2),
                    ),
                  )
                else if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.nerpaAccent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppTheme.nerpaAccent.withValues(alpha: 0.38)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.checkmark_20_regular, color: AppTheme.nerpaAccent, size: 15),
                        Gap(4),
                        Text(
                          'Выбран',
                          style: TextStyle(color: AppTheme.nerpaAccent, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                const Gap(8),
                // Колонка задержки: фиксированная ширина, значения встают ровно.
                SizedBox(
                  width: _kDelayColumnWidth,
                  child: Text(
                    delay <= 0 ? '—' : (delay > 65000 ? '×' : '$delay'),
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: delay <= 0 ? AppTheme.nerpaTextSecondary.withValues(alpha: 0.7) : _delayColor(delay),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Цвет задержки — как на экране «Серверы».
Color _delayColor(int delay) {
  return switch (delay) {
    < 800 => Colors.lightGreen,
    < 1500 => Colors.orange,
    _ => Colors.redAccent,
  };
}

/// Кнопка измерения задержки.
class _PingButton extends StatelessWidget {
  const _PingButton({required this.isPinging, required this.onTap});

  final bool isPinging;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Измерить задержку',
      child: Tooltip(
        message: 'Измерить задержку',
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: isPinging ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: isPinging
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(color: AppTheme.nerpaAccent, strokeWidth: 2),
                  )
                : const Icon(FluentIcons.arrow_sync_20_regular, color: AppTheme.nerpaTextSecondary, size: 15),
          ),
        ),
      ),
    );
  }
}

/// Подсказка вместо списка узлов.
class _NodesHint extends StatelessWidget {
  const _NodesHint({required this.text, this.showProgress = false});

  final String text;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (showProgress) ...[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(color: AppTheme.nerpaAccent, strokeWidth: 2),
          ),
          const Gap(8),
        ],
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.nerpaTextSecondary, height: 1.35),
          ),
        ),
      ],
    );
  }
}

/// Кнопка «Все узлы» — ведёт на экран «Серверы».
class _AllNodesButton extends StatelessWidget {
  const _AllNodesButton({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = total > kActiveProfileInlineNodesLimit ? 'Все узлы ($total)' : 'Все узлы';

    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => context.goNamed('proxies'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.nerpaAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(4),
                const Icon(FluentIcons.chevron_right_20_regular, color: AppTheme.nerpaAccent, size: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
