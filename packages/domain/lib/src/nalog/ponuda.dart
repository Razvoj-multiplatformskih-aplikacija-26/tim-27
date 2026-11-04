import 'package:meta/meta.dart';

import '../greske.dart';
import '../rezultat.dart';

/// Ponuda servisera za popravku. Klijent na nju odgovara u roku od 48 sati.
@immutable
final class Ponuda {
  const Ponuda._({required this.iznos, required this.opis, required this.poslataU});

  static const rokZaOdgovor = Duration(hours: 48);
  static const maksIznos = 1000000;

  /// Iznos u dinarima.
  final int iznos;
  final String opis;
  final DateTime poslataU;

  DateTime get istice => poslataU.add(rokZaOdgovor);

  bool jeIstekla(DateTime sada) => sada.isAfter(istice);

  static Rezultat<Ponuda> proveri({required int iznos, required String opis, required DateTime poslataU}) {
    if (iznos <= 0 || iznos > maksIznos) return Neuspeh(NeispravanIznos(iznos));
    final tekst = opis.trim();
    if (tekst.isEmpty) return const Neuspeh(OpisPonudeObavezan());
    return Uspeh(Ponuda._(iznos: iznos, opis: tekst, poslataU: poslataU));
  }

  @override
  bool operator ==(Object other) =>
      other is Ponuda && other.iznos == iznos && other.opis == opis && other.poslataU == poslataU;

  @override
  int get hashCode => Object.hash(iznos, opis, poslataU);

  @override
  String toString() => 'Ponuda($iznos RSD)';
}
