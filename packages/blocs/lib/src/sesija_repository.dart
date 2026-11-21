import 'package:domain/domain.dart';

/// Port za prijavu. HttpSesijaRepository čuva token iza porta TokenStore (bezbedno skladište
/// platforme), a u pregledaču prijavu drži HttpOnly kolačić.
abstract interface class SesijaRepository {
  /// null kada korisničko ime ili lozinka nisu tačni.
  Future<Korisnik?> prijavi({required String korisnickoIme, required String lozinka});

  /// Prijava sačuvana od ranije; null kada je nema. Baca GreskaRepozitorijuma sa vrstom
  /// prijavaIstekla kada je postojala, ali je istekla.
  Future<Korisnik?> trenutna();

  Future<void> odjavi();

  /// Javlja kada server odbije poziv jer je prijava istekla.
  Stream<void> get istekle;
}
