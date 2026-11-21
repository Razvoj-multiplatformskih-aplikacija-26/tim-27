import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart';

final _problemMimeType = MimeType.parse(ProblemDto.mediaType);

Response json(int status, Object? telo) =>
    Response(status, body: Body.fromString(jsonEncode(telo), mimeType: MimeType.json));

Response greska(DomenskaGreska greska) => problemOdgovor(greska.toProblem());

Response problemOdgovor(ProblemDto problem) =>
    Response(problem.status, body: Body.fromString(jsonEncode(problem.toJson()), mimeType: _problemMimeType));

Response odgovorNa(Rezultat<RadniNalog> rezultat, {int status = 200}) => switch (rezultat) {
  Uspeh(:final vrednost) => json(status, vrednost.toDto().toJson()),
  Neuspeh(greska: final g) => greska(g),
};

const maksVelicinaTela = 16 * 1024;

final class NepodrzanTip implements Exception {
  const NepodrzanTip();
}

Future<Map<String, Object?>> procitajObjekat(Request zahtev) async {
  if (zahtev.mimeType != MimeType.json) throw const NepodrzanTip();
  return switch (jsonDecode(await zahtev.readAsString(maxLength: maksVelicinaTela))) {
    final Map<String, Object?> objekat => objekat,
    _ => throw const FormatException('Očekivan JSON objekat'),
  };
}

Middleware obradiGreske() =>
    (Handler sledeci) => (Request zahtev) async {
      try {
        return await sledeci(zahtev);
      } on FormatException catch (uzrok) {
        return problemOdgovor(ProblemDto(status: 400, kod: KodoviGresaka.losZahtev, naslov: uzrok.message));
      } on NepodrzanTip {
        return problemOdgovor(
          const ProblemDto(status: 415, kod: KodoviGresaka.nepodrzanTip, naslov: 'Expected application/json'),
        );
      } on MaxBodySizeExceeded {
        return problemOdgovor(
          const ProblemDto(status: 413, kod: KodoviGresaka.prevelikZahtev, naslov: 'Request body too large'),
        );
      } catch (uzrok, trag) {
        stderr.writeln('${zahtev.method} ${zahtev.url.path}: $uzrok\n$trag');
        return problemOdgovor(greskaServera);
      }
    };

const greskaServera = ProblemDto(status: 500, kod: KodoviGresaka.greskaServera, naslov: 'Server error');

const nepostojecaPutanja = ProblemDto(status: 404, kod: KodoviGresaka.nijePronadjeno, naslov: 'No such route');
