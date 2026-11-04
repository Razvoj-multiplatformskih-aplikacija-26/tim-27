import 'package:characters/characters.dart';
import 'package:meta/meta.dart';

import '../greske.dart';
import '../rezultat.dart';

/// Pravilo: opis kvara ima od 10 do 500 znakova (posle uklanjanja razmaka sa krajeva).
@immutable
final class OpisKvara {
  const OpisKvara._(this.tekst);

  static const minDuzina = 10;
  static const maksDuzina = 500;

  final String tekst;

  static Rezultat<OpisKvara> proveri(String unos) {
    final tekst = unos.trim();
    final duzina = tekst.characters.length;
    if (duzina < minDuzina) return Neuspeh(OpisKvaraPrekratak(duzina));
    if (duzina > maksDuzina) return Neuspeh(OpisKvaraPredugacak(duzina));
    return Uspeh(OpisKvara._(tekst));
  }

  @override
  bool operator ==(Object other) => other is OpisKvara && other.tekst == tekst;

  @override
  int get hashCode => tekst.hashCode;

  @override
  String toString() => 'OpisKvara("$tekst")';
}
