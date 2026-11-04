import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'primeri.dart';

void main() {
  final stanja = <StanjeNaloga>[
    const Primljen(),
    const Dijagnostika(),
    CekaOdobrenje(ponuda),
    UPopravci(ponuda),
    const SpremanZaPreuzimanje(),
    Preuzet(sada),
    const Otkazan('Klijent odustao'),
    OdbijenaPonuda(ponuda),
  ];

  group('dozvoljenPrelaz', () {
    final dozvoljeni = {
      (Primljen, Dijagnostika),
      (Primljen, Otkazan),
      (Dijagnostika, Otkazan),
      (Dijagnostika, CekaOdobrenje),
      (CekaOdobrenje, UPopravci),
      (CekaOdobrenje, OdbijenaPonuda),
      (UPopravci, SpremanZaPreuzimanje),
      (SpremanZaPreuzimanje, Preuzet),
    };

    for (final iz in stanja) {
      for (final u in stanja) {
        final ocekivano = dozvoljeni.contains((iz.runtimeType, u.runtimeType));
        test('${iz.runtimeType} -> ${u.runtimeType} je ${ocekivano ? 'dozvoljen' : 'zabranjen'}', () {
          expect(dozvoljenPrelaz(iz, u), ocekivano);
        });
      }
    }

    test('iz završnih stanja nema prelaza', () {
      for (final iz in stanja.where((s) => s.jeZavrsno)) {
        expect(stanja.where((u) => dozvoljenPrelaz(iz, u)), isEmpty);
      }
    });
  });

  group('tok naloga', () {
    test('ceo tok od prijema do preuzimanja', () {
      var n = nalog();
      n = preuzmiNalog(n, serviser: serviser, sviNalozi: [n]).vrednostIliNull!;
      expect(n.stanje, isA<Dijagnostika>());
      expect(n.serviserId, serviser.id);
      n = posaljiPonudu(n, serviser: serviser, ponuda: ponuda).vrednostIliNull!;
      expect(n.stanje, CekaOdobrenje(ponuda));
      n = odgovoriNaPonudu(n, klijent: klijent, prihvata: true, sada: sada).vrednostIliNull!;
      expect(n.stanje, UPopravci(ponuda));
      n = oznaciSpreman(n, serviser: serviser).vrednostIliNull!;
      expect(n.stanje, isA<SpremanZaPreuzimanje>());
      n = izdajUredjaj(n, serviser: drugiServiser, sada: sada).vrednostIliNull!;
      expect(n.stanje, Preuzet(sada));
    });

    test('odbijena ponuda završava nalog', () {
      final n = nalog(stanje: CekaOdobrenje(ponuda), serviserId: serviser.id);
      final rezultat = odgovoriNaPonudu(n, klijent: klijent, prihvata: false, sada: sada);
      expect(rezultat.vrednostIliNull?.stanje, OdbijenaPonuda(ponuda));
    });

    test('ponuda se ne šalje za nalog koji nije u dijagnostici', () {
      final n = nalog(stanje: UPopravci(ponuda), serviserId: serviser.id);
      expect(posaljiPonudu(n, serviser: serviser, ponuda: ponuda).greskaIliNull, isA<NedozvoljenPrelaz>());
    });

    test('tuđ nalog menja samo šef servisa', () {
      final n = nalog(stanje: const Dijagnostika(), serviserId: serviser.id);
      expect(posaljiPonudu(n, serviser: drugiServiser, ponuda: ponuda), const Neuspeh<RadniNalog>(NemaPrava()));
      expect(posaljiPonudu(n, serviser: sef, ponuda: ponuda).jeUspeh, isTrue);
    });

    test('klijent ne odgovara na tuđu ponudu', () {
      final n = nalog(stanje: CekaOdobrenje(ponuda), serviserId: serviser.id);
      expect(
        odgovoriNaPonudu(n, klijent: drugiKlijent, prihvata: true, sada: sada),
        const Neuspeh<RadniNalog>(NemaPrava()),
      );
    });

    test('otkazuje se samo pre ponude', () {
      expect(otkaziNalog(nalog(), serviser: serviser, razlog: 'Duplikat').jeUspeh, isTrue);
      final n = nalog(stanje: CekaOdobrenje(ponuda), serviserId: serviser.id);
      expect(otkaziNalog(n, serviser: serviser, razlog: 'x').greskaIliNull, isA<NedozvoljenPrelaz>());
    });
  });
}
