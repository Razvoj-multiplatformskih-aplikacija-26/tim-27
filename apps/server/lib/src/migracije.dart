import 'dart:io';

import 'package:postgres/postgres.dart';

/// Izvršava SQL fajlove iz foldera migrations tačno jednom, po redu imena. Šema je tako
/// uvek ona iz repozitorijuma, bez posebnog alata u Docker Compose-u.
Future<void> primeniMigracije(Pool<void> baza, Directory folder) async {
  await baza.execute(
    'CREATE TABLE IF NOT EXISTS sema_migracije (ime text PRIMARY KEY, primenjena timestamptz NOT NULL)',
  );
  final fajlovi = folder.listSync().whereType<File>().where((f) => f.path.endsWith('.sql')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final fajl in fajlovi) {
    final ime = fajl.uri.pathSegments.last;
    await baza.runTx((tx) async {
      // Zaključavanje sprečava da dva servera koja se pokreću istovremeno primene istu migraciju.
      await tx.execute('LOCK TABLE sema_migracije IN EXCLUSIVE MODE');
      final vec = await tx.execute(
        Sql.named('SELECT 1 FROM sema_migracije WHERE ime = @ime'),
        parameters: {'ime': ime},
      );
      if (vec.isNotEmpty) return;
      await tx.execute(fajl.readAsStringSync(), queryMode: QueryMode.simple);
      await tx.execute(
        Sql.named('INSERT INTO sema_migracije (ime, primenjena) VALUES (@ime, now())'),
        parameters: {'ime': ime},
      );
      stdout.writeln('Migracija primenjena: $ime');
    });
  }
}

/// Folder sa migracijama: pored izvršnog fajla u Docker slici, ili apps/server/migrations lokalno.
Directory folderMigracija() {
  for (final putanja in [
    Platform.environment['MIGRATIONS_DIR'],
    'migrations',
    'apps/server/migrations',
    '../../apps/server/migrations',
  ]) {
    if (putanja != null && Directory(putanja).existsSync()) return Directory(putanja);
  }
  throw StateError('Folder sa migracijama nije pronađen. Postavite MIGRATIONS_DIR.');
}
