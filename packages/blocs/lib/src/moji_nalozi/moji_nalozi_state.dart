part of 'moji_nalozi_bloc.dart';

sealed class MojiNaloziState extends Equatable {
  const MojiNaloziState();

  @override
  List<Object?> get props => const [];
}

final class MojiNaloziUcitavanje extends MojiNaloziState {
  const MojiNaloziUcitavanje();
}

final class MojiNaloziGreska extends MojiNaloziState {
  const MojiNaloziGreska(this.uzrok);

  final Object uzrok;

  @override
  List<Object?> get props => [uzrok];
}

final class MojiNaloziPrazno extends MojiNaloziState {
  const MojiNaloziPrazno();
}

final class MojiNaloziUcitani extends MojiNaloziState {
  const MojiNaloziUcitani({required this.nalozi, required this.zaOdgovor, this.nalogUToku, this.obavestenje});

  final List<RadniNalog> nalozi;

  /// Nalozi čiju ponudu klijent još može da prihvati ili odbije.
  final Set<NalogId> zaOdgovor;
  final NalogId? nalogUToku;
  final MojiNaloziObavestenje? obavestenje;

  RadniNalog? nalog(NalogId id) => nalozi.where((n) => n.id == id).firstOrNull;

  bool mozeDaOdgovori(RadniNalog nalog) => zaOdgovor.contains(nalog.id) && nalogUToku == null;

  MojiNaloziUcitani saObavestenjem(MojiNaloziObavestenje? obavestenje) =>
      MojiNaloziUcitani(nalozi: nalozi, zaOdgovor: zaOdgovor, obavestenje: obavestenje);

  MojiNaloziUcitani saNalogomUToku(NalogId id) =>
      MojiNaloziUcitani(nalozi: nalozi, zaOdgovor: zaOdgovor, nalogUToku: id);

  @override
  List<Object?> get props => [nalozi, zaOdgovor, nalogUToku, obavestenje];
}

/// Jednokratna poruka posle akcije; ekran je prikaže i javi ObavestenjePrikazano.
sealed class MojiNaloziObavestenje extends Equatable {
  const MojiNaloziObavestenje();

  @override
  List<Object?> get props => const [];
}

final class NalogNapravljen extends MojiNaloziObavestenje {
  const NalogNapravljen(this.nalog);

  final RadniNalog nalog;

  @override
  List<Object?> get props => [nalog];
}

final class OdgovorSacuvan extends MojiNaloziObavestenje {
  const OdgovorSacuvan(this.nalog);

  final RadniNalog nalog;

  @override
  List<Object?> get props => [nalog];
}

final class AkcijaOdbijena extends MojiNaloziObavestenje {
  const AkcijaOdbijena(this.greska);

  final DomenskaGreska greska;

  @override
  List<Object?> get props => [greska];
}

final class AkcijaNijeUspela extends MojiNaloziObavestenje {
  const AkcijaNijeUspela(this.uzrok);

  final Object uzrok;

  @override
  List<Object?> get props => [uzrok];
}
