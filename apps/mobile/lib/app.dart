import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'dependencies.dart';
import 'router.dart';
import 'tema.dart';

class RebootApp extends StatefulWidget {
  const RebootApp({super.key, required this.zavisnosti});

  static const jezik = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  final Zavisnosti zavisnosti;

  @override
  State<RebootApp> createState() => _RebootAppState();
}

class _RebootAppState extends State<RebootApp> {
  late final GoRouter _ruter = napraviRuter();

  @override
  void dispose() {
    _ruter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zavisnosti = widget.zavisnosti;
    return RepositoryProvider.value(
      value: zavisnosti,
      child: BlocProvider(
        create: (_) =>
            MojiNaloziBloc(repozitorijum: zavisnosti.nalozi, klijent: zavisnosti.klijent)
              ..add(const MojiNaloziZatrazeni()),
        child: MaterialApp.router(
          title: 'Reboot',
          debugShowCheckedModeBanner: false,
          theme: RebootTema.svetla(),
          darkTheme: RebootTema.tamna(),
          locale: RebootApp.jezik,
          supportedLocales: const [RebootApp.jezik],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _ruter,
        ),
      ),
    );
  }
}
