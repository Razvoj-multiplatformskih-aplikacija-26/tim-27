import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../tekst.dart';
import '../widgets/oznaka_stanja.dart';
import '../widgets/prikazi_stanja.dart';

/// Detalj jednog naloga; ovde klijent prihvata ili odbija ponudu.
class DetaljNalogaScreen extends StatelessWidget {
  const DetaljNalogaScreen({super.key, required this.id});

  final NalogId id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nalog ${id.value}'),
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/nalozi')),
      ),
      body: BlocBuilder<MojiNaloziBloc, MojiNaloziState>(
        builder: (context, state) => switch (state) {
          MojiNaloziUcitavanje() => const PrikazUcitavanja(),
          MojiNaloziGreska() => PrikazGreske(
            onPonovo: () => context.read<MojiNaloziBloc>().add(const MojiNaloziZatrazeni()),
          ),
          MojiNaloziPrazno() => const PrazanPrikaz(naslov: 'Nalog nije pronađen.'),
          MojiNaloziUcitani() => switch (state.nalog(id)) {
            null => const PrazanPrikaz(naslov: 'Nalog nije pronađen.'),
            final nalog => _Detalj(
              nalog: nalog,
              mozeDaOdgovori: state.mozeDaOdgovori(nalog),
              uToku: state.nalogUToku == nalog.id,
            ),
          },
        },
      ),
    );
  }
}

class _Detalj extends StatelessWidget {
  const _Detalj({required this.nalog, required this.mozeDaOdgovori, required this.uToku});

  final RadniNalog nalog;
  final bool mozeDaOdgovori;
  final bool uToku;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final stanje = nalog.stanje;
    final ponuda = switch (stanje) {
      CekaOdobrenje(:final ponuda) || UPopravci(:final ponuda) || OdbijenaPonuda(:final ponuda) => ponuda,
      _ => null,
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: Text(nalog.uredjaj.naziv, style: tema.textTheme.headlineSmall)),
            OznakaStanja(stanje: stanje),
          ],
        ),
        const SizedBox(height: 16),
        _Red(naziv: 'Vrsta uređaja', vrednost: nazivVrste(nalog.uredjaj.vrsta)),
        _Red(naziv: 'Primljen', vrednost: datumIVreme(nalog.primljenU)),
        if (stanje case Preuzet(:final preuzetU)) _Red(naziv: 'Preuzet', vrednost: datumIVreme(preuzetU)),
        if (stanje case Otkazan(:final razlog) when razlog.isNotEmpty)
          _Red(naziv: 'Razlog otkazivanja', vrednost: razlog),
        const SizedBox(height: 8),
        Text('Opis kvara', style: tema.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(nalog.opisKvara.tekst),
        if (ponuda != null) ...[
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ponuda servisa', style: tema.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(dinari(ponuda.iznos), style: tema.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(ponuda.opis),
                  const SizedBox(height: 8),
                  if (stanje is CekaOdobrenje)
                    Text(
                      mozeDaOdgovori || uToku
                          ? 'Odgovor očekujemo do ${datumIVreme(ponuda.istice)}.'
                          : 'Rok za odgovor je istekao ${datumIVreme(ponuda.istice)}.',
                      style: tema.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ],
        if (stanje is CekaOdobrenje) ...[
          const SizedBox(height: 16),
          if (uToku)
            const Center(child: CircularProgressIndicator(semanticsLabel: 'Čuvanje odgovora'))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: mozeDaOdgovori ? () => _potvrdi(context, prihvata: false) : null,
                    child: const Text('Odbij ponudu'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: mozeDaOdgovori ? () => _potvrdi(context, prihvata: true) : null,
                    child: const Text('Prihvati ponudu'),
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }

  /// Odgovor na ponudu je nepovratan, pa traži potvrdu u dijalogu.
  Future<void> _potvrdi(BuildContext context, {required bool prihvata}) async {
    final bloc = context.read<MojiNaloziBloc>();
    final potvrdjeno = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(prihvata ? 'Prihvatiti ponudu?' : 'Odbiti ponudu?'),
        content: Text(
          prihvata
              ? 'Servis počinje popravku po ponudi. Odluka se ne može promeniti.'
              : 'Popravka se neće raditi i nalog se zatvara. Odluka se ne može promeniti.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(prihvata ? 'Prihvati' : 'Odbij')),
        ],
      ),
    );
    if (potvrdjeno == true) bloc.add(OdgovorNaPonuduPoslat(nalog.id, prihvata: prihvata));
  }
}

class _Red extends StatelessWidget {
  const _Red({required this.naziv, required this.vrednost});

  final String naziv;
  final String vrednost;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(naziv, style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(vrednost)),
        ],
      ),
    );
  }
}
