import 'package:flutter/material.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static const Color _trueDarkNavy = Color(0xFF0A1921);
  static const Color _desbyAmber = Color(0xFFFFC107);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _desbyAmber,
        onPrimary: _trueDarkNavy,
        secondary: _desbyAmber,
        surface: Colors.white,
        onSurface: _trueDarkNavy,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: const Color(0xFFF2F4F7),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _trueDarkNavy,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _trueDarkNavy),
        shadowColor: Color(0x0A000000),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _desbyAmber,
          foregroundColor: _trueDarkNavy,
          textStyle: AppTypography.button.copyWith(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _desbyAmber, width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIconColor: _desbyAmber,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _desbyAmber,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: _desbyAmber.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: _trueDarkNavy,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return const TextStyle(color: Colors.grey, fontSize: 12);
        }),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        selectedIconTheme: IconThemeData(color: _desbyAmber),
        unselectedIconTheme: IconThemeData(color: Colors.grey),
        selectedLabelTextStyle: TextStyle(
          color: _trueDarkNavy,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(color: Colors.grey),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: AppTypography.headline6.copyWith(color: _trueDarkNavy),
        contentTextStyle: AppTypography.body2.copyWith(
          color: const Color(0xFF64748B),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: Colors.black26,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.body2.copyWith(color: _trueDarkNavy),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.black12),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: _trueDarkNavy),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _trueDarkNavy),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _trueDarkNavy,
          side: const BorderSide(color: Colors.black12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(color: _trueDarkNavy, fontSize: 16),
        subtitleTextStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        iconColor: _trueDarkNavy,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _desbyAmber;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected))
            return _desbyAmber.withValues(alpha: 0.3);
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _desbyAmber;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(_trueDarkNavy),
        side: const BorderSide(color: Colors.black26),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _desbyAmber;
          return Colors.grey;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _desbyAmber,
        linearTrackColor: Colors.black12,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: _desbyAmber,
        side: const BorderSide(color: Colors.black12),
        labelStyle: const TextStyle(color: _trueDarkNavy),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: _trueDarkNavy),
        headlineMedium: TextStyle(color: _trueDarkNavy),
        headlineSmall: TextStyle(color: _trueDarkNavy),
        titleLarge: TextStyle(color: _trueDarkNavy),
        titleMedium: TextStyle(color: _trueDarkNavy),
        titleSmall: TextStyle(color: _trueDarkNavy),
        bodyLarge: TextStyle(color: _trueDarkNavy),
        bodyMedium: TextStyle(color: _trueDarkNavy),
        bodySmall: TextStyle(color: Color(0xFF64748B)),
        labelLarge: TextStyle(color: _trueDarkNavy),
        labelMedium: TextStyle(color: _trueDarkNavy),
        labelSmall: TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _desbyAmber,
        onPrimary: _trueDarkNavy,
        secondary: _desbyAmber,
        surface: _trueDarkNavy,
        onSurface: Colors.white,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: _trueDarkNavy,
      appBarTheme: const AppBarTheme(
        backgroundColor: _trueDarkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.03),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _desbyAmber,
          foregroundColor: _trueDarkNavy,
          textStyle: AppTypography.button.copyWith(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _desbyAmber, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.24)),
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIconColor: _desbyAmber,
      ),
      dividerTheme: const DividerThemeData(color: Colors.white12, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _trueDarkNavy,
        selectedItemColor: _desbyAmber,
        unselectedItemColor: Colors.white.withValues(alpha: 0.3),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _trueDarkNavy,
        indicatorColor: _desbyAmber.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _trueDarkNavy,
        selectedIconTheme: const IconThemeData(color: _desbyAmber),
        unselectedIconTheme: IconThemeData(
          color: Colors.white.withValues(alpha: 0.5),
        ),
        selectedLabelTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _trueDarkNavy,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: AppTypography.headline6.copyWith(color: Colors.white),
        contentTextStyle: AppTypography.body2.copyWith(color: Colors.white70),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _trueDarkNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: Colors.white24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: _trueDarkNavy,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.body2.copyWith(color: Colors.white),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(_trueDarkNavy),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: Colors.white),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.white),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
        subtitleTextStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        iconColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _desbyAmber;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected))
            return _desbyAmber.withValues(alpha: 0.3);
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _desbyAmber;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(_trueDarkNavy),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _desbyAmber;
          return Colors.white38;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _desbyAmber,
        linearTrackColor: Colors.white12,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        selectedColor: _desbyAmber,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        labelStyle: const TextStyle(color: Colors.white),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white70),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white),
        labelSmall: TextStyle(color: Colors.white38),
      ),
    );
  }
}
