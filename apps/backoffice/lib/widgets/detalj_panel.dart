import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../precice.dart';
import '../tekst.dart';
import 'oznaka_stanja.dart';

/// Bočni panel (na uskom ekranu donji) sa detaljem izabranog naloga i akcijama.
class DetaljPanel extends StatelessWidget {
  const DetaljPanel({
    super.key,
    required this.nalog,
    required this.stanje,
    required this.onAkcija,
    required this.onZatvori,
  });

  final RadniNalog nalog;
  final TablaUcitana stanje;
  final ValueChanged<AkcijaOsoblja> onAkcija;
  final VoidCallback onZatvori;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final klijent = stanje.klijenti[nalog.klijentId];
    final serviser = stanje.serviseri[nalog.serviserId];
    final akcije = stanje.akcijeZa(nalog);
    final ponuda = switch (nalog.stanje) {
      CekaOdobrenje(:final ponuda) || UPopravci(:final ponuda) || OdbijenaPonuda(:final ponuda) => ponuda,
      _ => null,
    };
    return Material(
      color: tema.colorScheme.surfaceContainerLow,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: Text('Nalog ${nalog.id.value}', style: tema.textTheme.titleLarge)),
              IconButton(tooltip: 'Zatvori (Esc)', onPressed: onZatvori, icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OznakaStanja(stanje: nalog.stanje),
          ),
          const SizedBox(height: 16),
          _Red('Uređaj', '${nalog.uredjaj.naziv} (${nazivVrste(nalog.uredjaj.vrsta)})'),
          _Red('Klijent', klijent == null ? '—' : '${klijent.ime}, ${klijent.telefon}'),
          _Red('Serviser', serviser?.ime ?? 'nije preuzet'),
          _Red('Primljen', datumIVreme(nalog.primljenU)),
          if (nalog.stanje case Preuzet(:final preuzetU)) _Red('Izdat', datumIVreme(preuzetU)),
          if (nalog.stanje case Otkazan(:final razlog) when razlog.isNotEmpty) _Red('Razlog', razlog),
          const SizedBox(height: 12),
          Text('Opis kvara', style: tema.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(nalog.opisKvara.tekst),
          if (ponuda != null) ...[
            const SizedBox(height: 16),
            Text('Ponuda', style: tema.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('${dinari(ponuda.iznos)} · ${ponuda.opis}'),
            if (nalog.stanje is CekaOdobrenje) Text('Rok za odgovor: ${datumIVreme(ponuda.istice)}'),
          ],
          const SizedBox(height: 24),
          if (stanje.nalogUToku == nalog.id)
            const Center(child: CircularProgressIndicator(semanticsLabel: 'Čuvanje izmene'))
          else if (akcije.isEmpty)
            Text(
              nalog.stanje.jeZavrsno ? 'Nalog je završen.' : 'Za ovaj nalog sada nemate dostupnih akcija.',
              style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final akcija in AkcijaOsoblja.values)
                  if (akcije.contains(akcija))
                    akcija == AkcijaOsoblja.otkazi
                        ? OutlinedButton(
                            onPressed: () => onAkcija(akcija),
                            child: Text('${nazivAkcije(akcija)} (${tasterAkcije(akcija)})'),
                          )
                        : FilledButton(
                            onPressed: () => onAkcija(akcija),
                            child: Text('${nazivAkcije(akcija)} (${tasterAkcije(akcija)})'),
                          ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Red extends StatelessWidget {
  const _Red(this.naziv, this.vrednost);

  final String naziv;
  final String vrednost;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(naziv, style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(vrednost)),
        ],
      ),
    );
  }
}
