import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' hide Session;
import 'package:relic/relic.dart';

import 'http.dart';
import 'lozinke.dart';

/// Prijava koju je izdao ovaj server: potpisan JWT (HS256) sa rokom trajanja iz podešavanja.
final class Sesija {
  const Sesija({required this.korisnik, required this.istice});

  final Korisnik korisnik;
  final DateTime istice;
}

final trenutnaSesija = ContextProperty<Sesija>('sesija');

const _prijavaPotrebna = ProblemDto(status: 401, kod: KodoviGresaka.prijavaPotrebna, naslov: 'Sign in required');
const _prijavaIstekla = ProblemDto(status: 401, kod: KodoviGresaka.prijavaIstekla, naslov: 'Session expired');
const _pogresniPodaci = ProblemDto(status: 401, kod: KodoviGresaka.pogresniPodaci, naslov: 'Invalid credentials');
const _algoritam = JWTAlgorithm.HS256;

final class SesijeRukovaoci {
  SesijeRukovaoci({required this.baza, required String tajna, required this.trajanje, this.bezbedanKolacic = false})
    : _kljuc = SecretKey(tajna),
      _hesNepostojeceg = hesLozinke('nema takvog naloga');

  final Pool<void> baza;
  final Duration trajanje;
  final bool bezbedanKolacic;
  final SecretKey _kljuc;

  /// Za nepostojeće korisničko ime se ipak proverava heš, pa odgovor traje isto i ne otkriva ko postoji.
  final Future<String> _hesNepostojeceg;

  /// Svaki zaštićen poziv: ko zove zna se samo iz potpisanog tokena koji je izdao server.
  Handler prijavljen(Handler rukovalac) => (Request zahtev) async {
    final token = _tokenIz(zahtev);
    if (token == null) return _neovlasceno(_prijavaPotrebna);
    final sesija = _proveri(token);
    if (sesija == null) return _neovlasceno(_prijavaIstekla);
    trenutnaSesija[zahtev] = sesija;
    return rukovalac(zahtev);
  };

  Future<Response> prijava(Request zahtev) async {
    final telo = PrijavaDto.fromJson(await procitajObjekat(zahtev));
    final redovi = await baza.execute(
      Sql.named(
        'SELECT id, ime, uloga, telefon, lozinka_hes FROM korisnici '
        'WHERE korisnicko_ime = @ime AND lozinka_hes IS NOT NULL',
      ),
      parameters: {'ime': telo.korisnickoIme.trim()},
    );
    final red = redovi.firstOrNull;
    final hes = red?[4] as String? ?? await _hesNepostojeceg;
    final poklapa = await proveriLozinku(telo.lozinka, hes);
    if (red == null || !poklapa) return _neovlasceno(_pogresniPodaci);
    final korisnik = Korisnik(
      id: red[0]! as String,
      ime: red[1]! as String,
      uloga: Uloga.values.byName(red[2]! as String),
      telefon: red[3]! as String,
    );
    final token = JWT({
      'ime': korisnik.ime,
      'uloga': korisnik.uloga.name,
      'telefon': korisnik.telefon,
    }, subject: korisnik.id).sign(_kljuc, algorithm: _algoritam, expiresIn: trajanje);
    final istice = _proveri(token)!.istice;
    final dto = SesijaDto(korisnik: korisnik.toDto(), istice: istice, token: telo.kolacic ? null : token);
    final odgovor = json(201, dto.toJson());
    if (!telo.kolacic) return odgovor;
    return odgovor.copyWith(
      headers: odgovor.headers.transform((h) => h.setCookie = _kolacic(token, trajanje: trajanje.inSeconds)),
    );
  }

  Future<Response> trenutna(Request zahtev) async {
    final sesija = trenutnaSesija.get(zahtev);
    return json(200, SesijaDto(korisnik: sesija.korisnik.toDto(), istice: sesija.istice).toJson());
  }

  /// Token je bez stanja na serveru: odjava briše kolačić, a aplikacija briše token iz skladišta.
  Future<Response> odjava(Request zahtev) async =>
      Response.noContent(headers: Headers.build((h) => h.setCookie = _kolacic('', trajanje: 0)));

  SetCookieHeader _kolacic(String vrednost, {required int trajanje}) => SetCookieHeader(
    name: ApiKolacici.sesija,
    value: vrednost,
    path: Uri.parse('/'),
    maxAge: trajanje,
    httpOnly: true,
    secure: bezbedanKolacic,
    sameSite: SameSite.lax,
  );

  Response _neovlasceno(ProblemDto problem) {
    final odgovor = problemOdgovor(problem);
    return odgovor.copyWith(headers: odgovor.headers.transform((h) => h['WWW-Authenticate'] = ['Bearer']));
  }

  Sesija? _proveri(String token) {
    try {
      if (JWT.decode(token).header?['alg'] != _algoritam.name) return null;
      return switch (JWT.verify(token, _kljuc).payload) {
        {
          'sub': final String id,
          'ime': final String ime,
          'uloga': final String uloga,
          'telefon': final String telefon,
          'exp': final int exp,
        } =>
          Sesija(
            korisnik: Korisnik(id: id, ime: ime, uloga: Uloga.values.byName(uloga), telefon: telefon),
            istice: DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true),
          ),
        _ => null,
      };
    } on JWTException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  String? _tokenIz(Request zahtev) => switch (zahtev.headers.authorization) {
    BearerAuthorizationHeader(:final token) => token,
    _ => switch (zahtev.headers.cookie?.getCookie(ApiKolacici.sesija)?.value) {
      final vrednost? when vrednost.isNotEmpty => vrednost,
      _ => null,
    },
  };
}
