import 'package:nerpa_vpn/features/profile/data/profile_data_mapper.dart';
import 'package:nerpa_vpn/features/profile/data/profile_data_providers.dart';
import 'package:nerpa_vpn/features/profile/model/profile_entity.dart';
import 'package:nerpa_vpn/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_profile_notifier.g.dart';

@Riverpod(keepAlive: true)
class ActiveProfile extends _$ActiveProfile with AppLogger {
  @override
  Stream<ProfileEntity?> build() {
    loggy.debug("watching active profile");
    return ref.watch(profileDataSourceProvider).watchActiveProfile().map((event) => event?.toEntity());
  }
}

// TODO: move to specific feature
@Riverpod(keepAlive: true)
Stream<bool> hasAnyProfile(Ref ref) {
  return ref.watch(profileDataSourceProvider).watchProfilesCount().map((event) => event != 0).distinct();
}
