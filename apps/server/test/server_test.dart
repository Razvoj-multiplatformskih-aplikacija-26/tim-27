@Tags(['db'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';
import 'package:test/test.dart';

// Testovi nad pravom bazom: potreban je PostgreSQL iz Docker Compose-a (docker compose up db)
// i .env u korenu repozitorijuma. Svako pokretanje pravi praznu bazu reboot_test.

late Pool<void> baza;
late RelicServer server;
late Uri adresa;
late Konfiguracija konfiguracija;

Future<String> prijava(String ime) async {
  final odgovor = await http.post(
    adresa.replace(path: ApiPutanje.sesije),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(PrijavaDto(korisnickoIme: ime, lozinka: konfiguracija.demoLozinka!).toJson()),
  );
  return SesijaDto.fromJson(jsonDecode(odgovor.body) as Map<String, Object?>).token!;
}

Map<String, String> kao(String token) => {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};

String kodIz(http.Response odgovor) => (jsonDecode(odgovor.body) as Map<String, Object?>)['kod']! as String;

Future<http.Response> post(String token, String putanja, [Object? telo]) => http.post(
  adresa.replace(path: putanja),
  headers: kao(token),
  body: telo == null ? null : jsonEncode(telo),
);

void main() {
  setUpAll(() async {
    konfiguracija = Konfiguracija.izOkruzenja(okruzenjeServera());
    final glavna = Uri.parse(konfiguracija.adresaBaze);
    final admin = await Connection.openFromUrl(glavna.toString());
    await admin.execute('DROP DATABASE IF EXISTS reboot_test WITH (FORCE)');
    await admin.execute('CREATE DATABASE reboot_test');
    await admin.close();
    baza = Pool<void>.withUrl(glavna.replace(path: '/reboot_test').toString());
    await primeniMigracije(baza, Directory('migrations'));
    await unesiPocetnePodatke(baza, demoLozinka: konfiguracija.demoLozinka, sada: DateTime.now().toUtc());
    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    await server.mountAndStart(
      napraviRukovaoca(
        NaloziRukovaoci(baza: NaloziBaza(baza), obavestenja: LaznaSmsObavestenja(kljuc: null)),
        SesijeRukovaoci(baza: baza, tajna: konfiguracija.jwtTajna, trajanje: const Duration(minutes: 5)),
        dozvoljeniIzvori: const ['http://localhost:8081'],
      ),
    );
    adresa = Uri.parse('http://127.0.0.1:${server.port}');
  });

  tearDownAll(() async {
    await server.close();
    await baza.close();
  });

  test('početni podaci: bar deset naloga i svako stanje', () async {
    final odgovor = await http.get(adresa.replace(path: ApiPutanje.nalozi), headers: kao(await prijava('nikola')));
    final nalozi = [
      for (final n in jsonDecode(odgovor.body) as List<Object?>) NalogDto.fromJson(n! as Map<String, Object?>),
    ];
    expect(nalozi.length, greaterThanOrEqualTo(10));
    expect({for (final n in nalozi) n.stanje.vrsta}, hasLength(8));
  });

  test('od istovremenih preuzimanja istog naloga prolazi samo jedno', () async {
    final tokeni = [await prijava('jelena'), await prijava('nikola')];
    final odgovori = await Future.wait([
      for (var i = 0; i < 6; i++) post(tokeni[i % 2], ApiPutanje.preuzimanje('RN-2003')),
    ]);
    expect(odgovori.where((o) => o.statusCode == 200), hasLength(1));
    expect({for (final o in odgovori.where((o) => o.statusCode != 200)) kodIz(o)}, {KodoviGresaka.nalogVecPreuzet});
  });

  test('serviser ni istovremenim zahtevima ne prelazi pet aktivnih naloga', () async {
    // Marko ima četiri aktivna naloga, pa od tri slobodna sme da preuzme samo jedan.
    final marko = await prijava('marko');
    final odgovori = await Future.wait([
      for (final id in ['RN-2001', 'RN-2002', 'RN-2004']) post(marko, ApiPutanje.preuzimanje(id)),
    ]);
    expect(odgovori.where((o) => o.statusCode == 200), hasLength(1));
    final odbijen = odgovori.firstWhere((o) => o.statusCode == 409);
    final problem = ProblemDto.fromJson(jsonDecode(odbijen.body) as Map<String, Object?>);
    expect((problem.kod, problem.maks), (KodoviGresaka.previseAktivnihNaloga, 5));
  });

  test('klijent ne može akciju osoblja ni mimo aplikacije', () async {
    final ana = await prijava('ana');
    expect(kodIz(await post(ana, ApiPutanje.zavrsetak('RN-2011'))), KodoviGresaka.nemaPrava);
    expect(kodIz(await post(ana, ApiPutanje.izdavanje('RN-2013'))), KodoviGresaka.nemaPrava);
  });

  test('klijent odgovara samo na ponudu za svoj nalog', () async {
    // RN-2009 je Miličin nalog koji čeka odobrenje.
    final petar = await prijava('petar');
    final tudj = await post(petar, ApiPutanje.odgovor('RN-2009'), const OdgovorDto(prihvata: true).toJson());
    expect((tudj.statusCode, kodIz(tudj)), (403, KodoviGresaka.nemaPrava));
    final milica = await prijava('milica');
    final svoj = await post(milica, ApiPutanje.odgovor('RN-2009'), const OdgovorDto(prihvata: true).toJson());
    expect(svoj.statusCode, 200);
  });

  test('klijent ne vidi tuđ nalog', () async {
    final odgovor = await http.get(
      adresa.replace(path: ApiPutanje.nalog('RN-2009')),
      headers: kao(await prijava('ana')),
    );
    expect(odgovor.statusCode, 404);
  });

  test('pravilo iz domena: prekratak opis kvara, isti kôd kao u aplikaciji', () async {
    final odgovor = await post(
      await prijava('ana'),
      ApiPutanje.nalozi,
      const NoviNalogDto(vrstaUredjaja: 'laptop', nazivUredjaja: 'Dell', opisKvara: 'kratko').toJson(),
    );
    final problem = ProblemDto.fromJson(jsonDecode(odgovor.body) as Map<String, Object?>);
    expect((odgovor.statusCode, problem.kod, problem.min), (422, KodoviGresaka.opisKvaraPrekratak, 10));
  });

  test('istekao ili lažan token se odbija', () async {
    final istekao = JWT({
      'ime': 'Marko',
      'uloga': 'sefServisa',
      'telefon': '',
    }, subject: 's-1').sign(SecretKey(konfiguracija.jwtTajna), expiresIn: const Duration(seconds: -1));
    final lazan = JWT({
      'ime': 'Ana',
      'uloga': 'sefServisa',
      'telefon': '',
    }, subject: 'k-1').sign(SecretKey('neka-druga-tajna-koju-server-ne-zna-123456'));
    for (final token in [istekao, lazan]) {
      final odgovor = await http.get(adresa.replace(path: ApiPutanje.nalozi), headers: kao(token));
      expect((odgovor.statusCode, kodIz(odgovor)), (401, KodoviGresaka.prijavaIstekla));
    }
  });

  test('pogrešna lozinka', () async {
    final odgovor = await http.post(
      adresa.replace(path: ApiPutanje.sesije),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(const PrijavaDto(korisnickoIme: 'ana', lozinka: 'pogresna').toJson()),
    );
    expect(kodIz(odgovor), KodoviGresaka.pogresniPodaci);
  });

  test('lozinke su u bazi samo kao Argon2id heš', () async {
    final redovi = await baza.execute('SELECT lozinka_hes FROM korisnici WHERE lozinka_hes IS NOT NULL');
    expect(redovi, isNotEmpty);
    for (final red in redovi) {
      expect(red[0]! as String, startsWith(r'$argon2id$'));
    }
  });
}
