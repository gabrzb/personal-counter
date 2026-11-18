import 'package:flutter/material.dart';

bool isIOS(BuildContext context) =>
    Theme.of(context).platform == TargetPlatform.iOS;
bool isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;
Duration motion(BuildContext context, [int milliseconds = 280]) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: milliseconds);

ThemeData metasTheme(Brightness brightness, {TargetPlatform? platform}) {
  final dark = brightness == Brightness.dark;
  final ios = platform == TargetPlatform.iOS;
  final accent = Color(dark ? 0xFFFDA4B2 : 0xFFC92A3E);
  final ink = Color(dark ? 0xFFF2F3F7 : 0xFF1F2937);
  final surface = Color(
    dark ? (ios ? 0xFF000000 : 0xFF111318) : (ios ? 0xFFF2F2F7 : 0xFFFFFFFF),
  );
  final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness)
      .copyWith(
        primary: accent,
        onPrimary: Color(dark ? 0xFF4B0D1B : 0xFFFFFFFF),
        surface: surface,
        onSurface: ink,
        onSurfaceVariant: Color(dark ? 0xFFBFC3CE : 0xFF626773),
        primaryContainer: Color(dark ? 0xFF44232B : 0xFFFEE2E2),
        onPrimaryContainer: accent,
        outlineVariant: Color(dark ? 0xFF41434C : 0xFFE4E7EC),
        error: accent,
      );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(ios ? 24 : 8),
  );
  return ThemeData(
    useMaterial3: true,
    platform: platform,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: surface,
    fontFamily: ios ? '.SF Pro Text' : 'Roboto',
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: !ios,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 54),
        shape: shape,
        textStyle: TextStyle(
          fontFamily: ios ? '.SF Pro Text' : 'Roboto',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(48, 54),
        shape: shape,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ios
          ? (dark ? const Color(0xFF1C1C1E) : Colors.white)
          : surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ios ? 13 : 6),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ios ? 13 : 6),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      contentTextStyle: TextStyle(
        color: surface,
        fontFamily: ios ? '.SF Pro Text' : 'Roboto',
        fontSize: 14,
      ),
      actionTextColor: scheme.primaryContainer,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}
