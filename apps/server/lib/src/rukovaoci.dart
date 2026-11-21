import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart';

import 'http.dart';
import 'nalozi_baza.dart';
import 'obavestenja.dart';
import 'sesije.dart';

/// Rukovaoci za radne naloge. Pre svakog upisa server pokreće istu akciju iz domena kao
/// klijent (preuzmiNalog, posaljiPonudu, ...), sa pravima iz domena (kaoServiser, kaoKlijent).
final class NaloziRukovaoci {
  NaloziRukovaoci({required this.baza, required this.obavestenja, DateTime Function()? sada})
    : sada = sada ?? (() => DateTime.now().toUtc());

  final NaloziBaza baza;
  final ObavestenjaKlijentu obavestenja;
  final DateTime Function() sada;

  Future<Response> svi(Request zahtev) async {
    final korisnik = _korisnik(zahtev);
    final nalozi = jeOsoblje(korisnik.uloga) ? await baza.sviNalozi() : await baza.naloziKlijenta(korisnik.id);
    return _lista(korisnik, nalozi);
  }

  Future<Response> klijentovi(Request zahtev) async {
    final korisnik = _korisnik(zahtev);
    return _lista(korisnik, await baza.naloziKlijenta(zahtev.rawPathParameters[#klijentId]!));
  }

  Future<Response> jedan(Request zahtev) async {
    final nalog = await baza.nalog(_id(zahtev));
    if (nalog == null || !smeDaVidi(_korisnik(zahtev), nalog)) return greska(const NalogNijePronadjen());
    return json(200, nalog.toDto().toJson());
  }

  Future<Response> klijenti(Request zahtev) => _korisnici(zahtev, const [Uloga.klijent]);

  Future<Response> serviseri(Request zahtev) => _korisnici(zahtev, const [Uloga.serviser, Uloga.sefServisa]);

  /// Klijent prijavljuje uređaj; pravila za uređaj i opis kvara su ista kao u aplikaciji.
  Future<Response> prijavi(Request zahtev) async {
    final klijent = kaoKlijent(_korisnik(zahtev));
    if (klijent == null) return greska(const NemaPrava());
    final telo = NoviNalogDto.fromJson(await procitajObjekat(zahtev));
    final uredjaj = Uredjaj.proveri(vrsta: vrstaUredjajaIz(telo.vrstaUredjaja), naziv: telo.nazivUredjaja);
    if (uredjaj case Neuspeh(greska: final g)) return greska(g);
    final opis = OpisKvara.proveri(telo.opisKvara);
    if (opis case Neuspeh(greska: final g)) return greska(g);
    final nalog = await baza.dodaj(
      klijent: klijent,
      uredjaj: uredjaj.vrednostIliNull!,
      opisKvara: opis.vrednostIliNull!,
    );
    return json(201, nalog.toDto().toJson());
  }

  /// Preuzimanje zavisi od podataka drugih servisera: zaključavaju se red naloga i red
  /// servisera, pa od dva istovremena zahteva prolazi samo onoliko koliko pravilo dozvoljava.
  Future<Response> preuzmi(Request zahtev) async {
    final serviser = kaoServiser(_korisnik(zahtev));
    if (serviser == null) return greska(const NemaPrava());
    final rezultat = await baza.promeni(
      _id(zahtev),
      zakljucajServisera: serviser.id.value,
      promena: (nalog, naloziServisera) => preuzmiNalog(nalog, serviser: serviser, sviNalozi: naloziServisera),
    );
    return odgovorNa(rezultat);
  }

  Future<Response> ponudi(Request zahtev) async {
    final serviser = kaoServiser(_korisnik(zahtev));
    if (serviser == null) return greska(const NemaPrava());
    final telo = NovaPonudaDto.fromJson(await procitajObjekat(zahtev));
    final ponuda = Ponuda.proveri(iznos: telo.iznosDinara, opis: telo.opis, poslataU: sada());
    if (ponuda case Neuspeh(greska: final g)) return greska(g);
    return _promeni(zahtev, (nalog) => posaljiPonudu(nalog, serviser: serviser, ponuda: ponuda.vrednostIliNull!));
  }

  /// Odgovor na ponudu sme samo klijent i samo za svoj nalog (domen vraća NemaPrava za tuđ).
  Future<Response> odgovori(Request zahtev) async {
    final klijent = kaoKlijent(_korisnik(zahtev));
    if (klijent == null) return greska(const NemaPrava());
    final telo = OdgovorDto.fromJson(await procitajObjekat(zahtev));
    return _promeni(
      zahtev,
      (nalog) => odgovoriNaPonudu(nalog, klijent: klijent, prihvata: telo.prihvata, sada: sada()),
    );
  }

  Future<Response> zavrsi(Request zahtev) async {
    final serviser = kaoServiser(_korisnik(zahtev));
    if (serviser == null) return greska(const NemaPrava());
    final rezultat = await baza.promeni(_id(zahtev), promena: (nalog, _) => oznaciSpreman(nalog, serviser: serviser));
    if (rezultat case Uspeh(vrednost: final nalog)) await _obavesti(nalog);
    return odgovorNa(rezultat);
  }

  Future<Response> izdaj(Request zahtev) async {
    final serviser = kaoServiser(_korisnik(zahtev));
    if (serviser == null) return greska(const NemaPrava());
    return _promeni(zahtev, (nalog) => izdajUredjaj(nalog, serviser: serviser, sada: sada()));
  }

  Future<Response> otkazi(Request zahtev) async {
    final serviser = kaoServiser(_korisnik(zahtev));
    if (serviser == null) return greska(const NemaPrava());
    final telo = OtkazivanjeDto.fromJson(await procitajObjekat(zahtev));
    return _promeni(zahtev, (nalog) => otkaziNalog(nalog, serviser: serviser, razlog: telo.razlog));
  }

  Future<Response> _promeni(Request zahtev, Rezultat<RadniNalog> Function(RadniNalog nalog) promena) async =>
      odgovorNa(await baza.promeni(_id(zahtev), promena: (nalog, _) => promena(nalog)));

  Future<void> _obavesti(RadniNalog nalog) async {
    final klijent = await baza.korisnik(nalog.klijentId.value);
    if (klijent == null) return;
    try {
      await obavestenja.uredjajSpreman(klijent: klijent, nalog: nalog);
    } on Exception catch (uzrok) {
      // Promena je već upisana; neuspelo obaveštenje se samo beleži.
      stderr.writeln('SMS nije poslat za ${nalog.id.value}: $uzrok');
    }
  }

  Future<Response> _korisnici(Request zahtev, List<Uloga> uloge) async {
    if (!smeDaVidiKorisnike(_korisnik(zahtev))) return greska(const NemaPrava());
    final korisnici = await baza.korisniciUloge(uloge);
    return json(200, [for (final k in korisnici) k.toDto().toJson()]);
  }

  Response _lista(Korisnik korisnik, List<RadniNalog> nalozi) => json(200, [
    for (final nalog in nalozi)
      if (smeDaVidi(korisnik, nalog)) nalog.toDto().toJson(),
  ]);

  Korisnik _korisnik(Request zahtev) => trenutnaSesija.get(zahtev).korisnik;

  NalogId _id(Request zahtev) => NalogId(zahtev.rawPathParameters[#id]!);
}
