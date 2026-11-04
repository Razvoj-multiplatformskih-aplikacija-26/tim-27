import 'package:domain/domain.dart';
import 'package:go_router/go_router.dart';

import 'screens/detalj_naloga_screen.dart';
import 'screens/moji_nalozi_screen.dart';
import 'screens/prijava_uredjaja_screen.dart';

/// Svaki ekran ima svoju adresu: /nalozi, /nalozi/novi, /nalozi/RN-1003.
GoRouter napraviRuter() => GoRouter(
  initialLocation: '/nalozi',
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/nalozi'),
    GoRoute(
      path: '/nalozi',
      builder: (context, state) => const MojiNaloziScreen(),
      routes: [
        GoRoute(path: 'novi', builder: (context, state) => const PrijavaUredjajaScreen()),
        GoRoute(
          path: ':id',
          builder: (context, state) => DetaljNalogaScreen(id: NalogId(state.pathParameters['id']!)),
        ),
      ],
    ),
  ],
);
