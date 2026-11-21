import 'dart:io';

import 'package:domain/domain.dart';

/// Port prema spoljnom servisu za SMS poruke. Poziva ga samo server; ključ je samo u
/// podešavanjima servera. Za KT2 postoji lažna implementacija koja poruku samo zapiše u log.
abstract interface class ObavestenjaKlijentu {
  Future<void> uredjajSpreman({required Korisnik klijent, required RadniNalog nalog});
}

final class LaznaSmsObavestenja implements ObavestenjaKlijentu {
  LaznaSmsObavestenja({required this.kljuc, IOSink? izlaz}) : _izlaz = izlaz ?? stdout;

  final String? kljuc;
  final IOSink _izlaz;
  final poslate = <String>[];

  @override
  Future<void> uredjajSpreman({required Korisnik klijent, required RadniNalog nalog}) async {
    final poruka =
        'Poštovani ${klijent.ime}, vaš uređaj ${nalog.uredjaj.naziv} (nalog ${nalog.id.value}) '
        'je popravljen i spreman za preuzimanje. Reboot servis.';
    poslate.add(poruka);
    final kljucOznaka = kljuc == null || kljuc!.isEmpty ? 'bez ključa' : 'ključ ${kljuc!.substring(0, 4)}…';
    _izlaz.writeln('[SMS, lažni servis, $kljucOznaka] ${klijent.telefon}: $poruka');
  }
}
