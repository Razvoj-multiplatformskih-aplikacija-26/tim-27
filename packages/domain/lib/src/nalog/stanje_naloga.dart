import 'package:meta/meta.dart';

import 'ponuda.dart';

/// Stanja radnog naloga. Stanja koja nose podatke (ponudu, razlog, vreme) imaju polja.
sealed class StanjeNaloga {
  const StanjeNaloga();

  /// Serviser trenutno radi na nalogu; broji se u ograničenje od 5 aktivnih naloga.
  bool get jeAktivno => switch (this) {
    Dijagnostika() || CekaOdobrenje() || UPopravci() => true,
    Primljen() || SpremanZaPreuzimanje() || Preuzet() || Otkazan() || OdbijenaPonuda() => false,
  };

  /// Iz ovog stanja nema daljih prelaza.
  bool get jeZavrsno => switch (this) {
    Preuzet() || Otkazan() || OdbijenaPonuda() => true,
    Primljen() || Dijagnostika() || CekaOdobrenje() || UPopravci() || SpremanZaPreuzimanje() => false,
  };
}

final class Primljen extends StanjeNaloga {
  const Primljen();

  @override
  String toString() => 'Primljen';
}

final class Dijagnostika extends StanjeNaloga {
  const Dijagnostika();

  @override
  String toString() => 'Dijagnostika';
}

@immutable
final class CekaOdobrenje extends StanjeNaloga {
  const CekaOdobrenje(this.ponuda);

  final Ponuda ponuda;

  @override
  bool operator ==(Object other) => other is CekaOdobrenje && other.ponuda == ponuda;

  @override
  int get hashCode => Object.hash(CekaOdobrenje, ponuda);

  @override
  String toString() => 'CekaOdobrenje($ponuda)';
}

@immutable
final class UPopravci extends StanjeNaloga {
  const UPopravci(this.ponuda);

  final Ponuda ponuda;

  @override
  bool operator ==(Object other) => other is UPopravci && other.ponuda == ponuda;

  @override
  int get hashCode => Object.hash(UPopravci, ponuda);

  @override
  String toString() => 'UPopravci($ponuda)';
}

final class SpremanZaPreuzimanje extends StanjeNaloga {
  const SpremanZaPreuzimanje();

  @override
  String toString() => 'SpremanZaPreuzimanje';
}

@immutable
final class Preuzet extends StanjeNaloga {
  const Preuzet(this.preuzetU);

  final DateTime preuzetU;

  @override
  bool operator ==(Object other) => other is Preuzet && other.preuzetU == preuzetU;

  @override
  int get hashCode => Object.hash(Preuzet, preuzetU);

  @override
  String toString() => 'Preuzet($preuzetU)';
}

@immutable
final class Otkazan extends StanjeNaloga {
  const Otkazan(this.razlog);

  final String razlog;

  @override
  bool operator ==(Object other) => other is Otkazan && other.razlog == razlog;

  @override
  int get hashCode => Object.hash(Otkazan, razlog);

  @override
  String toString() => 'Otkazan("$razlog")';
}

@immutable
final class OdbijenaPonuda extends StanjeNaloga {
  const OdbijenaPonuda(this.ponuda);

  final Ponuda ponuda;

  @override
  bool operator ==(Object other) => other is OdbijenaPonuda && other.ponuda == ponuda;

  @override
  int get hashCode => Object.hash(OdbijenaPonuda, ponuda);

  @override
  String toString() => 'OdbijenaPonuda($ponuda)';
}

/// Jedina funkcija koja kaže koji su prelazi između stanja dozvoljeni.
bool dozvoljenPrelaz(StanjeNaloga iz, StanjeNaloga u) => switch ((iz, u)) {
  (Primljen(), Dijagnostika()) => true,
  (Primljen() || Dijagnostika(), Otkazan()) => true,
  (Dijagnostika(), CekaOdobrenje()) => true,
  (CekaOdobrenje(), UPopravci()) => true,
  (CekaOdobrenje(), OdbijenaPonuda()) => true,
  (UPopravci(), SpremanZaPreuzimanje()) => true,
  (SpremanZaPreuzimanje(), Preuzet()) => true,
  _ => false,
};
