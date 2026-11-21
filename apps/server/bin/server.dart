import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';

Future<void> main() async {
  final konfiguracija = Konfiguracija.izOkruzenja(okruzenjeServera());
  final baza = Pool<void>.withUrl(konfiguracija.adresaBaze);
  await _sacekajBazu(baza);
  await primeniMigracije(baza, folderMigracija());
  await unesiPocetnePodatke(baza, demoLozinka: konfiguracija.demoLozinka, sada: DateTime.now().toUtc());
  final nalozi = NaloziRukovaoci(
    baza: NaloziBaza(baza),
    obavestenja: LaznaSmsObavestenja(kljuc: konfiguracija.smsKljuc),
  );
  final sesije = SesijeRukovaoci(
    baza: baza,
    tajna: konfiguracija.jwtTajna,
    trajanje: konfiguracija.trajanjePrijave,
    bezbedanKolacic: konfiguracija.bezbedanKolacic,
  );
  final server = RelicServer(() => IOAdapter.bind(InternetAddress(konfiguracija.host), port: konfiguracija.port));
  await server.mountAndStart(napraviRukovaoca(nalozi, sesije, dozvoljeniIzvori: konfiguracija.dozvoljeniIzvori));
  stdout.writeln('Reboot server radi na http://${konfiguracija.host}:${konfiguracija.port}');
  await _signalZaKraj();
  await server.close();
  await baza.close();
}

/// Baza u Docker Compose-u može da se podiže koju sekundu duže od servera.
Future<void> _sacekajBazu(Pool<void> baza) async {
  for (var pokusaj = 1; ; pokusaj++) {
    try {
      await baza.execute('SELECT 1');
      return;
    } on Exception catch (uzrok) {
      if (pokusaj >= 30) rethrow;
      stdout.writeln('Čekam bazu ($pokusaj): $uzrok');
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }
}

Future<void> _signalZaKraj() async {
  final kraj = Completer<void>();
  final pretplate = [
    for (final signal in [ProcessSignal.sigint, if (!Platform.isWindows) ProcessSignal.sigterm])
      signal.watch().listen((_) => kraj.isCompleted ? null : kraj.complete()),
  ];
  await kraj.future;
  for (final pretplata in pretplate) {
    await pretplata.cancel();
  }
}
