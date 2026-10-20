import 'dart:async';

import 'package:dio/dio.dart';
import 'package:nerpa_vpn/core/haptic/haptic_service.dart';
import 'package:nerpa_vpn/core/preferences/general_preferences.dart';
import 'package:nerpa_vpn/core/utils/throttler.dart';
import 'package:nerpa_vpn/features/connection/notifier/connection_notifier.dart';
import 'package:nerpa_vpn/features/proxy/data/proxy_data_providers.dart';
import 'package:nerpa_vpn/features/proxy/data/proxy_repository.dart';
import 'package:nerpa_vpn/features/proxy/model/ip_info_entity.dart' as oldipinfo;
import 'package:nerpa_vpn/features/proxy/model/proxy_failure.dart';
import 'package:nerpa_vpn/hiddifycore/generated/v2/hcore/hcore.pb.dart';

import 'package:nerpa_vpn/utils/riverpod_utils.dart';
import 'package:nerpa_vpn/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_proxy_notifier.g.dart';

@riverpod
class IpInfoNotifier extends _$IpInfoNotifier with AppLogger {
  @override
  Future<oldipinfo.IpInfo> build() async {
    ref.disposeDelay(const Duration(seconds: 20));
    final cancelToken = CancelToken();
    Timer? timer;
    ref.onDispose(() {
      loggy.debug("disposing");
      cancelToken.cancel();
      timer?.cancel();
    });

    ref.listen(serviceRunningProvider, (_, next) => _idle = false);

    final autoCheck = ref.watch(Preferences.autoCheckIp);
    final serviceRunning = ref.watch(serviceRunningProvider);
    // loggy.debug(
    //   "idle? [$_idle], forced? [$_forceCheck], connected? [$serviceRunning]",
    // );
    if (!_forceCheck && !serviceRunning) {
      throw const ServiceNotRunning();
    } else if ((_idle && !_forceCheck) || (!_forceCheck && serviceRunning && !autoCheck)) {
      throw const UnknownIp();
    }

    _forceCheck = false;
    final info = await ref.watch(proxyRepositoryProvider).getCurrentIpInfo(cancelToken).getOrElse((err) {
      loggy.warning("error getting proxy ip info", err, StackTrace.current);
      // throw err; //hiddify: remove exception to be logged
      throw const UnknownIp();
    }).run();

    timer = Timer(const Duration(seconds: 10), () {
      loggy.debug("entering idle mode");
      _idle = true;
      ref.invalidateSelf();
    });

    return info;
  }

  bool _idle = false;
  bool _forceCheck = false;

  Future<void> refresh() async {
    if (state.isLoading) return;
    loggy.debug("refreshing");
    state = const AsyncLoading();
    await ref.read(hapticServiceProvider.notifier).lightImpact();
    _forceCheck = true;
    ref.invalidateSelf();
  }
}

@Riverpod(keepAlive: true)
class ActiveProxyNotifier extends _$ActiveProxyNotifier with AppLogger {
  @override
  Stream<OutboundInfo> build() {
    // ref.disposeDelay(const Duration(seconds: 20));
    return _proxyRepo.watchActiveProxies().map((event) => event.getOrElse((l) => List<OutboundGroup>.empty())).map((
      groups,
    ) {
      loggy.info(
        "active proxy input groups: ${groups.map((group) => "groupTag=[${group.tag}] selected=[${group.selected}] items=[${group.items.map((item) => "${item.tag}:${item.isSelected}").join(',')}]").join(' | ')}",
      );
      for (final group in groups) {
        final selected = group.selected.isNotEmpty
            ? group.items.where((item) => item.tag == group.selected).firstOrNull ??
                  group.items.where((item) => item.isSelected).firstOrNull
            : group.items.where((item) => item.isSelected).firstOrNull;
        // v2RayTun shows the actual node on the home screen. When the selected
        // entry is a group (balance/lowest balancer), resolve down to the node
        // it currently routes through, e.g. select→balance→"📱 Mobile WS § 2".
        final leaf = selected == null ? null : _resolveLeaf(groups, selected);
        if (leaf != null) {
          loggy.info(
            "active proxy resolved: groupTag=[${group.tag}] selectedTag=[${group.selected}] outboundTag=[${leaf.tag}] isSelected=[${leaf.isSelected}]",
          );
          return leaf;
        }
      }
      final fallback = groups.firstOrNull?.items.firstOrNull ?? OutboundInfo();
      loggy.warning("active proxy fallback used: outboundTag=[${fallback.tag}] isSelected=[${fallback.isSelected}]");
      return fallback;
    });
  }

  /// Follows group chains (select → balance/lowest → node) until it reaches a
  /// node that is not itself a group, so the home screen displays a server.
  /// Balancers such as "balance" have no manual pick (round-robin), so fall
  /// back to the node the balancer currently routes through — and if that is
  /// unknown, to the first node of the group.
  OutboundInfo? _resolveLeaf(List<OutboundGroup> groups, OutboundInfo selected, [int depth = 0]) {
    if (!selected.isGroup) return selected;
    if (depth > 4) return selected;
    String? chosenTag = selected.groupSelectedTag;
    if (chosenTag == null || chosenTag.isEmpty) {
      chosenTag = groups.where((g) => g.tag == selected.tag).firstOrNull?.selected;
    }
    final groupItems = groups.where((g) => g.tag == selected.tag).expand((g) => g.items);
    if (chosenTag == null || chosenTag.isEmpty) {
      chosenTag = groupItems.where((item) => !item.isGroup).firstOrNull?.tag;
    }
    if (chosenTag == null || chosenTag.isEmpty) return selected;
    final child = groupItems.where((item) => item.tag == chosenTag).firstOrNull;
    return child == null ? selected : _resolveLeaf(groups, child, depth + 1);
  }

  ProxyRepository get _proxyRepo => ref.read(proxyRepositoryProvider);

  final _urlTestThrottler = Throttler(const Duration(seconds: 1));

  Future<void> urlTest(String? groupTag_) async {
    final groupTag = groupTag_ ?? "";
    _urlTestThrottler(() async {
      if (state case AsyncData()) {
        await ref.read(hapticServiceProvider.notifier).lightImpact();
        await ref.read(proxyRepositoryProvider).urlTest(groupTag).getOrElse((err) {
          loggy.warning("error testing group", err);
          throw err;
        }).run();
      }
    });
  }
}
