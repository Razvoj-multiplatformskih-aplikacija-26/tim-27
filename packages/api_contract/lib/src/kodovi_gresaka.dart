/// Kodovi grešaka na mreži. Poruku za korisnika pravi klijent, ne server.
abstract final class KodoviGresaka {
  static const opisKvaraPrekratak = 'opis-kvara-prekratak';
  static const opisKvaraPredugacak = 'opis-kvara-predugacak';
  static const nazivUredjajaObavezan = 'naziv-uredjaja-obavezan';
  static const neispravanIznos = 'neispravan-iznos';
  static const opisPonudeObavezan = 'opis-ponude-obavezan';
  static const previseAktivnihNaloga = 'previse-aktivnih-naloga';
  static const rokZaOdgovorIstekao = 'rok-za-odgovor-istekao';
  static const nemaPonudeZaOdgovor = 'nema-ponude-za-odgovor';
  static const nalogVecPreuzet = 'nalog-vec-preuzet';
  static const nemaDelaNaStanju = 'nema-dela-na-stanju';
  static const nedozvoljenPrelaz = 'nedozvoljen-prelaz';
  static const nemaPrava = 'nema-prava';
  static const nijePronadjeno = 'nije-pronadjeno';
  static const losZahtev = 'los-zahtev';
  static const nepodrzanTip = 'nepodrzan-tip';
  static const prevelikZahtev = 'prevelik-zahtev';
  static const greskaServera = 'greska-servera';
  static const pogresniPodaci = 'pogresni-podaci-za-prijavu';
  static const prijavaIstekla = 'prijava-istekla';
  static const prijavaPotrebna = 'prijava-potrebna';
}
