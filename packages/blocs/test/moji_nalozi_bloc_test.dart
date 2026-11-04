import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'lazni_repozitorijum.dart';

void main() {
  MojiNaloziBloc napravi(LazniRepozitorijum repozitorijum) =>
      MojiNaloziBloc(repozitorijum: repozitorijum, klijent: klijent, sada: () => sada);

  blocTest<MojiNaloziBloc, MojiNaloziState>(
    'učitava naloge klijenta',
    build: () => napravi(LazniRepozitorijum([nalog('n-1'), nalog('n-2', stanje: CekaOdobrenje(ponuda))])),
    act: (bloc) => bloc.add(const MojiNaloziZatrazeni()),
    expect: () => [
      const MojiNaloziUcitavanje(),
      isA<MojiNaloziUcitani>().having((s) => s.nalozi.length, 'broj naloga', 2).having(
        (s) => s.zaOdgovor,
        'za odgovor',
        {const NalogId('n-2')},
      ),
    ],
  );

  blocTest<MojiNaloziBloc, MojiNaloziState>(
    'prazan prikaz kad klijent nema naloga',
    build: () => napravi(LazniRepozitorijum(const [])),
    act: (bloc) => bloc.add(const MojiNaloziZatrazeni()),
    expect: () => const [MojiNaloziUcitavanje(), MojiNaloziPrazno()],
  );

  blocTest<MojiNaloziBloc, MojiNaloziState>(
    'greška kad zahtev ne uspe',
    build: () => napravi(LazniRepozitorijum(const [])..neuspesnihZahteva = 1),
    act: (bloc) => bloc.add(const MojiNaloziZatrazeni()),
    expect: () => [const MojiNaloziUcitavanje(), isA<MojiNaloziGreska>()],
  );

  blocTest<MojiNaloziBloc, MojiNaloziState>(
    'prihvatanje ponude prebacuje nalog u popravku',
    build: () => napravi(LazniRepozitorijum([nalog('n-1', stanje: CekaOdobrenje(ponuda), serviserId: serviser.id)])),
    act: (bloc) => bloc
      ..add(const MojiNaloziZatrazeni())
      ..add(const OdgovorNaPonuduPoslat(NalogId('n-1'), prihvata: true)),
    skip: 2,
    expect: () => [
      isA<MojiNaloziUcitani>().having((s) => s.nalogUToku, 'u toku', const NalogId('n-1')),
      isA<MojiNaloziUcitani>()
          .having((s) => s.nalozi.single.stanje, 'stanje', UPopravci(ponuda))
          .having((s) => s.obavestenje, 'obaveštenje', isA<OdgovorSacuvan>()),
    ],
  );

  blocTest<MojiNaloziBloc, MojiNaloziState>(
    'posle roka od 48 sati odgovor se odbija greškom iz domena',
    build: () => MojiNaloziBloc(
      repozitorijum: LazniRepozitorijum([nalog('n-1', stanje: CekaOdobrenje(ponuda), serviserId: serviser.id)]),
      klijent: klijent,
      sada: () => sada.add(const Duration(hours: 49)),
    ),
    act: (bloc) => bloc
      ..add(const MojiNaloziZatrazeni())
      ..add(const OdgovorNaPonuduPoslat(NalogId('n-1'), prihvata: true)),
    skip: 3,
    expect: () => [
      isA<MojiNaloziUcitani>().having((s) => s.obavestenje, 'obaveštenje', const AkcijaOdbijena(RokZaOdgovorIstekao())),
    ],
  );

  blocTest<MojiNaloziBloc, MojiNaloziState>(
    'prijava uređaja pravi primljen nalog',
    build: () => napravi(LazniRepozitorijum(const [])),
    act: (bloc) => bloc
      ..add(const MojiNaloziZatrazeni())
      ..add(UredjajPrijavljen(uredjaj: uredjaj, opisKvara: opis)),
    skip: 2,
    expect: () => [
      isA<MojiNaloziUcitani>()
          .having((s) => s.nalozi.single.stanje, 'stanje', isA<Primljen>())
          .having((s) => s.obavestenje, 'obaveštenje', isA<NalogNapravljen>()),
    ],
  );
}
