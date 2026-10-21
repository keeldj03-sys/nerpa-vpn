import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/model/constants.dart';
import 'package:nerpa_vpn/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:nerpa_vpn/core/router/dialog/dialog_notifier.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/features/connection/model/connection_status.dart';
import 'package:nerpa_vpn/features/connection/notifier/connection_notifier.dart';
import 'package:nerpa_vpn/features/profile/notifier/active_profile_notifier.dart';
import 'package:nerpa_vpn/features/proxy/active/active_proxy_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// What the button shows, one value per look.
enum _Look { loading, disconnected, connecting, connected, noPing, hotReloading, disconnecting, failed }

/// The core reports the tunnel as up before the first ping answers, so a tunnel
/// with no ping yet still looks like connecting: the user waits once, not twice.
/// A delay of 0 is a ping not measured yet; any other invalid delay timed out.
///
/// The status reloads after every core start; until the new stream answers,
/// the last status holds. A failed start comes back as disconnected with the
/// failure attached.
///
/// A hot reload keeps the tunnel up, and the status stays connected through it.
/// It comes before the ping checks, so a reload never looks like a ping problem.
_Look _lookOf(AsyncValue<ConnectionStatus> status, int delay, bool hotReloading) => switch (status) {
  AsyncError() => _Look.failed,
  AsyncValue(valueOrNull: Disconnected(connectionFailure: _?)) => _Look.failed,
  AsyncValue(valueOrNull: Disconnected()) => _Look.disconnected,
  AsyncValue(valueOrNull: Connecting()) => _Look.connecting,
  AsyncValue(valueOrNull: Connected()) when hotReloading => _Look.hotReloading,
  AsyncValue(valueOrNull: Connected()) when delay == 0 => _Look.connecting,
  AsyncValue(valueOrNull: Connected()) when !ConnectionConst.isValidDelay(delay) => _Look.noPing,
  AsyncValue(valueOrNull: Connected()) => _Look.connected,
  AsyncValue(valueOrNull: Disconnecting()) => _Look.disconnecting,
  _ => _Look.loading,
};

class ConnectionButton extends HookConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final status = ref.watch(connectionNotifierProvider);
    // After a disconnect Riverpod keeps the last ping as the previous value,
    // which would show the next connection as up before its own ping answers.
    final delay = ref.watch(activeProxyNotifierProvider).unwrapPrevious().valueOrNull?.urlTestDelay ?? 0;
    final hotReloading = ref.watch(hotReloadingProvider).valueOrNull ?? false;
    final look = _lookOf(status, delay, hotReloading);

    // What a tap does follows the core alone: a tunnel that is up can be
    // turned off even while it still looks like connecting. The core is busy
    // while it hot reloads, so the tap is off until that ends.
    final onTap = switch (status) {
      AsyncData(value: Connected()) when hotReloading => null,
      AsyncData(value: Disconnected()) || AsyncError() => () => _connect(ref),
      AsyncData(value: Connected()) => () => ref.read(connectionNotifierProvider.notifier).toggleConnection(),
      _ => null,
    };

    return _NerpaPowerButton(
      look: look,
      onTap: onTap,
      label: switch (look) {
        _Look.loading => "",
        _Look.disconnected => t.connection.tapToConnect,
        _Look.connecting => t.connection.connecting,
        _Look.connected || _Look.noPing => t.connection.connected,
        _Look.hotReloading => t.connection.hotReloading,
        _Look.disconnecting => t.connection.disconnecting,
        _Look.failed => t.connection.failed,
      },
      hint: look == _Look.failed ? t.connection.tapToRetry : null,
    );
  }

  /// Connects, or sends the user to add a profile when there is none.
  Future<void> _connect(WidgetRef ref) async {
    final dialogs = ref.read(dialogNotifierProvider.notifier);
    if (ref.read(activeProfileProvider).valueOrNull == null) {
      await dialogs.showNoActiveProfile();
      ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile();
      return;
    }
    if (await dialogs.showExperimentalFeatureNotice()) {
      await ref.read(connectionNotifierProvider.notifier).toggleConnection();
    }
  }
}

