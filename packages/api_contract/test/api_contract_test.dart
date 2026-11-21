import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

void main() {
  test('nalog prolazi kroz JSON bez gubitka', () {
    final nalog = NalogDto(
      id: 'RN-2001',
      klijentId: 'k-1',
      serviserId: 's-1',
      vrstaUredjaja: 'laptop',
      nazivUredjaja: 'Lenovo ThinkPad T14',
      opisKvara: 'Gasi se posle par minuta.',
      primljenU: DateTime.utc(2026, 11, 20, 9),
      stanje: StanjeDto(
        vrsta: VrsteStanja.cekaOdobrenje,
        ponuda: PonudaDto(iznosDinara: 8500, opis: 'Ventilator', poslataU: DateTime.utc(2026, 11, 21, 10)),
      ),
    );
    final nazad = NalogDto.fromJson(nalog.toJson());
    expect(nazad.toJson(), nalog.toJson());
    expect(nalog.toJson()['primljenU'], '2026-11-20T09:00:00.000Z');
  });

  test('greška nosi kôd i granicu, a ne poruku za korisnika', () {
    const problem = ProblemDto(
      status: 409,
      kod: KodoviGresaka.previseAktivnihNaloga,
      naslov: 'Too many active work orders',
      vrednost: 5,
      maks: 5,
    );
    final json = problem.toJson();
    expect(json['kod'], 'previse-aktivnih-naloga');
    expect(ProblemDto.fromJson(json).maks, 5);
  });

  test('vreme bez vremenske zone se odbija', () {
    expect(
      () => PonudaDto.fromJson({'iznosDinara': 1, 'opis': 'x', 'poslataU': '2026-11-21T10:00:00'}),
      throwsFormatException,
    );
  });
}
