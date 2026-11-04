import 'package:domain/domain.dart';

final sada = DateTime.utc(2026, 11, 4, 12);

const klijent = Klijent(id: KlijentId('k-1'), ime: 'Ana Jovanović', telefon: '0641234567');
const drugiKlijent = Klijent(id: KlijentId('k-2'), ime: 'Petar Ilić', telefon: '0657654321');
const serviser = Serviser(id: ServiserId('s-1'), ime: 'Marko Marković');
const drugiServiser = Serviser(id: ServiserId('s-2'), ime: 'Jelena Petrović');
const sef = Serviser(id: ServiserId('s-sef'), ime: 'Nikola Nikolić', uloga: UlogaOsoblja.sefServisa);

final ponuda = Ponuda.proveri(iznos: 8500, opis: 'Zamena ventilatora', poslataU: sada).vrednostIliNull!;

RadniNalog nalog({String id = 'n-1', StanjeNaloga stanje = const Primljen(), ServiserId? serviserId}) => RadniNalog(
  id: NalogId(id),
  klijentId: klijent.id,
  uredjaj: Uredjaj.proveri(vrsta: VrstaUredjaja.laptop, naziv: 'Lenovo ThinkPad T14').vrednostIliNull!,
  opisKvara: OpisKvara.proveri('Laptop se gasi posle par minuta rada.').vrednostIliNull!,
  primljenU: sada,
  stanje: stanje,
  serviserId: serviserId,
);
