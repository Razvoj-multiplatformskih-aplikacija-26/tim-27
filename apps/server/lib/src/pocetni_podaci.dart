import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

import 'lozinke.dart';
import 'nalozi_baza.dart';

// Početni podaci koji se učitavaju pri prvom podizanju: 18 naloga (bar jedan u svakom stanju),
// nalog za svaku ulogu i tri klijenta sa prijavom. Lozinka svih demo naloga je DEMO_PASSWORD iz .env.

/// Korisničko ime za prijavu, po id-ju korisnika.
const korisnickaImena = {
  'k-1': 'ana',
  'k-2': 'petar',
  'k-3': 'milica',
  's-1': 'marko',
  's-2': 'jelena',
  's-3': 'nikola',
};

Future<void> unesiPocetnePodatke(Pool<void> baza, {required String? demoLozinka, required DateTime sada}) async {
  final brojKorisnika = (await baza.execute('SELECT count(*) FROM korisnici')).single[0]! as int;
  if (brojKorisnika > 0) return;
  if (demoLozinka == null || demoLozinka.isEmpty) {
    throw StateError('DEMO_PASSWORD nije podešen. Kopirajte .env.example u .env.');
  }
  final hes = await hesLozinke(demoLozinka);
  await baza.runTx((tx) async {
    Future<void> korisnik(String id, String ime, Uloga uloga, {String telefon = ''}) => tx.execute(
      Sql.named(
        'INSERT INTO korisnici (id, ime, telefon, uloga, korisnicko_ime, lozinka_hes) '
        'VALUES (@id, @ime, @telefon, @uloga, @korisnickoIme, @hes)',
      ),
      parameters: {
        'id': id,
        'ime': ime,
        'telefon': telefon,
        'uloga': uloga.name,
        'korisnickoIme': korisnickaImena[id],
        'hes': korisnickaImena.containsKey(id) ? hes : null,
      },
    );
    for (final k in klijenti) {
      await korisnik(k.id.value, k.ime, Uloga.klijent, telefon: k.telefon);
    }
    for (final s in serviseri) {
      await korisnik(s.id.value, s.ime, s.jeSef ? Uloga.sefServisa : Uloga.serviser);
    }
    for (final nalog in pocetniNalozi(sada)) {
      await NaloziBaza.upisi(tx, nalog);
    }
  });
}

const serviseri = [
  Serviser(id: ServiserId('s-1'), ime: 'Marko Marković'),
  Serviser(id: ServiserId('s-2'), ime: 'Jelena Petrović'),
  Serviser(id: ServiserId('s-3'), ime: 'Nikola Nikolić', uloga: UlogaOsoblja.sefServisa),
];

const klijenti = [
  Klijent(id: KlijentId('k-1'), ime: 'Ana Jovanović', telefon: '064 123 4567'),
  Klijent(id: KlijentId('k-2'), ime: 'Petar Ilić', telefon: '065 765 4321'),
  Klijent(id: KlijentId('k-3'), ime: 'Milica Stojanović', telefon: '063 222 3344'),
  Klijent(id: KlijentId('k-4'), ime: 'Stefan Đorđević', telefon: '062 555 0101'),
  Klijent(id: KlijentId('k-5'), ime: 'Jovana Pavlović', telefon: '061 909 8080'),
  Klijent(id: KlijentId('k-6'), ime: 'Luka Kostić', telefon: '060 414 1414'),
];

