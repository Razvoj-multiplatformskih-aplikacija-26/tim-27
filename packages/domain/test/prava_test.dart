import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'primeri.dart';

void main() {
  const ana = Korisnik(id: 'k-1', ime: 'Ana Jovanović', uloga: Uloga.klijent);
  const petar = Korisnik(id: 'k-2', ime: 'Petar Ilić', uloga: Uloga.klijent);
  const marko = Korisnik(id: 's-1', ime: 'Marko Marković', uloga: Uloga.serviser);
  const nikola = Korisnik(id: 's-3', ime: 'Nikola Nikolić', uloga: Uloga.sefServisa);

  test('backoffice je za osoblje, mobilna aplikacija za klijente', () {
    expect(smeDaKoristi(Aplikacija.backoffice, Uloga.klijent), isFalse);
    expect(smeDaKoristi(Aplikacija.backoffice, Uloga.serviser), isTrue);
    expect(smeDaKoristi(Aplikacija.backoffice, Uloga.sefServisa), isTrue);
    expect(smeDaKoristi(Aplikacija.mobilna, Uloga.klijent), isTrue);
    expect(smeDaKoristi(Aplikacija.mobilna, Uloga.serviser), isFalse);
  });

  test('klijent vidi samo svoj nalog, osoblje vidi sve', () {
    final anin = nalog();
    expect(smeDaVidi(ana, anin), isTrue);
    expect(smeDaVidi(petar, anin), isFalse);
    expect(smeDaVidi(marko, anin), isTrue);
  });

  test('klijent ne postaje serviser, pa ne može akcije osoblja', () {
    expect(kaoServiser(ana), isNull);
    expect(kaoServiser(marko)?.jeSef, isFalse);
    expect(kaoServiser(nikola)?.jeSef, isTrue);
    expect(kaoKlijent(marko), isNull);
    expect(kaoKlijent(ana)?.id, const KlijentId('k-1'));
  });

  test('tuđ klijent ne može da odgovori na ponudu', () {
    final ceka = nalog(stanje: CekaOdobrenje(ponuda));
    expect(
      odgovoriNaPonudu(ceka, klijent: kaoKlijent(petar)!, prihvata: true, sada: sada),
      const Neuspeh<RadniNalog>(NemaPrava()),
    );
  });
}
