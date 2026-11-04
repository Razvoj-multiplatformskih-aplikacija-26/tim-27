import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'primeri.dart';

void main() {
  group('opis kvara od 10 do 500 znakova', () {
    test('prekratak opis', () {
      expect(OpisKvara.proveri('Ne radi'), const Neuspeh<OpisKvara>(OpisKvaraPrekratak(7)));
    });

    test('razmaci na krajevima se ne broje', () {
      expect(OpisKvara.proveri('   kratko   ').greskaIliNull, const OpisKvaraPrekratak(6));
    });

    test('granice su uključene', () {
      expect(OpisKvara.proveri('a' * 10).jeUspeh, isTrue);
      expect(OpisKvara.proveri('a' * 500).jeUspeh, isTrue);
      expect(OpisKvara.proveri('a' * 501), const Neuspeh<OpisKvara>(OpisKvaraPredugacak(501)));
    });

    test('naša slova se broje kao po jedan znak', () {
      expect(OpisKvara.proveri('čćžšđ' * 2).jeUspeh, isTrue);
    });
  });

  group('serviser ima najviše 5 aktivnih naloga', () {
    List<RadniNalog> aktivni(int broj) => [
      for (var i = 0; i < broj; i++) nalog(id: 'a-$i', stanje: const Dijagnostika(), serviserId: serviser.id),
    ];

    test('peti nalog može, šesti ne može', () {
      final slobodan = nalog(id: 'novi');
      expect(preuzmiNalog(slobodan, serviser: serviser, sviNalozi: [...aktivni(4), slobodan]).jeUspeh, isTrue);
      expect(
        preuzmiNalog(slobodan, serviser: serviser, sviNalozi: [...aktivni(5), slobodan]),
        const Neuspeh<RadniNalog>(PreviseAktivnihNaloga(5)),
      );
    });

    test('nalozi spremni za preuzimanje i završeni se ne broje', () {
      final nalozi = [
        ...aktivni(4),
        nalog(id: 'sp', stanje: const SpremanZaPreuzimanje(), serviserId: serviser.id),
        nalog(id: 'pr', stanje: Preuzet(sada), serviserId: serviser.id),
      ];
      expect(brojAktivnihNaloga(serviser.id, nalozi), 4);
      expect(preostaloMestaZaNaloge(serviser.id, nalozi), 1);
    });

    test('nalozi drugih servisera se ne broje', () {
      final nalozi = [
        for (var i = 0; i < 5; i++) nalog(id: 'd-$i', stanje: const Dijagnostika(), serviserId: drugiServiser.id),
      ];
      expect(brojAktivnihNaloga(serviser.id, nalozi), 0);
    });
  });

  group('rok od 48 sati za odgovor na ponudu', () {
    final n = nalog(stanje: CekaOdobrenje(ponuda), serviserId: serviser.id);

    test('tačno na roku još može', () {
      final rok = sada.add(const Duration(hours: 48));
      expect(odgovoriNaPonudu(n, klijent: klijent, prihvata: true, sada: rok).jeUspeh, isTrue);
      expect(klijentMozeDaOdgovori(n, sada: rok), isTrue);
    });

    test('posle roka ne može', () {
      final kasno = sada.add(const Duration(hours: 48, minutes: 1));
      expect(
        odgovoriNaPonudu(n, klijent: klijent, prihvata: true, sada: kasno),
        const Neuspeh<RadniNalog>(RokZaOdgovorIstekao()),
      );
      expect(klijentMozeDaOdgovori(n, sada: kasno), isFalse);
    });
  });

  group('ponuda', () {
    test('iznos mora biti pozitivan', () {
      expect(Ponuda.proveri(iznos: 0, opis: 'x', poslataU: sada).greskaIliNull, const NeispravanIznos(0));
    });

    test('opis je obavezan', () {
      expect(Ponuda.proveri(iznos: 100, opis: '  ', poslataU: sada).greskaIliNull, isA<OpisPonudeObavezan>());
    });
  });

  group('isti nalog ne mogu preuzeti dva servisera', () {
    test('preuzet nalog više nije slobodan', () {
      final n = nalog();
      final preuzet = preuzmiNalog(n, serviser: serviser, sviNalozi: [n]).vrednostIliNull!;
      expect(slobodniNalozi([preuzet]), isEmpty);
      expect(
        preuzmiNalog(preuzet, serviser: drugiServiser, sviNalozi: [preuzet]).greskaIliNull,
        isA<NalogVecPreuzet>(),
      );
    });

    test('slobodni su samo primljeni nalozi bez servisera', () {
      final nalozi = [
        nalog(id: '1'),
        nalog(id: '2', stanje: const Dijagnostika(), serviserId: serviser.id),
        nalog(id: '3', stanje: const Otkazan('')),
      ];
      expect(slobodniNalozi(nalozi).map((n) => n.id), [const NalogId('1')]);
    });
  });

  group('poslednji komad dela', () {
    const ssd = Deo(id: DeoId('d-ssd'), naziv: 'SSD 512 GB', naStanju: 2);

    test('drugi serviser ne može uzeti deo kog više nema', () {
      final prva = rezervisiDeo(deo: ssd, nalogId: const NalogId('n-1'), rezervacije: const []).vrednostIliNull!;
      final druga = rezervisiDeo(deo: ssd, nalogId: const NalogId('n-2'), rezervacije: [prva]).vrednostIliNull!;
      expect(preostaloNaStanju(ssd, [prva, druga]), 0);
      expect(
        rezervisiDeo(deo: ssd, nalogId: const NalogId('n-3'), rezervacije: [prva, druga]),
        const Neuspeh<RezervacijaDela>(NemaDelaNaStanju()),
      );
    });
  });

  group('akcije osoblja', () {
    test('slobodan nalog se preuzima ili otkazuje', () {
      final n = nalog();
      expect(akcijeOsoblja(n, serviser: serviser, sviNalozi: [n]), {AkcijaOsoblja.preuzmi, AkcijaOsoblja.otkazi});
    });

    test('nalog u popravci označava spremnim samo njegov serviser ili šef', () {
      final n = nalog(stanje: UPopravci(ponuda), serviserId: serviser.id);
      expect(akcijeOsoblja(n, serviser: serviser, sviNalozi: [n]), {AkcijaOsoblja.oznaciSpreman});
      expect(akcijeOsoblja(n, serviser: drugiServiser, sviNalozi: [n]), isEmpty);
      expect(akcijeOsoblja(n, serviser: sef, sviNalozi: [n]), {AkcijaOsoblja.oznaciSpreman});
    });
  });
}
