import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'dependencies.dart';

void main() {
  usePathUrlStrategy();
  runApp(BackofficeApp(zavisnosti: Zavisnosti.lazne()));
}