/// Lažni nalozi celog servisa. Prijavljeni serviser ima 4 aktivna naloga, pa može
/// da preuzme još jedan, a za šesti dobija grešku iz pravila o najviše 5 naloga.
List<RadniNalog> pocetniNalozi(DateTime sada) {
  var broj = 2001;
  RadniNalog nalog(
    int klijent,
    VrstaUredjaja vrsta,
    String naziv,
    String opis, {
    required int satiRanije,
    StanjeNaloga stanje = const Primljen(),
    int? serviser,
  }) => RadniNalog(
    id: NalogId('RN-${broj++}'),
    klijentId: klijenti[klijent].id,
    uredjaj: Uredjaj.proveri(vrsta: vrsta, naziv: naziv).vrednostIliNull!,
    opisKvara: OpisKvara.proveri(opis).vrednostIliNull!,
    primljenU: sada.subtract(Duration(hours: satiRanije)),
    stanje: stanje,
    serviserId: serviser == null ? null : serviseri[serviser].id,
  );

  Ponuda ponuda(int iznos, String opis, int satiRanije) => Ponuda.proveri(
    iznos: iznos,
    opis: opis,
    poslataU: sada.subtract(Duration(hours: satiRanije)),
  ).vrednostIliNull!;

  const l = VrstaUredjaja.laptop, d = VrstaUredjaja.desktop, m = VrstaUredjaja.monitor, s = VrstaUredjaja.stampac;
  return [
    nalog(0, l, 'Lenovo ThinkPad T14', 'Laptop se gasi posle desetak minuta rada.', satiRanije: 2),
    nalog(1, d, 'HP ProDesk 400', 'Računar se ne pali, lampica napajanja trepće.', satiRanije: 5),
    nalog(2, l, 'Dell XPS 13', 'Touchpad ne reaguje na dodir posle ažuriranja.', satiRanije: 8),
    nalog(3, s, 'Canon PIXMA G3411', 'Štampač zaglavljuje papir na svakoj drugoj stranici.', satiRanije: 20),
    nalog(4, m, 'LG UltraGear 27GP850', 'Na ekranu se pojavila vertikalna linija.', satiRanije: 26),
    nalog(
      5,
      l,
      'Asus ROG Strix G15',
      'Laptop se pregreva i gasi pri igranju igrica.',
      satiRanije: 30,
      stanje: const Dijagnostika(),
      serviser: 0,
    ),
    nalog(
      0,
      d,
      'Dell OptiPlex 7090',
      'Ne prikazuje sliku, čuju se tri zvučna signala.',
      satiRanije: 28,
      stanje: const Dijagnostika(),
      serviser: 0,
    ),
    nalog(
      1,
      l,
      'Acer Swift 3',
      'Tastatura ne radi, slova se kucaju sama od sebe.',
      satiRanije: 40,
      stanje: const Dijagnostika(),
      serviser: 1,
    ),
    nalog(
      2,
      l,
      'Apple MacBook Air M1',
      'Prosuta kafa po tastaturi, neki tasteri ne rade.',
      satiRanije: 50,
      stanje: CekaOdobrenje(ponuda(14500, 'Zamena tastature i čišćenje ploče.', 5)),
      serviser: 0,
    ),
    nalog(
      3,
      m,
      'Samsung Odyssey G5',
      'Monitor treperi i povremeno se sam isključi.',
      satiRanije: 90,
      stanje: CekaOdobrenje(ponuda(6200, 'Zamena napajanja monitora.', 60)),
      serviser: 1,
    ),
    nalog(
      4,
      l,
      'HP Pavilion 15',
      'Baterija se ne puni, radi samo na punjaču.',
      satiRanije: 96,
      stanje: UPopravci(ponuda(7800, 'Nova baterija.', 70)),
      serviser: 0,
    ),
    nalog(
      5,
      d,
      'Lenovo IdeaCentre 3',
      'Računar je spor i zagreva se, potrebno čišćenje.',
      satiRanije: 72,
      stanje: UPopravci(ponuda(3500, 'Čišćenje i nova termalna pasta.', 48)),
      serviser: 2,
    ),
    nalog(
      0,
      s,
      'Epson EcoTank L3250',
      'Izbacuje prazne stranice iako ima mastila.',
      satiRanije: 140,
      stanje: const SpremanZaPreuzimanje(),
      serviser: 1,
    ),
    nalog(
      1,
      l,
      'Huawei MateBook D15',
      'Ne radi Wi-Fi, mreža se ne vidi.',
      satiRanije: 120,
      stanje: const SpremanZaPreuzimanje(),
      serviser: 0,
    ),
    nalog(
      2,
      d,
      'Gaming PC (Ryzen 5, RTX 3060)',
      'Restartuje se pri pokretanju igrica.',
      satiRanije: 480,
      stanje: Preuzet(sada.subtract(const Duration(days: 12))),
      serviser: 1,
    ),
    nalog(
      3,
      l,
      'Asus VivoBook 14',
      'Ekran je napukao posle pada laptopa.',
      satiRanije: 360,
      stanje: OdbijenaPonuda(ponuda(18900, 'Zamena ekrana.', 300)),
      serviser: 2,
    ),
    nalog(
      4,
      VrstaUredjaja.ostalo,
      'Logitech MX Keys',
      'Tastatura se ne povezuje preko Bluetooth-a.',
      satiRanije: 240,
      stanje: const Otkazan('Klijent je sam rešio problem.'),
    ),
    nalog(
      5,
      l,
      'Acer Aspire 5',
      'Windows se ne pokreće, stoji na ekranu za popravku.',
      satiRanije: 720,
      stanje: Preuzet(sada.subtract(const Duration(days: 25))),
      serviser: 0,
    ),
  ];
}
