import 'package:flutter/material.dart';

class AppConstants {
  // Base URL for API
  static const String baseUrl = 'https://face-detection-backend-cxgl.onrender.com';

  // Local storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';

  // Aesthetic Custom Color Theme
  static const Color primary = Color(0xFF4361EE);      // Indigo Sapphire
  static const Color primaryLight = Color(0xFFE8EDFF); // Soft Blue Accent
  static const Color secondary = Color(0xFF3F37C9);    // Deep Violet
  static const Color accent = Color(0xFF4CC9F0);       // Neon Cyan
  static const Color background = Color(0xFFF8F9FA);   // Off White Grey
  static const Color darkBackground = Color(0xFF0F172A); // Slate Slate Blue
  static const Color cardColor = Colors.white;
  static const Color cardColorDark = Color(0xFF1E293B);
  
  static const Color textDark = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color success = Color(0xFF06D6A0);      // Soft Mint Green
  static const Color warning = Color(0xFFFFD166);      // Warm Yellow
  static const Color error = Color(0xFFF72585);        // Raspberry Neon Red

  // Visual Borders & Paddings
  static const double borderRadius = 16.0;
  static const double padding = 16.0;
  static const double paddingLarge = 24.0;
}
