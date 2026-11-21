import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'lazni_repozitorijum.dart';

/// Bloc obrađuje događaje različitih tipova istovremeno, pa test sačeka da se tabla učita.
Future<void> ucitaj(TablaNalogaBloc bloc) async {
  bloc.add(const TablaZatrazena());
  await bloc.stream.firstWhere((s) => s is TablaUcitana);
}

void main() {
  TablaNalogaBloc napravi(LazniRepozitorijum repozitorijum) =>
      TablaNalogaBloc(repozitorijum: repozitorijum, serviser: serviser, sada: () => sada);

  blocTest<TablaNalogaBloc, TablaNalogaState>(
    'učitava naloge po fazama i računa akcije',
    build: () => napravi(LazniRepozitorijum([nalog('n-2', stanje: const SpremanZaPreuzimanje()), nalog('n-1')])),
    act: (bloc) => bloc.add(const TablaZatrazena()),
    expect: () => [
      const TablaUcitavanje(),
      isA<TablaUcitana>().having((s) => s.nalozi.map((n) => n.id.value), 'redosled', ['n-1', 'n-2']).having(
        (s) => s.akcije[const NalogId('n-2')],
        'akcije',
        {AkcijaOsoblja.izdaj},
      ),
    ],
  );

  blocTest<TablaNalogaBloc, TablaNalogaState>(
    'kretanje tastaturom menja izbor i ne izlazi van liste',
    build: () => napravi(LazniRepozitorijum([nalog('n-1'), nalog('n-2')])),
    act: (bloc) async {
      await ucitaj(bloc);
      bloc
        ..add(const IzborPomeren(1))
        ..add(const IzborPomeren(1))
        ..add(const IzborPomeren(1));
    },
    skip: 2,
    expect: () => [
      isA<TablaUcitana>().having((s) => s.izabraniId, 'izabran', const NalogId('n-1')),
      isA<TablaUcitana>().having((s) => s.izabraniId, 'izabran', const NalogId('n-2')),
    ],
  );

  blocTest<TablaNalogaBloc, TablaNalogaState>(
    'preuzimanje naloga čuva izbor i javlja uspeh',
    build: () => napravi(LazniRepozitorijum([nalog('n-1')])),
    act: (bloc) async {
      await ucitaj(bloc);
      bloc.add(const NalogIzabran(NalogId('n-1')));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AkcijaZatrazena(NalogId('n-1'), AkcijaOsoblja.preuzmi));
    },
    skip: 3,
    expect: () => [
      isA<TablaUcitana>().having((s) => s.nalogUToku, 'u toku', const NalogId('n-1')),
      isA<TablaUcitana>()
          .having((s) => s.izabrani?.stanje, 'stanje', isA<Dijagnostika>())
          .having((s) => s.izabrani?.serviserId, 'serviser', serviser.id)
          .having((s) => s.obavestenje, 'obaveštenje', isA<AkcijaTableUspela>()),
    ],
  );

  blocTest<TablaNalogaBloc, TablaNalogaState>(
    'šesti aktivni nalog se odbija pravilom iz domena',
    build: () => napravi(
      LazniRepozitorijum([
        for (var i = 0; i < 5; i++) nalog('a-$i', stanje: const Dijagnostika(), serviserId: serviser.id),
        nalog('n-1'),
      ]),
    ),
    act: (bloc) async {
      await ucitaj(bloc);
      bloc.add(const AkcijaZatrazena(NalogId('n-1'), AkcijaOsoblja.preuzmi));
    },
    skip: 3,
    expect: () => [
      isA<TablaUcitana>().having(
        (s) => s.obavestenje,
        'obaveštenje',
        const AkcijaTableOdbijena(PreviseAktivnihNaloga(5, granica: 5)),
      ),
    ],
  );

  blocTest<TablaNalogaBloc, TablaNalogaState>(
    'greška repozitorijuma pri akciji ne ruši tablu',
    build: () => napravi(LazniRepozitorijum([nalog('n-1')])),
    act: (bloc) async {
      await ucitaj(bloc);
      (bloc.repozitorijum as LazniRepozitorijum).neuspesnihZahteva = 1;
      bloc.add(const AkcijaZatrazena(NalogId('n-1'), AkcijaOsoblja.preuzmi));
    },
    skip: 3,
    expect: () => [isA<TablaUcitana>().having((s) => s.obavestenje, 'obaveštenje', isA<AkcijaTableNijeUspela>())],
  );

  blocTest<TablaNalogaBloc, TablaNalogaState>(
    'kada server odbije preuzimanje, tabla prikazuje razlog i ponovo se učitava',
    build: () => napravi(LazniRepozitorijum([nalog('n-1')])),
    act: (bloc) async {
      await ucitaj(bloc);
      final repozitorijum = bloc.repozitorijum as LazniRepozitorijum;
      repozitorijum.odbijSledece = const NalogVecPreuzet();
      repozitorijum.promeniSpolja(nalog('n-1', stanje: const Dijagnostika(), serviserId: const ServiserId('s-2')));
      bloc.add(const AkcijaZatrazena(NalogId('n-1'), AkcijaOsoblja.preuzmi));
    },
    skip: 2,
    expect: () => [
      isA<TablaUcitana>().having((s) => s.nalogUToku, 'u toku', const NalogId('n-1')),
      isA<TablaUcitana>()
          .having((s) => s.obavestenje, 'obaveštenje', const AkcijaTableOdbijena(NalogVecPreuzet()))
          .having((s) => s.nalogUToku, 'u toku', isNull),
    ],
  );
}
