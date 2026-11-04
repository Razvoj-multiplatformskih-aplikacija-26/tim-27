import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'dependencies.dart';
import 'screens/tabla_screen.dart';
import 'tema.dart';

class BackofficeApp extends StatefulWidget {
  const BackofficeApp({super.key, required this.zavisnosti});

  static const jezik = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  final Zavisnosti zavisnosti;

  @override
  State<BackofficeApp> createState() => _BackofficeAppState();
}

class _BackofficeAppState extends State<BackofficeApp> {
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
  Widget build(BuildContext context) {
    final zavisnosti = widget.zavisnosti;
    return RepositoryProvider.value(
      value: zavisnosti,
      child: BlocProvider(
        create: (_) =>
            TablaNalogaBloc(repozitorijum: zavisnosti.nalozi, serviser: zavisnosti.serviser)
              ..add(const TablaZatrazena()),
        child: MaterialApp.router(
          title: 'Reboot backoffice',
          debugShowCheckedModeBanner: false,
          theme: RebootTema.svetla(),
          darkTheme: RebootTema.tamna(),
          locale: BackofficeApp.jezik,
          supportedLocales: const [BackofficeApp.jezik],
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
