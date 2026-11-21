import 'dart:async';

import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

/// Lažna prijava za testove i demo bez servera.
final class LazneSesije implements SesijaRepository {
  LazneSesije({required this.korisnik, this.prijavljen = true, this.lozinka = 'reboot-demo'});

  final Korisnik korisnik;
  final String lozinka;
  bool prijavljen;
  final _istekle = StreamController<void>.broadcast();

  void istekni() => _istekle.add(null);

  @override
  Future<Korisnik?> prijavi({required String korisnickoIme, required String lozinka}) async {
    if (lozinka != this.lozinka) return null;
    prijavljen = true;
    return korisnik;
  }

  @override
  Future<Korisnik?> trenutna() async => prijavljen ? korisnik : null;

  @override
  Future<void> odjavi() async => prijavljen = false;

  @override
  Stream<void> get istekle => _istekle.stream;
}
