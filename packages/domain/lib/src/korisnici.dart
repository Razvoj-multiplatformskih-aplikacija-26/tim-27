import 'package:meta/meta.dart';

import 'identifikatori.dart';

/// Klijent servisa: vidi i menja samo svoje radne naloge.
@immutable
final class Klijent {
  const Klijent({required this.id, required this.ime, required this.telefon});

  final KlijentId id;
  final String ime;
  final String telefon;

  @override
  bool operator ==(Object other) => other is Klijent && other.id == id && other.ime == ime && other.telefon == telefon;

  @override
  int get hashCode => Object.hash(id, ime, telefon);

  @override
  String toString() => 'Klijent($ime)';
}

enum UlogaOsoblja { serviser, sefServisa }

/// Član osoblja: serviser ili šef servisa. Oba vide sve naloge.
@immutable
final class Serviser {
  const Serviser({required this.id, required this.ime, this.uloga = UlogaOsoblja.serviser});

  final ServiserId id;
  final String ime;
  final UlogaOsoblja uloga;

  bool get jeSef => uloga == UlogaOsoblja.sefServisa;

  @override
  bool operator ==(Object other) => other is Serviser && other.id == id && other.ime == ime && other.uloga == uloga;

  @override
  int get hashCode => Object.hash(id, ime, uloga);

  @override
  String toString() => 'Serviser($ime, ${uloga.name})';
}

/// Uloga prijavljenog korisnika. Klijent radi u mobilnoj aplikaciji, osoblje u backoffice-u.
enum Uloga { klijent, serviser, sefServisa }

/// Korisnik sistema kako ga vidi prijava: ko je i u kojoj ulozi.
@immutable
final class Korisnik {
  const Korisnik({required this.id, required this.ime, required this.uloga, this.telefon = ''});

  final String id;
  final String ime;
  final Uloga uloga;
  final String telefon;

  @override
  bool operator ==(Object other) =>
      other is Korisnik && other.id == id && other.ime == ime && other.uloga == uloga && other.telefon == telefon;

  @override
  int get hashCode => Object.hash(id, ime, uloga, telefon);

  @override
  String toString() => 'Korisnik($ime, ${uloga.name})';
}
