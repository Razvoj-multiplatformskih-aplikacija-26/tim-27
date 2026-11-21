part of 'sesija_bloc.dart';

sealed class SesijaEvent {
  const SesijaEvent();
}

/// Pri pokretanju: vrati prijavu sačuvanu od ranije, ako postoji.
final class SesijaVracanjeZatrazeno extends SesijaEvent {
  const SesijaVracanjeZatrazeno();
}

final class PrijavaZatrazena extends SesijaEvent {
  const PrijavaZatrazena({required this.korisnickoIme, required this.lozinka});

  final String korisnickoIme;
  final String lozinka;
}

final class OdjavaZatrazena extends SesijaEvent {
  const OdjavaZatrazena();
}

final class SesijaIstekla extends SesijaEvent {
  const SesijaIstekla();
}
