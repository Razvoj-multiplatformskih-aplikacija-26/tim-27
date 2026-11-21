import 'package:meta/meta.dart';

import 'nalog/stanje_naloga.dart';

/// Sve greške koje pravila domena mogu da vrate. Aplikacija za svaku bira tekst.
sealed class DomenskaGreska {
  const DomenskaGreska();
}

@immutable
final class OpisKvaraPrekratak extends DomenskaGreska {
  const OpisKvaraPrekratak(this.duzina);

  final int duzina;

  @override
  bool operator ==(Object other) => other is OpisKvaraPrekratak && other.duzina == duzina;

  @override
  int get hashCode => Object.hash(OpisKvaraPrekratak, duzina);

  @override
  String toString() => 'OpisKvaraPrekratak($duzina)';
}

@immutable
final class OpisKvaraPredugacak extends DomenskaGreska {
  const OpisKvaraPredugacak(this.duzina);

  final int duzina;

  @override
  bool operator ==(Object other) => other is OpisKvaraPredugacak && other.duzina == duzina;

  @override
  int get hashCode => Object.hash(OpisKvaraPredugacak, duzina);

  @override
  String toString() => 'OpisKvaraPredugacak($duzina)';
}

final class NazivUredjajaObavezan extends DomenskaGreska {
  const NazivUredjajaObavezan();
}

@immutable
final class NeispravanIznos extends DomenskaGreska {
  const NeispravanIznos(this.iznos);

  final int iznos;

  @override
  bool operator ==(Object other) => other is NeispravanIznos && other.iznos == iznos;

  @override
  int get hashCode => Object.hash(NeispravanIznos, iznos);

  @override
  String toString() => 'NeispravanIznos($iznos)';
}

final class OpisPonudeObavezan extends DomenskaGreska {
  const OpisPonudeObavezan();
}

@immutable
final class PreviseAktivnihNaloga extends DomenskaGreska {
  const PreviseAktivnihNaloga(this.aktivnih, {required this.granica});

  final int aktivnih;

  /// Granica iz pravila u trenutku provere; poruka je prikazuje, pa server javlja i nju.
  final int granica;

  @override
  bool operator ==(Object other) =>
      other is PreviseAktivnihNaloga && other.aktivnih == aktivnih && other.granica == granica;

  @override
  int get hashCode => Object.hash(PreviseAktivnihNaloga, aktivnih, granica);

  @override
  String toString() => 'PreviseAktivnihNaloga($aktivnih/$granica)';
}

final class RokZaOdgovorIstekao extends DomenskaGreska {
  const RokZaOdgovorIstekao();
}

final class NemaPonudeZaOdgovor extends DomenskaGreska {
  const NemaPonudeZaOdgovor();
}

final class NalogVecPreuzet extends DomenskaGreska {
  const NalogVecPreuzet();
}

final class NemaDelaNaStanju extends DomenskaGreska {
  const NemaDelaNaStanju();
}

final class NemaPrava extends DomenskaGreska {
  const NemaPrava();
}

final class NalogNijePronadjen extends DomenskaGreska {
  const NalogNijePronadjen();
}

@immutable
final class NedozvoljenPrelaz extends DomenskaGreska {
  const NedozvoljenPrelaz({required this.iz, required this.u});

  final StanjeNaloga iz;
  final StanjeNaloga u;

  @override
  bool operator ==(Object other) =>
      other is NedozvoljenPrelaz && other.iz.runtimeType == iz.runtimeType && other.u.runtimeType == u.runtimeType;

  @override
  int get hashCode => Object.hash(NedozvoljenPrelaz, iz.runtimeType, u.runtimeType);

  @override
  String toString() => 'NedozvoljenPrelaz(${iz.runtimeType} -> ${u.runtimeType})';
}
