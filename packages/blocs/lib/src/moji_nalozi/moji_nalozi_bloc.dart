import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

import '../nalog_repository.dart';

part 'moji_nalozi_event.dart';
part 'moji_nalozi_state.dart';

/// Glavni tok klijenta u mobilnoj aplikaciji: njegovi nalozi, prijava uređaja i odgovor na ponudu.
final class MojiNaloziBloc extends Bloc<MojiNaloziEvent, MojiNaloziState> {
  MojiNaloziBloc({required this.repozitorijum, required this.klijent, DateTime Function()? sada})
    : sada = sada ?? DateTime.now,
      super(const MojiNaloziUcitavanje()) {
    on<MojiNaloziZatrazeni>((event, emit) async {
      emit(const MojiNaloziUcitavanje());
      await _ucitaj(emit);
    });
    on<UredjajPrijavljen>(_naPrijavu);
    on<OdgovorNaPonuduPoslat>(_naOdgovor);
    on<ObavestenjePrikazano>((event, emit) {
      final trenutno = state;
      if (trenutno is MojiNaloziUcitani) emit(trenutno.saObavestenjem(null));
    });
  }

  final NalogRepository repozitorijum;
  final Klijent klijent;
  final DateTime Function() sada;

  Future<void> _naPrijavu(UredjajPrijavljen event, Emitter<MojiNaloziState> emit) async {
    try {
      final rezultat = await repozitorijum.prijavi(
        klijent: klijent,
        uredjaj: event.uredjaj,
        opisKvara: event.opisKvara,
      );
      await _ucitaj(
        emit,
        obavestenje: switch (rezultat) {
          Uspeh(:final vrednost) => NalogNapravljen(vrednost),
          Neuspeh(:final greska) => AkcijaOdbijena(greska),
        },
      );
    } on Exception catch (uzrok) {
      await _posleGreske(emit, uzrok);
    }
  }

  Future<void> _naOdgovor(OdgovorNaPonuduPoslat event, Emitter<MojiNaloziState> emit) async {
    final trenutno = state;
    if (trenutno is! MojiNaloziUcitani) return;
    emit(trenutno.saNalogomUToku(event.id));
    try {
      final nalog = await repozitorijum.nadji(event.id);
      if (nalog == null) {
        await _ucitaj(emit, obavestenje: const AkcijaOdbijena(NalogNijePronadjen()));
        return;
      }
      // Prvo isto pravilo proverava aplikacija, a server ga proverava ponovo pre upisa.
      switch (odgovoriNaPonudu(nalog, klijent: klijent, prihvata: event.prihvata, sada: sada())) {
        case Uspeh(:final vrednost):
          await _ucitaj(
            emit,
            obavestenje: switch (await repozitorijum.sacuvaj(vrednost)) {
              Uspeh(:final vrednost) => OdgovorSacuvan(vrednost),
              Neuspeh(:final greska) => AkcijaOdbijena(greska),
            },
          );
        case Neuspeh(:final greska):
          emit(trenutno.saObavestenjem(AkcijaOdbijena(greska)));
      }
    } on Exception catch (uzrok) {
      await _posleGreske(emit, uzrok, prethodno: trenutno);
    }
  }

  /// Odbijen poziv: prikaži razlog i ponovo učitaj podatke. Nedostupan server: samo javi.
  Future<void> _posleGreske(Emitter<MojiNaloziState> emit, Exception uzrok, {MojiNaloziUcitani? prethodno}) async {
    if (uzrok is GreskaRepozitorijuma && uzrok.vrsta == VrstaGreske.odbijeno) {
      await _ucitaj(emit, obavestenje: AkcijaNijeUspela(uzrok));
      return;
    }
    final trenutno = prethodno ?? state;
    if (trenutno is MojiNaloziUcitani) {
      emit(trenutno.saObavestenjem(AkcijaNijeUspela(uzrok)));
    } else {
      emit(MojiNaloziGreska(uzrok));
    }
  }

  Future<void> _ucitaj(Emitter<MojiNaloziState> emit, {MojiNaloziObavestenje? obavestenje}) async {
    try {
      final nalozi = await repozitorijum.naloziKlijenta(klijent.id);
      if (nalozi.isEmpty) {
        emit(const MojiNaloziPrazno());
        return;
      }
      final sortirani = [...nalozi]..sort((a, b) => b.primljenU.compareTo(a.primljenU));
      final trenutak = sada();
      emit(
        MojiNaloziUcitani(
          nalozi: sortirani,
          zaOdgovor: {
            for (final n in sortirani)
              if (klijentMozeDaOdgovori(n, sada: trenutak)) n.id,
          },
          obavestenje: obavestenje,
        ),
      );
    } on Exception catch (uzrok) {
      emit(MojiNaloziGreska(uzrok));
    }
  }
}
