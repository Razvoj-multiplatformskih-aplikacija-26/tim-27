import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

const ana = Korisnik(id: 'k-1', ime: 'Ana Jovanović', uloga: Uloga.klijent);
const marko = Korisnik(id: 's-1', ime: 'Marko Marković', uloga: Uloga.serviser);

final class LazneSesije implements SesijaRepository {
  LazneSesije({this.sacuvana, this.istekla = false});

  Korisnik? sacuvana;
  bool istekla;
  int odjava = 0;
  final _istekle = StreamController<void>.broadcast();

  void istekni() => _istekle.add(null);

  @override
  Future<Korisnik?> prijavi({required String korisnickoIme, required String lozinka}) async =>
      switch ((korisnickoIme, lozinka)) {
        ('ana', 'reboot-demo') => sacuvana = ana,
        ('marko', 'reboot-demo') => sacuvana = marko,
        _ => null,
      };

  @override
  Future<Korisnik?> trenutna() async {
    if (istekla) throw const GreskaRepozitorijuma('Istekla', vrsta: VrstaGreske.prijavaIstekla);
    return sacuvana;
  }

  @override
  Future<void> odjavi() async {
    odjava++;
    sacuvana = null;
  }

  @override
  Stream<void> get istekle => _istekle.stream;
}

void main() {
  blocTest<SesijaBloc, SesijaState>(
    'prijava ostaje posle ponovnog pokretanja',
    build: () => SesijaBloc(
      repozitorijum: LazneSesije(sacuvana: marko),
      aplikacija: Aplikacija.backoffice,
    ),
    act: (bloc) => bloc.add(const SesijaVracanjeZatrazeno()),
    expect: () => [const Prijavljen(marko)],
  );

  blocTest<SesijaBloc, SesijaState>(
    'backoffice odbija klijenta i odjavljuje ga',
    build: () => SesijaBloc(repozitorijum: LazneSesije(), aplikacija: Aplikacija.backoffice),
    act: (bloc) => bloc.add(const PrijavaZatrazena(korisnickoIme: 'ana', lozinka: 'reboot-demo')),
    expect: () => [const Odjavljen(prijavaUToku: true), const Odjavljen(razlog: RazlogOdjave.pogresnaAplikacija)],
    verify: (bloc) => expect((bloc.repozitorijum as LazneSesije).odjava, 1),
  );

  blocTest<SesijaBloc, SesijaState>(
    'pogrešna lozinka',
    build: () => SesijaBloc(repozitorijum: LazneSesije(), aplikacija: Aplikacija.mobilna),
    act: (bloc) => bloc.add(const PrijavaZatrazena(korisnickoIme: 'ana', lozinka: 'x')),
    expect: () => [const Odjavljen(prijavaUToku: true), const Odjavljen(razlog: RazlogOdjave.pogresniPodaci)],
  );

  blocTest<SesijaBloc, SesijaState>(
    'istekla prijava vraća na prijavu i kaže zašto',
    build: () => SesijaBloc(
      repozitorijum: LazneSesije(sacuvana: ana),
      aplikacija: Aplikacija.mobilna,
    ),
    act: (bloc) async {
      bloc.add(const SesijaVracanjeZatrazeno());
      await bloc.stream.firstWhere((s) => s is Prijavljen);
      (bloc.repozitorijum as LazneSesije).istekni();
    },
    expect: () => [const Prijavljen(ana), const Odjavljen(razlog: RazlogOdjave.istekla)],
  );

  blocTest<SesijaBloc, SesijaState>(
    'sačuvana prijava koja je istekla',
    build: () => SesijaBloc(repozitorijum: LazneSesije(istekla: true), aplikacija: Aplikacija.mobilna),
    act: (bloc) => bloc.add(const SesijaVracanjeZatrazeno()),
    expect: () => [const Odjavljen(razlog: RazlogOdjave.istekla)],
  );

  blocTest<SesijaBloc, SesijaState>(
    'odjava',
    build: () => SesijaBloc(
      repozitorijum: LazneSesije(sacuvana: ana),
      aplikacija: Aplikacija.mobilna,
    ),
    act: (bloc) async {
      bloc.add(const SesijaVracanjeZatrazeno());
      await bloc.stream.firstWhere((s) => s is Prijavljen);
      bloc.add(const OdjavaZatrazena());
    },
    expect: () => [const Prijavljen(ana), const Odjavljen(razlog: RazlogOdjave.odjava)],
  );
}
