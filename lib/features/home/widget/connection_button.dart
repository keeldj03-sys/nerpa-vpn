import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:nerpa_vpn/core/router/dialog/dialog_notifier.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/features/connection/model/connection_status.dart';
import 'package:nerpa_vpn/features/connection/notifier/connection_notifier.dart';
import 'package:nerpa_vpn/features/profile/notifier/active_profile_notifier.dart';
import 'package:nerpa_vpn/features/proxy/active/active_proxy_notifier.dart';
import 'package:nerpa_vpn/features/settings/notifier/config_option/config_option_notifier.dart';

/// Nerpa VPN — Power Connection Button
/// Dark circular button with cyan glow when connected, ripple animation when connecting
class ConnectionButton extends HookConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final delay = activeProxy.valueOrNull?.urlTestDelay ?? 0;
    final requiresReconnect = ref.watch(configOptionNotifierProvider).valueOrNull;

    final isConnected =
        connectionStatus.valueOrNull is Connected && !(requiresReconnect == true) && !(delay <= 0 || delay >= 65000);
    final isConnecting =
        connectionStatus.valueOrNull is Connecting ||
        (connectionStatus.valueOrNull is Connected && (delay <= 0 || delay >= 65000));

    final label = switch (connectionStatus) {
      AsyncData(value: Connected()) when requiresReconnect == true => t.connection.reconnect,
      AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => t.connection.connecting,
      AsyncData(value: final status) => status.present(t),
      _ => '',
    };

    return _NerpaPowerButton(
      isConnected: isConnected,
      isConnecting: isConnecting,
      label: label,
      onTap: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => () async {
          final activeProfile = await ref.read(activeProfileProvider.future);
          return ref.read(connectionNotifierProvider.notifier).reconnect(activeProfile);
        },
        AsyncData(value: Disconnected()) || AsyncError() => () async {
          if (ref.read(activeProfileProvider).valueOrNull == null) {
            await ref.read(dialogNotifierProvider.notifier).showNoActiveProfile();
            ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile();
            return;
          }
          if (await ref.read(dialogNotifierProvider.notifier).showExperimentalFeatureNotice()) {
            return ref.read(connectionNotifierProvider.notifier).toggleConnection();
          }
        },
        AsyncData(value: Connected()) => () async {
          if (requiresReconnect == true &&
              await ref.read(dialogNotifierProvider.notifier).showExperimentalFeatureNotice()) {
            return ref
                .read(connectionNotifierProvider.notifier)
                .reconnect(await ref.read(activeProfileProvider.future));
          }
          return ref.read(connectionNotifierProvider.notifier).toggleConnection();
        },
        _ => () {},
      },
      enabled: switch (connectionStatus) {
        AsyncData(value: Connected()) || AsyncData(value: Disconnected()) || AsyncError() => true,
        _ => false,
      },
    );
  }
}

class _NerpaPowerButton extends StatefulWidget {
  const _NerpaPowerButton({
    required this.isConnected,
    required this.isConnecting,
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  final bool isConnected;
  final bool isConnecting;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_NerpaPowerButton> createState() => _NerpaPowerButtonState();
}

class _NerpaPowerButtonState extends State<_NerpaPowerButton> with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);

