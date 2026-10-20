import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:loggy/loggy.dart';
import 'package:nerpa_vpn/core/haptic/haptic_service.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/notification/in_app_notification_controller.dart';
import 'package:nerpa_vpn/features/connection/notifier/connection_notifier.dart';
import 'package:nerpa_vpn/features/profile/data/profile_data_providers.dart';
import 'package:nerpa_vpn/features/profile/data/selected_outbound_store.dart';
import 'package:nerpa_vpn/features/profile/notifier/active_profile_notifier.dart';
import 'package:nerpa_vpn/features/profile/overview/active_profile_outbound_model.dart';
import 'package:nerpa_vpn/features/proxy/data/proxy_data_providers.dart';
import 'package:nerpa_vpn/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:nerpa_vpn/hiddifycore/hiddify_core_service_provider.dart';
import 'package:nerpa_vpn/utils/utils.dart';

/// Снимок групп, которые сейчас держит ядро.
///
/// Источник — `HiddifyCoreService.activeGroupsController`: ядро кладёт туда
/// снимок при каждом событии групп (в том числе после url-теста). Домашний
/// экран читает этот же провайдер, поэтому он должен остаться здесь.
final activeGroupsSnapshotProvider = StreamProvider<List<OutboundGroup>>((ref) {
  return ref.watch(hiddifyCoreServiceProvider).watchActiveGroupsSnapshot();
});

/// Плоский список узлов активного профиля.
///
/// Синхронный `Provider` намеренно: у провайдера нет состояния загрузки, поэтому
/// список не может «мигать» (спиннер → список → спиннер) на каждое событие ядра.
/// Тяжёлая генерация конфига (`generateConfig`) из этого пути убрана — она
/// парсила весь профиль по gRPC на каждое обновление и подвешивала интерфейс.
final activeProfileOutboundsProvider = Provider<List<ActiveProfileOutbound>>((ref) {
  final groups = ref.watch(activeGroupsSnapshotProvider).valueOrNull ?? const <OutboundGroup>[];
  return flattenActiveProfileOutbounds(groups);
});

/// Узлы из конфига активного профиля — на случай, когда ядро ещё не держит
/// снимок групп (VPN не подключён). Без этого узлы были бы видны только
/// после подключения.
///
/// Считается ОДИН раз на профиль: зависимость только от id активного профиля,
/// поэтому события ядра не запускают пересчёт и список не «мигает».
final activeProfileConfigOutboundsProvider = FutureProvider<List<ActiveProfileOutbound>>((ref) async {
  final profileId = ref.watch(activeProfileProvider.select((state) => state.valueOrNull?.id));
  if (profileId == null) return const [];

  final profilesRepo = await ref.watch(profileRepositoryProvider.future);
  final either = await profilesRepo.generateConfig(profileId).run();
  final config = either.getOrElse((failure) {
    logWarning('failed to generate config for active profile: $failure');
    return '';
  });
  if (config.isEmpty) return const [];

  return parseProfileConfigOutbounds(config);
});

/// Применяет сохранённый выбор узла к ядру.
///
/// Вызывается после подключения: конфиг каждый раз собирается заново, и без
/// этого выбор узла сбрасывался бы на узел подписки по умолчанию.
Future<void> applySavedOutbound(Ref ref, String profileId) async {
  final tag = ref.read(selectedOutboundStoreProvider)?.read(profileId);
  if (tag == null || tag.isEmpty) return;

  for (var attempt = 1; attempt <= 3; attempt++) {
    final result = await ref
        .read(proxyRepositoryProvider)
        .selectProxy(kActiveProfileMainSelectorTag, tag)
        .run();

    if (result.isRight()) {
      logInfo('applied saved outbound [$tag]');
      return;
    }

    // Группа может быть ещё не готова сразу после старта ядра — пробуем ещё раз.
    logWarning('failed to apply saved outbound [$tag] (attempt $attempt): ${result.getLeft()}');
    if (attempt < 3) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    }
  }

  // Узла больше нет в подписке — сохранять бессмысленно.
  await ref.read(selectedOutboundStoreProvider)?.write(profileId, '');
  ref.invalidate(activeProfileSavedOutboundProvider);
}

/// Состояние переключения узла: что переключаем сейчас и что выбрано оптимистично.
class ActiveProfileNodeSelectionState {
  const ActiveProfileNodeSelectionState({this.pendingTag, this.selectedTag, this.isPinging = false});

  /// Узел, который сейчас переключается. Пока он задан, строка показывает спиннер.
  final String? pendingTag;

  /// Оптимистически выбранный узел: галочка переезжает мгновенно, до ответа ядра.
  final String? selectedTag;

  /// Идёт ли измерение задержки.
  final bool isPinging;

  /// Пока есть оптимистический выбор, он важнее данных снимка: галочка должна
  /// переехать сразу, а не после ответа ядра.
  ///
  /// [offlineSelectedTag] — сохранённый выбор, который показываем, пока ядро
  /// не отдаёт снимок групп (VPN выключен).
  bool isSelectedFor(ActiveProfileOutbound node, {String? offlineSelectedTag}) {
    final selected = selectedTag;
    if (selected != null) return node.tag == selected;
    if (offlineSelectedTag != null) return node.tag == offlineSelectedTag;
    return node.isSelected;
  }

