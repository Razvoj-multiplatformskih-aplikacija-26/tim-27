import 'package:domain/domain.dart';

/// Port kroz koji Blocovi dobijaju podatke. Implementacije: lažna u memoriji (testovi, demo)
/// i HttpNalogRepository u paketu api_client, koji zove server. Ekrani i Blocovi ne znaju koja je.
abstract interface class NalogRepository {
  Future<List<RadniNalog>> naloziKlijenta(KlijentId klijentId);

  Future<List<RadniNalog>> sviNalozi();

  Future<RadniNalog?> nadji(NalogId id);

  /// Čuva promenu stanja naloga. Server ponovo proverava ista pravila domena i može da odbije
  /// promenu (na primer, nalog je u međuvremenu preuzeo drugi serviser): tada vraća Neuspeh.
  Future<Rezultat<RadniNalog>> sacuvaj(RadniNalog nalog);

  Future<Rezultat<RadniNalog>> prijavi({
    required Klijent klijent,
    required Uredjaj uredjaj,
    required OpisKvara opisKvara,
  });

  Future<List<Klijent>> klijenti();

  Future<List<Serviser>> serviseri();
}

enum VrstaGreske {
  /// Nema mreže ili server ne radi.
  nedostupan,

  /// Server je odgovorio greškom koju ne razume ova verzija aplikacije.
  greskaServera,

  /// Server je odbio radnju razlogom koji ova verzija aplikacije ne poznaje (novije pravilo).
  odbijeno,

  /// Prijava je istekla ili ne postoji.
  prijavaIstekla,
}

/// Zahtev ka izvoru podataka nije uspeo.
final class GreskaRepozitorijuma implements Exception {
  const GreskaRepozitorijuma(this.poruka, {this.vrsta = VrstaGreske.nedostupan, this.uzrok});

  final String poruka;
  final VrstaGreske vrsta;
  final Object? uzrok;

  @override
  String toString() => 'GreskaRepozitorijuma(${vrsta.name}): $poruka';
}
