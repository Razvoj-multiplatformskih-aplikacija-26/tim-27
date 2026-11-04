import '../identifikatori.dart';
import '../korisnici.dart';
import 'radni_nalog.dart';
import 'stanje_naloga.dart';

/// Pravilo: serviser može imati najviše 5 aktivnih naloga.
const maksAktivnihNaloga = 5;

int brojAktivnihNaloga(ServiserId serviserId, List<RadniNalog> nalozi) =>
    nalozi.where((n) => n.serviserId == serviserId && n.stanje.jeAktivno).length;

int preostaloMestaZaNaloge(ServiserId serviserId, List<RadniNalog> nalozi) =>
    maksAktivnihNaloga - brojAktivnihNaloga(serviserId, nalozi);

/// Nalozi koje još niko nije preuzeo. Zavisi od podataka drugih servisera, pa u KT2
/// konačno odlučuje server: dva servisera ne mogu preuzeti isti nalog.
List<RadniNalog> slobodniNalozi(List<RadniNalog> nalozi) =>
    nalozi.where((n) => n.stanje is Primljen && n.serviserId == null).toList();

/// Nalog menja serviser koji ga je preuzeo ili šef servisa.
bool smeDaMenja(Serviser serviser, RadniNalog nalog) => serviser.jeSef || nalog.serviserId == serviser.id;

enum AkcijaOsoblja { preuzmi, posaljiPonudu, oznaciSpreman, izdaj, otkazi }

/// Akcije koje član osoblja sada može da uradi nad nalogom; ekran po njima pali dugmad i prečice.
Set<AkcijaOsoblja> akcijeOsoblja(RadniNalog nalog, {required Serviser serviser, required List<RadniNalog> sviNalozi}) {
  final stanje = nalog.stanje;
  final mozeDaMenja = smeDaMenja(serviser, nalog);
  return {
    if (stanje is Primljen &&
        nalog.serviserId == null &&
        brojAktivnihNaloga(serviser.id, sviNalozi) < maksAktivnihNaloga)
      AkcijaOsoblja.preuzmi,
    if (stanje is Dijagnostika && mozeDaMenja) AkcijaOsoblja.posaljiPonudu,
    if (stanje is UPopravci && mozeDaMenja) AkcijaOsoblja.oznaciSpreman,
    if (stanje is SpremanZaPreuzimanje) AkcijaOsoblja.izdaj,
    if ((stanje is Primljen || stanje is Dijagnostika) && (nalog.serviserId == null || mozeDaMenja))
      AkcijaOsoblja.otkazi,
  };
}

/// Da li klijent još može da odgovori na ponudu (ponuda čeka i rok od 48 sati nije prošao).
bool klijentMozeDaOdgovori(RadniNalog nalog, {required DateTime sada}) => switch (nalog.stanje) {
  CekaOdobrenje(:final ponuda) => !ponuda.jeIstekla(sada),
  _ => false,
};
