import 'package:nerpa_vpn/core/directories/directories_provider.dart';
import 'package:nerpa_vpn/features/log/data/log_path_resolver.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'log_data_providers.g.dart';

@Riverpod(keepAlive: true)
LogPathResolver logPathResolver(Ref ref) {
  return LogPathResolver(ref.watch(appDirectoriesProvider).requireValue.workingDir);
}
