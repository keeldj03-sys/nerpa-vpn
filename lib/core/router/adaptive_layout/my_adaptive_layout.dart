import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/model/constants.dart';
import 'package:nerpa_vpn/core/router/adaptive_layout/shell_route_action.dart';
import 'package:nerpa_vpn/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:nerpa_vpn/core/router/go_router/routing_config_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/features/stats/widget/side_bar_stats_overview.dart';

class MyAdaptiveLayout extends HookConsumerWidget {
  const MyAdaptiveLayout({
    super.key,
    required this.navigationShell,
    required this.isMobileBreakpoint,
    required this.showProfilesAction,
  });

  final StatefulNavigationShell navigationShell;
  final bool isMobileBreakpoint;
  final bool showProfilesAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final primaryFocusHash = useState<int?>(null);
    final navScopeNode = useFocusScopeNode();

    useEffect(() {
      bool handler(KeyEvent event) {
        final arrows = isMobileBreakpoint ? KeyboardConst.verticalArrows : KeyboardConst.horizontalArrows;
        if (!arrows.contains(event.logicalKey)) return false;
        if (event is KeyDownEvent) {
          primaryFocusHash.value = FocusManager.instance.primaryFocus.hashCode;
        } else {
          if (primaryFocusHash.value == FocusManager.instance.primaryFocus.hashCode) {
            if (branchesScope.values.any((node) => node.hasFocus)) {
              navScopeNode.requestFocus();
            } else if (navScopeNode.hasFocus) {
              branchesScope[getNameOfBranch(isMobileBreakpoint, showProfilesAction, navigationShell.currentIndex)]
                  ?.requestFocus();
            }
          }
        }
        return true;
      }

      HardwareKeyboard.instance.addHandler(handler);
      return () => HardwareKeyboard.instance.removeHandler(handler);
    }, [isMobileBreakpoint, showProfilesAction, navigationShell.currentIndex]);

    final actions = _actions(t, showProfilesAction, isMobileBreakpoint);

    return Material(
      color: AppTheme.nerpaBackground,
      child: Scaffold(
        backgroundColor: AppTheme.nerpaBackground,
        body: isMobileBreakpoint
            ? navigationShell
            : Row(
                children: [
                  // ── Nerpa VPN Sidebar ──
                  FocusScope(
                    node: navScopeNode,
                    child: _NerpaSidebar(
                      actions: actions,
                      selectedIndex: navigationShell.currentIndex,
                      // The reference uses an icon-first 76 px desktop rail.
                      // Keep labels available through tooltips instead of widening it.
                      isExtended: false,
                      onTap: (i) => _onTap(context, i),
                    ),
                  ),
                  // ── Main content ──
                  Expanded(child: navigationShell),
                ],
              ),
        bottomNavigationBar: isMobileBreakpoint
            ? FocusScope(
                node: navScopeNode,
                child: _NerpaBottomNav(
                  actions: actions,
                  selectedIndex: navigationShell.currentIndex <= 1 ? navigationShell.currentIndex : 0,
                  onTap: (i) => _onTap(context, i),
                ),
              )
            : null,
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  List<ShellRouteAction> _actions(Translations t, bool showProfilesAction, bool isMobileBreakpoint) => [
    ShellRouteAction(Icons.power_settings_new_rounded, t.pages.home.title),
    if (showProfilesAction && !isMobileBreakpoint) ShellRouteAction(Icons.view_list_rounded, t.pages.profiles.title),
    ShellRouteAction(Icons.settings_rounded, t.pages.settings.title),
    if (!isMobileBreakpoint) ShellRouteAction(Icons.description_rounded, t.pages.logs.title),
    if (!isMobileBreakpoint) ShellRouteAction(Icons.info_rounded, t.pages.about.title),
  ];
}

// ─────────────────────────────────────────
// Nerpa VPN Sidebar (Desktop Navigation Rail)
// ─────────────────────────────────────────
class _NerpaSidebar extends StatelessWidget {
  const _NerpaSidebar({
    required this.actions,
    required this.selectedIndex,
    required this.isExtended,
    required this.onTap,
  });

  final List<ShellRouteAction> actions;
  final int selectedIndex;
  final bool isExtended;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = isExtended ? 200.0 : 76.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF09090B),
        border: Border(right: BorderSide(color: AppTheme.nerpaBorder.withOpacity(0.3), width: 1)),
      ),
      child: Column(
        children: [
          // ── Logo area ──
          Container(
            height: 76,
            padding: EdgeInsets.symmetric(horizontal: isExtended ? 16 : 0),
            child: isExtended
                ? Row(
                    children: [
                      _LogoIcon(),
                      const SizedBox(width: 10),
                      const Text(
                        'Nerpa VPN',
                        style: TextStyle(
                          color: AppTheme.nerpaTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  )
                : Center(child: _LogoIcon()),
          ),

          Divider(height: 1, color: AppTheme.nerpaBorder.withOpacity(0.3)),
          const SizedBox(height: 8),

          // ── Nav items ──
          ...actions.asMap().entries.map((entry) {
            final i = entry.key;
            final action = entry.value;
            final isSelected = selectedIndex == i;
            return _SidebarItem(
              icon: action.icon,
              label: action.title,
              isSelected: isSelected,
              isExtended: isExtended,
              onTap: () => onTap(i),
            );
          }),

          const Spacer(),

          // ── Stats at bottom ──
          if (isExtended) ...[
            Divider(height: 1, color: AppTheme.nerpaBorder.withOpacity(0.3)),
            const SizedBox(width: 220, child: SideBarStatsOverview()),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LogoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset('assets/images/app_icon.png', width: 32, height: 32, fit: BoxFit.cover),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExtended,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExtended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isExtended ? 10 : 10, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 42,
          padding: EdgeInsets.symmetric(horizontal: isExtended ? 12 : 0),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.nerpaAccent.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: isExtended
              ? Row(
                  children: [
                    Icon(icon, size: 20, color: isSelected ? AppTheme.nerpaAccent : AppTheme.nerpaTextMuted),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? AppTheme.nerpaAccent : AppTheme.nerpaTextSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Tooltip(
                    message: label,
                    child: Icon(icon, size: 20, color: isSelected ? AppTheme.nerpaAccent : AppTheme.nerpaTextMuted),
                  ),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Nerpa VPN Bottom Navigation Bar (Mobile)
// ─────────────────────────────────────────
class _NerpaBottomNav extends StatelessWidget {
  const _NerpaBottomNav({required this.actions, required this.selectedIndex, required this.onTap});

  final List<ShellRouteAction> actions;
  final int selectedIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF09090B),
        border: Border(top: BorderSide(color: AppTheme.nerpaBorder.withOpacity(0.3), width: 1)),
      ),
      child: Row(
        children: actions.asMap().entries.map((entry) {
          final i = entry.key;
          final action = entry.value;
          final isSelected = selectedIndex == i;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(i),
              child: Container(
                height: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action.icon, size: 22, color: isSelected ? AppTheme.nerpaAccent : AppTheme.nerpaTextMuted),
                    const SizedBox(height: 3),
                    Text(
                      action.title,
                      style: TextStyle(
                        color: isSelected ? AppTheme.nerpaAccent : AppTheme.nerpaTextMuted,
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(color: AppTheme.nerpaAccent, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
