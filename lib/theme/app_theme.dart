import 'package:flutter/material.dart';
import '../models/product_model.dart';

class AppTheme {
  AppTheme._();

  // Primary brand colors
  static const Color primary = Color(0xFF1E3A8A); // Deep Navy Blue
  static const Color primaryLight = Color(0xFF3B82F6); // Vibrant Blue accent
  static const Color primaryContainer = Color(0xFFEEF2FF); // Soft indigo tint
  static const Color onPrimaryContainer = Color(0xFF1E3A8A);

  // Secondary accent colors
  static const Color secondary = Color(0xFF0D9488); // Modern Teal
  static const Color secondaryContainer = Color(0xFFCCFBF1);
  static const Color onSecondaryContainer = Color(0xFF115E59);

  // Neutral background & surface colors
  static const Color scaffoldBackground = Color(0xFFF8FAFC); // Very light crisp neutral
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFCBD5E1);

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status colors - Active (Green)
  static const Color statusActiveText = Color(0xFF059669);
  static const Color statusActiveBg = Color(0xFFECFDF5);
  static const Color statusActiveBorder = Color(0xFFA7F3D0);

  // Status colors - Expiring Soon (Amber/Orange)
  static const Color statusExpiringText = Color(0xFFD97706);
  static const Color statusExpiringBg = Color(0xFFFFFBEB);
  static const Color statusExpiringBorder = Color(0xFFFDE68A);

  // Status colors - Expired (Red)
  static const Color statusExpiredText = Color(0xFFDC2626);
  static const Color statusExpiredBg = Color(0xFFFEF2F2);
  static const Color statusExpiredBorder = Color(0xFFFECACA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        error: Color(0xFFDC2626),
        onError: Colors.white,
        errorContainer: Color(0xFFFEF2F2),
        onErrorContainer: Color(0xFF991B1B),
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Color(0xFFF8FAFC),
        surfaceContainer: Color(0xFFF1F5F9),
        surfaceContainerHigh: Color(0xFFE2E8F0),
        surfaceContainerHighest: Color(0xFFCBD5E1),
        onSurfaceVariant: textSecondary,
        outline: borderSubtle,
        outlineVariant: borderLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          side: const BorderSide(color: borderSubtle, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceMuted,
        selectedColor: primaryContainer,
        disabledColor: surfaceMuted,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: borderSubtle,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Category Icon Resolver
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase().trim()) {
      case 'electronics':
        return Icons.devices_rounded;
      case 'appliances':
        return Icons.kitchen_rounded;
      case 'furniture':
        return Icons.chair_rounded;
      case 'automobiles':
      case 'vehicles':
        return Icons.directions_car_rounded;
      case 'computing':
      case 'computers':
        return Icons.laptop_mac_rounded;
      case 'fashion & accessories':
      case 'fashion':
      case 'clothing':
        return Icons.checkroom_rounded;
      case 'home & kitchen':
        return Icons.home_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  // Status Styling Resolvers
  static Color getStatusTextColor(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.active:
        return statusActiveText;
      case WarrantyStatus.expiringSoon:
        return statusExpiringText;
      case WarrantyStatus.expired:
        return statusExpiredText;
    }
  }

  static Color getStatusBgColor(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.active:
        return statusActiveBg;
      case WarrantyStatus.expiringSoon:
        return statusExpiringBg;
      case WarrantyStatus.expired:
        return statusExpiredBg;
    }
  }

  static Color getStatusBorderColor(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.active:
        return statusActiveBorder;
      case WarrantyStatus.expiringSoon:
        return statusExpiringBorder;
      case WarrantyStatus.expired:
        return statusExpiredBorder;
    }
  }

  static IconData getStatusIcon(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.active:
        return Icons.verified_user_rounded;
      case WarrantyStatus.expiringSoon:
        return Icons.warning_amber_rounded;
      case WarrantyStatus.expired:
        return Icons.event_busy_rounded;
    }
  }
}
