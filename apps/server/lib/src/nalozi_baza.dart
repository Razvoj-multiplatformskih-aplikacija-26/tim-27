import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

/// Pristup tabelama korisnici i nalozi. Promene idu kroz [promeni], u transakciji sa
/// zaključanim redovima, pa pravilo nad podacima drugih korisnika konačno odlučuje server.
final class NaloziBaza {
  const NaloziBaza(this._baza);

  final Pool<void> _baza;

  Future<Korisnik?> korisnik(String id) async {
    final redovi = await _baza.execute(
      Sql.named('SELECT id, ime, uloga, telefon FROM korisnici WHERE id = @id'),
      parameters: {'id': id},
    );
    return redovi.isEmpty ? null : _korisnik(redovi.single);
  }

  Future<List<Korisnik>> korisniciUloge(List<Uloga> uloge) async {
    final redovi = await _baza.execute(
      Sql.named('SELECT id, ime, uloga, telefon FROM korisnici WHERE uloga = ANY(@uloge) ORDER BY ime'),
      parameters: {
        'uloge': TypedValue(Type.textArray, [for (final u in uloge) u.name]),
      },
    );
    return [for (final red in redovi) _korisnik(red)];
  }

  Future<List<RadniNalog>> sviNalozi() => _nalozi(_baza, 'TRUE', const {});

  Future<List<RadniNalog>> naloziKlijenta(String klijentId) =>
      _nalozi(_baza, 'klijent_id = @klijent', {'klijent': klijentId});

  Future<RadniNalog?> nalog(NalogId id) async {
    final nadjeni = await _nalozi(_baza, 'id = @id', {'id': id.value});
    return nadjeni.firstOrNull;
  }

  Future<RadniNalog> dodaj({required Klijent klijent, required Uredjaj uredjaj, required OpisKvara opisKvara}) async {
    return _baza.runTx((tx) async {
      final broj = (await tx.execute("SELECT nextval('broj_naloga')")).single[0]! as int;
      final nalog = prijaviUredjaj(
        id: NalogId('RN-$broj'),
        klijent: klijent,
        uredjaj: uredjaj,
        opisKvara: opisKvara,
        sada: DateTime.now().toUtc(),
      );
      await upisi(tx, nalog);
      return nalog;
    });
  }

  /// Menja nalog u transakciji. Red naloga je zaključan (FOR UPDATE), pa dva klijenta koja
  /// istovremeno menjaju isti nalog idu jedan za drugim, a drugi vidi promenu prvog.
  /// [zakljucajServisera] zaključava i red servisera i daje njegove naloge, pa ni dva
  /// istovremena preuzimanja istog servisera ne mogu da pređu granicu aktivnih naloga.
  Future<Rezultat<RadniNalog>> promeni(
    NalogId id, {
    String? zakljucajServisera,
    required Rezultat<RadniNalog> Function(RadniNalog trenutni, List<RadniNalog> naloziServisera) promena,
  }) => _baza.runTx((tx) async {
    var naloziServisera = const <RadniNalog>[];
    if (zakljucajServisera != null) {
      await tx.execute(
        Sql.named('SELECT id FROM korisnici WHERE id = @id FOR UPDATE'),
        parameters: {'id': zakljucajServisera},
      );
      naloziServisera = await _nalozi(tx, 'serviser_id = @serviser', {'serviser': zakljucajServisera});
    }
    final trenutni = (await _nalozi(tx, 'id = @id', {'id': id.value}, zakljucaj: true)).firstOrNull;
    if (trenutni == null) return const Neuspeh(NalogNijePronadjen());
    final rezultat = promena(trenutni, naloziServisera);
    if (rezultat case Uspeh(:final vrednost)) await upisi(tx, vrednost);
    return rezultat;
  });

