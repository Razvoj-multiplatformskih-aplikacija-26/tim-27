import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../tekst.dart';
import 'oznaka_stanja.dart';

/// Tabela svih naloga za širok ekran (uzan: [ListaNaloga]). Izabrani red je istaknut i
/// uvek vidljiv; okvir tabele pokazuje da je fokus na njoj.
class TabelaNaloga extends StatefulWidget {
  const TabelaNaloga({
    super.key,
    required this.stanje,
    required this.imaFokus,
    required this.onIzaberi,
    this.uska = false,
  });

  final TablaUcitana stanje;
  final bool imaFokus;
  final ValueChanged<RadniNalog> onIzaberi;

  /// Uzan prikaz: lista kartica umesto kolona tabele.
  final bool uska;

  @override
  State<TabelaNaloga> createState() => _TabelaNalogaState();
}

class _TabelaNalogaState extends State<TabelaNaloga> {
  final _skrol = ScrollController();

  double get _visinaReda => widget.uska ? 76 : 52;

  @override
  void initState() {
    super.initState();
    // Posle promene rasporeda (tabela <-> lista) izabrani nalog ostaje vidljiv.
    final indeks = widget.stanje.indeksIzabranog;
    if (indeks != null) WidgetsBinding.instance.addPostFrameCallback((_) => _prikaziRed(indeks));
  }

  @override
  void didUpdateWidget(TabelaNaloga stari) {
    super.didUpdateWidget(stari);
    final indeks = widget.stanje.indeksIzabranog;
    if (indeks != null && indeks != stari.stanje.indeksIzabranog) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prikaziRed(indeks));
    }
  }

  void _prikaziRed(int indeks) {
    if (!_skrol.hasClients) return;
    final pozicija = _skrol.position;
    final vrh = indeks * _visinaReda;
    final dno = vrh + _visinaReda;
    if (vrh < pozicija.pixels) {
      _skrol.jumpTo(vrh);
    } else if (dno > pozicija.pixels + pozicija.viewportDimension) {
      _skrol.jumpTo(dno - pozicija.viewportDimension);
    }
  }

  @override
  void dispose() {
    _skrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final stanje = widget.stanje;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.imaFokus ? tema.colorScheme.primary : tema.colorScheme.outlineVariant,
          width: widget.imaFokus ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          children: [
            if (!widget.uska) const _Zaglavlje(),
            Expanded(
              child: ListView.builder(
                controller: _skrol,
                itemExtent: _visinaReda,
                itemCount: stanje.nalozi.length,
                itemBuilder: (context, i) {
                  final nalog = stanje.nalozi[i];
                  final izabran = nalog.id == stanje.izabraniId;
                  final klijent = stanje.klijenti[nalog.klijentId]?.ime ?? '—';
                  final serviser = stanje.serviseri[nalog.serviserId]?.ime ?? '—';
                  return Material(
                    color: izabran ? tema.colorScheme.primaryContainer : Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onIzaberi(nalog),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: izabran ? tema.colorScheme.primary : Colors.transparent, width: 4),
                            bottom: BorderSide(color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: widget.uska
                            ? _UskiRed(nalog: nalog, klijent: klijent)
                            : _SirokiRed(nalog: nalog, klijent: klijent, serviser: serviser),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _kolone = [2, 4, 3, 4, 3, 3];

class _Zaglavlje extends StatelessWidget {
  const _Zaglavlje();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    const nazivi = ['Broj', 'Uređaj', 'Klijent', 'Stanje', 'Serviser', 'Primljen'];
    return Container(
      color: tema.colorScheme.surfaceContainerHigh,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          for (var i = 0; i < nazivi.length; i++)
            Expanded(
              flex: _kolone[i],
              child: Text(nazivi[i], style: tema.textTheme.labelLarge),
            ),
        ],
      ),
    );
  }
}

class _SirokiRed extends StatelessWidget {
  const _SirokiRed({required this.nalog, required this.klijent, required this.serviser});

  final RadniNalog nalog;
  final String klijent;
  final String serviser;

  @override
  Widget build(BuildContext context) {
    Widget celija(int kolona, Widget sadrzaj) => Expanded(
      flex: _kolone[kolona],
      child: Align(alignment: Alignment.centerLeft, child: sadrzaj),
    );
    Text tekst(String s) => Text(s, maxLines: 1, overflow: TextOverflow.ellipsis);
    return Row(
      children: [
        celija(0, tekst(nalog.id.value)),
        celija(1, tekst(nalog.uredjaj.naziv)),
        celija(2, tekst(klijent)),
        celija(3, OznakaStanja(stanje: nalog.stanje)),
        celija(4, tekst(serviser)),
        celija(5, tekst(datumIVreme(nalog.primljenU))),
      ],
    );
  }
}

class _UskiRed extends StatelessWidget {
  const _UskiRed({required this.nalog, required this.klijent});

  final RadniNalog nalog;
  final String klijent;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nalog.uredjaj.naziv, maxLines: 1, overflow: TextOverflow.ellipsis, style: tema.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                '${nalog.id.value} · $klijent',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tema.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OznakaStanja(stanje: nalog.stanje),
      ],
    );
  }
}
