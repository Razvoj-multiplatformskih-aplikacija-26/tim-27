import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'adresa_servera.dart';
import 'app.dart';
import 'data/sigurno_skladiste.dart';
import 'dependencies.dart';

void main() {
  usePathUrlStrategy();
  runApp(
    BackofficeApp(
      zavisnosti: Zavisnosti.server(adresa: adresaServera(), tokeni: const SigurnoSkladiste()),
    ),
  );
}
