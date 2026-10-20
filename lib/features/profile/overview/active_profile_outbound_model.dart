import 'dart:convert';

import 'package:dartx/dartx.dart';
import 'package:nerpa_vpn/hiddifycore/generated/v2/hcore/hcore.pb.dart';

/// Тег группы, в которой ядро держит ручной выбор узла.
/// Так же, как на экране «Серверы» (см. ProxiesOverviewNotifier._flattenOutbounds).
const String kActiveProfileMainSelectorTag = 'select';

/// Служебные outbound'ы ядра — в списке узлов им не место.
const Set<String> _internalOutboundTypes = {'selector', 'urltest', 'direct', 'block', 'dns', 'dns-out'};

/// Маркер, которым ядро помечает свои скрытые outbound'ы.
const String _hiddenTagMarker = '§hide§';

/// Отображаемое имя узла: ядро отрезает всё после «§» (см. TrimTagName в ядре).
String trimTagDisplay(String tag) => tag.split('§').first.trim();

/// Узел активного профиля, приведённый к плоскому виду для списка «Узлы».
class ActiveProfileOutbound {
  const ActiveProfileOutbound({
    required this.tag,
    required this.displayName,
    required this.type,
    required this.groupTag,
    required this.isSelected,
    this.delayMs = 0,
  });

  /// Сырой тег узла — именно он передаётся в `selectOutbound`.
  final String tag;

  /// Имя для показа: `tagDisplay` ядра, с откатом на `tag`.
  final String displayName;

  /// Тип протокола (vless, vmess, trojan, ...).
  final String type;

  /// Группа, в которой живёт узел. Не nullable: узел без группы в список не попадает.
  final String groupTag;

  /// Помечен ли узел как выбранный в снимке ядра.
  final bool isSelected;

  /// Измеренная задержка в мс. 0 — задержка неизвестна.
  final int delayMs;
}

/// Разворачивает снимок групп ядра в плоский список узлов.
///
/// Берётся группа `select` — единственная, где поддержан ручной выбор узла.
/// Остальные группы (balance/urltest) в ручном выборе не участвуют, поэтому
/// узлы из них не дублируются. Ссылки на другие группы (`isGroup`) пропускаются.
List<ActiveProfileOutbound> flattenActiveProfileOutbounds(List<OutboundGroup> groups) {
  final mainSelector = groups.where((group) => group.tag == kActiveProfileMainSelectorTag).firstOrNull;
  final sourceGroups = mainSelector != null ? [mainSelector] : groups.where((group) => group.selectable).toList();

  final seen = <String>{};
  final items = <ActiveProfileOutbound>[];
  for (final group in sourceGroups) {
    for (final item in group.items) {
      if (item.isGroup) continue;
      if (!seen.add(item.tag)) continue;
      items.add(
        ActiveProfileOutbound(
          tag: item.tag,
          displayName: item.tagDisplay.isNotEmpty ? item.tagDisplay : item.tag,
          type: item.type,
          groupTag: group.tag,
          isSelected: group.selected == item.tag || item.isSelected,
          delayMs: item.urlTestDelay,
        ),
      );
    }
  }
  return items;
}

/// Разворачивает сгенерированный конфиг профиля в плоский список узлов.
///
/// Нужен, когда ядро ещё не держит снимок групп (VPN не подключён) — тогда узлы
/// видны по конфигу подписки, как и раньше. Порядок и текущий выбор берутся из
/// группы `select`: её `outbounds` перечисляют узлы, а `default` — выбранный.
List<ActiveProfileOutbound> parseProfileConfigOutbounds(String configJson) {
  Object? decoded;
  try {
    decoded = jsonDecode(configJson);
  } catch (_) {
    return const [];
  }
  if (decoded is! Map) return const [];

  final rawOutbounds = decoded['outbounds'];
  if (rawOutbounds is! List) return const [];

  final byTag = <String, Map<String, dynamic>>{};
  for (final item in rawOutbounds) {
    if (item is! Map) continue;
    final outbound = item.map((key, value) => MapEntry(key.toString(), value));
    final tag = outbound['tag']?.toString();
    if (tag == null || tag.isEmpty) continue;
    byTag[tag] = outbound;
  }

  final selector = byTag[kActiveProfileMainSelectorTag];
  final selectorTags =
      (selector?['outbounds'] as List?)?.map((item) => item.toString()).toList(growable: false) ??
      const <String>[];
  final defaultTag = selector?['default']?.toString();
  final orderedTags = selectorTags.isNotEmpty ? selectorTags : byTag.keys.toList(growable: false);

  final result = <ActiveProfileOutbound>[];
  final seen = <String>{};
  for (final tag in orderedTags) {
    if (!seen.add(tag)) continue;
    final outbound = byTag[tag];
    if (outbound == null) continue;
    final type = outbound['type']?.toString() ?? '';
    if (_internalOutboundTypes.contains(type)) continue;
    if (tag.contains(_hiddenTagMarker)) continue;
    result.add(
      ActiveProfileOutbound(
        tag: tag,
        displayName: trimTagDisplay(tag),
        type: type,
        groupTag: kActiveProfileMainSelectorTag,
        isSelected: defaultTag == tag,
      ),
    );
  }
  return result;
}
