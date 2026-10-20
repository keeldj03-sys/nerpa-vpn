import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nerpa_vpn/core/theme/app_theme_mode.dart';
import 'package:nerpa_vpn/core/theme/theme_extensions.dart';

/// Nerpa VPN — Design System
/// Primary: Dark #0A0E1A + Cyan #06B6D4 accent
class AppTheme {
  AppTheme(this.mode, this.fontFamily);
  final AppThemeMode mode;
  final String fontFamily;

  // ─── Nerpa VPN Color Palette ───
  static const Color nerpaBackground    = Color(0xFF0A0E1A);
  static const Color nerpaSurface       = Color(0xFF0C0C0E);
  static const Color nerpaCard          = Color(0xFF121215);
  static const Color nerpaAccent        = Color(0xFF06B6D4); // cyan-500
  static const Color nerpaAccentBlue    = Color(0xFF3B82F6); // blue-500
  static const Color nerpaAccentPurple  = Color(0xFF8B5CF6); // violet-500
  static const Color nerpaSuccess       = Color(0xFF34D399); // emerald-400
  static const Color nerpaWarning       = Color(0xFFFBBF24); // amber-400
  static const Color nerpaError         = Color(0xFFF87171); // red-400
  static const Color nerpaBorder        = Color(0xFF3F3F46); // zinc-700
  static const Color nerpaTextPrimary   = Color(0xFFF4F4F5); // zinc-100
  static const Color nerpaTextSecondary = Color(0xFFA1A1AA); // zinc-400
  static const Color nerpaTextMuted     = Color(0xFF52525B); // zinc-600

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary:          nerpaAccent,
    onPrimary:        Colors.white,
    primaryContainer: Color(0xFF083344),
    onPrimaryContainer: nerpaAccent,
    secondary:        nerpaAccentBlue,
    onSecondary:      Colors.white,
    secondaryContainer: Color(0xFF1E3A5F),
    onSecondaryContainer: nerpaAccentBlue,
    tertiary:         nerpaAccentPurple,
    onTertiary:       Colors.white,
    tertiaryContainer: Color(0xFF2E1065),
    onTertiaryContainer: nerpaAccentPurple,
    error:            nerpaError,
    onError:          Colors.white,
    errorContainer:   Color(0xFF450A0A),
    onErrorContainer: nerpaError,
    surface:          nerpaSurface,
    onSurface:        nerpaTextPrimary,
    surfaceContainerHighest: nerpaCard,
    onSurfaceVariant: nerpaTextSecondary,
    outline:          nerpaBorder,
    outlineVariant:   Color(0xFF27272A),
    shadow:           Colors.black,
    scrim:            Colors.black,
    inverseSurface:   nerpaTextPrimary,
    onInverseSurface: nerpaSurface,
    inversePrimary:   Color(0xFF083344),
  );

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary:          Color(0xFF0E7490),
    onPrimary:        Colors.white,
    primaryContainer: Color(0xFFCFFAFE),
    onPrimaryContainer: Color(0xFF083344),
    secondary:        Color(0xFF1D4ED8),
    onSecondary:      Colors.white,
    secondaryContainer: Color(0xFFDBEAFE),
    onSecondaryContainer: Color(0xFF1E3A5F),
    tertiary:         Color(0xFF7C3AED),
    onTertiary:       Colors.white,
    tertiaryContainer: Color(0xFFEDE9FE),
    onTertiaryContainer: Color(0xFF2E1065),
    error:            Color(0xFFDC2626),
    onError:          Colors.white,
    errorContainer:   Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF450A0A),
    surface:          Color(0xFFF8FAFC),
    onSurface:        Color(0xFF0F172A),
    surfaceContainerHighest: Color(0xFFE2E8F0),
    onSurfaceVariant: Color(0xFF475569),
    outline:          Color(0xFFCBD5E1),
    outlineVariant:   Color(0xFFE2E8F0),
    shadow:           Colors.black,
    scrim:            Colors.black,
    inverseSurface:   Color(0xFF1E293B),
    onInverseSurface: Color(0xFFF1F5F9),
    inversePrimary:   nerpaAccent,
  );

  ThemeData lightTheme(ColorScheme? dynamicScheme) {
    final scheme = dynamicScheme ?? _lightScheme;
    return _buildTheme(scheme);
  }

  ThemeData darkTheme(ColorScheme? dynamicScheme) {
    final scheme = dynamicScheme ?? _darkScheme;
    return _buildTheme(scheme).copyWith(
      scaffoldBackgroundColor: mode.trueBlack ? Colors.black : nerpaBackground,
    );
  }

  ThemeData _buildTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: isDark ? nerpaBackground : scheme.surface,
      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? nerpaSurface : scheme.surface,
        foregroundColor: isDark ? nerpaTextPrimary : scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      // ─── Cards ───
      cardTheme: CardThemeData(
        color: isDark ? nerpaCard : scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? nerpaBorder.withOpacity(0.4) : scheme.outlineVariant),
        ),
      ),
      // ─── List Tiles ───
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      // ─── Input / TextField ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF18181B) : scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? nerpaBorder : scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? nerpaBorder.withOpacity(0.5) : scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: nerpaAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      // ─── Buttons ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: nerpaAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: nerpaAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: nerpaAccent,
          side: const BorderSide(color: nerpaAccent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: nerpaAccent),
      ),
      // ─── Switch ───
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? Colors.white : nerpaTextMuted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? nerpaAccent : const Color(0xFF27272A)),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      // ─── Divider ───
      dividerTheme: DividerThemeData(
        color: isDark ? nerpaBorder.withOpacity(0.3) : scheme.outlineVariant,
        thickness: 1,
        space: 0,
      ),
      // ─── Navigation Rail ─── (used for sidebar)
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? const Color(0xFF09090B) : scheme.surface,
        selectedIconTheme: const IconThemeData(color: nerpaAccent),
        unselectedIconTheme: IconThemeData(color: nerpaTextMuted),
        indicatorColor: nerpaAccent.withOpacity(0.12),
        labelType: NavigationRailLabelType.none,
      ),
      // ─── Chip ───
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF18181B) : scheme.surfaceContainerHighest,
        selectedColor: nerpaAccent.withOpacity(0.15),
        side: BorderSide(color: isDark ? nerpaBorder.withOpacity(0.4) : scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: TextStyle(color: isDark ? nerpaTextSecondary : scheme.onSurface, fontSize: 13),
      ),
      // ─── SnackBar ───
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF27272A) : scheme.inverseSurface,
        contentTextStyle: TextStyle(color: isDark ? nerpaTextPrimary : scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      // ─── Dialog ───
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF111113) : scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: isDark ? nerpaTextPrimary : scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
      ),
      // ─── Tooltip ───
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF27272A) : scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          color: isDark ? nerpaTextPrimary : scheme.onInverseSurface,
          fontSize: 12,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>{
        ConnectionButtonTheme.nerpa,
      },
    );
  }

  CupertinoThemeData cupertinoThemeData(bool sysDark, ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
    final bool isDark = switch (mode) {
      AppThemeMode.system => sysDark,
      AppThemeMode.light  => false,
      AppThemeMode.dark   => true,
      AppThemeMode.black  => true,
    };
    final def = CupertinoThemeData(brightness: isDark ? Brightness.dark : Brightness.light);
    final defaultMaterialTheme = isDark ? darkTheme(darkColorScheme) : lightTheme(lightColorScheme);
    return MaterialBasedCupertinoThemeData(
      materialTheme: defaultMaterialTheme.copyWith(
        cupertinoOverrideTheme: def.copyWith(
          textTheme: CupertinoTextThemeData(
            textStyle:              def.textTheme.textStyle.copyWith(fontFamily: fontFamily),
            actionTextStyle:        def.textTheme.actionTextStyle.copyWith(fontFamily: fontFamily),
            navActionTextStyle:     def.textTheme.navActionTextStyle.copyWith(fontFamily: fontFamily),
            navTitleTextStyle:      def.textTheme.navTitleTextStyle.copyWith(fontFamily: fontFamily),
            navLargeTitleTextStyle: def.textTheme.navLargeTitleTextStyle.copyWith(fontFamily: fontFamily),
            pickerTextStyle:        def.textTheme.pickerTextStyle.copyWith(fontFamily: fontFamily),
            dateTimePickerTextStyle: def.textTheme.dateTimePickerTextStyle.copyWith(fontFamily: fontFamily),
            tabLabelTextStyle:      def.textTheme.tabLabelTextStyle.copyWith(fontFamily: fontFamily),
          ).copyWith(),
          barBackgroundColor:      def.barBackgroundColor,
          scaffoldBackgroundColor: def.scaffoldBackgroundColor,
        ),
      ),
    );
  }
}
