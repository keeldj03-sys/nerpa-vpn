import 'dart:async';

import 'package:dartx/dartx.dart';

import 'package:nerpa_vpn/core/haptic/haptic_service.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/notification/in_app_notification_controller.dart';
import 'package:nerpa_vpn/core/preferences/preferences_provider.dart';
import 'package:nerpa_vpn/core/utils/preferences_utils.dart';
import 'package:nerpa_vpn/features/connection/notifier/connection_notifier.dart';
import 'package:nerpa_vpn/features/profile/data/selected_outbound_store.dart';
import 'package:nerpa_vpn/features/proxy/data/proxy_data_providers.dart';
import 'package:nerpa_vpn/features/proxy/model/proxy_failure.dart';
import 'package:nerpa_vpn/features/proxy/overview/proxy_overview_item.dart';
import 'package:nerpa_vpn/hiddifycore/generated/v2/hcore/hcore.pb.dart';

import 'package:nerpa_vpn/utils/riverpod_utils.dart';
import 'package:nerpa_vpn/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'proxies_overview_notifier.g.dart';

enum ProxiesSort {
  unsorted,
  name,
  delay,
  usage;

  String present(TranslationsEn t) => switch (this) {
    ProxiesSort.unsorted => t.pages.proxies.sortOptions.unsorted,
    ProxiesSort.name => t.pages.proxies.sortOptions.name,
    ProxiesSort.delay => t.pages.proxies.sortOptions.delay,
    ProxiesSort.usage => t.pages.proxies.sortOptions.usage,
  };
}

@Riverpod(keepAlive: true)
class ProxiesSortNotifier extends _$ProxiesSortNotifier with AppLogger {
  late final _pref = PreferencesEntry(
    preferences: ref.watch(sharedPreferencesProvider).requireValue,
    key: "proxies_sort_mode",
    defaultValue: ProxiesSort.delay,
    mapFrom: ProxiesSort.values.byName,
    mapTo: (value) => value.name,
  );

  @override
  ProxiesSort build() {
    final sortBy = _pref.read();
    loggy.info("sort proxies by: [${sortBy.name}]");
    return sortBy;
  }

  Future<void> update(ProxiesSort value) {
    state = value;
    return _pref.write(value);
  }
}

@riverpod
class ProxiesOverviewNotifier extends _$ProxiesOverviewNotifier with AppLogger {
  @override
  Stream<List<ProxyOverviewItem>> build() {
    ref.disposeDelay(const Duration(seconds: 15));
    final serviceRunning = ref.watch(serviceRunningProvider);
    if (!serviceRunning) {
      return Stream.error(const ServiceNotRunning());
    }
    final sortBy = ref.watch(proxiesSortNotifierProvider);
    return ref
        .watch(proxyRepositoryProvider)
        .watchActiveProxies()
        .map(
          (event) => event.getOrElse((err) {
            loggy.warning("error receiving active proxies", err);
            throw err;
          }),
        )
        .map(_flattenOutbounds)
        .map((items) => _sortOutbounds(items, sortBy))
        // Transient gRPC failures (e.g. while the core is still starting)
        // used to switch the page into the error state and make the whole
        // list disappear; keep the last snapshot instead.
        .handleError((Object error, StackTrace stackTrace) {
          loggy.warning("transient proxies stream error, keeping last snapshot", error, stackTrace);
        });
  }

  // Future<List<OutboundGroup>> _sortOutbounds(
  //   List<OutboundGroup> proxies,
  //   ProxiesSort sortBy,
  // ) async {
  //   final groupWithSelected = {
  //     for (final o in proxies) o.tag: o.selected,
  //   };
  //   final sortedProxies = <OutboundGroup>[];
  //   for (final group in proxies) {
  //     final sortedItems = switch (sortBy) {
  //       ProxiesSort.name => group.items.sortedWith((a, b) {
  //           if (a.isGroup && !b.isGroup) return -1;
  //           if (!a.isGroup && b.isGroup) return 1;
  //           return a.tag.compareTo(b.tag);
  //         }),
  //       ProxiesSort.delay => group.items.sortedWith((a, b) {
  //           if (a.isGroup && !b.isGroup) return -1;
  //           if (!a.isGroup && b.isGroup) return 1;

  //           final ai = a.urlTestDelay;
  //           final bi = b.urlTestDelay;
  //           if (ai == 0 && bi == 0) return -1;
  //           if (ai == 0 && bi > 0) return 1;
  //           if (ai > 0 && bi == 0) return -1;
  //           return ai.compareTo(bi);
  //         }),
  //       ProxiesSort.unsorted => group.items,
  //     };
  //     final items = <OutboundInfo>[];
  //     for (final item in sortedItems) {
  //       // if (groupWithSelected.keys.contains(item.tag)) {
  //       //   items.add(item.copyWith(selectedTag: groupWithSelected[item.tag]));
  //       // } else {
  //       items.add(item);
  //       // }
  //     }
  //     group.items.clear();
  //     group.items.addAll(items);
  //     sortedProxies.add(group);
  //   }
  //   return sortedProxies;
  // }

