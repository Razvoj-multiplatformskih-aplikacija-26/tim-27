import 'package:domain/domain.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class PomeriIzborIntent extends Intent {
  const PomeriIzborIntent(this.korak);

  final int korak;
}

class PonistiIzborIntent extends Intent {
  const PonistiIzborIntent();
}

class AkcijaIntent extends Intent {
  const AkcijaIntent(this.akcija);

  final AkcijaOsoblja akcija;
}

class OsveziIntent extends Intent {
  const OsveziIntent();
}

class PrikaziPreciceIntent extends Intent {
  const PrikaziPreciceIntent();
}

/// Sve prečice backoffice-a na jednom mestu.
const Map<ShortcutActivator, Intent> precice = {
  SingleActivator(LogicalKeyboardKey.arrowDown): PomeriIzborIntent(1),
  SingleActivator(LogicalKeyboardKey.arrowUp): PomeriIzborIntent(-1),
  SingleActivator(LogicalKeyboardKey.keyJ): PomeriIzborIntent(1),
  SingleActivator(LogicalKeyboardKey.keyK): PomeriIzborIntent(-1),
  SingleActivator(LogicalKeyboardKey.escape): PonistiIzborIntent(),
  SingleActivator(LogicalKeyboardKey.keyP): AkcijaIntent(AkcijaOsoblja.preuzmi),
  SingleActivator(LogicalKeyboardKey.keyO): AkcijaIntent(AkcijaOsoblja.posaljiPonudu),
  SingleActivator(LogicalKeyboardKey.keyS): AkcijaIntent(AkcijaOsoblja.oznaciSpreman),
  SingleActivator(LogicalKeyboardKey.keyI): AkcijaIntent(AkcijaOsoblja.izdaj),
  SingleActivator(LogicalKeyboardKey.keyX): AkcijaIntent(AkcijaOsoblja.otkazi),
  SingleActivator(LogicalKeyboardKey.keyR): OsveziIntent(),
  CharacterActivator('?'): PrikaziPreciceIntent(),
  SingleActivator(LogicalKeyboardKey.f1): PrikaziPreciceIntent(),
};

/// Taster i naziv akcije, za dugmad, panel i pregled prečica.
String tasterAkcije(AkcijaOsoblja akcija) => switch (akcija) {
  AkcijaOsoblja.preuzmi => 'P',
  AkcijaOsoblja.posaljiPonudu => 'O',
  AkcijaOsoblja.oznaciSpreman => 'S',
  AkcijaOsoblja.izdaj => 'I',
  AkcijaOsoblja.otkazi => 'X',
};

String nazivAkcije(AkcijaOsoblja akcija) => switch (akcija) {
  AkcijaOsoblja.preuzmi => 'Preuzmi nalog',
  AkcijaOsoblja.posaljiPonudu => 'Pošalji ponudu',
  AkcijaOsoblja.oznaciSpreman => 'Označi spreman',
  AkcijaOsoblja.izdaj => 'Izdaj uređaj klijentu',
  AkcijaOsoblja.otkazi => 'Otkaži nalog',
};

const opisPrecica = [
  ('↑ / ↓  ili  K / J', 'Prethodni / sledeći nalog'),
  ('Esc', 'Poništi izbor'),
  ('P', 'Preuzmi nalog'),
  ('O', 'Pošalji ponudu'),
  ('S', 'Označi spreman za preuzimanje'),
  ('I', 'Izdaj uređaj klijentu'),
  ('X', 'Otkaži nalog'),
  ('R', 'Osveži naloge'),
  ('?  ili  F1', 'Pregled prečica'),
  ('Tab', 'Kretanje kroz dugmad'),
];
