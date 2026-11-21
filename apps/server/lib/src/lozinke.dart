import 'dart:convert';
import 'dart:isolate';

import 'package:hashlib/hashlib.dart';
import 'package:hashlib/random.dart';
import 'package:pool/pool.dart';

final _hashing = Pool(4);

Future<String> hesLozinke(String lozinka) => _hashing.withResource(
  () => Isolate.run(() => argon2id(utf8.encode(lozinka), randomBytes(16), security: Argon2Security.owasp2).encoded()),
);

Future<bool> proveriLozinku(String lozinka, String hes) =>
    _hashing.withResource(() => Isolate.run(() => argon2Verify(hes, utf8.encode(lozinka))));
