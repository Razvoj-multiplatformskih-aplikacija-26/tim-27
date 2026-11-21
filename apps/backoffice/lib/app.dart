import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'dependencies.dart';
import 'screens/prijava_screen.dart';
import 'screens/tabla_screen.dart';
import 'tema.dart';
import 'widgets/prikazi_stanja.dart';

class BackofficeApp extends StatelessWidget {
  const BackofficeApp({super.key, required this.zavisnosti});

  static const jezik = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  final Zavisnosti zavisnosti;

  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
    value: zavisnosti,
    child: BlocProvider(
      create: (_) =>
          SesijaBloc(repozitorijum: zavisnosti.sesije, aplikacija: Aplikacija.backoffice)
            ..add(const SesijaVracanjeZatrazeno()),
      child: BlocBuilder<SesijaBloc, SesijaState>(
        buildWhen: (pre, sada) => pre.runtimeType != sada.runtimeType || sada is Prijavljen,
        builder: (context, state) => switch (state) {
          Prijavljen(:final korisnik) => _PrijavljenaAplikacija(
            key: ValueKey(korisnik.id),
            serviser: kaoServiser(korisnik)!,
            zavisnosti: zavisnosti,
          ),
          Odjavljen() => _materijal(home: const PrijavaScreen()),
          SesijaNepoznata() => _materijal(home: const Scaffold(body: PrikazUcitavanja())),
        },
      ),
    ),
  );
}

MaterialApp _materijal({Widget? home, RouterConfig<Object>? ruter}) {
  const delegati = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  if (ruter != null) {
    return MaterialApp.router(
      title: 'Reboot backoffice',
      debugShowCheckedModeBanner: false,
      theme: RebootTema.svetla(),
      darkTheme: RebootTema.tamna(),
      locale: BackofficeApp.jezik,
      supportedLocales: const [BackofficeApp.jezik],
      localizationsDelegates: delegati,
      routerConfig: ruter,
    );
  }
  return MaterialApp(
    title: 'Reboot backoffice',
    debugShowCheckedModeBanner: false,
    theme: RebootTema.svetla(),
    darkTheme: RebootTema.tamna(),
    locale: BackofficeApp.jezik,
    supportedLocales: const [BackofficeApp.jezik],
    localizationsDelegates: delegati,
    home: home,
  );
}

/// Posle prijave: tokovi iz KT1, sa serviserom iz prijave umesto zadatog.
class _PrijavljenaAplikacija extends StatefulWidget {
  const _PrijavljenaAplikacija({super.key, required this.serviser, required this.zavisnosti});

  final Serviser serviser;
  final Zavisnosti zavisnosti;

  @override
  State<_PrijavljenaAplikacija> createState() => _PrijavljenaAplikacijaState();
}

class _PrijavljenaAplikacijaState extends State<_PrijavljenaAplikacija> {
  late final GoRouter _ruter = GoRouter(
    initialLocation: '/nalozi',
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/nalozi'),
      GoRoute(path: '/nalozi', builder: (context, state) => const TablaScreen()),
    ],
  );

  @override
  void dispose() {
    _ruter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        TablaNalogaBloc(repozitorijum: widget.zavisnosti.nalozi, serviser: widget.serviser)
          ..add(const TablaZatrazena()),
    child: _materijal(ruter: _ruter),
  );
}
