import "package:flutter/material.dart";

mixin DarkThemeColors {
  static const scaffoldBackground = Color(0xFF121212);
  static const appBarBackground = Color(0xFF1E1E1E);
  static const appBarForeground = Colors.white;
  static const textPrimary = Colors.white;
  static final inputFill = Colors.grey.shade900.withAlpha((0.5 * 255).round());
  static final inputBorder = Colors.grey.shade700;
  static const inputFocusedBorder = BorderSide(color: Colors.blueAccent, width: 1.5);
  static final labelStyle = TextStyle(color: Colors.grey.shade400);
  static final hintStyle = TextStyle(color: Colors.grey.shade500);
  static const buttonBackground = Colors.blueAccent;
  static const buttonForeground = Colors.white;
  static final cardColor = Colors.grey.shade900;
  static final dividerColor = Colors.grey.shade800;
}
