import 'package:domain/domain.dart';

/// Port kroz koji Blocovi dobijaju podatke. Lažna implementacija je u svakoj aplikaciji
/// (lib/data), a u KT2 je zamenjuje implementacija koja zove server, bez izmene ekrana.
abstract interface class NalogRepository {
  Future<List<RadniNalog>> naloziKlijenta(KlijentId klijentId);

  Future<List<RadniNalog>> sviNalozi();

  Future<RadniNalog?> nadji(NalogId id);

  Future<RadniNalog> sacuvaj(RadniNalog nalog);

  Future<RadniNalog> prijavi({required Klijent klijent, required Uredjaj uredjaj, required OpisKvara opisKvara});

  Future<List<Klijent>> klijenti();

  Future<List<Serviser>> serviseri();
}

/// Zahtev ka izvoru podataka nije uspeo (nema mreže, server ne odgovara...).
final class GreskaRepozitorijuma implements Exception {
  const GreskaRepozitorijuma(this.poruka);

  final String poruka;

  @override
  String toString() => 'GreskaRepozitorijuma: $poruka';
}
