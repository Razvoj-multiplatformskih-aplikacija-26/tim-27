import 'identifikatori.dart';
import 'korisnici.dart';
import 'nalog/radni_nalog.dart';

// Prava na jednom mestu. Koriste ih obe aplikacije (ko sme da se prijavi, šta se prikazuje)
// i server (pre svake akcije). Akcije nad nalogom primaju Klijent ili Serviser, a do njih
// se iz prijavljenog korisnika stiže samo kroz kaoKlijent i kaoServiser.

enum Aplikacija { mobilna, backoffice }

bool jeOsoblje(Uloga uloga) => switch (uloga) {
  Uloga.serviser || Uloga.sefServisa => true,
  Uloga.klijent => false,
};

/// Mobilna aplikacija je za klijente, backoffice za osoblje servisa.
bool smeDaKoristi(Aplikacija aplikacija, Uloga uloga) => switch (aplikacija) {
  Aplikacija.mobilna => uloga == Uloga.klijent,
  Aplikacija.backoffice => jeOsoblje(uloga),
};

/// Klijent vidi samo svoje naloge, osoblje vidi sve.
bool smeDaVidi(Korisnik korisnik, RadniNalog nalog) =>
    jeOsoblje(korisnik.uloga) || nalog.klijentId == KlijentId(korisnik.id);

/// Osoblje vidi spisak klijenata i servisera (imena na tabli naloga).
bool smeDaVidiKorisnike(Korisnik korisnik) => jeOsoblje(korisnik.uloga);

/// Korisnik u ulozi klijenta; null za osoblje, pa akcije klijenta nisu dostupne osoblju.
Klijent? kaoKlijent(Korisnik korisnik) => korisnik.uloga == Uloga.klijent
    ? Klijent(id: KlijentId(korisnik.id), ime: korisnik.ime, telefon: korisnik.telefon)
    : null;

/// Korisnik kao član osoblja; null za klijenta, pa akcije osoblja (preuzimanje, ponuda,
/// završetak popravke, izdavanje, otkazivanje) klijent ne može da pozove ni mimo aplikacije.
Serviser? kaoServiser(Korisnik korisnik) => switch (korisnik.uloga) {
  Uloga.serviser => Serviser(id: ServiserId(korisnik.id), ime: korisnik.ime),
  Uloga.sefServisa => Serviser(id: ServiserId(korisnik.id), ime: korisnik.ime, uloga: UlogaOsoblja.sefServisa),
  Uloga.klijent => null,
};
