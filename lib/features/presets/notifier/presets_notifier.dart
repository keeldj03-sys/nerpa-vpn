import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:loggy/loggy.dart';
import 'package:nerpa_vpn/core/http_client/http_client_provider.dart';
import 'package:nerpa_vpn/core/preferences/general_preferences.dart';
import 'package:nerpa_vpn/features/presets/model/preset.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'presets_notifier.g.dart';

final _loggy = Loggy('presetsNotifier');

/// Routing presets: built-in bundles from `assets/presets/presets.json`,
/// optionally extended with a custom URL ([Preferences.presetsUrl]),
/// mirroring v2RayTun's preset system (without its proprietary backend).
@riverpod
Future<List<Preset>> presets(Ref ref) async {
  final result = <Preset>[];

  // 1. built-in presets
  try {
    final content = await rootBundle.loadString('assets/presets/presets.json');
    final json = jsonDecode(content) as Map<String, dynamic>;
    final presets =
        ((json['presets'] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>();
    result.addAll(presets.map(Preset.fromJson));
  } catch (e, st) {
    _loggy.warning("error loading built-in presets", e, st);
  }

  // 2. optional custom presets URL
  final url = ref.watch(Preferences.presetsUrl);
  if (url.trim().isNotEmpty) {
    try {
      final response = await ref.read(httpClientProvider).get<String>(url.trim());
      final body = response.data?.trim() ?? '';
      if (body.isNotEmpty) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final custom = ((json['presets'] as List<dynamic>?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map((e) => Preset.fromJson({...e, 'isCustom': true}));
        result.addAll(custom);
      }
    } catch (e, st) {
      _loggy.warning("error loading custom presets from '$url'", e, st);
    }
  }

  return result;
}
