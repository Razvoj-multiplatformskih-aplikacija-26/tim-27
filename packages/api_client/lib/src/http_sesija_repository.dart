import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

import 'api_klijent.dart';

final class HttpSesijaRepository implements SesijaRepository {
  const HttpSesijaRepository(this._api);

  final ApiKlijent _api;

  @override
  Future<Korisnik?> prijavi({required String korisnickoIme, required String lozinka}) async {
    final prijava = PrijavaDto(korisnickoIme: korisnickoIme, lozinka: lozinka, kolacic: _api.prijavaUKolacicu);
    final odgovor = await _api.post(ApiPutanje.sesije, telo: prijava.toJson());
    if (odgovor case ApiNepoznato(problem: ProblemDto(kod: KodoviGresaka.pogresniPodaci))) return null;
    final sesija = prihvaceno(odgovor, (json) => SesijaDto.fromJson(objekat(json)));
    if (sesija.token case final token?) await _api.tokeni.upisi(token);
    return procitajJson(sesija.korisnik.toDomain);
  }

  @override
  Future<Korisnik?> trenutna() async {
    if (!_api.prijavaUKolacicu && await _api.tokeni.procitaj() == null) return null;
    try {
      final odgovor = await _api.get(ApiPutanje.trenutnaSesija);
      final korisnik = prihvaceno(odgovor, (json) => SesijaDto.fromJson(objekat(json)).korisnik.toDomain());
      return korisnik;
    } on GreskaRepozitorijuma catch (greska) {
      if (greska.vrsta != VrstaGreske.prijavaIstekla) rethrow;
      await _api.tokeni.obrisi();
      // Kolačić koji je istekao pregledač sam obriše, pa server tada kaže samo da prijave nema.
      if (greska.uzrok == KodoviGresaka.prijavaIstekla) rethrow;
      return null;
    }
  }

  @override
  Future<void> odjavi() async {
    try {
      await _api.delete(ApiPutanje.trenutnaSesija);
    } on GreskaRepozitorijuma {
      // Odjava na uređaju uspeva i kada server nije dostupan ili je prijava već istekla.
    } finally {
      await _api.tokeni.obrisi();
    }
  }

  @override
  Stream<void> get istekle => _api.istekle;
}
