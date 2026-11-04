import 'package:domain/domain.dart';

const prijavljeniKlijent = Klijent(id: KlijentId('k-1'), ime: 'Ana Jovanović', telefon: '064 123 4567');

const _serviser = ServiserId('s-1');

/// Lažni nalozi prijavljenog klijenta: 11 naloga, svako stanje bar jednom.
List<RadniNalog> pocetniNalozi(DateTime sada) {
  RadniNalog nalog(
    String id,
    VrstaUredjaja vrsta,
    String naziv,
    String opis, {
    required Duration pre,
    StanjeNaloga stanje = const Primljen(),
    bool preuzet = true,
  }) => RadniNalog(
    id: NalogId(id),
    klijentId: prijavljeniKlijent.id,
    uredjaj: Uredjaj.proveri(vrsta: vrsta, naziv: naziv).vrednostIliNull!,
    opisKvara: OpisKvara.proveri(opis).vrednostIliNull!,
    primljenU: sada.subtract(pre),
    stanje: stanje,
    serviserId: preuzet && stanje is! Primljen ? _serviser : null,
  );

  Ponuda ponuda(int iznos, String opis, Duration pre) =>
      Ponuda.proveri(iznos: iznos, opis: opis, poslataU: sada.subtract(pre)).vrednostIliNull!;

  return [
    nalog(
      'RN-1001',
      VrstaUredjaja.laptop,
      'Lenovo ThinkPad T14',
      'Laptop se gasi posle desetak minuta rada, ventilator je jako bučan.',
      pre: const Duration(hours: 3),
    ),
    nalog(
      'RN-1002',
      VrstaUredjaja.desktop,
      'Dell OptiPlex 7090',
      'Računar ne prikazuje sliku, čuju se tri kratka zvučna signala.',
      pre: const Duration(days: 1),
      stanje: const Dijagnostika(),
    ),
    nalog(
      'RN-1003',
      VrstaUredjaja.laptop,
      'Apple MacBook Air M1',
      'Prosuta kafa po tastaturi, neki tasteri ne rade.',
      pre: const Duration(days: 2),
      stanje: CekaOdobrenje(ponuda(14500, 'Zamena tastature i čišćenje matične ploče.', const Duration(hours: 5))),
    ),
    nalog(
      'RN-1004',
      VrstaUredjaja.monitor,
      'Samsung Odyssey G5',
      'Monitor treperi i povremeno se sam isključi.',
      pre: const Duration(days: 5),
      stanje: CekaOdobrenje(ponuda(6200, 'Zamena napajanja monitora.', const Duration(hours: 60))),
    ),
    nalog(
      'RN-1005',
      VrstaUredjaja.laptop,
      'HP Pavilion 15',
      'Baterija se ne puni, laptop radi samo na punjaču.',
      pre: const Duration(days: 4),
      stanje: UPopravci(ponuda(7800, 'Nova baterija i provera konektora za punjenje.', const Duration(days: 3))),
    ),
    nalog(
      'RN-1006',
      VrstaUredjaja.stampac,
      'Epson EcoTank L3250',
      'Štampač izbacuje prazne stranice iako ima mastila.',
      pre: const Duration(days: 6),
      stanje: const SpremanZaPreuzimanje(),
    ),
    nalog(
      'RN-1007',
      VrstaUredjaja.desktop,
      'Gaming PC (Ryzen 5, RTX 3060)',
      'Računar se restartuje pri pokretanju igrica.',
      pre: const Duration(days: 20),
      stanje: Preuzet(sada.subtract(const Duration(days: 12))),
    ),
    nalog(
      'RN-1008',
      VrstaUredjaja.laptop,
      'Asus VivoBook 14',
      'Ekran je napukao posle pada, slika se vidi samo u donjem delu.',
      pre: const Duration(days: 15),
      stanje: OdbijenaPonuda(ponuda(18900, 'Zamena ekrana.', const Duration(days: 13))),
    ),
    nalog(
      'RN-1009',
      VrstaUredjaja.ostalo,
      'Logitech MX Keys',
      'Tastatura se ne povezuje preko Bluetooth-a.',
      pre: const Duration(days: 10),
      stanje: const Otkazan('Klijent je sam rešio problem.'),
    ),
    nalog(
      'RN-1010',
      VrstaUredjaja.laptop,
      'Acer Aspire 5',
      'Windows se ne pokreće, stoji na ekranu za popravku.',
      pre: const Duration(days: 30),
      stanje: Preuzet(sada.subtract(const Duration(days: 25))),
    ),
    nalog(
      'RN-1011',
      VrstaUredjaja.desktop,
      'Lenovo IdeaCentre 3',
      'Računar je jako spor i zagreva se, potrebno čišćenje i nova termalna pasta.',
      pre: const Duration(days: 3),
      stanje: UPopravci(ponuda(3500, 'Čišćenje i zamena termalne paste.', const Duration(days: 2))),
    ),
  ];
}
