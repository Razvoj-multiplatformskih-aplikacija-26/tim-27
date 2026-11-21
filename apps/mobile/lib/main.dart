import 'package:flutter/material.dart';

import 'adresa_servera.dart';
import 'app.dart';
import 'data/sigurno_skladiste.dart';
import 'dependencies.dart';

void main() {
  runApp(
    RebootApp(
      zavisnosti: Zavisnosti.server(adresa: adresaServera(), tokeni: const SigurnoSkladiste()),
    ),
  );
}
