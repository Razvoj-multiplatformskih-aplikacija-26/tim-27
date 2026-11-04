import 'package:flutter/material.dart';

class PrikazUcitavanja extends StatelessWidget {
  const PrikazUcitavanja({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(semanticsLabel: 'Učitavanje naloga'));
}

class PrikazGreske extends StatelessWidget {
  const PrikazGreske({super.key, required this.onPonovo});

  final VoidCallback onPonovo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 64, color: tema.colorScheme.error),
            const SizedBox(height: 16),
            Text('Nalozi trenutno nisu dostupni.', style: tema.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onPonovo,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      ),
    );
  }
}

class PrazanPrikaz extends StatelessWidget {
  const PrazanPrikaz({super.key, required this.naslov, this.akcija});

  final String naslov;
  final Widget? akcija;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: tema.colorScheme.outline),
            const SizedBox(height: 16),
            Text(naslov, style: tema.textTheme.titleMedium, textAlign: TextAlign.center),
            if (akcija case final akcija?) ...[const SizedBox(height: 16), akcija],
          ],
        ),
      ),
    );
  }
}
