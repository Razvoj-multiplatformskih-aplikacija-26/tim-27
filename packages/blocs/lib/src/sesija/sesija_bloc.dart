import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

import '../nalog_repository.dart';
import '../sesija_repository.dart';

part 'sesija_event.dart';
part 'sesija_state.dart';

/// Prijava, njeno vraćanje posle ponovnog pokretanja, istek i odjava. Deli se između obe
/// aplikacije; svaka kaže koja je, a domen (smeDaKoristi) odlučuje ko sme da uđe.
final class SesijaBloc extends Bloc<SesijaEvent, SesijaState> {
  SesijaBloc({required this.repozitorijum, required this.aplikacija}) : super(const SesijaNepoznata()) {
    on<SesijaVracanjeZatrazeno>(_naVracanje);
    on<PrijavaZatrazena>(_naPrijavu);
    on<OdjavaZatrazena>((event, emit) async {
      await _odjaviTiho();
      emit(const Odjavljen(razlog: RazlogOdjave.odjava));
    });
    on<SesijaIstekla>((event, emit) async {
      if (state is! Prijavljen) return;
      await _odjaviTiho();
      emit(const Odjavljen(razlog: RazlogOdjave.istekla));
    });
    _istekle = repozitorijum.istekle.listen((_) => add(const SesijaIstekla()));
  }

  final SesijaRepository repozitorijum;
  final Aplikacija aplikacija;
  late final StreamSubscription<void> _istekle;

  Future<void> _naVracanje(SesijaVracanjeZatrazeno event, Emitter<SesijaState> emit) async {
    try {
      final korisnik = await repozitorijum.trenutna();
      if (korisnik == null) return emit(const Odjavljen());
      await _udji(korisnik, emit);
    } on GreskaRepozitorijuma catch (greska) {
      emit(
        Odjavljen(
          razlog: greska.vrsta == VrstaGreske.prijavaIstekla ? RazlogOdjave.istekla : RazlogOdjave.serverNedostupan,
        ),
      );
    }
  }

  Future<void> _naPrijavu(PrijavaZatrazena event, Emitter<SesijaState> emit) async {
    emit(const Odjavljen(prijavaUToku: true));
    try {
      final korisnik = await repozitorijum.prijavi(korisnickoIme: event.korisnickoIme.trim(), lozinka: event.lozinka);
      if (korisnik == null) return emit(const Odjavljen(razlog: RazlogOdjave.pogresniPodaci));
      await _udji(korisnik, emit);
    } on GreskaRepozitorijuma {
      emit(const Odjavljen(razlog: RazlogOdjave.serverNedostupan));
    }
  }

  Future<void> _udji(Korisnik korisnik, Emitter<SesijaState> emit) async {
    if (smeDaKoristi(aplikacija, korisnik.uloga)) return emit(Prijavljen(korisnik));
    await _odjaviTiho();
    emit(const Odjavljen(razlog: RazlogOdjave.pogresnaAplikacija));
  }

  Future<void> _odjaviTiho() async {
    try {
      await repozitorijum.odjavi();
    } on GreskaRepozitorijuma catch (uzrok, trag) {
      addError(uzrok, trag);
    }
  }

  @override
  Future<void> close() async {
    await _istekle.cancel();
    return super.close();
  }
}