/// Nerpa VPN — the power button.
///
/// A dark circle that glows cyan while the tunnel is up and throws a ripple
/// while it is connecting. The look is a state, so the button reports the
/// same states the core does.
class _NerpaPowerButton extends StatefulWidget {
  const _NerpaPowerButton({required this.look, required this.onTap, required this.label, this.hint});

  final _Look look;
  final VoidCallback? onTap;
  final String label;
  final String? hint;

  @override
  State<_NerpaPowerButton> createState() => _NerpaPowerButtonState();
}

class _NerpaPowerButtonState extends State<_NerpaPowerButton> with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _rippleController;

  bool get _isConnected => widget.look == _Look.connected || widget.look == _Look.noPing;
  bool get _isBusy => widget.look == _Look.connecting || widget.look == _Look.disconnecting;

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
    final wasBusy = oldWidget.look == _Look.connecting || oldWidget.look == _Look.disconnecting;
    if (_isBusy && !wasBusy) {
      _rippleController.repeat();
    } else if (!_isBusy && wasBusy) {
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

    final connected = _isConnected;
    final failed = widget.look == _Look.failed;

    final buttonColor = failed
        ? Colors.red.withValues(alpha: 0.40)
        : connected
            ? cyan.withValues(alpha: 0.40)
            : zinc800.withValues(alpha: 0.46);
    final iconColor = Colors.white.withValues(alpha: connected ? 1 : 0.98);
    final borderColor = failed
        ? Colors.red.withValues(alpha: 0.90)
        : connected
            ? cyan.withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.28);
    final innerRingColor = connected ? cyan.withValues(alpha: 0.34) : Colors.white.withValues(alpha: 0.20);
    final innerCoreColor = connected ? cyan.withValues(alpha: 0.30) : Colors.white.withValues(alpha: 0.14);
    final highlightColor = connected ? cyan.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.22);
    final shadowColor = connected ? cyan.withValues(alpha: 0.22) : Colors.black.withValues(alpha: 0.30);

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
              if (connected)
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
                enabled: widget.onTap != null,
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
                        blurRadius: connected ? 46 : 30,
                        spreadRadius: connected ? -10 : -5,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: connected ? 0.10 : 0.18),
                        blurRadius: 28,
                        spreadRadius: -14,
                        offset: const Offset(0, 14),
                      ),
                      if (connected) ...[
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
                        buttonColor.withValues(alpha: connected ? 0.30 : 0.28),
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
                          color: Colors.white.withValues(alpha: connected ? 0.14 : 0.09),
                          blurRadius: 18,
                          spreadRadius: -8,
                          offset: const Offset(0, -2),
                        ),
                        BoxShadow(
                          color: cyan.withValues(alpha: connected ? 0.22 : 0.11),
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
                        onTap: widget.onTap,
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
                                      Colors.white.withValues(alpha: connected ? 0.28 : 0.20),
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
                                      Colors.white.withValues(alpha: connected ? 0.14 : 0.09),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.58, 1.0],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: connected ? 0.20 : 0.14),
                                    width: 0.9,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cyan.withValues(alpha: connected ? 0.30 : 0.12),
                                      blurRadius: connected ? 34 : 22,
                                      spreadRadius: -14,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _PowerIcon(connected: connected, failed: failed, color: iconColor),
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
              color: failed
                  ? Colors.red
                  : connected
                      ? AppTheme.nerpaAccent
                      : AppTheme.nerpaTextSecondary,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (widget.hint != null) ...[
          const Gap(4),
          Text(
            widget.hint!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// The power glyph. It turns into a spinner while the core is busy, so the
/// button always shows what the core is doing.
class _PowerIcon extends StatelessWidget {
  const _PowerIcon({required this.connected, required this.failed, required this.color});

  final bool connected;
  final bool failed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Icon(
        failed ? Icons.error_outline_rounded : Icons.power_settings_new_rounded,
        key: ValueKey('$connected-$failed'),
        size: 68,
        color: color,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: connected ? 0.24 : 0.30),
            blurRadius: 20,
          ),
          Shadow(
            color: AppTheme.nerpaAccent.withValues(alpha: connected ? 0.28 : 0.12),
            blurRadius: 24,
          ),
        ],
      ),
    );
  }
}
