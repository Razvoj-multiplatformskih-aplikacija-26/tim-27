abstract final class ApiPutanje {
  static const zdravlje = '/health';
  static const nalozi = '/api/v1/nalozi';
  static const klijenti = '/api/v1/klijenti';
  static const serviseri = '/api/v1/serviseri';
  static const sesije = '/api/v1/sesije';
  static const trenutnaSesija = '/api/v1/sesije/trenutna';

  static String nalog(String id) => '$nalozi/$id';

  static String naloziKlijenta(String klijentId) => '$klijenti/$klijentId/nalozi';

  static String preuzimanje(String id) => '${nalog(id)}/preuzimanje';

  static String ponuda(String id) => '${nalog(id)}/ponuda';

  static String odgovor(String id) => '${nalog(id)}/odgovor';

  static String zavrsetak(String id) => '${nalog(id)}/zavrsetak';

  static String izdavanje(String id) => '${nalog(id)}/izdavanje';

  static String otkazivanje(String id) => '${nalog(id)}/otkazivanje';
}

abstract final class ApiKolacici {
  static const sesija = 'reboot_sesija';
}
