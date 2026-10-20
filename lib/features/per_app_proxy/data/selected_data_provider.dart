import 'package:nerpa_vpn/core/db/provider/db_providers.dart';
import 'package:nerpa_vpn/features/per_app_proxy/data/app_proxy_data_source.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_data_provider.g.dart';

@riverpod
AppProxyDataSource appProxyDataSource(Ref ref) => AppProxyDao(ref.watch(dbProvider));
