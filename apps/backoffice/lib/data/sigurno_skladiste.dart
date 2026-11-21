import 'package:api_client/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token prijave u bezbednom skladištu platforme (Android Keystore, iOS Keychain,
/// Windows Credential Manager, libsecret). Lozinka se na uređaju ne čuva.
final class SigurnoSkladiste implements TokenStore {
  const SigurnoSkladiste([
    this._skladiste = const FlutterSecureStorage(mOptions: MacOsOptions(usesDataProtectionKeychain: false)),
  ]);

  static const _kljuc = 'reboot_prijava';

  final FlutterSecureStorage _skladiste;

  @override
  Future<String?> procitaj() => _skladiste.read(key: _kljuc);

  @override
  Future<void> upisi(String token) => _skladiste.write(key: _kljuc, value: token);

  @override
  Future<void> obrisi() => _skladiste.delete(key: _kljuc);
}
