import 'package:meta/meta.dart';

import '../greske.dart';
import '../rezultat.dart';

enum VrstaUredjaja { laptop, desktop, monitor, stampac, ostalo }

@immutable
final class Uredjaj {
  const Uredjaj._({required this.vrsta, required this.naziv});

  final VrstaUredjaja vrsta;

  /// Marka i model, npr. "Lenovo ThinkPad T14".
  final String naziv;

  static Rezultat<Uredjaj> proveri({required VrstaUredjaja vrsta, required String naziv}) {
    final tekst = naziv.trim();
    if (tekst.isEmpty) return const Neuspeh(NazivUredjajaObavezan());
    return Uspeh(Uredjaj._(vrsta: vrsta, naziv: tekst));
  }

  @override
  bool operator ==(Object other) => other is Uredjaj && other.vrsta == vrsta && other.naziv == naziv;

  @override
  int get hashCode => Object.hash(vrsta, naziv);

  @override
  String toString() => 'Uredjaj(${vrsta.name}, $naziv)';
}
