import 'package:api_client/api_client.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

import 'data/lazne_sesije.dart';
import 'data/lazni_nalozi.dart';
import 'data/pocetni_podaci.dart';

/// Jedino mesto gde se bira implementacija portova. Ekrani i Blocovi znaju samo za
/// NalogRepository i SesijaRepository, pa rade isto nad serverom i nad lažnim podacima.
final class Zavisnosti {
  const Zavisnosti({required this.nalozi, required this.sesije, this.lazniNalozi});

  factory Zavisnosti.server({required Uri adresa, required TokenStore tokeni}) {
    final api = ApiKlijent(adresa: adresa, tokeni: tokeni);
    return Zavisnosti(nalozi: HttpNalogRepository(api), sesije: HttpSesijaRepository(api));
  }

  factory Zavisnosti.lazne({
    Duration kasnjenje = const Duration(milliseconds: 600),
    bool prijavljen = true,
    Korisnik? korisnik,
  }) {
    final lazni = LazniNalozi(kasnjenje: kasnjenje);
    return Zavisnosti(
      nalozi: lazni,
      sesije: LazneSesije(korisnik: korisnik ?? prijavljeniKorisnik, prijavljen: prijavljen),
      lazniNalozi: lazni,
    );
  }

  static final prijavljeniKorisnik = Korisnik(
    id: prijavljeniServiser.id.value,
    ime: prijavljeniServiser.ime,
    uloga: Uloga.serviser,
  );

  final NalogRepository nalozi;
  final SesijaRepository sesije;

  /// Postoji samo uz lažnu implementaciju; služi za dugme koje izaziva grešku.
  final LazniNalozi? lazniNalozi;
}
