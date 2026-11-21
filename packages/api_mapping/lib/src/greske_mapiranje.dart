import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

import 'nalog_mapiranje.dart';

extension DomenskaGreskaUProblem on DomenskaGreska {
  ProblemDto toProblem() => switch (this) {
    OpisKvaraPrekratak(:final duzina) => ProblemDto(
      status: 422,
      kod: KodoviGresaka.opisKvaraPrekratak,
      naslov: 'Fault description too short',
      vrednost: duzina,
      min: OpisKvara.minDuzina,
    ),
    OpisKvaraPredugacak(:final duzina) => ProblemDto(
      status: 422,
      kod: KodoviGresaka.opisKvaraPredugacak,
      naslov: 'Fault description too long',
      vrednost: duzina,
      maks: OpisKvara.maksDuzina,
    ),
    NazivUredjajaObavezan() => const ProblemDto(
      status: 422,
      kod: KodoviGresaka.nazivUredjajaObavezan,
      naslov: 'Device name required',
    ),
    NeispravanIznos(:final iznos) => ProblemDto(
      status: 422,
      kod: KodoviGresaka.neispravanIznos,
      naslov: 'Invalid amount',
      vrednost: iznos,
      min: 1,
      maks: Ponuda.maksIznos,
    ),
    OpisPonudeObavezan() => const ProblemDto(
      status: 422,
      kod: KodoviGresaka.opisPonudeObavezan,
      naslov: 'Quote description required',
    ),
    PreviseAktivnihNaloga(:final aktivnih, :final granica) => ProblemDto(
      status: 409,
      kod: KodoviGresaka.previseAktivnihNaloga,
      naslov: 'Too many active work orders',
      vrednost: aktivnih,
      maks: granica,
    ),
    RokZaOdgovorIstekao() => const ProblemDto(
      status: 409,
      kod: KodoviGresaka.rokZaOdgovorIstekao,
      naslov: 'Quote expired',
    ),
    NemaPonudeZaOdgovor() => const ProblemDto(
      status: 409,
      kod: KodoviGresaka.nemaPonudeZaOdgovor,
      naslov: 'No quote awaiting an answer',
    ),
    NalogVecPreuzet() => const ProblemDto(
      status: 409,
      kod: KodoviGresaka.nalogVecPreuzet,
      naslov: 'Work order already taken',
    ),
    NemaDelaNaStanju() => const ProblemDto(
      status: 409,
      kod: KodoviGresaka.nemaDelaNaStanju,
      naslov: 'Part out of stock',
    ),
    NedozvoljenPrelaz(:final iz, :final u) => ProblemDto(
      status: 409,
      kod: KodoviGresaka.nedozvoljenPrelaz,
      naslov: 'Invalid transition',
      iz: iz.vrsta,
      u: u.vrsta,
    ),
    NemaPrava() => const ProblemDto(status: 403, kod: KodoviGresaka.nemaPrava, naslov: 'Not allowed'),
    NalogNijePronadjen() => const ProblemDto(status: 404, kod: KodoviGresaka.nijePronadjeno, naslov: 'Not found'),
  };
}

extension ProblemUDomenskuGresku on ProblemDto {
  /// Greška pravila iz domena, ili null kada kôd nije poznat ovoj verziji aplikacije
  /// (novi server, stara aplikacija): tada klijent prikazuje opštu poruku.
  DomenskaGreska? toDomenskaGreska() => switch (this) {
    ProblemDto(kod: KodoviGresaka.opisKvaraPrekratak, :final vrednost?) => OpisKvaraPrekratak(vrednost),
    ProblemDto(kod: KodoviGresaka.opisKvaraPredugacak, :final vrednost?) => OpisKvaraPredugacak(vrednost),
    ProblemDto(kod: KodoviGresaka.nazivUredjajaObavezan) => const NazivUredjajaObavezan(),
    ProblemDto(kod: KodoviGresaka.neispravanIznos, :final vrednost?) => NeispravanIznos(vrednost),
    ProblemDto(kod: KodoviGresaka.opisPonudeObavezan) => const OpisPonudeObavezan(),
    ProblemDto(kod: KodoviGresaka.previseAktivnihNaloga, :final vrednost?, :final maks?) => PreviseAktivnihNaloga(
      vrednost,
      granica: maks,
    ),
    ProblemDto(kod: KodoviGresaka.rokZaOdgovorIstekao) => const RokZaOdgovorIstekao(),
    ProblemDto(kod: KodoviGresaka.nemaPonudeZaOdgovor) => const NemaPonudeZaOdgovor(),
    ProblemDto(kod: KodoviGresaka.nalogVecPreuzet) => const NalogVecPreuzet(),
    ProblemDto(kod: KodoviGresaka.nemaDelaNaStanju) => const NemaDelaNaStanju(),
    ProblemDto(kod: KodoviGresaka.nedozvoljenPrelaz, :final iz?, :final u?) => switch ((
      _stanjeBezPodataka(iz),
      _stanjeBezPodataka(u),
    )) {
      (final iz?, final u?) => NedozvoljenPrelaz(iz: iz, u: u),
      _ => null,
    },
    ProblemDto(kod: KodoviGresaka.nemaPrava) => const NemaPrava(),
    ProblemDto(kod: KodoviGresaka.nijePronadjeno) => const NalogNijePronadjen(),
    _ => null,
  };
}

/// Za poruku o nedozvoljenom prelazu bitna je samo vrsta stanja, ne i podaci u njemu.
StanjeNaloga? _stanjeBezPodataka(String vrsta) {
  final ponuda = PonudaDto(iznosDinara: 1, opis: '-', poslataU: DateTime.utc(2000));
  final preuzetU = DateTime.utc(2000);
  try {
    return StanjeDto(vrsta: vrsta, ponuda: ponuda, preuzetU: preuzetU).toDomain();
  } on FormatException {
    return null;
  }
}
