import 'json.dart';

/// Greška na mreži (RFC 9457, application/problem+json): kôd i podaci pravila, bez poruke za korisnika.
final class ProblemDto {
  const ProblemDto({
    required this.status,
    required this.kod,
    required this.naslov,
    this.vrednost,
    this.min,
    this.maks,
    this.iz,
    this.u,
  });

  static const mediaType = 'application/problem+json';

  static String tipZa(String kod) => 'tag:raf.rs,2026:reboot/problem/$kod';

  final int status;
  final String kod;

  /// Kratak opis za programera (curl, logovi); korisnik ga ne vidi.
  final String naslov;
  final int? vrednost;
  final int? min;
  final int? maks;

  /// Za nedozvoljen prelaz: vrsta stanja iz koga i u koje.
  final String? iz;
  final String? u;

  Map<String, Object?> toJson() => {
    'type': tipZa(kod),
    'title': naslov,
    'status': status,
    'kod': kod,
    'vrednost': ?vrednost,
    'min': ?min,
    'maks': ?maks,
    'iz': ?iz,
    'u': ?u,
  };

  factory ProblemDto.fromJson(Map<String, Object?> json) => ProblemDto(
    status: jsonInt(json, 'status'),
    kod: jsonString(json, 'kod'),
    naslov: jsonOptionalString(json, 'title') ?? '',
    vrednost: jsonOptionalInt(json, 'vrednost'),
    min: jsonOptionalInt(json, 'min'),
    maks: jsonOptionalInt(json, 'maks'),
    iz: jsonOptionalString(json, 'iz'),
    u: jsonOptionalString(json, 'u'),
  );
}
