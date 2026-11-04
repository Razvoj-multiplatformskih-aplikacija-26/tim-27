part of 'moji_nalozi_bloc.dart';

sealed class MojiNaloziEvent {
  const MojiNaloziEvent();
}

final class MojiNaloziZatrazeni extends MojiNaloziEvent {
  const MojiNaloziZatrazeni();
}

final class UredjajPrijavljen extends MojiNaloziEvent {
  const UredjajPrijavljen({required this.uredjaj, required this.opisKvara});

  final Uredjaj uredjaj;
  final OpisKvara opisKvara;
}

final class OdgovorNaPonuduPoslat extends MojiNaloziEvent {
  const OdgovorNaPonuduPoslat(this.id, {required this.prihvata});

  final NalogId id;
  final bool prihvata;
}

final class ObavestenjePrikazano extends MojiNaloziEvent {
  const ObavestenjePrikazano();
}
