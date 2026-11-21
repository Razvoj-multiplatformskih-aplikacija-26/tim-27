import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

import 'pocetni_podaci.dart' as podaci;

/// Lažna implementacija porta: podaci u memoriji, sa kašnjenjem kao da idu preko mreže.
/// Aplikacija nad serverom koristi HttpNalogRepository; izbor je samo u dependencies.dart.
final class LazniNalozi implements NalogRepository {
  LazniNalozi({this.kasnjenje = const Duration(milliseconds: 800)}) : _nalozi = podaci.pocetniNalozi(DateTime.now());

  final Duration kasnjenje;
  final List<RadniNalog> _nalozi;
  int _sledeciBroj = 2019;

  /// Koliko sledećih zahteva baca grešku (dugme „Simuliraj grešku").
  int neuspesniZahtevi = 0;

  /// Koliko sledećih učitavanja vraća praznu listu (za prikaz praznog stanja).
  int prazniOdgovori = 0;

  Future<void> _mreza() async {
    await Future<void>.delayed(kasnjenje);
    if (neuspesniZahtevi > 0) {
      neuspesniZahtevi--;
      throw const GreskaRepozitorijuma('Simulirana greška mreže');
    }
  }

  @override
  Future<List<RadniNalog>> naloziKlijenta(KlijentId klijentId) async {
    await _mreza();
    return _nalozi.where((n) => n.klijentId == klijentId).toList();
  }

  @override
  Future<List<RadniNalog>> sviNalozi() async {
    await _mreza();
    if (prazniOdgovori > 0) {
      prazniOdgovori--;
      return const [];
    }
    return [..._nalozi];
  }

  @override
  Future<RadniNalog?> nadji(NalogId id) async {
    await _mreza();
    return _nalozi.where((n) => n.id == id).firstOrNull;
  }

  @override
  Future<Rezultat<RadniNalog>> sacuvaj(RadniNalog nalog) async {
    await _mreza();
    _nalozi[_nalozi.indexWhere((n) => n.id == nalog.id)] = nalog;
    return Uspeh(nalog);
  }

  @override
  Future<Rezultat<RadniNalog>> prijavi({
    required Klijent klijent,
    required Uredjaj uredjaj,
    required OpisKvara opisKvara,
  }) async {
    await _mreza();
    final nalog = prijaviUredjaj(
      id: NalogId('RN-${_sledeciBroj++}'),
      klijent: klijent,
      uredjaj: uredjaj,
      opisKvara: opisKvara,
      sada: DateTime.now(),
    );
    _nalozi.add(nalog);
    return Uspeh(nalog);
  }

  @override
  Future<List<Klijent>> klijenti() async => podaci.klijenti;

  @override
  Future<List<Serviser>> serviseri() async => podaci.serviseri;
}
