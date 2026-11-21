import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

const platformaCuvaPrijavuUKolacicu = true;

http.Client platformskiHttpKlijent() => BrowserClient()..withCredentials = true;
