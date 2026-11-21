/// Port za čuvanje tokena prijave. Aplikacije ga implementiraju bezbednim skladištem
/// platforme (Keychain, Keystore, Credential Manager, libsecret); lozinka se ne čuva.
abstract interface class TokenStore {
  Future<String?> procitaj();

  Future<void> upisi(String token);

  Future<void> obrisi();
}

final class MemorijskiTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> procitaj() async => _token;

  @override
  Future<void> upisi(String token) async => _token = token;

  @override
  Future<void> obrisi() async => _token = null;
}
