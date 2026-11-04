import 'package:meta/meta.dart';

import 'greske.dart';
import 'identifikatori.dart';
import 'rezultat.dart';

/// Rezervni deo na stanju servisa.
@immutable
final class Deo {
  const Deo({required this.id, required this.naziv, required this.naStanju});

  final DeoId id;
  final String naziv;
  final int naStanju;

  @override
  bool operator ==(Object other) =>
      other is Deo && other.id == id && other.naziv == naziv && other.naStanju == naStanju;

  @override
  int get hashCode => Object.hash(id, naziv, naStanju);

  @override
  String toString() => 'Deo($naziv, $naStanju)';
}

/// Deo rezervisan za jedan radni nalog.
@immutable
final class RezervacijaDela {
  const RezervacijaDela({required this.deoId, required this.nalogId, this.komada = 1});

  final DeoId deoId;
  final NalogId nalogId;
  final int komada;

  @override
  bool operator ==(Object other) =>
      other is RezervacijaDela && other.deoId == deoId && other.nalogId == nalogId && other.komada == komada;

  @override
  int get hashCode => Object.hash(deoId, nalogId, komada);
}

/// Koliko komada dela je ostalo kad se oduzmu sve rezervacije (i drugih servisera).
int preostaloNaStanju(Deo deo, List<RezervacijaDela> rezervacije) =>
    deo.naStanju - rezervacije.where((r) => r.deoId == deo.id).fold(0, (zbir, r) => zbir + r.komada);

/// Rezerviše deo za nalog ako ga ima dovoljno. Dva servisera ne mogu uzeti poslednji komad:
/// ovo je izračunavanje nad listom, a konačnu odluku u KT2 donosi server.
Rezultat<RezervacijaDela> rezervisiDeo({
  required Deo deo,
  required NalogId nalogId,
  required List<RezervacijaDela> rezervacije,
  int komada = 1,
}) {
  if (preostaloNaStanju(deo, rezervacije) < komada) return const Neuspeh(NemaDelaNaStanju());
  return Uspeh(RezervacijaDela(deoId: deo.id, nalogId: nalogId, komada: komada));
}
