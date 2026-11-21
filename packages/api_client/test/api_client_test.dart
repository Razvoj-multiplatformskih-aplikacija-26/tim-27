import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  final sada = DateTime.utc(2026, 11, 21, 10);
  final nalog = RadniNalog(
    id: const NalogId('RN-2001'),
    klijentId: const KlijentId('k-1'),
    uredjaj: Uredjaj.proveri(vrsta: VrstaUredjaja.laptop, naziv: 'Lenovo ThinkPad T14').vrednostIliNull!,
    opisKvara: OpisKvara.proveri('Laptop se gasi posle par minuta.').vrednostIliNull!,
    primljenU: sada,
  );

  http.Response problem(ProblemDto problem) =>
      http.Response(jsonEncode(problem.toJson()), problem.status, headers: {'content-type': ProblemDto.mediaType});

  ApiKlijent klijent(MockClientHandler odgovor, {TokenStore? tokeni}) => ApiKlijent(
    adresa: Uri.parse('http://server'),
    httpKlijent: MockClient(odgovor),
    tokeni: tokeni,
    prijavaUKolacicu: false,
  );

  test('preuzimanje ide na svoju adresu sa tokenom iz skladišta', () async {
    final tokeni = MemorijskiTokenStore();
    await tokeni.upisi('abc');
    late http.Request poslat;
    final repozitorijum = HttpNalogRepository(
      klijent((zahtev) async {
        poslat = zahtev;
        return http.Response(jsonEncode(nalog.copyWith(stanje: const Dijagnostika()).toDto().toJson()), 200);
      }, tokeni: tokeni),
    );
    final rezultat = await repozitorijum.sacuvaj(nalog.copyWith(stanje: const Dijagnostika()));
    expect(poslat.url.path, '/api/v1/nalozi/RN-2001/preuzimanje');
    expect(poslat.headers['Authorization'], 'Bearer abc');
    expect(rezultat.vrednostIliNull?.stanje, isA<Dijagnostika>());
  });

  test('odbijeno pravilom postaje ista greška domena', () async {
    final repozitorijum = HttpNalogRepository(klijent((_) async => problem(const NalogVecPreuzet().toProblem())));
    expect(
      await repozitorijum.sacuvaj(nalog.copyWith(stanje: const Dijagnostika())),
      const Neuspeh<RadniNalog>(NalogVecPreuzet()),
    );
  });

  test('nepoznat kôd sa novijeg servera ne ruši aplikaciju', () async {
    final repozitorijum = HttpNalogRepository(
      klijent((_) async => problem(const ProblemDto(status: 409, kod: 'novo-pravilo', naslov: 'New rule'))),
    );
    expect(
      repozitorijum.sacuvaj(nalog.copyWith(stanje: const Dijagnostika())),
      throwsA(isA<GreskaRepozitorijuma>().having((g) => g.vrsta, 'vrsta', VrstaGreske.odbijeno)),
    );
  });

  test('nedostupan server je GreskaRepozitorijuma, ne beskonačno učitavanje', () async {
    final repozitorijum = HttpNalogRepository(klijent((_) async => throw http.ClientException('connection refused')));
    expect(
      repozitorijum.sviNalozi(),
      throwsA(isA<GreskaRepozitorijuma>().having((g) => g.vrsta, 'vrsta', VrstaGreske.nedostupan)),
    );
  });

  test('istekla prijava javlja događaj i baca odgovarajuću grešku', () async {
    final api = klijent(
      (_) async => problem(const ProblemDto(status: 401, kod: KodoviGresaka.prijavaIstekla, naslov: 'Expired')),
    );
    final javljeno = expectLater(api.istekle, emits(null));
    await expectLater(
      HttpNalogRepository(api).sviNalozi(),
      throwsA(isA<GreskaRepozitorijuma>().having((g) => g.vrsta, 'vrsta', VrstaGreske.prijavaIstekla)),
    );
    await javljeno;
  });

  test('prijava upisuje token, odjava ga briše', () async {
    final tokeni = MemorijskiTokenStore();
    final api = klijent((zahtev) async {
      if (zahtev.method == 'DELETE') return http.Response('', 204);
      final sesija = SesijaDto(
        korisnik: const KorisnikDto(id: 'k-1', ime: 'Ana', uloga: 'klijent'),
        istice: sada,
        token: 'tok',
      );
      return http.Response(jsonEncode(sesija.toJson()), 201);
    }, tokeni: tokeni);
    final sesije = HttpSesijaRepository(api);
    final korisnik = await sesije.prijavi(korisnickoIme: 'ana', lozinka: 'x');
    expect(korisnik?.uloga, Uloga.klijent);
    expect(await tokeni.procitaj(), 'tok');
    await sesije.odjavi();
    expect(await tokeni.procitaj(), isNull);
  });
}
