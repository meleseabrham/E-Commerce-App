import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static Color primary = const Color(0xFF18804B); // Deep green for brand
  static Color secondary = const Color(0xFFFFC107); // Gold accent for CTAs
  static Color surface = Colors.white;
  static Color background = const Color(0xFFF5F7FA); // Soft light background
  static Color error = const Color(0xFFD32F2F); // Strong red
  static Color textPrimary = const Color(0xFF222222); // Near-black for best contrast
  static Color textSecondary = const Color(0xFF555555); // Muted dark gray
  static Color shadow = const Color(0x1A000000); // Subtle shadow
  static Color highlight = const Color(0xFF00BFAE); // Teal highlight for buttons/links

  // Dark Theme Colors
  static Color darkSurface = const Color(0xFF23272A);
  static Color darkBackground = const Color(0xFF181A1B);
  static Color darkCardColor = const Color(0xFF23272A);
  static Color darkTextPrimary = Colors.white;
  static Color darkTextSecondary = const Color(0xFFB3B3B3);
  static Color darkInputBackground = const Color(0xFF23272A);
  static Color darkInputBorder = const Color(0xFF3D3D3D);
  static Color darkShadow = const Color(0x66000000); // Subtle shadow for dark
  static Color darkHighlight = const Color(0xFF00BFAE); // Teal highlight for dark
  
  // Accent Colors for both themes
  static Color successColor = const Color(0xFF43A047); // Green for success
  static Color warningColor = const Color(0xFFFFA000); // Amber for warning
  static Color infoColor = const Color(0xFF1976D2); // Blue for info
} 