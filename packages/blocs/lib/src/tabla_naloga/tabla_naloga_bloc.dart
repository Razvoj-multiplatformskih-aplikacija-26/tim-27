import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

import '../nalog_repository.dart';

part 'tabla_naloga_event.dart';
part 'tabla_naloga_state.dart';

/// Glavni tok osoblja u backoffice-u: svi nalozi servisa, izbor naloga i akcije koje menjaju stanje.
final class TablaNalogaBloc extends Bloc<TablaNalogaEvent, TablaNalogaState> {
  TablaNalogaBloc({required this.repozitorijum, required this.serviser, DateTime Function()? sada})
    : sada = sada ?? DateTime.now,
      super(const TablaUcitavanje()) {
    on<TablaZatrazena>((event, emit) async {
      emit(const TablaUcitavanje());
      await _ucitaj(emit, izabraniId: null);
    });
    on<NalogIzabran>((event, emit) {
      final trenutno = state;
      if (trenutno is TablaUcitana) emit(trenutno.copyWith(izabraniId: () => event.id));
    });
    on<IzborPomeren>((event, emit) {
      final trenutno = state;
      if (trenutno is TablaUcitana) emit(trenutno.copyWith(izabraniId: () => trenutno.pomeriIzbor(event.korak)));
    });
    on<AkcijaZatrazena>(_naAkciju);
    on<ObavestenjeTablePrikazano>((event, emit) {
      final trenutno = state;
      if (trenutno is TablaUcitana) emit(trenutno.copyWith(obavestenje: () => null));
    });
  }

  final NalogRepository repozitorijum;
  final Serviser serviser;
  final DateTime Function() sada;

  Future<void> _naAkciju(AkcijaZatrazena event, Emitter<TablaNalogaState> emit) async {
    final trenutno = state;
    if (trenutno is! TablaUcitana || trenutno.nalogUToku != null) return;
    emit(trenutno.copyWith(nalogUToku: () => event.id));
    try {
      final sviNalozi = await repozitorijum.sviNalozi();
      final nalog = sviNalozi.where((n) => n.id == event.id).firstOrNull;
      if (nalog == null) {
        emit(trenutno.copyWith(obavestenje: () => const AkcijaTableOdbijena(NalogNijePronadjen())));
        return;
      }
      final rezultat = switch (event.akcija) {
        AkcijaOsoblja.preuzmi => preuzmiNalog(nalog, serviser: serviser, sviNalozi: sviNalozi),
        AkcijaOsoblja.posaljiPonudu => switch (event.ponuda) {
          final ponuda? => posaljiPonudu(nalog, serviser: serviser, ponuda: ponuda),
          null => const Neuspeh<RadniNalog>(OpisPonudeObavezan()),
        },
        AkcijaOsoblja.oznaciSpreman => oznaciSpreman(nalog, serviser: serviser),
        AkcijaOsoblja.izdaj => izdajUredjaj(nalog, serviser: serviser, sada: sada()),
        AkcijaOsoblja.otkazi => otkaziNalog(nalog, serviser: serviser, razlog: event.razlog),
      };
      switch (rezultat) {
        case Uspeh(:final vrednost):
          final sacuvan = await repozitorijum.sacuvaj(vrednost);
          await _ucitaj(emit, izabraniId: trenutno.izabraniId, obavestenje: AkcijaTableUspela(event.akcija, sacuvan));
        case Neuspeh(:final greska):
          emit(trenutno.copyWith(obavestenje: () => AkcijaTableOdbijena(greska)));
      }
    } on Exception catch (uzrok) {
      emit(trenutno.copyWith(obavestenje: () => AkcijaTableNijeUspela(uzrok)));
    }
  }

  Future<void> _ucitaj(Emitter<TablaNalogaState> emit, {NalogId? izabraniId, TablaObavestenje? obavestenje}) async {
    try {
      final nalozi = await repozitorijum.sviNalozi();
      if (nalozi.isEmpty) {
        emit(const TablaPrazna());
        return;
      }
      final klijenti = await repozitorijum.klijenti();
      final serviseri = await repozitorijum.serviseri();
      final sortirani = [...nalozi]..sort(_poFaziPaDatumu);
      emit(
        TablaUcitana(
          nalozi: sortirani,
          klijenti: {for (final k in klijenti) k.id: k},
          serviseri: {for (final s in serviseri) s.id: s},
          akcije: {for (final n in sortirani) n.id: akcijeOsoblja(n, serviser: serviser, sviNalozi: sortirani)},
          izabraniId: sortirani.any((n) => n.id == izabraniId) ? izabraniId : null,
          obavestenje: obavestenje,
        ),
      );
    } on Exception catch (uzrok) {
      emit(TablaGreska(uzrok));
    }
  }
}

/// Redosled faza na tabli: prvo ono što čeka posao, na kraju završeni nalozi.
int fazaNaloga(StanjeNaloga stanje) => switch (stanje) {
  Primljen() => 0,
  Dijagnostika() => 1,
  CekaOdobrenje() => 2,
  UPopravci() => 3,
  SpremanZaPreuzimanje() => 4,
  Preuzet() => 5,
  OdbijenaPonuda() => 6,
  Otkazan() => 7,
};

int _poFaziPaDatumu(RadniNalog a, RadniNalog b) {
  final poFazi = fazaNaloga(a.stanje).compareTo(fazaNaloga(b.stanje));
  return poFazi != 0 ? poFazi : a.primljenU.compareTo(b.primljenU);
}
