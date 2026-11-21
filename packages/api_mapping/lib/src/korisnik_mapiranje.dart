import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

extension KorisnikUDto on Korisnik {
  KorisnikDto toDto() => KorisnikDto(id: id, ime: ime, uloga: uloga.name, telefon: telefon);
}

extension KlijentUDto on Klijent {
  KorisnikDto toDto() => KorisnikDto(id: id.value, ime: ime, uloga: Uloga.klijent.name, telefon: telefon);
}

extension ServiserUDto on Serviser {
  KorisnikDto toDto() =>
      KorisnikDto(id: id.value, ime: ime, uloga: jeSef ? Uloga.sefServisa.name : Uloga.serviser.name);
}

extension KorisnikDtoUDomen on KorisnikDto {
  Korisnik toDomain() => Korisnik(
    id: id,
    ime: ime,
    uloga: Uloga.values.asNameMap()[uloga] ?? (throw FormatException('Nepoznata uloga', uloga)),
    telefon: telefon,
  );

  Klijent toKlijent() => Klijent(id: KlijentId(id), ime: ime, telefon: telefon);

  Serviser toServiser() => Serviser(
    id: ServiserId(id),
    ime: ime,
    uloga: uloga == Uloga.sefServisa.name ? UlogaOsoblja.sefServisa : UlogaOsoblja.serviser,
  );
}