  /// Upisuje ceo nalog (nov ili izmenjen).
  static Future<void> upisi(Session tx, RadniNalog nalog) async {
    final stanje = nalog.stanje;
    final ponuda = switch (stanje) {
      CekaOdobrenje(:final ponuda) || UPopravci(:final ponuda) || OdbijenaPonuda(:final ponuda) => ponuda,
      _ => null,
    };
    await tx.execute(
      Sql.named('''
        INSERT INTO nalozi (id, klijent_id, serviser_id, vrsta_uredjaja, naziv_uredjaja, opis_kvara, primljen_u, stanje,
                            ponuda_iznos, ponuda_opis, ponuda_poslata_u, preuzet_u, razlog_otkaza)
        VALUES (@id, @klijent, @serviser, @vrsta, @naziv, @opis, @primljen, @stanje,
                @iznos, @ponudaOpis, @poslata, @preuzet, @razlog)
        ON CONFLICT (id) DO UPDATE SET
          serviser_id = EXCLUDED.serviser_id, stanje = EXCLUDED.stanje,
          ponuda_iznos = EXCLUDED.ponuda_iznos, ponuda_opis = EXCLUDED.ponuda_opis,
          ponuda_poslata_u = EXCLUDED.ponuda_poslata_u, preuzet_u = EXCLUDED.preuzet_u,
          razlog_otkaza = EXCLUDED.razlog_otkaza
      '''),
      parameters: {
        'id': nalog.id.value,
        'klijent': nalog.klijentId.value,
        'serviser': nalog.serviserId?.value,
        'vrsta': nalog.uredjaj.vrsta.name,
        'naziv': nalog.uredjaj.naziv,
        'opis': nalog.opisKvara.tekst,
        'primljen': nalog.primljenU.toUtc(),
        'stanje': stanje.vrsta,
        'iznos': ponuda?.iznos,
        'ponudaOpis': ponuda?.opis,
        'poslata': ponuda?.poslataU.toUtc(),
        'preuzet': switch (stanje) {
          Preuzet(:final preuzetU) => preuzetU.toUtc(),
          _ => null,
        },
        'razlog': switch (stanje) {
          Otkazan(:final razlog) => razlog,
          _ => null,
        },
      },
    );
  }

  static Future<List<RadniNalog>> _nalozi(
    Session baza,
    String uslov,
    Map<String, Object?> parametri, {
    bool zakljucaj = false,
  }) async {
    final redovi = await baza.execute(
      Sql.named('''
        SELECT id, klijent_id, serviser_id, vrsta_uredjaja, naziv_uredjaja, opis_kvara, primljen_u, stanje,
               ponuda_iznos, ponuda_opis, ponuda_poslata_u, preuzet_u, razlog_otkaza
        FROM nalozi WHERE $uslov ORDER BY primljen_u DESC${zakljucaj ? ' FOR UPDATE' : ''}
      '''),
      parameters: parametri,
    );
    return [for (final red in redovi) _nalog(red.toColumnMap())];
  }
}

RadniNalog _nalog(Map<String, dynamic> red) => NalogDto(
  id: red['id'] as String,
  klijentId: red['klijent_id'] as String,
  serviserId: red['serviser_id'] as String?,
  vrstaUredjaja: red['vrsta_uredjaja'] as String,
  nazivUredjaja: red['naziv_uredjaja'] as String,
  opisKvara: red['opis_kvara'] as String,
  primljenU: (red['primljen_u'] as DateTime).toUtc(),
  stanje: StanjeDto(
    vrsta: red['stanje'] as String,
    ponuda: switch (red['ponuda_iznos']) {
      final int iznos => PonudaDto(
        iznosDinara: iznos,
        opis: red['ponuda_opis'] as String,
        poslataU: (red['ponuda_poslata_u'] as DateTime).toUtc(),
      ),
      _ => null,
    },
    preuzetU: (red['preuzet_u'] as DateTime?)?.toUtc(),
    razlog: red['razlog_otkaza'] as String?,
  ),
).toDomain();

Korisnik _korisnik(ResultRow red) => Korisnik(
  id: red[0]! as String,
  ime: red[1]! as String,
  uloga: Uloga.values.byName(red[2]! as String),
  telefon: red[3]! as String,
);
