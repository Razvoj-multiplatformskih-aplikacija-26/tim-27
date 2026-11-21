import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final sada = DateTime.utc(2026, 11, 21, 10);
  final ponuda = Ponuda.proveri(iznos: 8500, opis: 'Zamena ventilatora', poslataU: sada).vrednostIliNull!;
  RadniNalog nalog(StanjeNaloga stanje) => RadniNalog(
    id: const NalogId('RN-2001'),
    klijentId: const KlijentId('k-1'),
    serviserId: const ServiserId('s-1'),
    uredjaj: Uredjaj.proveri(vrsta: VrstaUredjaja.laptop, naziv: 'Lenovo ThinkPad T14').vrednostIliNull!,
    opisKvara: OpisKvara.proveri('Laptop se gasi posle par minuta.').vrednostIliNull!,
    primljenU: sada,
    stanje: stanje,
  );

  test('svako stanje prolazi kroz ugovor i nazad', () {
    for (final stanje in <StanjeNaloga>[
      const Primljen(),
      const Dijagnostika(),
      CekaOdobrenje(ponuda),
      UPopravci(ponuda),
      OdbijenaPonuda(ponuda),
      const SpremanZaPreuzimanje(),
      Preuzet(sada),
      const Otkazan('Klijent odustao'),
    ]) {
      final original = nalog(stanje);
      expect(NalogDto.fromJson(original.toDto().toJson()).toDomain(), original);
    }
  });

  test('svaka greška domena prolazi kroz ProblemDto i nazad', () {
    final greske = <DomenskaGreska>[
      const OpisKvaraPrekratak(3),
      const OpisKvaraPredugacak(600),
      const NazivUredjajaObavezan(),
      const NeispravanIznos(0),
      const OpisPonudeObavezan(),
      const PreviseAktivnihNaloga(5, granica: 5),
      const RokZaOdgovorIstekao(),
      const NemaPonudeZaOdgovor(),
      const NalogVecPreuzet(),
      const NemaDelaNaStanju(),
      NedozvoljenPrelaz(iz: const Primljen(), u: UPopravci(ponuda)),
      const NemaPrava(),
      const NalogNijePronadjen(),
    ];
    for (final greska in greske) {
      final problem = ProblemDto.fromJson(greska.toProblem().toJson());
      expect(problem.toDomenskaGreska(), greska, reason: problem.kod);
    }
  });

  test('nepoznat kôd (noviji server) nije greška domena', () {
    const problem = ProblemDto(status: 409, kod: 'novo-pravilo', naslov: 'New rule');
    expect(problem.toDomenskaGreska(), isNull);
  });

  test('zapis koji krši pravilo domena nije ispravan odgovor', () {
    final json = nalog(const Primljen()).toDto().toJson()..['opisKvara'] = 'kratko';
    expect(() => NalogDto.fromJson(json).toDomain(), throwsFormatException);
  });
}
