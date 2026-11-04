import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

import 'data/lazni_nalozi.dart';
import 'data/pocetni_podaci.dart';

/// Jedino mesto gde se bira implementacija porta. Ekrani znaju samo za NalogRepository.
final class Zavisnosti {
  const Zavisnosti({required this.nalozi, required this.serviser, this.lazniNalozi});

  factory Zavisnosti.lazne({Duration kasnjenje = const Duration(milliseconds: 600)}) {
    final lazni = LazniNalozi(kasnjenje: kasnjenje);
    return Zavisnosti(nalozi: lazni, serviser: prijavljeniServiser, lazniNalozi: lazni);
  }

  final NalogRepository nalozi;

  /// KT1: backoffice radi kao jedan prijavljeni serviser; prijava stiže u KT2.
  final Serviser serviser;

  /// Postoji samo uz lažnu implementaciju; služi za dugme koje izaziva grešku.
  final LazniNalozi? lazniNalozi;
}
