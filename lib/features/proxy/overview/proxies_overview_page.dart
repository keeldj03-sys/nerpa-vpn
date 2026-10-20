import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/model/failures.dart';
import 'package:nerpa_vpn/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:nerpa_vpn/features/proxy/widget/proxy_tile.dart';
import 'package:nerpa_vpn/utils/utils.dart';

class ProxiesOverviewPage extends HookConsumerWidget with PresLogger {
  const ProxiesOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final proxies = ref.watch(proxiesOverviewNotifierProvider);
    final sortBy = ref.watch(proxiesSortNotifierProvider);
    final search = useState('');

    // final selectActiveProxyMutation = useMutation(
    //   initialOnFailure: (error) => CustomToast.error(t.presentShortError(error)).show(context),
    // );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.proxies.title),
        actions: [
          PopupMenuButton<ProxiesSort>(
            initialValue: sortBy,
            onSelected: ref.read(proxiesSortNotifierProvider.notifier).update,
            icon: const Icon(FluentIcons.arrow_sort_24_regular),
            tooltip: t.pages.proxies.sort,
            itemBuilder: (context) {
              return [...ProxiesSort.values.map((e) => PopupMenuItem(value: e, child: Text(e.present(t))))];
            },
          ),
          const Gap(8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (value) => search.value = value.toLowerCase().trim(),
              decoration: InputDecoration(
                hintText: t.pages.proxies.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => await ref.read(proxiesOverviewNotifierProvider.notifier).urlTest("select"),
        tooltip: t.pages.proxies.testDelay,
        child: const Icon(FluentIcons.flash_24_filled),
      ),
      body: proxies.when(
        data: (group) {
          if (group == null) return Center(child: Text(t.pages.proxies.empty));
          final query = search.value;
          final items = group.items;
          final filtered = query.isEmpty
              ? items
              : items
                  .where(
                    (e) =>
                        e.tag.toLowerCase().contains(query) ||
                        (e.ipinfo.countryCode.toLowerCase().contains(query)) ||
                        (e.ipinfo.org.toLowerCase().contains(query)),
                  )
                  .toList();
          return filtered.isNotEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = PlatformUtils.isMobile && width < 600 ? 1 : max(1, (width / 268).floor());
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 86),
                      itemCount: filtered.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisExtent: 72,
                      ),
                      itemBuilder: (context, index) {
                        final proxy = filtered[index];
                        return ProxyTile(
                          proxy,
                          selected: proxy.tag == group.selected,
                          onTap: () async {
                            await ref
                                .read(proxiesOverviewNotifierProvider.notifier)
                                .changeProxy(group.tag, proxy.tag);
                          },
                        );
                      },
                    );
                  },
                )
              : Center(child: Text(t.pages.proxies.empty));
        },
        error: (error, stackTrace) => Center(child: Text(t.presentShortError(error))),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
