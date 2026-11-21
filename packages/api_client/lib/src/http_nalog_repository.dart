import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

import 'api_klijent.dart';

/// Implementacija porta NalogRepository nad serverom. Svaka promena stanja ide na svoju
/// adresu, a server na njoj ponovo pokreće istu akciju iz domena.
final class HttpNalogRepository implements NalogRepository {
  const HttpNalogRepository(this._api);

  final ApiKlijent _api;

  @override
  Future<List<RadniNalog>> naloziKlijenta(KlijentId klijentId) async =>
      prihvaceno(await _api.get(ApiPutanje.naloziKlijenta(klijentId.value)), _nalozi);

  @override
  Future<List<RadniNalog>> sviNalozi() async => prihvaceno(await _api.get(ApiPutanje.nalozi), _nalozi);

  @override
  Future<RadniNalog?> nadji(NalogId id) async {
    final odgovor = await _api.get(ApiPutanje.nalog(id.value));
    if (odgovor case ApiOdbijeno(greska: NalogNijePronadjen())) return null;
    return prihvaceno(odgovor, _nalog);
  }

  @override
  Future<Rezultat<RadniNalog>> sacuvaj(RadniNalog nalog) async {
    final id = nalog.id.value;
    final odgovor = await switch (nalog.stanje) {
      Dijagnostika() => _api.post(ApiPutanje.preuzimanje(id)),
      CekaOdobrenje(:final ponuda) => _api.post(
        ApiPutanje.ponuda(id),
        telo: NovaPonudaDto(iznosDinara: ponuda.iznos, opis: ponuda.opis).toJson(),
      ),
      UPopravci() => _api.post(ApiPutanje.odgovor(id), telo: const OdgovorDto(prihvata: true).toJson()),
      OdbijenaPonuda() => _api.post(ApiPutanje.odgovor(id), telo: const OdgovorDto(prihvata: false).toJson()),
      SpremanZaPreuzimanje() => _api.post(ApiPutanje.zavrsetak(id)),
      Preuzet() => _api.post(ApiPutanje.izdavanje(id)),
      Otkazan(:final razlog) => _api.post(ApiPutanje.otkazivanje(id), telo: OtkazivanjeDto(razlog: razlog).toJson()),
      Primljen() => throw ArgumentError.value(nalog, 'nalog', 'Nov nalog se prijavljuje, ne čuva'),
    };
    return rezultat(odgovor, _nalog);
  }

  @override
  Future<Rezultat<RadniNalog>> prijavi({
    required Klijent klijent,
    required Uredjaj uredjaj,
    required OpisKvara opisKvara,
  }) async {
    final telo = NoviNalogDto(
      vrstaUredjaja: uredjaj.vrsta.name,
      nazivUredjaja: uredjaj.naziv,
      opisKvara: opisKvara.tekst,
    );
    return rezultat(await _api.post(ApiPutanje.nalozi, telo: telo.toJson()), _nalog);
  }

  @override
  Future<List<Klijent>> klijenti() async => prihvaceno(
    await _api.get(ApiPutanje.klijenti),
    (json) => [for (final k in objekti(json)) KorisnikDto.fromJson(k).toKlijent()],
  );

  @override
  Future<List<Serviser>> serviseri() async => prihvaceno(
    await _api.get(ApiPutanje.serviseri),
    (json) => [for (final s in objekti(json)) KorisnikDto.fromJson(s).toServiser()],
  );

  RadniNalog _nalog(Object? json) => NalogDto.fromJson(objekat(json)).toDomain();

  List<RadniNalog> _nalozi(Object? json) => [for (final n in objekti(json)) NalogDto.fromJson(n).toDomain()];
}
