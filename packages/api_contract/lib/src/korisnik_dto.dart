import 'json.dart';

/// Uloga na mreži: 'klijent', 'serviser' ili 'sefServisa'.
final class KorisnikDto {
  const KorisnikDto({required this.id, required this.ime, required this.uloga, this.telefon = ''});

  final String id;
  final String ime;
  final String uloga;
  final String telefon;

  Map<String, Object?> toJson() => {'id': id, 'ime': ime, 'uloga': uloga, 'telefon': telefon};

  factory KorisnikDto.fromJson(Map<String, Object?> json) => KorisnikDto(
    id: jsonString(json, 'id'),
    ime: jsonString(json, 'ime'),
    uloga: jsonString(json, 'uloga'),
    telefon: jsonOptionalString(json, 'telefon') ?? '',
  );
}

final class PrijavaDto {
  const PrijavaDto({required this.korisnickoIme, required this.lozinka, this.kolacic = false});

  final String korisnickoIme;
  final String lozinka;

  /// Pregledač traži prijavu u HttpOnly kolačiću; ostale platforme dobijaju token u telu odgovora.
  final bool kolacic;

  Map<String, Object?> toJson() => {'korisnickoIme': korisnickoIme, 'lozinka': lozinka, 'kolacic': kolacic};

  factory PrijavaDto.fromJson(Map<String, Object?> json) => PrijavaDto(
    korisnickoIme: jsonString(json, 'korisnickoIme'),
    lozinka: jsonString(json, 'lozinka'),
    kolacic: json['kolacic'] == true,
  );
}

final class SesijaDto {
  const SesijaDto({required this.korisnik, required this.istice, this.token});

  final KorisnikDto korisnik;
  final DateTime istice;
  final String? token;

  Map<String, Object?> toJson() => {'korisnik': korisnik.toJson(), 'istice': instantToJson(istice), 'token': ?token};

  factory SesijaDto.fromJson(Map<String, Object?> json) => SesijaDto(
    korisnik: KorisnikDto.fromJson(jsonObject(json['korisnik'])),
    istice: jsonInstant(json, 'istice'),
    token: jsonOptionalString(json, 'token'),
  );
}
