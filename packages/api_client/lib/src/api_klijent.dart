import 'dart:async';
import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;

import 'platform_client.dart';
import 'token_store.dart';

sealed class ApiOdgovor {
  const ApiOdgovor();
}

final class ApiPrihvaceno extends ApiOdgovor {
  const ApiPrihvaceno(this.json);

  final Object? json;
}

/// Server je odbio poziv pravilom koje ova verzija aplikacije poznaje.
final class ApiOdbijeno extends ApiOdgovor {
  const ApiOdbijeno(this.greska);

  final DomenskaGreska greska;
}

/// Server je odbio poziv kodom koji ova verzija aplikacije ne poznaje (ili greškom prijave).
final class ApiNepoznato extends ApiOdgovor {
  const ApiNepoznato(this.problem);

  final ProblemDto problem;
}

/// Jedino mesto gde aplikacije pričaju sa serverom. Radi na VM-u (http.Client) i u pregledaču
/// (BrowserClient sa kolačićem); izbor radi uslovni import u platform_client.dart.
final class ApiKlijent {
  ApiKlijent({
    required this.adresa,
    TokenStore? tokeni,
    http.Client? httpKlijent,
    this.prijavaUKolacicu = platformaCuvaPrijavuUKolacicu,
    this.rok = const Duration(seconds: 8),
  }) : tokeni = tokeni ?? MemorijskiTokenStore(),
       _http = httpKlijent ?? platformskiHttpKlijent();

  final Uri adresa;
  final TokenStore tokeni;
  final bool prijavaUKolacicu;

  /// Posle ovoliko vremena bez odgovora ekran kaže da server nije dostupan.
  final Duration rok;
  final http.Client _http;
  final _istekle = StreamController<void>.broadcast();

  Stream<void> get istekle => _istekle.stream;

  Future<ApiOdgovor> get(String putanja) => _posalji('GET', putanja);

  Future<ApiOdgovor> post(String putanja, {Map<String, Object?>? telo}) => _posalji('POST', putanja, telo: telo);

  Future<ApiOdgovor> delete(String putanja) => _posalji('DELETE', putanja);

  Future<ApiOdgovor> _posalji(String metod, String putanja, {Map<String, Object?>? telo}) async {
    final zahtev = http.Request(metod, adresa.replace(path: putanja))..headers['Accept'] = 'application/json';
    if (!prijavaUKolacicu) {
      if (await tokeni.procitaj() case final token?) zahtev.headers['Authorization'] = 'Bearer $token';
    }
    if (telo != null) {
      zahtev
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(telo);
    }
    final http.Response odgovor;
    try {
      odgovor = await _http.send(zahtev).then(http.Response.fromStream).timeout(rok);
    } on http.ClientException catch (uzrok) {
      throw GreskaRepozitorijuma('Server nije dostupan', uzrok: uzrok);
    } on TimeoutException catch (uzrok) {
      throw GreskaRepozitorijuma('Server ne odgovara', uzrok: uzrok);
    }
    return _procitaj(odgovor);
  }

  ApiOdgovor _procitaj(http.Response odgovor) {
    final status = odgovor.statusCode;
    final json = procitajJson(() => odgovor.body.isEmpty ? null : jsonDecode(utf8.decode(odgovor.bodyBytes)));
    if (status >= 200 && status < 300) return ApiPrihvaceno(json);
    if (status >= 400 && status < 500 && json is Map<String, Object?>) {
      final problem = procitajJson(() => ProblemDto.fromJson(json));
      if (problem.kod case KodoviGresaka.prijavaIstekla || KodoviGresaka.prijavaPotrebna) {
        _istekle.add(null);
        throw GreskaRepozitorijuma('Prijava ne važi', vrsta: VrstaGreske.prijavaIstekla, uzrok: problem.kod);
      }
      return switch (problem.toDomenskaGreska()) {
        final greska? => ApiOdbijeno(greska),
        null => ApiNepoznato(problem),
      };
    }
    throw GreskaRepozitorijuma('Server je odgovorio sa $status', vrsta: VrstaGreske.greskaServera);
  }
}

T procitajJson<T>(T Function() citaj) {
  try {
    return citaj();
  } on FormatException catch (uzrok) {
    throw GreskaRepozitorijuma('Nečitljiv odgovor', vrsta: VrstaGreske.greskaServera, uzrok: uzrok);
  } on ArgumentError catch (uzrok) {
    throw GreskaRepozitorijuma('Nečitljiv odgovor', vrsta: VrstaGreske.greskaServera, uzrok: uzrok);
  }
}

/// Odgovor na čitanje: greška pravila ovde nije očekivana.
T prihvaceno<T>(ApiOdgovor odgovor, T Function(Object? json) citaj) => switch (odgovor) {
  ApiPrihvaceno(:final json) => procitajJson(() => citaj(json)),
  ApiOdbijeno(:final greska) => throw GreskaRepozitorijuma('Odbijeno: $greska', vrsta: VrstaGreske.odbijeno),
  ApiNepoznato(:final problem) => throw GreskaRepozitorijuma('Odbijeno: ${problem.kod}', vrsta: VrstaGreske.odbijeno),
};

/// Odgovor na promenu: greška pravila postaje Neuspeh, kao kada pravilo proveri klijent.
Rezultat<T> rezultat<T>(ApiOdgovor odgovor, T Function(Object? json) citaj) => switch (odgovor) {
  ApiPrihvaceno(:final json) => Uspeh(procitajJson(() => citaj(json))),
  ApiOdbijeno(:final greska) => Neuspeh(greska),
  ApiNepoznato(:final problem) => throw GreskaRepozitorijuma('Odbijeno: ${problem.kod}', vrsta: VrstaGreske.odbijeno),
};

Map<String, Object?> objekat(Object? json) => switch (json) {
  final Map<String, Object?> objekat => objekat,
  _ => throw FormatException('Očekivan JSON objekat', json),
};

List<Map<String, Object?>> objekti(Object? json) => switch (json) {
  final List<Object?> lista => [for (final stavka in lista) objekat(stavka)],
  _ => throw FormatException('Očekivana JSON lista', json),
};
