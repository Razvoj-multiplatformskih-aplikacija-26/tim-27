part of 'tabla_naloga_bloc.dart';

sealed class TablaNalogaState extends Equatable {
  const TablaNalogaState();

  @override
  List<Object?> get props => const [];
}

final class TablaUcitavanje extends TablaNalogaState {
  const TablaUcitavanje();
}

final class TablaGreska extends TablaNalogaState {
  const TablaGreska(this.uzrok);

  final Object uzrok;

  @override
  List<Object?> get props => [uzrok];
}

final class TablaPrazna extends TablaNalogaState {
  const TablaPrazna();
}

final class TablaUcitana extends TablaNalogaState {
  const TablaUcitana({
    required this.nalozi,
    required this.klijenti,
    required this.serviseri,
    required this.akcije,
    required this.aktivnihPrijavljenog,
    this.izabraniId,
    this.nalogUToku,
    this.obavestenje,
  });

  final List<RadniNalog> nalozi;
  final Map<KlijentId, Klijent> klijenti;
  final Map<ServiserId, Serviser> serviseri;

  /// Za svaki nalog akcije koje prijavljeni član osoblja sme da uradi (računa domen).
  final Map<NalogId, Set<AkcijaOsoblja>> akcije;

  /// Koliko aktivnih naloga ima prijavljeni serviser (najviše 5).
  final int aktivnihPrijavljenog;
  final NalogId? izabraniId;
  final NalogId? nalogUToku;
  final TablaObavestenje? obavestenje;

  RadniNalog? get izabrani => nalozi.where((n) => n.id == izabraniId).firstOrNull;

  int? get indeksIzabranog {
    final indeks = nalozi.indexWhere((n) => n.id == izabraniId);
    return indeks < 0 ? null : indeks;
  }

  Set<AkcijaOsoblja> akcijeZa(RadniNalog nalog) => nalogUToku == null ? akcije[nalog.id] ?? const {} : const {};

  bool izabraniDozvoljava(AkcijaOsoblja akcija) => switch (izabrani) {
    final nalog? => akcijeZa(nalog).contains(akcija),
    null => false,
  };

  NalogId pomeriIzbor(int korak) {
    final indeks = indeksIzabranog;
    final novi = indeks == null ? (korak > 0 ? 0 : nalozi.length - 1) : (indeks + korak).clamp(0, nalozi.length - 1);
    return nalozi[novi].id;
  }

  TablaUcitana copyWith({
    NalogId? Function()? izabraniId,
    NalogId? Function()? nalogUToku,
    TablaObavestenje? Function()? obavestenje,
  }) => TablaUcitana(
    nalozi: nalozi,
    klijenti: klijenti,
    serviseri: serviseri,
    akcije: akcije,
    aktivnihPrijavljenog: aktivnihPrijavljenog,
    izabraniId: izabraniId == null ? this.izabraniId : izabraniId(),
    nalogUToku: nalogUToku == null ? this.nalogUToku : nalogUToku(),
    obavestenje: obavestenje == null ? this.obavestenje : obavestenje(),
  );

  @override
  List<Object?> get props => [
    nalozi,
    klijenti,
    serviseri,
    akcije,
    aktivnihPrijavljenog,
    izabraniId,
    nalogUToku,
    obavestenje,
  ];
}

sealed class TablaObavestenje extends Equatable {
  const TablaObavestenje();

  @override
  List<Object?> get props => const [];
}

final class AkcijaTableUspela extends TablaObavestenje {
  const AkcijaTableUspela(this.akcija, this.nalog);

  final AkcijaOsoblja akcija;
  final RadniNalog nalog;

  @override
  List<Object?> get props => [akcija, nalog];
}

final class AkcijaTableOdbijena extends TablaObavestenje {
  const AkcijaTableOdbijena(this.greska);

  final DomenskaGreska greska;

  @override
  List<Object?> get props => [greska];
}

final class AkcijaTableNijeUspela extends TablaObavestenje {
  const AkcijaTableNijeUspela(this.uzrok);

  final Object uzrok;

  @override
  List<Object?> get props => [uzrok];
}
