import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nerpa_vpn/core/directories/directories_provider.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/notification/in_app_notification_controller.dart';
import 'package:nerpa_vpn/core/router/dialog/dialog_notifier.dart';
import 'package:nerpa_vpn/features/connection/notifier/connection_notifier.dart';
import 'package:nerpa_vpn/utils/custom_loggers.dart';

/// Performs a "hard reset": clears the sing-box geo/rule-set cache
/// (cache.db), the last generated config, crash reports and the temporary
/// directory, keeping profiles and preferences intact. Triggered by the
/// `nerpa://control/hard-reset` deep link.
final hardResetServiceProvider = Provider<HardResetService>((ref) => HardResetService(ref));

class HardResetService with AppLogger {
  HardResetService(this._ref);

  final Ref _ref;

  static const _workingDirCaches = <String>[
    'cache.db',
    'data',
    'crash_reports',
    'oom_reports',
  ];

  Future<void> reset() async {
    final t = _ref.read(translationsProvider).requireValue;

    final confirmed = await _ref.read(dialogNotifierProvider.notifier).showConfirmation(
          title: t.pages.settings.hardReset.title,
          message: t.pages.settings.hardReset.message,
        );
    if (!confirmed) {
      loggy.debug('hard reset cancelled by user');
      return;
    }

    loggy.info('hard reset: clearing caches');
    final notifications = _ref.read(inAppNotificationControllerProvider);

    try {
      // Stop the running core first: it holds cache.db and the config open.
      await _ref.read(connectionNotifierProvider.notifier).abortConnection();
      await Future<void>.delayed(const Duration(milliseconds: 600));

      final dirs = _ref.read(appDirectoriesProvider).requireValue;

      await _clearDirectoryContents(dirs.tempDir);
      await _clearWorkingDirCaches(dirs.workingDir);

      loggy.info('hard reset: done');
      notifications.showSuccessToast(t.pages.settings.hardReset.success);
    } catch (e, stack) {
      loggy.error('hard reset failed', e, stack);
      notifications.showErrorToast(t.pages.settings.hardReset.failure);
    }
  }

  Future<void> _clearDirectoryContents(Directory dir) async {
    if (!dir.existsSync()) return;
    await for (final entry in dir.list()) {
      try {
        if (entry is File) {
          await entry.delete();
        } else if (entry is Directory) {
          await entry.delete(recursive: true);
        }
      } catch (e) {
        loggy.warning('failed to delete ${entry.path}: $e');
      }
    }
  }

  Future<void> _clearWorkingDirCaches(Directory workingDir) async {
    if (!workingDir.existsSync()) return;
    for (final name in _workingDirCaches) {
      final entity = FileSystemEntity.typeSync('${workingDir.path}/$name');
      try {
        if (entity == FileSystemEntityType.file) {
          await File('${workingDir.path}/$name').delete();
        } else if (entity == FileSystemEntityType.directory) {
          await Directory('${workingDir.path}/$name').delete(recursive: true);
        }
      } catch (e) {
        loggy.warning('failed to delete $name: $e');
      }
    }
    // Core crash logs (CrashReport-*.log) are safe to drop as well.
    await for (final entry in workingDir.list()) {
      if (entry is File && entry.path.split(Platform.pathSeparator).last.startsWith('CrashReport-')) {
        try {
          await entry.delete();
        } catch (_) {}
      }
    }
  }
}
