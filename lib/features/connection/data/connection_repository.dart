import 'package:fpdart/fpdart.dart';
import 'package:nerpa_vpn/core/model/directories.dart';
import 'package:nerpa_vpn/core/preferences/general_preferences.dart';
import 'package:nerpa_vpn/core/router/dialog/dialog_notifier.dart';
import 'package:nerpa_vpn/core/utils/exception_handler.dart';
import 'package:nerpa_vpn/features/connection/model/connection_failure.dart';
import 'package:nerpa_vpn/features/connection/model/connection_status.dart';
import 'package:nerpa_vpn/features/profile/data/profile_path_resolver.dart';
import 'package:nerpa_vpn/features/profile/model/profile_entity.dart';
import 'package:nerpa_vpn/features/settings/data/config_option_repository.dart';
import 'package:nerpa_vpn/hiddifycore/hiddify_core_service.dart';
import 'package:nerpa_vpn/singbox/model/core_status.dart';
import 'package:nerpa_vpn/singbox/model/singbox_config_option.dart';
import 'package:nerpa_vpn/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:meta/meta.dart';

abstract interface class ConnectionRepository {
  SingboxConfigOption? get configOptionsSnapshot;

  TaskEither<ConnectionFailure, Unit> setup();
  Stream<ConnectionStatus> watchConnectionStatus();
  TaskEither<ConnectionFailure, Unit> connect(ProfileEntity activeProfile, bool disableMemoryLimit);
  TaskEither<ConnectionFailure, Unit> disconnect();
  TaskEither<ConnectionFailure, Unit> reconnect(ProfileEntity activeProfile, bool disableMemoryLimit);
}

class ConnectionRepositoryImpl with ExceptionHandler, InfraLogger implements ConnectionRepository {
  ConnectionRepositoryImpl({
    required this.ref,
    required this.directories,
    required this.singbox,
    required this.configOptionRepository,
    required this.profilePathResolver,
  });

  final Ref ref;

  final Directories directories;
  final HiddifyCoreService singbox;

  final ConfigOptionRepository configOptionRepository;
  final ProfilePathResolver profilePathResolver;

  SingboxConfigOption? _configOptionsSnapshot;
  @override
  SingboxConfigOption? get configOptionsSnapshot => _configOptionsSnapshot;

  bool _initialized = false;

  @override
  TaskEither<ConnectionFailure, Unit> setup() {
    if (_initialized) return TaskEither.of(unit);
    return exceptionHandler(() {
      loggy.debug("setting up singbox");

      return singbox
          .setup()
          .map((r) {
            _initialized = true;
            return r;
          })
          .mapLeft(UnexpectedConnectionFailure.new)
          .run();
    }, UnexpectedConnectionFailure.new);
  }

  @override
  Stream<ConnectionStatus> watchConnectionStatus() {
    return singbox.watchStatus().map(
      (event) => switch (event) {
        CoreStopped() => Disconnected(event.getCoreAlert()),
        CoreStarting() => const Connecting(),
        CoreStarted() => const Connected(),
        CoreStopping() => const Disconnecting(),
      },
    );
  }

  @override
  TaskEither<ConnectionFailure, Unit> connect(ProfileEntity activeProfile, bool disableMemoryLimit) => setup().flatMap(
    (_) => applyConfigOption(activeProfile).flatMap(
      (_) => singbox.start(profilePathResolver.file(activeProfile.id).path, activeProfile.name, disableMemoryLimit),
      // .mapLeft(UnexpectedConnectionFailure.new),
    ),
  );

  @override
  TaskEither<ConnectionFailure, Unit> disconnect() => singbox.stop().mapLeft(UnexpectedConnectionFailure.new);

  @override
  TaskEither<ConnectionFailure, Unit> reconnect(ProfileEntity activeProfile, bool disableMemoryLimit) =>
      applyConfigOption(activeProfile).flatMap(
        (_) => singbox
            .restart(profilePathResolver.file(activeProfile.id).path, activeProfile.name, disableMemoryLimit)
            .mapLeft(UnexpectedConnectionFailure.new),
      );

  @visibleForTesting
  TaskEither<ConnectionFailure, Unit> applyConfigOption(ProfileEntity prof) =>
      TaskEither.fromEither(configOptionRepository.fullOptionsOverrided(prof.profileOverride()))
          .mapLeft((l) => ConnectionFailure.invalidConfigOption(null, l))
          .flatMap(
            (overridedOptions) => TaskEither.tryCatch(() async {
              if (!overridedOptions.chainStatus.isOff()) {
                final isWarpLicenseAgreed = ref.read(Preferences.warpConsentGiven) == true;
                final isWarpEnabled =
                    overridedOptions.unblocker.mode.isWarp() || overridedOptions.extraSecurity.mode.isWarp();
                if (!isWarpLicenseAgreed && isWarpEnabled) {
                  final isAgreed = await ref.read(dialogNotifierProvider.notifier).showWarpLicense();
                  if (isAgreed == true) {
                    await ref.read(Preferences.warpConsentGiven.notifier).update(true);
                    // return (await applyConfigOption(prof).run()).match((l) => throw l, (_) => unit);
                  } else {
                    throw const MissingWarpLicense();
                  }
                }

                final isPsiphonLicenseAgreed = ref.read(Preferences.psiphonConsentGiven) == true;
                final isPsiphonEnabled =
                    overridedOptions.unblocker.mode.isPsiphon() || overridedOptions.extraSecurity.mode.isPsiphon();
                if (!isPsiphonLicenseAgreed && isPsiphonEnabled) {
                  final isAgreed = await ref.read(dialogNotifierProvider.notifier).showPsiphonLicense();
                  if (isAgreed == true) {
                    await ref.read(Preferences.psiphonConsentGiven.notifier).update(true);
                  } else {
                    throw const MissingPsiphonLicense();
                  }
                }
              }

              _configOptionsSnapshot = overridedOptions;
              await singbox.changeOptions(overridedOptions).run();
              return unit;
            }, (err, st) => err is ConnectionFailure ? err : ConnectionFailure.unexpected(err, st)),
          );
}
