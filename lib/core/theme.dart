import 'package:flutter/material.dart';

class BatshoColors {
  static const orange = Color(0xFFF58A4B);
  static const coral = Color(0xFFE8566B);
  static const pink = Color(0xFFC94A8A);
}

const batshoGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [BatshoColors.orange, BatshoColors.coral, BatshoColors.pink],
);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: BatshoColors.coral,
    primary: BatshoColors.coral,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      filled: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
