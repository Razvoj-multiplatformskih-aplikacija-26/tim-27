import 'package:meta/meta.dart';

import '../identifikatori.dart';
import 'opis_kvara.dart';
import 'stanje_naloga.dart';
import 'uredjaj.dart';

/// Glavni pojam sistema: radni nalog za popravku jednog uređaja.
@immutable
final class RadniNalog {
  const RadniNalog({
    required this.id,
    required this.klijentId,
    required this.uredjaj,
    required this.opisKvara,
    required this.primljenU,
    this.stanje = const Primljen(),
    this.serviserId,
  });

  final NalogId id;
  final KlijentId klijentId;
  final Uredjaj uredjaj;
  final OpisKvara opisKvara;
  final DateTime primljenU;
  final StanjeNaloga stanje;

  /// Serviser koji je preuzeo nalog; null dok nalog niko nije preuzeo.
  final ServiserId? serviserId;

  RadniNalog copyWith({StanjeNaloga? stanje, ServiserId? serviserId}) => RadniNalog(
    id: id,
    klijentId: klijentId,
    uredjaj: uredjaj,
    opisKvara: opisKvara,
    primljenU: primljenU,
    stanje: stanje ?? this.stanje,
    serviserId: serviserId ?? this.serviserId,
  );

  @override
  bool operator ==(Object other) =>
      other is RadniNalog &&
      other.id == id &&
      other.klijentId == klijentId &&
      other.uredjaj == uredjaj &&
      other.opisKvara == opisKvara &&
      other.primljenU == primljenU &&
      other.stanje == stanje &&
      other.serviserId == serviserId;

  @override
  int get hashCode => Object.hash(id, klijentId, uredjaj, opisKvara, primljenU, stanje, serviserId);

  @override
  String toString() => 'RadniNalog(${id.value}, $stanje)';
}
