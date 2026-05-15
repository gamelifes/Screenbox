import 'package:flutter/material.dart';

/// 应用主题管理类
class AppTheme {
  AppTheme._();

  // ============================================
  // ColorSchemes
  // ============================================

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0061A4),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFD1E4FF),
    onPrimaryContainer: Color(0xFF001D36),
    secondary: Color(0xFF535F70),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD7E3F7),
    onSecondaryContainer: Color(0xFF101C2B),
    tertiary: Color(0xFF6B5778),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFF2DAFF),
    onTertiaryContainer: Color(0xFF251431),
    error: Color(0xFFBA1A1A),
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: Color(0xFFFDFCFF),
    onBackground: Color(0xFF001A37),
    surface: Color(0xFFFDFCFF),
    onSurface: Color(0xFF001A37),
    surfaceVariant: Color(0xFFDFE4EB),
    onSurfaceVariant: Color(0xFF43474E),
    outline: Color(0xFF73777F),
    outlineVariant: Color(0xFFC3C7CF),
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF9ECAFF),
    onPrimary: Color(0xFF003258),
    primaryContainer: Color(0xFF004A77),
    onPrimaryContainer: Color(0xFFD1E4FF),
    secondary: Color(0xFFBBC7DB),
    onSecondary: Color(0xFF253140),
    secondaryContainer: Color(0xFF3B4858),
    onSecondaryContainer: Color(0xFFD7E3F7),
    tertiary: Color(0xFFD6BEE4),
    onTertiary: Color(0xFF3A2947),
    tertiaryContainer: Color(0xFF523F5E),
    onTertiaryContainer: Color(0xFFF2DAFF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    background: Color(0xFF001A37),
    onBackground: Color(0xFFFDFCFF),
    surface: Color(0xFF001A37),
    onSurface: Color(0xFFFDFCFF),
    surfaceVariant: Color(0xFF43474E),
    onSurfaceVariant: Color(0xFFC3C7CF),
    outline: Color(0xFF8D9199),
    outlineVariant: Color(0xFF43474E),
  );

  // ============================================
  // ThemeData Getters
  // ============================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _lightColorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _lightColorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        backgroundColor: _lightColorScheme.surface,
        indicatorColor: _lightColorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: _lightColorScheme.primary,
              fontWeight: FontWeight.w500,
            );
          }
          return TextStyle(color: _lightColorScheme.onSurfaceVariant);
        }),
      ),
      iconTheme: IconThemeData(
        color: _lightColorScheme.onSurfaceVariant,
        size: 24,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _darkColorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _darkColorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        backgroundColor: _darkColorScheme.surface,
        indicatorColor: _darkColorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: _darkColorScheme.primary,
              fontWeight: FontWeight.w500,
            );
          }
          return TextStyle(color: _darkColorScheme.onSurfaceVariant);
        }),
      ),
      iconTheme: IconThemeData(
        color: _darkColorScheme.onSurfaceVariant,
        size: 24,
      ),
    );
  }

  /// 根据 ThemeMode 获取对应的 ThemeData
  static ThemeData getTheme(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return lightTheme;
      case ThemeMode.dark:
        return darkTheme;
      case ThemeMode.system:
        return lightTheme;
    }
  }

  /// 获取当前 ColorScheme
  static ColorScheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.colorScheme;
  }
}
