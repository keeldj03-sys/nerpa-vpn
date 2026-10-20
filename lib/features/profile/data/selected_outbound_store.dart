import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nerpa_vpn/core/preferences/preferences_provider.dart';
import 'package:nerpa_vpn/features/profile/notifier/active_profile_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сохранённый выбор узла профиля.
///
/// Пока VPN выключен, ядро не может переключить узел: бокс sing-box не запущен,
/// и `SelectOutbound` завершается успехом, ничего не меняя. Поэтому выбор
/// храним в приложении и применяем к ядру сразу после подключения.
class SelectedOutboundStore {
  const SelectedOutboundStore(this.preferences);

  final SharedPreferences preferences;

  static String keyFor(String profileId) => 'selected_outbound_$profileId';

  /// Тег сохранённого узла профиля или null, если выбор не сохранён.
  String? read(String profileId) {
    final value = preferences.getString(keyFor(profileId));
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> write(String profileId, String outboundTag) async {
    await preferences.setString(keyFor(profileId), outboundTag);
  }
}

final selectedOutboundStoreProvider = Provider<SelectedOutboundStore?>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider).valueOrNull;
  if (preferences == null) return null;
  return SelectedOutboundStore(preferences);
});

/// Сохранённый выбор узла активного профиля.
final activeProfileSavedOutboundProvider = Provider<String?>((ref) {
  final profileId = ref.watch(activeProfileProvider.select((state) => state.valueOrNull?.id));
  if (profileId == null) return null;
  return ref.watch(selectedOutboundStoreProvider)?.read(profileId);
});

/// Сохраняет выбранный узел активного профиля.
///
/// Вызывается отовсюду, где узел выбирается (карточка профиля, экран «Серверы»),
/// чтобы выбор не терялся при следующем подключении.
Future<void> saveSelectedOutbound(Ref ref, String outboundTag) async {
  final profileId = ref.read(activeProfileProvider).valueOrNull?.id;
  if (profileId == null) return;
  await ref.read(selectedOutboundStoreProvider)?.write(profileId, outboundTag);
  ref.invalidate(activeProfileSavedOutboundProvider);
}
