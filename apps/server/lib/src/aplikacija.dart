import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

import 'cors.dart';
import 'http.dart';
import 'rukovaoci.dart';
import 'sesije.dart';

Handler napraviRukovaoca(NaloziRukovaoci nalozi, SesijeRukovaoci sesije, {required List<String> dozvoljeniIzvori}) {
  final p = sesije.prijavljen;
  final ruter = RelicRouter()
    ..get(ApiPutanje.zdravlje, (zahtev) => Response.ok(body: Body.fromString('ok')))
    ..post(ApiPutanje.sesije, sesije.prijava)
    ..get(ApiPutanje.trenutnaSesija, p(sesije.trenutna))
    ..delete(ApiPutanje.trenutnaSesija, p(sesije.odjava))
    ..get(ApiPutanje.nalozi, p(nalozi.svi))
    ..post(ApiPutanje.nalozi, p(nalozi.prijavi))
    ..get(ApiPutanje.nalog(':id'), p(nalozi.jedan))
    ..get(ApiPutanje.naloziKlijenta(':klijentId'), p(nalozi.klijentovi))
    ..get(ApiPutanje.klijenti, p(nalozi.klijenti))
    ..get(ApiPutanje.serviseri, p(nalozi.serviseri))
    ..post(ApiPutanje.preuzimanje(':id'), p(nalozi.preuzmi))
    ..post(ApiPutanje.ponuda(':id'), p(nalozi.ponudi))
    ..post(ApiPutanje.odgovor(':id'), p(nalozi.odgovori))
    ..post(ApiPutanje.zavrsetak(':id'), p(nalozi.zavrsi))
    ..post(ApiPutanje.izdavanje(':id'), p(nalozi.izdaj))
    ..post(ApiPutanje.otkazivanje(':id'), p(nalozi.otkazi))
    ..fallback = respondWith((zahtev) => problemOdgovor(nepostojecaPutanja));
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(allowOrigins(dozvoljeniIzvori))
      .addMiddleware(obradiGreske())
      .addHandler(ruter.asHandler);
}
