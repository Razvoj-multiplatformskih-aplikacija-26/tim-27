part of 'tabla_naloga_bloc.dart';

sealed class TablaNalogaEvent {
  const TablaNalogaEvent();
}

final class TablaZatrazena extends TablaNalogaEvent {
  const TablaZatrazena();
}

/// Izbor naloga mišem; null poništava izbor.
final class NalogIzabran extends TablaNalogaEvent {
  const NalogIzabran(this.id);

  final NalogId? id;
}

/// Kretanje tastaturom: -1 prethodni, +1 sledeći nalog.
final class IzborPomeren extends TablaNalogaEvent {
  const IzborPomeren(this.korak);

  final int korak;
}

final class AkcijaZatrazena extends TablaNalogaEvent {
  const AkcijaZatrazena(this.id, this.akcija, {this.ponuda, this.razlog = ''});

  final NalogId id;
  final AkcijaOsoblja akcija;

  /// Samo za slanje ponude.
  final Ponuda? ponuda;

  /// Samo za otkazivanje.
  final String razlog;
}

final class ObavestenjeTablePrikazano extends TablaNalogaEvent {
  const ObavestenjeTablePrikazano();
}
