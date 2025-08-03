import 'package:flutter/material.dart';

/// Application color scheme following Material Design 3 principles
/// Designed for airline/aviation theme with professional look
abstract class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF1565C0); // Deep blue - aviation theme
  static const Color primaryVariant = Color(0xFF0D47A1);
  static const Color secondary = Color(0xFF00ACC1); // Light blue - sky theme
  static const Color secondaryVariant = Color(0xFF0097A7);

  // Surface colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Status colors
  static const Color success = Color(0xFF10B981); // Green for success states
  static const Color warning = Color(0xFFF59E0B); // Orange for warnings
  static const Color error = Color(0xFFEF4444); // Red for errors
  static const Color info = Color(0xFF3B82F6); // Blue for info

  // Semantic colors for boarding pass states
  static const Color issued = Color(0xFF6B7280); // Gray for issued
  static const Color activated = Color(0xFF10B981); // Green for activated
  static const Color used = Color(0xFF8B5CF6); // Purple for used
  static const Color expired = Color(0xFFEF4444); // Red for expired
  static const Color cancelled = Color(0xFF6B7280); // Gray for cancelled

  // UI element colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderFocus = primary;
  static const Color divider = Color(0xFFE5E7EB);

  // Member tier colors
  static const Color tierBronze = Color(0xFFCD7F32);
  static const Color tierSilver = Color(0xFFC0C0C0);
  static const Color tierGold = Color(0xFFFFD700);

  // QR Code colors
  static const Color qrCodeBackground = Color(0xFFFFFFFF);
  static const Color qrCodeForeground = Color(0xFF000000);

  // Gradient colors for premium effects
  static const Color gradientStart = Color(0xFF1565C0);
  static const Color gradientEnd = Color(0xFF42A5F5);

  // Offline/connectivity colors
  static const Color offline = Color(0xFF9CA3AF);
  static const Color online = success;

  // Shadow colors
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color shadowHeavy = Color(0x26000000);

  /// Get color for boarding pass status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'issued':
        return issued;
      case 'activated':
        return activated;
      case 'used':
        return used;
      case 'expired':
        return expired;
      case 'cancelled':
        return cancelled;
      default:
        return textSecondary;
    }
  }

  /// Get color for member tier
  static Color getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return tierBronze;
      case 'silver':
        return tierSilver;
      case 'gold':
        return tierGold;
      default:
        return textSecondary;
    }
  }

  /// Get gradient for premium UI elements
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  /// Get gradient for member tier
  static LinearGradient getTierGradient(String tier) {
    final tierColor = getTierColor(tier);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [tierColor, tierColor.withAlpha(179)],
    );
  }

  /// Material color swatch for theme integration
  static const MaterialColor primarySwatch =
      MaterialColor(0xFF1565C0, <int, Color>{
        50: Color(0xFFE3F2FD),
        100: Color(0xFFBBDEFB),
        200: Color(0xFF90CAF9),
        300: Color(0xFF64B5F6),
        400: Color(0xFF42A5F5),
        500: Color(0xFF1565C0),
        600: Color(0xFF1E88E5),
        700: Color(0xFF1976D2),
        800: Color(0xFF1565C0),
        900: Color(0xFF0D47A1),
      });
}
