import 'json.dart';

/// Novac je ceo broj dinara, vreme je ISO 8601 u UTC-u, a stanje je objekat sa poljem 'vrsta'.
final class PonudaDto {
  const PonudaDto({required this.iznosDinara, required this.opis, required this.poslataU});

  final int iznosDinara;
  final String opis;
  final DateTime poslataU;

  Map<String, Object?> toJson() => {'iznosDinara': iznosDinara, 'opis': opis, 'poslataU': instantToJson(poslataU)};

  factory PonudaDto.fromJson(Map<String, Object?> json) => PonudaDto(
    iznosDinara: jsonInt(json, 'iznosDinara'),
    opis: jsonString(json, 'opis'),
    poslataU: jsonInstant(json, 'poslataU'),
  );
}

abstract final class VrsteStanja {
  static const primljen = 'primljen';
  static const dijagnostika = 'dijagnostika';
  static const cekaOdobrenje = 'ceka-odobrenje';
  static const uPopravci = 'u-popravci';
  static const spremanZaPreuzimanje = 'spreman-za-preuzimanje';
  static const preuzet = 'preuzet';
  static const otkazan = 'otkazan';
  static const odbijenaPonuda = 'odbijena-ponuda';
}

final class StanjeDto {
  const StanjeDto({required this.vrsta, this.ponuda, this.preuzetU, this.razlog});

  final String vrsta;
  final PonudaDto? ponuda;
  final DateTime? preuzetU;
  final String? razlog;

  Map<String, Object?> toJson() => {
    'vrsta': vrsta,
    if (ponuda case final ponuda?) 'ponuda': ponuda.toJson(),
    if (preuzetU case final preuzetU?) 'preuzetU': instantToJson(preuzetU),
    'razlog': ?razlog,
  };

  factory StanjeDto.fromJson(Map<String, Object?> json) => StanjeDto(
    vrsta: jsonString(json, 'vrsta'),
    ponuda: json['ponuda'] == null ? null : PonudaDto.fromJson(jsonObject(json['ponuda'])),
    preuzetU: jsonOptionalInstant(json, 'preuzetU'),
    razlog: jsonOptionalString(json, 'razlog'),
  );
}

final class NalogDto {
  const NalogDto({
    required this.id,
    required this.klijentId,
    required this.vrstaUredjaja,
    required this.nazivUredjaja,
    required this.opisKvara,
    required this.primljenU,
    required this.stanje,
    this.serviserId,
  });

  final String id;
  final String klijentId;
  final String? serviserId;

  /// 'laptop', 'desktop', 'monitor', 'stampac' ili 'ostalo'.
  final String vrstaUredjaja;
  final String nazivUredjaja;
  final String opisKvara;
  final DateTime primljenU;
  final StanjeDto stanje;

  Map<String, Object?> toJson() => {
    'id': id,
    'klijentId': klijentId,
    'serviserId': ?serviserId,
    'vrstaUredjaja': vrstaUredjaja,
    'nazivUredjaja': nazivUredjaja,
    'opisKvara': opisKvara,
    'primljenU': instantToJson(primljenU),
    'stanje': stanje.toJson(),
  };

  factory NalogDto.fromJson(Map<String, Object?> json) => NalogDto(
    id: jsonString(json, 'id'),
    klijentId: jsonString(json, 'klijentId'),
    serviserId: jsonOptionalString(json, 'serviserId'),
    vrstaUredjaja: jsonString(json, 'vrstaUredjaja'),
    nazivUredjaja: jsonString(json, 'nazivUredjaja'),
    opisKvara: jsonString(json, 'opisKvara'),
    primljenU: jsonInstant(json, 'primljenU'),
    stanje: StanjeDto.fromJson(jsonObject(json['stanje'])),
  );
}

final class NoviNalogDto {
  const NoviNalogDto({required this.vrstaUredjaja, required this.nazivUredjaja, required this.opisKvara});

  final String vrstaUredjaja;
  final String nazivUredjaja;
  final String opisKvara;

  Map<String, Object?> toJson() => {
    'vrstaUredjaja': vrstaUredjaja,
    'nazivUredjaja': nazivUredjaja,
    'opisKvara': opisKvara,
  };

  factory NoviNalogDto.fromJson(Map<String, Object?> json) => NoviNalogDto(
    vrstaUredjaja: jsonString(json, 'vrstaUredjaja'),
    nazivUredjaja: jsonString(json, 'nazivUredjaja'),
    opisKvara: jsonString(json, 'opisKvara'),
  );
}

final class NovaPonudaDto {
  const NovaPonudaDto({required this.iznosDinara, required this.opis});

  final int iznosDinara;
  final String opis;

  Map<String, Object?> toJson() => {'iznosDinara': iznosDinara, 'opis': opis};

  factory NovaPonudaDto.fromJson(Map<String, Object?> json) =>
      NovaPonudaDto(iznosDinara: jsonInt(json, 'iznosDinara'), opis: jsonString(json, 'opis'));
}

final class OdgovorDto {
  const OdgovorDto({required this.prihvata});

  final bool prihvata;

  Map<String, Object?> toJson() => {'prihvata': prihvata};

  factory OdgovorDto.fromJson(Map<String, Object?> json) => switch (json['prihvata']) {
    final bool prihvata => OdgovorDto(prihvata: prihvata),
    _ => throw FormatException('Očekivano "prihvata" kao true ili false', json),
  };
}

final class OtkazivanjeDto {
  const OtkazivanjeDto({required this.razlog});

  final String razlog;

  Map<String, Object?> toJson() => {'razlog': razlog};

  factory OtkazivanjeDto.fromJson(Map<String, Object?> json) => OtkazivanjeDto(razlog: jsonString(json, 'razlog'));
}