  List<ProxyOverviewItem> _flattenOutbounds(List<OutboundGroup> groups) {
    // v2RayTun shows one flat list of the subscription's nodes. Every node
    // exists in several groups (select/balance/lowest); the "select" group is
    // the one Selector that supports manual picking, so prefer it when present
    // and deduplicate the rest of the groups by tag.
    final mainSelector = groups.where((g) => g.tag == "select").firstOrNull;
    final sourceGroups = mainSelector != null ? [mainSelector] : groups;
    final seen = <String>{};
    final items = <ProxyOverviewItem>[];
    for (final group in sourceGroups) {
      for (final item in group.items) {
        if (item.isGroup) continue;
        if (!seen.add(item.tag)) continue;
        items.add(
          ProxyOverviewItem(
            groupTag: group.tag,
            outbound: item,
            isSelected: group.selected == item.tag || item.isSelected,
          ),
        );
      }
    }
    return items;
  }

  List<ProxyOverviewItem> _sortOutbounds(List<ProxyOverviewItem> proxies, ProxiesSort sortBy) {
    return switch (sortBy) {
      ProxiesSort.name => proxies.sortedWith((a, b) => a.outbound.tag.compareTo(b.outbound.tag)),
      ProxiesSort.delay => proxies.sortedWith((a, b) {
        final ai = a.outbound.urlTestDelay;
        final bi = b.outbound.urlTestDelay;
        if (ai == 0 && bi == 0) return a.outbound.tag.compareTo(b.outbound.tag);
        if (ai == 0 && bi > 0) return 1;
        if (ai > 0 && bi == 0) return -1;
        final delayCompare = ai.compareTo(bi);
        return delayCompare != 0 ? delayCompare : a.outbound.tag.compareTo(b.outbound.tag);
      }),
      ProxiesSort.unsorted => proxies,
      ProxiesSort.usage => proxies.sortedWith(
        (a, b) => (b.outbound.upload + b.outbound.download).compareTo(a.outbound.upload + a.outbound.download),
      ),
    };
  }

  // Future<void> changeProxy(String groupTag, String outboundTag) async {
  //   loggy.debug(
  //     "changing proxy, group: [$groupTag] - outbound: [$outboundTag]",
  //   );
  //   if (state case AsyncData(value: final outbounds)) {
  //     await ref.read(hapticServiceProvider.notifier).lightImpact();
  //     await ref.read(proxyRepositoryProvider).selectProxy(groupTag, outboundTag).getOrElse((err) {
  //       loggy.warning("error selecting outbound", err);
  //       throw err;
  //     }).run();
  //     final outboundg = outbounds.where((e) => e.tag == groupTag).firstOrNull;
  //     if (outboundg != null) {
  //       final newselected = outboundg.items.where((e) => e.tag == outboundTag).firstOrNull;
  //       if (newselected != null) {
  //         newselected.isSelected = true;
  //         outboundg.selected = newselected;
  //       }
  //     }
  //     state = AsyncData(
  //       [...outbounds],
  //     ).copyWithPrevious(state);
  //   }
  // }

  Future<void> changeProxy(String groupTag, String outboundTag) async {
    loggy.debug("changing proxy, group: [$groupTag] - outbound: [$outboundTag]");
    if (!state.hasValue) return;
    final outbounds = state.value!;
    await ref.read(hapticServiceProvider.notifier).lightImpact();
    try {
      await ref.read(proxyRepositoryProvider).selectProxy(groupTag, outboundTag).run();
    } catch (error, stackTrace) {
      loggy.warning("error selecting outbound", error, stackTrace);
      ref.read(inAppNotificationControllerProvider).showErrorToast(
            ref.read(translationsProvider).requireValue.pages.proxies.changeFailed,
          );
    }
    // Сохраняем выбор, чтобы он не слетел при следующем подключении:
    // конфиг каждый раз собирается заново и узел сбрасывается на узел по умолчанию.
    await saveSelectedOutbound(ref, outboundTag);
    state = AsyncValue.data([
      for (final item in outbounds)
        ProxyOverviewItem(
          groupTag: item.groupTag,
          outbound: item.outbound,
          isSelected: item.groupTag == groupTag ? item.outbound.tag == outboundTag : item.isSelected,
        ),
    ]);
  }

  Future<void> urlTest(String groupTag) async {
    loggy.debug("testing group: [$groupTag]");
    if (state case AsyncData()) {
      await ref.read(hapticServiceProvider.notifier).lightImpact();
      await ref.read(proxyRepositoryProvider).urlTest(groupTag).getOrElse((err) {
        loggy.error("error testing group", err);
        throw err;
      }).run();
    }
  }
}
