import 'package:flutter/foundation.dart';

/// Adresa servera bez izmene koda: desktop i pregledač na istom računaru kao server.
/// Za pravi telefon: flutter run --dart-define=SERVER_URL=http://192.168.x.y:8080
Uri adresaServera() {
  const zadata = String.fromEnvironment('SERVER_URL');
  if (zadata.isNotEmpty) return Uri.parse(zadata);
  final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
  return Uri.parse('http://$host:8080');
}
