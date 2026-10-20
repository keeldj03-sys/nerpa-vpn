import 'dart:convert';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nerpa_vpn/features/profile/data/profile_data_providers.dart';
import 'package:nerpa_vpn/features/profile/model/profile_entity.dart';
import 'package:nerpa_vpn/utils/custom_loggers.dart';
import 'package:path/path.dart' as p;

/// Imports subscriptions from an installed v2RayTun client
/// (`%APPDATA%\v2RayTun.net\v2RayTun\shared_preferences.json`) into Nerpa.
/// Each v2RayTun subscription becomes a remote profile identified by its URL,
/// so re-importing updates instead of duplicating.
final v2raytunImportServiceProvider = Provider<V2RayTunImportService>((ref) => V2RayTunImportService(ref));

typedef V2RayTunImportResult = ({int total, int imported, int failed, List<String> failedNames});

class V2RayTunImportService with AppLogger {
  V2RayTunImportService(this._ref);

  final Ref _ref;

  static const _relativePath = r'v2RayTun.net\v2RayTun\shared_preferences.json';

  /// Location of the v2RayTun preferences file, or null when it is absent
  /// (e.g. v2RayTun is not installed or not on Windows).
  File? preferencesFile() {
    final appData = Platform.environment['APPDATA'];
    if (appData == null || appData.isEmpty) return null;
    final file = File(p.join(appData, _relativePath));
    return file.existsSync() ? file : null;
  }

  /// Runs the import. Each subscription is upserted by URL; subscriptions that
  /// fail to fetch are counted as failed and the rest is still imported.
  Future<V2RayTunImportResult> import() async {
    final file = preferencesFile();
    if (file == null) {
      loggy.warning('v2RayTun preferences not found');
      return (total: 0, imported: 0, failed: 0, failedNames: const <String>[]);
    }

    final prefs = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final idsRaw = prefs['flutter.subscriptions'];
    final ids = <String>[];
    if (idsRaw is String) {
      ids.addAll((jsonDecode(idsRaw) as List).whereType<String>());
    } else if (idsRaw is List) {
      ids.addAll(idsRaw.whereType<String>());
    }
    loggy.info('found ${ids.length} v2RayTun subscriptions');

    final repo = await _ref.read(profileRepositoryProvider.future);
    var imported = 0;
    final failedNames = <String>[];

    for (final id in ids) {
      final raw = prefs['flutter.sub_$id'];
      if (raw is! String) continue;
      final sub = jsonDecode(raw) as Map<String, dynamic>;
      final url = (sub['url'] as String?)?.trim() ?? '';
      final name = (sub['remarks'] as String?)?.trim() ?? url;
      if (url.isEmpty) continue;

      final hours = sub['updateInterval'] as int?;
      final userOverride = UserOverride(
        name: name,
        updateInterval: hours,
        isAutoUpdateDisable: sub['autoUpdate'] == false,
      );

      final result = await repo.upsertRemote(url, userOverride: userOverride).run();

      if (result.isRight()) {
        loggy.debug('imported subscription [$name]');
        imported++;
      } else {
        loggy.warning('failed to import subscription [$name]');
        failedNames.add(name);
      }
    }

    loggy.info('import finished: $imported ok, ${failedNames.length} failed');
    return (total: ids.length, imported: imported, failed: failedNames.length, failedNames: failedNames);
  }
}