  ActiveProfileNodeSelectionState copyWith({
    String? pendingTag,
    String? selectedTag,
    bool? isPinging,
    bool clearPending = false,
    bool clearSelected = false,
  }) {
    return ActiveProfileNodeSelectionState(
      pendingTag: clearPending ? null : (pendingTag ?? this.pendingTag),
      selectedTag: clearSelected ? null : (selectedTag ?? this.selectedTag),
      isPinging: isPinging ?? this.isPinging,
    );
  }
}

/// Переключение узла активного профиля и измерение задержки.
///
/// Оптимистичное: выбор применяется сразу, подтверждение приходит от ядра.
/// Ошибки не теряются — пользователь всегда получает тост, а строка не остаётся
/// со спиннером.
class ActiveProfileNodeSelectionNotifier extends Notifier<ActiveProfileNodeSelectionState> with AppLogger {
  /// Сколько ждём ответа ядра, прежде чем считать переключение неудачным.
  static const Duration selectTimeout = Duration(seconds: 8);

  /// Сколько держим индикатор измерения: тест идёт в фоне, результат приезжает
  /// в снимке ядра позже.
  static const Duration pingIndicatorDuration = Duration(seconds: 6);

  bool _disposed = false;

  @override
  ActiveProfileNodeSelectionState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);

    // Как только ядро подтвердило выбор (в снимке узел помечен выбранным),
    // оптимистическое состояние сбрасывается — источником истины снова ядро.
    ref.listen(activeProfileOutboundsProvider, (previous, next) {
      final selectedTag = state.selectedTag;
      if (selectedTag == null) return;
      final confirmed = next.any((node) => node.tag == selectedTag && node.isSelected);
      final stillExists = next.any((node) => node.tag == selectedTag);
      if (confirmed || !stillExists) {
        // Ядро подтвердило выбор — источником истины снова становится снимок.
        // Если узла больше нет в списке (сменился профиль/подписка) —
        // оптимистическое состояние тоже сбрасываем.
        state = const ActiveProfileNodeSelectionState();
      }
    });
    return const ActiveProfileNodeSelectionState();
  }

  /// Переключает узел. Работает и без подключённого VPN: выбор сохраняется
  /// в приложении и применяется к ядру при следующем подключении.
  Future<bool> select(ActiveProfileOutbound node) async {
    if (state.pendingTag != null) return false;

    state = ActiveProfileNodeSelectionState(pendingTag: node.tag, selectedTag: node.tag);
    await ref.read(hapticServiceProvider.notifier).lightImpact();

    if (!ref.read(serviceRunningProvider)) {
      // Ядро выключено — переключить узел сейчас нечем, но выбор сохраняем.
      await _saveSelection(node.tag);
      state = state.copyWith(clearPending: true);
      _showInfo('Узел сохранён — применится при подключении');
      return true;
    }

    try {
      final result = await ref
          .read(proxyRepositoryProvider)
          .selectProxy(node.groupTag, node.tag)
          .run()
          .timeout(selectTimeout);

      if (result.isLeft()) {
        loggy.warning('select outbound rejected: ${result.getLeft()}');
        state = state.copyWith(clearPending: true, clearSelected: true);
        _showError(_changeFailedMessage);
        return false;
      }

      await _saveSelection(node.tag);
      state = state.copyWith(clearPending: true);
      return true;
    } catch (error, stackTrace) {
      loggy.warning('error selecting outbound', error, stackTrace);
      state = state.copyWith(clearPending: true, clearSelected: true);
      _showError(_changeFailedMessage);
      return false;
    }
  }

  /// Запускает измерение задержки по узлам группы выбора.
  Future<void> ping() async {
    if (state.isPinging) return;

    if (!ref.read(serviceRunningProvider)) {
      _showInfo('Подключитесь, чтобы измерить задержку');
      return;
    }

    state = state.copyWith(isPinging: true);
    try {
      final result = await ref.read(proxyRepositoryProvider).urlTest(kActiveProfileMainSelectorTag).run();
      if (result.isLeft()) {
        loggy.warning('url test failed: ${result.getLeft()}');
        _showError('Не удалось измерить задержку');
      }
    } catch (error, stackTrace) {
      loggy.warning('error running url test', error, stackTrace);
      _showError('Не удалось измерить задержку');
    }

    // Результат измерения приходит в снимке ядра позже — держим индикатор.
    await Future<void>.delayed(pingIndicatorDuration);
    if (_disposed) return;
    state = state.copyWith(isPinging: false);
  }

  Future<void> _saveSelection(String tag) async {
    await saveSelectedOutbound(ref, tag);
  }

  String get _changeFailedMessage {
    final t = ref.read(translationsProvider).valueOrNull;
    return t?.pages.proxies.changeFailed ?? 'Не удалось переключить узел';
  }

  void _showError(String message) {
    ref.read(inAppNotificationControllerProvider).showErrorToast(message);
  }

  void _showInfo(String message) {
    ref.read(inAppNotificationControllerProvider).showInfoToast(message);
  }
}

final activeProfileNodeSelectionProvider =
    NotifierProvider<ActiveProfileNodeSelectionNotifier, ActiveProfileNodeSelectionState>(
  ActiveProfileNodeSelectionNotifier.new,
);
