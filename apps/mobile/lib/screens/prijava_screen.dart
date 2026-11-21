import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../tekst.dart';
import '../tema.dart';

/// Prijava klijenta. Token posle prijave čuva se u bezbednom skladištu, lozinka nigde.
class PrijavaScreen extends StatefulWidget {
  const PrijavaScreen({super.key});

  @override
  State<PrijavaScreen> createState() => _PrijavaScreenState();
}

class _PrijavaScreenState extends State<PrijavaScreen> {
  final _ime = TextEditingController();
  final _lozinka = TextEditingController();

  @override
  void dispose() {
    _ime.dispose();
    _lozinka.dispose();
    super.dispose();
  }

  void _prijavi() => context.read<SesijaBloc>().add(PrijavaZatrazena(korisnickoIme: _ime.text, lozinka: _lozinka.text));

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocBuilder<SesijaBloc, SesijaState>(
                builder: (context, state) {
                  final uToku = state is Odjavljen && state.prijavaUToku;
                  final razlog = state is Odjavljen ? state.razlog : null;
                  return AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.build_circle_outlined, size: 72, color: RebootTema.plava),
                        const SizedBox(height: 12),
                        Text('Reboot', style: tema.textTheme.headlineMedium, textAlign: TextAlign.center),
                        Text(
                          'Prijavite se da vidite svoje radne naloge.',
                          style: tema.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (razlog != null) ...[
                          Card(
                            color: tema.colorScheme.secondaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(porukaOdjave(razlog), key: const Key('razlog-odjave')),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: _ime,
                          enabled: !uToku,
                          autofillHints: const [AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Korisničko ime'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _lozinka,
                          enabled: !uToku,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _prijavi(),
                          decoration: const InputDecoration(labelText: 'Lozinka'),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: uToku ? null : _prijavi,
                          child: uToku
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Prijava u toku'),
                                )
                              : const Text('Prijavi se'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
