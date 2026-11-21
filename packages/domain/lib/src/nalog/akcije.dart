import '../greske.dart';
import '../identifikatori.dart';
import '../korisnici.dart';
import '../rezultat.dart';
import 'opis_kvara.dart';
import 'pravila.dart';
import 'ponuda.dart';
import 'radni_nalog.dart';
import 'stanje_naloga.dart';
import 'uredjaj.dart';

// Akcije nad radnim nalogom. Svaka proverava prava, dozvoljen prelaz i pravila,
// pa vraća izmenjen nalog ili grešku kao tip.

/// Klijent prijavljuje uređaj: nastaje novi nalog u stanju primljen.
RadniNalog prijaviUredjaj({
  required NalogId id,
  required Klijent klijent,
  required Uredjaj uredjaj,
  required OpisKvara opisKvara,
  required DateTime sada,
}) => RadniNalog(id: id, klijentId: klijent.id, uredjaj: uredjaj, opisKvara: opisKvara, primljenU: sada);

/// Serviser preuzima slobodan nalog i počinje dijagnostiku.
Rezultat<RadniNalog> preuzmiNalog(RadniNalog nalog, {required Serviser serviser, required List<RadniNalog> sviNalozi}) {
  if (nalog.serviserId != null) return const Neuspeh(NalogVecPreuzet());
  final aktivnih = brojAktivnihNaloga(serviser.id, sviNalozi);
  if (aktivnih >= maksAktivnihNaloga) return Neuspeh(PreviseAktivnihNaloga(aktivnih, granica: maksAktivnihNaloga));
  return _predji(nalog, const Dijagnostika(), serviserId: serviser.id);
}

/// Serviser posle dijagnostike šalje ponudu klijentu.
Rezultat<RadniNalog> posaljiPonudu(RadniNalog nalog, {required Serviser serviser, required Ponuda ponuda}) {
  if (!smeDaMenja(serviser, nalog)) return const Neuspeh(NemaPrava());
  return _predji(nalog, CekaOdobrenje(ponuda));
}

/// Klijent prihvata ili odbija ponudu, najkasnije 48 sati pošto je poslata.
Rezultat<RadniNalog> odgovoriNaPonudu(
  RadniNalog nalog, {
  required Klijent klijent,
  required bool prihvata,
  required DateTime sada,
}) {
  if (nalog.klijentId != klijent.id) return const Neuspeh(NemaPrava());
  final stanje = nalog.stanje;
  if (stanje is! CekaOdobrenje) return const Neuspeh(NemaPonudeZaOdgovor());
  if (stanje.ponuda.jeIstekla(sada)) return const Neuspeh(RokZaOdgovorIstekao());
  return _predji(nalog, prihvata ? UPopravci(stanje.ponuda) : OdbijenaPonuda(stanje.ponuda));
}

/// Serviser završava popravku: uređaj je spreman za preuzimanje.
Rezultat<RadniNalog> oznaciSpreman(RadniNalog nalog, {required Serviser serviser}) {
  if (!smeDaMenja(serviser, nalog)) return const Neuspeh(NemaPrava());
  return _predji(nalog, const SpremanZaPreuzimanje());
}

/// Bilo ko iz osoblja predaje popravljen uređaj klijentu.
Rezultat<RadniNalog> izdajUredjaj(RadniNalog nalog, {required Serviser serviser, required DateTime sada}) =>
    _predji(nalog, Preuzet(sada));

/// Osoblje otkazuje nalog pre nego što je ponuda poslata.
Rezultat<RadniNalog> otkaziNalog(RadniNalog nalog, {required Serviser serviser, required String razlog}) {
  if (nalog.serviserId != null && !smeDaMenja(serviser, nalog)) return const Neuspeh(NemaPrava());
  return _predji(nalog, Otkazan(razlog.trim()));
}

Rezultat<RadniNalog> _predji(RadniNalog nalog, StanjeNaloga novo, {ServiserId? serviserId}) {
  if (!dozvoljenPrelaz(nalog.stanje, novo)) return Neuspeh(NedozvoljenPrelaz(iz: nalog.stanje, u: novo));
  return Uspeh(nalog.copyWith(stanje: novo, serviserId: serviserId));
}
