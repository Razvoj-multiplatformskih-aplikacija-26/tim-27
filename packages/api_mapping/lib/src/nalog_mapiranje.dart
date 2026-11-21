import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

extension RadniNalogUDto on RadniNalog {
  NalogDto toDto() => NalogDto(
    id: id.value,
    klijentId: klijentId.value,
    serviserId: serviserId?.value,
    vrstaUredjaja: uredjaj.vrsta.name,
    nazivUredjaja: uredjaj.naziv,
    opisKvara: opisKvara.tekst,
    primljenU: primljenU.toUtc(),
    stanje: stanje.toDto(),
  );
}

extension NalogDtoUDomen on NalogDto {
  /// Zapis koji ne prolazi pravila domena nije ispravan odgovor: baca FormatException.
  RadniNalog toDomain() => RadniNalog(
    id: NalogId(id),
    klijentId: KlijentId(klijentId),
    serviserId: switch (serviserId) {
      final id? => ServiserId(id),
      null => null,
    },
    uredjaj: _ispravno(Uredjaj.proveri(vrsta: vrstaUredjajaIz(vrstaUredjaja), naziv: nazivUredjaja)),
    opisKvara: _ispravno(OpisKvara.proveri(opisKvara)),
    primljenU: primljenU,
    stanje: stanje.toDomain(),
  );
}

extension PonudaUDto on Ponuda {
  PonudaDto toDto() => PonudaDto(iznosDinara: iznos, opis: opis, poslataU: poslataU.toUtc());
}

extension PonudaDtoUDomen on PonudaDto {
  Ponuda toDomain() => _ispravno(Ponuda.proveri(iznos: iznosDinara, opis: opis, poslataU: poslataU));
}

extension StanjeUDto on StanjeNaloga {
  String get vrsta => switch (this) {
    Primljen() => VrsteStanja.primljen,
    Dijagnostika() => VrsteStanja.dijagnostika,
    CekaOdobrenje() => VrsteStanja.cekaOdobrenje,
    UPopravci() => VrsteStanja.uPopravci,
    SpremanZaPreuzimanje() => VrsteStanja.spremanZaPreuzimanje,
    Preuzet() => VrsteStanja.preuzet,
    Otkazan() => VrsteStanja.otkazan,
    OdbijenaPonuda() => VrsteStanja.odbijenaPonuda,
  };

  StanjeDto toDto() => switch (this) {
    CekaOdobrenje(:final ponuda) ||
    UPopravci(:final ponuda) ||
    OdbijenaPonuda(:final ponuda) => StanjeDto(vrsta: vrsta, ponuda: ponuda.toDto()),
    Preuzet(:final preuzetU) => StanjeDto(vrsta: vrsta, preuzetU: preuzetU.toUtc()),
    Otkazan(:final razlog) => StanjeDto(vrsta: vrsta, razlog: razlog),
    _ => StanjeDto(vrsta: vrsta),
  };
}

extension StanjeDtoUDomen on StanjeDto {
  StanjeNaloga toDomain() {
    Ponuda trazenaPonuda() => switch (ponuda) {
      final ponuda? => ponuda.toDomain(),
      null => throw FormatException('Stanje $vrsta mora imati ponudu'),
    };
    return switch (vrsta) {
      VrsteStanja.primljen => const Primljen(),
      VrsteStanja.dijagnostika => const Dijagnostika(),
      VrsteStanja.cekaOdobrenje => CekaOdobrenje(trazenaPonuda()),
      VrsteStanja.uPopravci => UPopravci(trazenaPonuda()),
      VrsteStanja.odbijenaPonuda => OdbijenaPonuda(trazenaPonuda()),
      VrsteStanja.spremanZaPreuzimanje => const SpremanZaPreuzimanje(),
      VrsteStanja.preuzet => Preuzet(preuzetU ?? (throw const FormatException('Preuzet nalog mora imati vreme'))),
      VrsteStanja.otkazan => Otkazan(razlog ?? ''),
      _ => throw FormatException('Nepoznato stanje naloga', vrsta),
    };
  }
}

VrstaUredjaja vrstaUredjajaIz(String naziv) =>
    VrstaUredjaja.values.asNameMap()[naziv] ?? (throw FormatException('Nepoznata vrsta uređaja', naziv));

T _ispravno<T>(Rezultat<T> rezultat) => switch (rezultat) {
  Uspeh(:final vrednost) => vrednost,
  Neuspeh(:final greska) => throw FormatException('Zapis ne prolazi pravilo domena', greska),
};
