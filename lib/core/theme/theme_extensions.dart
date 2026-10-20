import 'package:flutter/material.dart';

class ConnectionButtonTheme extends ThemeExtension<ConnectionButtonTheme> {
  const ConnectionButtonTheme({this.idleColor, this.connectedColor});

  final Color? idleColor;
  final Color? connectedColor;

  // Nerpa VPN — Cyan accent theme
  static const ConnectionButtonTheme nerpa = ConnectionButtonTheme(
    idleColor:      Color(0xFF27272A), // zinc-800 — idle state
    connectedColor: Color(0xFF06B6D4), // cyan-500 — connected state
  );

  // Legacy light (kept for compatibility)
  static const ConnectionButtonTheme light = nerpa;

  @override
  ThemeExtension<ConnectionButtonTheme> copyWith({Color? idleColor, Color? connectedColor}) =>
      ConnectionButtonTheme(
        idleColor:      idleColor      ?? this.idleColor,
        connectedColor: connectedColor ?? this.connectedColor,
      );

  @override
  ThemeExtension<ConnectionButtonTheme> lerp(
    covariant ThemeExtension<ConnectionButtonTheme>? other,
    double t,
  ) {
    if (other is! ConnectionButtonTheme) return this;
    return ConnectionButtonTheme(
      idleColor:      Color.lerp(idleColor,      other.idleColor,      t),
      connectedColor: Color.lerp(connectedColor, other.connectedColor, t),
    );
  }
}
