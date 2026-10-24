import 'package:flutter/material.dart';

/// Semantic Design Tokens for Amikom Student Android Application
/// Sourced directly from official Amikom Purwokerto website (https://amikompurwokerto.ac.id)
/// Signature: Royal Amikom Purple (#7706C7), Majestic Plum (#2B0D46), & University Gold (#F7A600)
class AppColors {
  AppColors._();

  // Official Amikom Purwokerto Website Brand Palette
  static const Color amikomPurple = Color(0xFF7706C7);      // Signature Vivid Royal Violet
  static const Color amikomPurpleDeep = Color(0xFF501276);  // Medium Rich Plum
  static const Color amikomPurpleNight = Color(0xFF2B0D46); // Deep Night Plum (Hero/Header)
  static const Color amikomPurpleDark = Color(0xFF180724);  // Midnight Violet Base
  static const Color amikomPurpleLight = Color(0xFF9D31E5); // Bright Violet Accent
  static const Color amikomPurpleTint = Color(0xFFF7F1FB);  // Soft Violet-tinted Surface

  // Official Amikom Gold & Amber Accents
  static const Color amikomGold = Color(0xFFF7A600);        // Official Amikom Gold
  static const Color amikomGoldLight = Color(0xFFFFD15A);   // Light Amber Glow
  static const Color amikomGoldDark = Color(0xFFD98200);    // Warm Deep Gold
  static const Color amikomGoldAccent = Color(0xFFF49F31);  // Orange-Amber Tone
  static const Color amikomGoldContainer = Color(0xFFFFF7E6);
  static const Color amikomGoldDarkContainer = Color(0xFF381F00);
  static const Color amikomGoldText = Color(0xFF945200);
  static const Color amikomGoldDarkText = Color(0xFFFCD34D);

  // Primitive Brand Palette - Compatibility Anchors
  static const Color purple50 = Color(0xFFF7F1FB);
  static const Color purple100 = Color(0xFFECE0FE);
  static const Color purple200 = Color(0xFFDCC6FD);
  static const Color purple300 = Color(0xFFC39EFC);
  static const Color purple400 = Color(0xFF9D31E5);
  static const Color purple500 = Color(0xFF8B42F6);
  static const Color purple600 = Color(0xFF7B20B8);
  static const Color purple700 = Color(0xFF7706C7); // Updated to Amikom Vivid Violet
  static const Color purple800 = Color(0xFF501276);
  static const Color purple900 = Color(0xFF2B0D46);

  // Primitive Neutrals - Slate Grayscale
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);
  static const Color neutral950 = Color(0xFF0A0512);

  // Semantic Light Mode
  static const Color lightPrimary = amikomPurple;
  static const Color lightPrimaryContainer = amikomPurpleTint;
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSubtle = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderStrong = Color(0xFFCBD5E1);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextTertiary = Color(0xFF94A3B8);

  // Semantic Dark Mode (Midnight Plum matching amikompurwokerto.ac.id)
  static const Color darkPrimary = amikomPurpleLight;
  static const Color darkPrimaryContainer = amikomPurpleNight;
  static const Color darkBackground = Color(0xFF10051C);
  static const Color darkSurface = Color(0xFF1B0C30);
  static const Color darkSurfaceSubtle = Color(0xFF251140);
  static const Color darkBorder = Color(0xFF351D52);
  static const Color darkBorderStrong = Color(0xFF4D2C75);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextTertiary = Color(0xFF94A3B8);

  // Status & Feedback Tokens (Light & Dark Compatible)
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successContainer = Color(0xFFE6F7F0);
  static const Color successText = Color(0xFF065F46);

  static const Color warning = amikomGold;
  static const Color warningContainer = amikomGoldContainer;
  static const Color warningText = amikomGoldText;

  static const Color danger = Color(0xFFEF4444); // Red 500
  static const Color dangerContainer = Color(0xFFFEE2E2);
  static const Color dangerText = Color(0xFF991B1B);

  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoContainer = Color(0xFFEFF6FF);
  static const Color infoText = Color(0xFF1E40AF);

  // Official Amikom Gradients from amikompurwokerto.ac.id
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7706C7), Color(0xFF361261)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2B0D46), Color(0xFF501276), Color(0xFF7706C7)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD15A), Color(0xFFF7A600), Color(0xFFD98200)],
  );

  static const LinearGradient fusionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7706C7), Color(0xFFF49F31)],
  );

  static const LinearGradient nightSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF180724), Color(0xFF2B0D46), Color(0xFF3B105D)],
  );

  static const LinearGradient cardLightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F1FB)],
  );
}
