# Reboot – servis računara

Sistem za prijem i praćenje popravki računara u servisu. Klijenti preko mobilne aplikacije prijavljuju uređaj za popravku, prate radni nalog kroz dijagnostiku i popravku i odobravaju ponudu, i kada nemaju signal. Serviseri i šef servisa u backoffice aplikaciji preuzimaju naloge, prave ponude i vode stanje rezervnih delova, a javni veb prikazuje cenovnik, usluge i radno vreme servisa.

## Tim

| Ime i prezime | Broj indeksa | GitHub nalog |
| --- | --- | --- |
| Vojin Prljević | SI 74/24 | [VPrljevic](https://github.com/VPrljevic) |

Projekat radim samostalno.

## Zahtevi za temu

1. **Uloge.** Klijent vidi i menja samo svoje radne naloge (prijava uređaja, odgovor na ponudu). Serviser vidi sve naloge, preuzima ih i menja im stanje, a šef servisa uz to dodeljuje naloge serviserima i vodi stanje rezervnih delova.
2. **Stanja.** Glavni pojam je radni nalog, koji prolazi kroz stanja: primljen, dijagnostika, čeka odobrenje, u popravci, spreman za preuzimanje i preuzet. Nalog može da završi i kao otkazan ili kao odbijena ponuda.
3. **Pravila.** Klijent mora da odgovori na ponudu u roku od 48 sati, a serviser može imati najviše 5 aktivnih naloga. Dva servisera ne mogu istovremeno preuzeti isti nalog niti rezervisati poslednji komad istog dela sa stanja; o tome konačno odlučuje server, jer zavisi od podataka drugih korisnika.
4. **Rad bez mreže.** Klijent može da odobri ili odbije ponudu bez signala, a odluka se šalje serveru kada se veza vrati. Ako ponuda u međuvremenu istekne, server odbija zakasnelu odluku i klijent to vidi u aplikaciji.
5. **Posao za osoblje.** Osoblje radi sa svim nalozima servisa odjednom: tabla naloga po fazama, dodela servisera i pregled stanja delova, što zahteva veći ekran.
6. **Javni sadržaj.** Cenovnik usluga, vrste uređaja koje servis popravlja i radno vreme dostupni su svima bez prijave i imaju smisla za pretraživače.

## Delovi sistema

| Deo | Korisnici | Tehnologija | Platforme |
| --- | --- | --- | --- |
| Mobilna aplikacija | klijenti | Flutter | Android, iOS |
| Backoffice | serviseri, šef servisa | Flutter | Windows, macOS, Linux, veb |
| Javni veb | svi, pretraživači | Jaspr | veb |
| Server | svi klijenti sistema | Dart, Relic | Linux (Docker) |
| Domenski paket | svi delovi | Dart | sve |

```mermaid
flowchart LR
    M[Mobilna aplikacija] --> S[Server]
    B[Backoffice] --> S
    W[Javni veb] --> S
    S --> DB[(PostgreSQL)]
```

## Stanje projekta

Urađena je KT1: mobilna aplikacija i backoffice rade nad istim domenskim paketom i paketom sa Blocovima. Podaci su lažni i čuvaju se u memoriji; svaka aplikacija ima svoje podatke i oni se ne sinhronizuju. Server, baza i prijava korisnika (KT2), rad bez mreže (KT3) i javni veb (KT4) dolaze kasnije.

| Folder | Šta je u njemu |
| --- | --- |
| `packages/domain` | čist Dart: radni nalog, stanja (sealed), `dozvoljenPrelaz`, akcije i pravila koja vraćaju `Rezultat` sa greškom kao tipom |
| `packages/blocs` | čist Dart: port `NalogRepository`, `MojiNaloziBloc` (klijent) i `TablaNalogaBloc` (osoblje) |
| `apps/mobile` | Flutter za Android i iOS, uloga klijent (Ana Jovanović) |
| `apps/backoffice` | Flutter za Windows, macOS, Linux i veb, uloga serviser (Marko Marković) |

Lažna implementacija porta je u `lib/data/lazni_nalozi.dart` svake aplikacije i bira se samo u `lib/dependencies.dart`.

## Pokretanje

Potreban je Flutter 3.47 (Dart 3.13 ili noviji). Iz korena repozitorijuma:

```sh
flutter pub get
```

Mobilna aplikacija, na Android emulatoru ili telefonu:

```sh
cd apps/mobile
flutter run
```

Backoffice, na desktopu ili u pregledaču:

```sh
cd apps/backoffice
flutter run -d windows    # ili -d macos, -d linux, -d chrome
```

Provere iz korena:

```sh
flutter analyze
cd packages/domain && dart test
cd packages/blocs && dart test
cd apps/mobile && flutter test
cd apps/backoffice && flutter test
```

Za demonstraciju stanja ekrana obe aplikacije imaju meni (tri tačke gore desno): „Simuliraj grešku sledećeg zahteva“ i „Prikaži prazan odgovor“. Lažni podaci kasne oko 0,7 s, pa se vidi i učitavanje.

## Prečice u backoffice-u

| Taster | Radnja |
| --- | --- |
| ↑ / ↓ ili K / J | prethodni / sledeći nalog |
| Esc | poništi izbor |
| P | preuzmi nalog |
| O | pošalji ponudu |
| S | označi spreman za preuzimanje |
| I | izdaj uređaj klijentu |
| X | otkaži nalog |
| R | osveži naloge |
| ? ili F1 | pregled prečica |
| Tab | kretanje kroz dugmad |

Ispod širine od 900 tačaka tabela postaje lista, a detalj izabranog naloga prelazi ispod liste; izbor ostaje isti.
