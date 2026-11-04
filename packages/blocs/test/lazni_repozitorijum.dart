import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

final sada = DateTime.utc(2026, 11, 4, 12);

const klijent = Klijent(id: KlijentId('k-1'), ime: 'Ana Jovanović', telefon: '0641234567');
const serviser = Serviser(id: ServiserId('s-1'), ime: 'Marko Marković');

final ponuda = Ponuda.proveri(iznos: 8500, opis: 'Zamena ventilatora', poslataU: sada).vrednostIliNull!;
final uredjaj = Uredjaj.proveri(vrsta: VrstaUredjaja.laptop, naziv: 'Lenovo ThinkPad T14').vrednostIliNull!;
final opis = OpisKvara.proveri('Laptop se gasi posle par minuta rada.').vrednostIliNull!;

RadniNalog nalog(String id, {StanjeNaloga stanje = const Primljen(), ServiserId? serviserId}) => RadniNalog(
  id: NalogId(id),
  klijentId: klijent.id,
  uredjaj: uredjaj,
  opisKvara: opis,
  primljenU: sada,
  stanje: stanje,
  serviserId: serviserId,
);

/// Najjednostavnija implementacija porta za testove: bez kašnjenja.
final class LazniRepozitorijum implements NalogRepository {
  LazniRepozitorijum(List<RadniNalog> nalozi) : _nalozi = [...nalozi];

  final List<RadniNalog> _nalozi;
  int neuspesnihZahteva = 0;

  void _proveri() {
    if (neuspesnihZahteva > 0) {
      neuspesnihZahteva--;
      throw const GreskaRepozitorijuma('Simulirana greška');
    }
  }

  @override
  Future<List<RadniNalog>> naloziKlijenta(KlijentId klijentId) async {
    _proveri();
    return _nalozi.where((n) => n.klijentId == klijentId).toList();
  }

  @override
  Future<List<RadniNalog>> sviNalozi() async {
    _proveri();
    return [..._nalozi];
  }

  @override
  Future<RadniNalog?> nadji(NalogId id) async {
    _proveri();
    return _nalozi.where((n) => n.id == id).firstOrNull;
  }

  @override
  Future<RadniNalog> sacuvaj(RadniNalog nalog) async {
    _proveri();
    _nalozi[_nalozi.indexWhere((n) => n.id == nalog.id)] = nalog;
    return nalog;
  }

  @override
  Future<RadniNalog> prijavi({required Klijent klijent, required Uredjaj uredjaj, required OpisKvara opisKvara}) async {
    _proveri();
    final novi = prijaviUredjaj(
      id: NalogId('novi-${_nalozi.length}'),
      klijent: klijent,
      uredjaj: uredjaj,
      opisKvara: opisKvara,
      sada: sada,
    );
    _nalozi.add(novi);
    return novi;
  }

  @override
  Future<List<Klijent>> klijenti() async => const [klijent];

  @override
  Future<List<Serviser>> serviseri() async => const [serviser];
}
