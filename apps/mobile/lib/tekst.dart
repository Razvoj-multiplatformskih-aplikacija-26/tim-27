import 'package:domain/domain.dart';

// Tekstovi na srpskom koje bira aplikacija. Domen vraća samo tip greške ili stanja.

extension PorukaGreske on DomenskaGreska {
  String get poruka => switch (this) {
    OpisKvaraPrekratak(:final duzina) => 'Opis kvara mora imati bar ${OpisKvara.minDuzina} znakova (sada $duzina).',
    OpisKvaraPredugacak(:final duzina) =>
      'Opis kvara može imati najviše ${OpisKvara.maksDuzina} znakova (sada $duzina).',
    NazivUredjajaObavezan() => 'Unesite marku i model uređaja.',
    NeispravanIznos() => 'Iznos ponude nije ispravan.',
    OpisPonudeObavezan() => 'Ponuda mora imati opis.',
    PreviseAktivnihNaloga() => 'Serviser već ima $maksAktivnihNaloga aktivnih naloga.',
    RokZaOdgovorIstekao() => 'Rok od 48 sati za odgovor na ponudu je istekao.',
    NemaPonudeZaOdgovor() => 'Ovaj nalog ne čeka vaš odgovor na ponudu.',
    NalogVecPreuzet() => 'Nalog je već preuzeo drugi serviser.',
    NemaDelaNaStanju() => 'Deo više nije na stanju.',
    NemaPrava() => 'Nemate pravo na ovu radnju.',
    NalogNijePronadjen() => 'Nalog nije pronađen.',
    NedozvoljenPrelaz() => 'Ova promena naloga nije moguća.',
  };
}

String nazivStanja(StanjeNaloga stanje) => switch (stanje) {
  Primljen() => 'Primljen',
  Dijagnostika() => 'Dijagnostika',
  CekaOdobrenje() => 'Čeka odobrenje',
  UPopravci() => 'U popravci',
  SpremanZaPreuzimanje() => 'Spreman za preuzimanje',
  Preuzet() => 'Preuzet',
  Otkazan() => 'Otkazan',
  OdbijenaPonuda() => 'Odbijena ponuda',
};

String nazivVrste(VrstaUredjaja vrsta) => switch (vrsta) {
  VrstaUredjaja.laptop => 'Laptop',
  VrstaUredjaja.desktop => 'Desktop računar',
  VrstaUredjaja.monitor => 'Monitor',
  VrstaUredjaja.stampac => 'Štampač',
  VrstaUredjaja.ostalo => 'Ostalo',
};

String _dve(int broj) => broj.toString().padLeft(2, '0');

/// Npr. "4. 11. 2026. u 14:05".
String datumIVreme(DateTime vreme) {
  final v = vreme.toLocal();
  return '${v.day}. ${v.month}. ${v.year}. u ${_dve(v.hour)}:${_dve(v.minute)}';
}

/// Npr. "8.500 RSD".
String dinari(int iznos) {
  final cifre = iznos.toString();
  final grupe = <String>[];
  for (var kraj = cifre.length; kraj > 0; kraj -= 3) {
    grupe.insert(0, cifre.substring(kraj - 3 < 0 ? 0 : kraj - 3, kraj));
  }
  return '${grupe.join('.')} RSD';
}
