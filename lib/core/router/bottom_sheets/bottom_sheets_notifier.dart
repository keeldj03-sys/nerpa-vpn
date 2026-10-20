import 'package:flutter/material.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/model/constants.dart';
import 'package:nerpa_vpn/core/router/bottom_sheets/widgets/auto_apps_selection_modal.dart';
import 'package:nerpa_vpn/core/router/bottom_sheets/widgets/quick_settings_modal.dart';
import 'package:nerpa_vpn/core/router/dialog/dialog_notifier.dart';
import 'package:nerpa_vpn/core/router/go_router/go_router_notifier.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:nerpa_vpn/features/presets/widget/presets_modal.dart';
import 'package:nerpa_vpn/features/profile/add/add_profile_modal.dart';
import 'package:nerpa_vpn/features/profile/overview/profiles_modal.dart';
import 'package:nerpa_vpn/features/route_rules/overview/predefined_rules_modal.dart';
import 'package:nerpa_vpn/utils/platform_utils.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bottom_sheets_notifier.g.dart';

@riverpod
class BottomSheetsNotifier extends _$BottomSheetsNotifier {
  @override
  void build() {}

  Future<T?> _show<T>({required Widget child, required bool isScrollControlled}) async {
    final context = rootNavKey.currentContext;
    if (context == null) return null;
    // ref.read(popupCountNotifierProvider.notifier).increase();
    return await Navigator.of(context)
        .push<T>(
          ModalBottomSheetRoute(
            constraints: BottomSheetConst.boxConstraints,
            isScrollControlled: isScrollControlled,
            builder: (context) => ClipRRect(
              borderRadius: BottomSheetConst.borderRadius,
              child: Material(
                child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: child,
                ),
              ),
            ),
          ),
        )
        .then((value) {
          // ref.read(popupCountNotifierProvider.notifier).decrease();
          return value;
        });
  }

  Future<void> showAddProfile({String? url, bool triggeredByDeepLink = false}) async {
    Future<void> open() async {
      if (PlatformUtils.isDesktop) {
        final context = rootNavKey.currentContext;
        if (context == null) return;
        await Navigator.of(context).push<void>(_AddProfileSideRoute(url: url));
      } else {
        await _show(isScrollControlled: true, child: AddProfileModal(url: url));
      }
    }

    if (url != null && triggeredByDeepLink) {
      // Preventing Zero-click SSRF
      final t = ref.watch(translationsProvider).requireValue;
      final isConfirmed = await ref
          .read(dialogNotifierProvider.notifier)
          .showConfirmation(
            title: t.dialogs.confirmation.addProfileByDeepLinkWarning.title,
            message: t.dialogs.confirmation.addProfileByDeepLinkWarning.message(host: Uri.parse(url).host),
          );
      if (isConfirmed) await open();
    } else {
      await open();
    }
  }

  Future<void> showProfilesOverview() async => await _show(isScrollControlled: true, child: const ProfilesModal());

  Future<void> showQuickSettings() async => await _show(isScrollControlled: false, child: const QuickSettingsModal());

  Future<void> showAutoAppsSelection({required AppProxyMode mode}) async =>
      await _show(isScrollControlled: false, child: AutoAppsSelectionModal(mode: mode));

  Future<void> showPredefinedRules() async =>
      await _show(isScrollControlled: true, child: const PredefinedRulesModal());

  Future<void> showPresets() async => await _show(isScrollControlled: true, child: const PresetsModal());
}

class _AddProfileSideRoute extends PageRoute<void> {
  _AddProfileSideRoute({this.url});

  final String? url;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => Colors.black.withOpacity(0.58);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Закрыть добавление подключения';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  bool get opaque => false;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return Align(
      alignment: Alignment.centerRight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(420.0, 520.0);
          return SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: Material(
              color: AppTheme.nerpaSurface,
              elevation: 24,
              shadowColor: Colors.black.withOpacity(0.5),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(left: Radius.circular(28))),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  AddProfileModal(url: url),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      key: const ValueKey('add_profile_close_button'),
                      tooltip: 'Закрыть',
                      icon: const Icon(Icons.close_rounded),
                      color: AppTheme.nerpaTextSecondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final offset = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
    return SlideTransition(position: offset, child: child);
  }
}