    _rippleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  }

  @override
  void didUpdateWidget(_NerpaPowerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnecting && !oldWidget.isConnecting) {
      _rippleController.repeat();
    } else if (!widget.isConnecting && oldWidget.isConnecting) {
      _rippleController.stop();
      _rippleController.reset();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cyan = AppTheme.nerpaAccent;
    const zinc800 = Color(0xFF27272A);

    final buttonColor = widget.isConnected ? cyan.withValues(alpha: 0.40) : zinc800.withValues(alpha: 0.46);
    final iconColor = Colors.white.withValues(alpha: widget.isConnected ? 1 : 0.98);
    final borderColor = widget.isConnected ? cyan.withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.28);
    final innerRingColor = widget.isConnected ? cyan.withValues(alpha: 0.34) : Colors.white.withValues(alpha: 0.20);
    final innerCoreColor = widget.isConnected ? cyan.withValues(alpha: 0.30) : Colors.white.withValues(alpha: 0.14);
    final highlightColor = widget.isConnected ? cyan.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.22);
    final shadowColor = widget.isConnected ? cyan.withValues(alpha: 0.22) : Colors.black.withValues(alpha: 0.30);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Ripple + Button Stack ──
        SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient background glow (when connected)
              if (widget.isConnected)
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (_, _) => Container(
                    width: 220 + 24 * _glowController.value,
                    height: 220 + 24 * _glowController.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cyan.withValues(alpha: 0.14 + 0.06 * _glowController.value),
                          blurRadius: 64 + 18 * _glowController.value,
                          spreadRadius: -8,
                        ),
                      ],
                    ),
                  ),
                ),

              // Ripple ring 1
              AnimatedBuilder(
                animation: _rippleController,
                builder: (_, _) {
                  final v = _rippleController.value;
                  if (v == 0.0) return const SizedBox.shrink();
                  return Opacity(
                    opacity: (1 - v).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 1.0 + 0.4 * v,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: cyan.withValues(alpha: 0.7), width: 1.5),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Ripple ring 2 (offset by 0.5)
              AnimatedBuilder(
                animation: _rippleController,
                builder: (_, _) {
                  final v = (_rippleController.value + 0.5) % 1.0;
                  if (v == 0.0) return const SizedBox.shrink();
                  return Opacity(
                    opacity: (1 - v).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 1.0 + 0.4 * v,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: cyan.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Main button
              Semantics(
                button: true,
                enabled: widget.enabled,
                label: widget.label,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: buttonColor,
                    border: Border.all(color: borderColor, width: 1.6),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: widget.isConnected ? 46 : 30,
                        spreadRadius: widget.isConnected ? -10 : -5,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: widget.isConnected ? 0.10 : 0.18),
                        blurRadius: 28,
                        spreadRadius: -14,
                        offset: const Offset(0, 14),
                      ),
                      if (widget.isConnected) ...[
                        BoxShadow(color: cyan.withValues(alpha: 0.30), blurRadius: 58, spreadRadius: -14),
                        BoxShadow(color: cyan.withValues(alpha: 0.16), blurRadius: 104, spreadRadius: -30),
                      ],
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        highlightColor,
                        buttonColor,
                        buttonColor.withValues(alpha: widget.isConnected ? 0.30 : 0.28),
                      ],
                      stops: const [0.0, 0.40, 1.0],
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: innerRingColor, width: 1.1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: widget.isConnected ? 0.14 : 0.09),
                          blurRadius: 18,
                          spreadRadius: -8,
                          offset: const Offset(0, -2),
                        ),
                        BoxShadow(
                          color: cyan.withValues(alpha: widget.isConnected ? 0.22 : 0.11),
                          blurRadius: 26,
                          spreadRadius: -16,
                        ),
                      ],
                    ),
                    child: Material(
                      key: const ValueKey('home_connection_button'),
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: widget.enabled ? widget.onTap : null,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Align(
                              alignment: const Alignment(-0.25, -0.28),
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: widget.isConnected ? 0.28 : 0.20),
                                      Colors.white.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                width: 124,
                                height: 124,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      innerCoreColor,
                                      Colors.white.withValues(alpha: widget.isConnected ? 0.14 : 0.09),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.58, 1.0],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: widget.isConnected ? 0.20 : 0.14),
                                    width: 0.9,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cyan.withValues(alpha: widget.isConnected ? 0.30 : 0.12),
                                      blurRadius: widget.isConnected ? 34 : 22,
                                      spreadRadius: -14,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      Icons.power_settings_new_rounded,
                                      key: ValueKey(widget.isConnected),
                                      size: 68,
                                      color: iconColor,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: widget.isConnected ? 0.24 : 0.30),
                                          blurRadius: 20,
                                        ),
                                        Shadow(
                                          color: cyan.withValues(alpha: widget.isConnected ? 0.28 : 0.12),
                                          blurRadius: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Gap(12),

        // ── Status label ──
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            widget.label,
            key: ValueKey(widget.label),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: widget.isConnected ? AppTheme.nerpaAccent : AppTheme.nerpaTextSecondary,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
