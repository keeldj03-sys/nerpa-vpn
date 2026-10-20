import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:nerpa_vpn/core/http_client/dio_http_client.dart';
import 'package:nerpa_vpn/core/utils/exception_handler.dart';
import 'package:nerpa_vpn/features/proxy/model/ip_info_entity.dart' as oldipinfo;

import 'package:nerpa_vpn/features/proxy/model/proxy_failure.dart';
import 'package:nerpa_vpn/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:nerpa_vpn/hiddifycore/hiddify_core_service.dart';
import 'package:nerpa_vpn/utils/custom_loggers.dart';

abstract interface class ProxyRepository {
  // Stream<Either<ProxyFailure, List<OutboundGroup>>> watchProxies();
  Stream<Either<ProxyFailure, OutboundGroup?>> watchProxies();
  Stream<Either<ProxyFailure, List<OutboundGroup>>> watchActiveProxies();
  TaskEither<ProxyFailure, oldipinfo.IpInfo> getCurrentIpInfo(CancelToken cancelToken);
  TaskEither<ProxyFailure, Unit> selectProxy(String groupTag, String outboundTag);
  TaskEither<ProxyFailure, Unit> urlTest(String groupTag);
}

class ProxyRepositoryImpl with ExceptionHandler, InfraLogger implements ProxyRepository {
  ProxyRepositoryImpl({required this.singbox, required this.client});

  final HiddifyCoreService singbox;
  final DioHttpClient client;

  // @override
  // Stream<Either<ProxyFailure, List<OutboundGroup>>> watchProxies() {
  //   return singbox.watchGroups().map((event) {
  //     // final groupWithSelected = {
  //     //   for (final group in event) group.tag: group.selected,
  //     // };

  //     return event;
  //     // .map(
  //     //   (e) => ProxyGroupEntity(
  //     //     tag: e.tag,
  //     //     type: e.type,
  //     //     selected: e.selected,
  //     //     items: e.items
  //     //         .map(
  //     //           (e) => ProxyItemEntity(
  //     //             tag: e.tag,
  //     //             type: e.type,
  //     //             urlTestDelay: e.urlTestDelay,
  //     //             selectedTag: groupWithSelected[e.tag],
  //     //           ),
  //     //         )
  //     //         .filter((t) => t.isVisible)
  //     //         .toList(),
  //     //   ),
  //     // )
  //     // .toList();
  //   }).handleExceptions(
  //     (error, stackTrace) {
  //       loggy.error("error watching proxies", error, stackTrace);
  //       return ProxyUnexpectedFailure(error, stackTrace);
  //     },
  //   );
  // }

  @override
  Stream<Either<ProxyFailure, OutboundGroup?>> watchProxies() {
    return singbox.watchGroup().handleExceptions((error, stackTrace) {
      loggy.error("error watching proxies", error, stackTrace);
      return ProxyUnexpectedFailure(error, stackTrace);
    });
  }

  @override
  Stream<Either<ProxyFailure, List<OutboundGroup>>> watchActiveProxies() async* {
    // The gRPC stream breaks whenever the core process is replaced. Yield the
    // last snapshot so the UI keeps its list, then resubscribe instead of
    // ending the stream (which would freeze the proxies page forever).
    while (true) {
      try {
        await for (final groups in singbox.watchActiveGroups()) {
          yield right<ProxyFailure, List<OutboundGroup>>(groups);
        }
      } catch (error, stackTrace) {
        loggy.error("error watching active proxies; using latest snapshot", error, stackTrace);
        yield right<ProxyFailure, List<OutboundGroup>>(singbox.latest);
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  @override
  TaskEither<ProxyFailure, Unit> selectProxy(String groupTag, String outboundTag) {
    return exceptionHandler(
      () => singbox.selectOutbound(groupTag, outboundTag).mapLeft(ProxyUnexpectedFailure.new).run(),
      ProxyUnexpectedFailure.new,
    );
  }

  @override
  TaskEither<ProxyFailure, Unit> urlTest(String groupTag) {
    return exceptionHandler(
      () => singbox.urlTest(groupTag).mapLeft(ProxyUnexpectedFailure.new).run(),
      ProxyUnexpectedFailure.new,
    );
  }

  static final Map<String, oldipinfo.IpInfo Function(Map<String, dynamic> response)> _ipInfoSources = {
    // "https://geolocation-db.com/json/": IpInfo.fromGeolocationDbComJson, //bug response is not json
    "https://ipwho.is/": oldipinfo.IpInfo.fromIpwhoIsJson,
    "https://api.ip.sb/geoip/": oldipinfo.IpInfo.fromIpSbJson,
    "https://ipapi.co/json/": oldipinfo.IpInfo.fromIpApiCoJson,
    "https://ipinfo.io/json/": oldipinfo.IpInfo.fromIpInfoIoJson,
  };

  @override
  TaskEither<ProxyFailure, oldipinfo.IpInfo> getCurrentIpInfo(CancelToken cancelToken) {
    return TaskEither.tryCatch(() async {
      Object? error;
      for (final source in _ipInfoSources.entries) {
        try {
          loggy.debug("getting current ip info using [${source.key}]");
          final response = await client.get<Map<String, dynamic>>(
            source.key,
            cancelToken: cancelToken,
            proxyOnly: true,
          );
          if (response.statusCode == 200 && response.data != null) {
            return source.value(response.data!);
          }
        } catch (e, s) {
          loggy.debug("failed getting ip info using [${source.key}]", e, s);
          error = e;
          continue;
        }
      }
      throw UnableToRetrieveIp(error, StackTrace.current);
    }, ProxyUnexpectedFailure.new);
  }
}
