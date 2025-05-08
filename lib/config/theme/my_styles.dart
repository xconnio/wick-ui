import "package:flutter/material.dart";
import "package:wick_ui/config/theme/dark_theme_colors.dart";

mixin MyStyles {
  static final inputDecoration = InputDecorationTheme(
    filled: true,
    fillColor: DarkThemeColors.inputFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: DarkThemeColors.inputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: DarkThemeColors.inputFocusedBorder,
    ),
    labelStyle: DarkThemeColors.labelStyle,
    hintStyle: DarkThemeColors.hintStyle,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  static final elevatedButton = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: DarkThemeColors.buttonBackground,
      foregroundColor: DarkThemeColors.buttonForeground,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
    ),
  );

  static final card = CardTheme(
    color: DarkThemeColors.cardColor,
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    margin: EdgeInsets.zero,
  );

  static final divider = DividerThemeData(
    color: DarkThemeColors.dividerColor,
    thickness: 1,
    space: 1,
  );
}
