import 'dart:convert';
import 'dart:io';

/// Podešavanja servera iz okruženja; lokalno iz .env u korenu repozitorijuma (van git-a).
final class Konfiguracija {
  const Konfiguracija({
    required this.host,
    required this.port,
    required this.adresaBaze,
    required this.dozvoljeniIzvori,
    required this.jwtTajna,
    this.trajanjePrijave = const Duration(hours: 8),
    this.bezbedanKolacic = false,
    this.demoLozinka,
    this.smsKljuc,
  });

  factory Konfiguracija.izOkruzenja(Map<String, String> okruzenje) => Konfiguracija(
    host: okruzenje['HOST'] ?? '127.0.0.1',
    port: int.parse(okruzenje['PORT'] ?? '8080'),
    adresaBaze:
        okruzenje['DATABASE_URL'] ??
        (throw StateError('DATABASE_URL nije podešen. Kopirajte .env.example u .env u korenu repozitorijuma.')),
    dozvoljeniIzvori: [
      for (final izvor in (okruzenje['CORS_ORIGINS'] ?? 'http://localhost:8081').split(','))
        if (izvor.trim().isNotEmpty) izvor.trim(),
    ],
    trajanjePrijave: Duration(minutes: int.parse(okruzenje['SESSION_TTL_MINUTES'] ?? '480')),
    bezbedanKolacic: okruzenje['COOKIE_SECURE'] == 'true',
    demoLozinka: okruzenje['DEMO_PASSWORD'],
    jwtTajna: _jwtTajna(okruzenje['JWT_SECRET']),
    smsKljuc: okruzenje['SMS_API_KEY'],
  );

  final String host;
  final int port;
  final String adresaBaze;
  final List<String> dozvoljeniIzvori;
  final Duration trajanjePrijave;
  final bool bezbedanKolacic;
  final String? demoLozinka;
  final String jwtTajna;

  /// Ključ spoljnog SMS servisa; postoji samo na serveru, klijenti ga nikad ne vide.
  final String? smsKljuc;
}

String _jwtTajna(String? tajna) => switch (tajna) {
  null => throw StateError('JWT_SECRET nije podešen. Kopirajte .env.example u .env u korenu repozitorijuma.'),
  final tajna when utf8.encode(tajna).length < 32 => throw StateError('JWT_SECRET mora imati bar 32 bajta.'),
  final tajna => tajna,
};

Map<String, String> procitajEnv(File fajl) {
  if (!fajl.existsSync()) return const {};
  return {
    for (final red in fajl.readAsLinesSync())
      if (red.indexOf('=') case final podela when podela > 0 && !red.trimLeft().startsWith('#'))
        red.substring(0, podela).trim(): _bezNavodnika(red.substring(podela + 1).trim()),
  };
}

String _bezNavodnika(String vrednost) =>
    vrednost.length > 1 && (vrednost[0] == '"' || vrednost[0] == "'") && vrednost.endsWith(vrednost[0])
    ? vrednost.substring(1, vrednost.length - 1)
    : vrednost;

/// .env iz korena workspace-a, pa promenljive okruženja (one imaju prednost, kao u Docker Compose-u).
Map<String, String> okruzenjeServera() => {
  ...procitajEnv(_envFajl(Directory.current.absolute)),
  ...Platform.environment,
};

File _envFajl(Directory folder) {
  final fajl = File('${folder.path}${Platform.pathSeparator}.env');
  final roditelj = folder.parent;
  if (fajl.existsSync() || _jeKorenWorkspacea(folder) || roditelj.path == folder.path) return fajl;
  return _envFajl(roditelj);
}

bool _jeKorenWorkspacea(Directory folder) {
  final pubspec = File('${folder.path}${Platform.pathSeparator}pubspec.yaml');
  return pubspec.existsSync() && pubspec.readAsLinesSync().any((red) => red.startsWith('workspace:'));
}
