part of 'sesija_bloc.dart';

enum RazlogOdjave { odjava, istekla, pogresniPodaci, pogresnaAplikacija, serverNedostupan }

sealed class SesijaState extends Equatable {
  const SesijaState();

  @override
  List<Object?> get props => const [];
}

final class SesijaNepoznata extends SesijaState {
  const SesijaNepoznata();
}

final class Odjavljen extends SesijaState {
  const Odjavljen({this.razlog, this.prijavaUToku = false});

  final RazlogOdjave? razlog;
  final bool prijavaUToku;

  @override
  List<Object?> get props => [razlog, prijavaUToku];
}

final class Prijavljen extends SesijaState {
  const Prijavljen(this.korisnik);

  final Korisnik korisnik;

  @override
  List<Object?> get props => [korisnik];
}
