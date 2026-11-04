import 'package:flutter/material.dart';

import 'package:domain/domain.dart';

/// Boje i font aplikacije Reboot.
abstract final class RebootTema {
  static const plava = Color(0xFF1E5AA8);
  static const narandzasta = Color(0xFFE8792B);

  static ThemeData svetla() => _napravi(Brightness.light);

  static ThemeData tamna() => _napravi(Brightness.dark);

  static ThemeData _napravi(Brightness osvetljenje) {
    final boje = ColorScheme.fromSeed(seedColor: plava, secondary: narandzasta, brightness: osvetljenje);
    return ThemeData(
      colorScheme: boje,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(backgroundColor: boje.surface, centerTitle: false),
      cardTheme: CardThemeData(
        elevation: 0,
        color: boje.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );
  }
}

/// Boja oznake za svako stanje naloga.
Color bojaStanja(StanjeNaloga stanje) => switch (stanje) {
  Primljen() => Colors.blueGrey,
  Dijagnostika() => Colors.indigo,
  CekaOdobrenje() => Colors.orange.shade800,
  UPopravci() => Colors.blue.shade700,
  SpremanZaPreuzimanje() => Colors.green.shade700,
  Preuzet() => Colors.teal.shade700,
  Otkazan() => Colors.grey.shade600,
  OdbijenaPonuda() => Colors.red.shade700,
};
