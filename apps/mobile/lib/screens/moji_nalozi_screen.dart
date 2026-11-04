import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../dependencies.dart';
import '../tekst.dart';
import '../widgets/oznaka_stanja.dart';
import '../widgets/prikazi_stanja.dart';

/// Glavni ekran klijenta: lista njegovih naloga u četiri stanja ekrana.
class MojiNaloziScreen extends StatelessWidget {
  const MojiNaloziScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MojiNaloziBloc>();
    return Scaffold(
      appBar: AppBar(title: const Text('Moji nalozi'), actions: const [_MeniZaDemo()]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/nalozi/novi'),
        icon: const Icon(Icons.add),
        label: const Text('Prijavi uređaj'),
      ),
      body: BlocConsumer<MojiNaloziBloc, MojiNaloziState>(
        listenWhen: (pre, sada) => sada is MojiNaloziUcitani && sada.obavestenje != null,
        listener: (context, state) => _prikaziObavestenje(context, (state as MojiNaloziUcitani).obavestenje!),
        builder: (context, state) => switch (state) {
          MojiNaloziUcitavanje() => const PrikazUcitavanja(),
          MojiNaloziGreska() => PrikazGreske(onPonovo: () => bloc.add(const MojiNaloziZatrazeni())),
          MojiNaloziPrazno() => PrazanPrikaz(
            naslov: 'Još nemate radnih naloga.',
            akcija: FilledButton.tonal(
              onPressed: () => context.go('/nalozi/novi'),
              child: const Text('Prijavi uređaj'),
            ),
          ),
          MojiNaloziUcitani(:final nalozi) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: nalozi.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _KarticaNaloga(
              nalog: nalozi[i],
              cekaOdgovor: state.zaOdgovor.contains(nalozi[i].id),
              onOtvori: () => context.go('/nalozi/${nalozi[i].id.value}'),
            ),
          ),
        },
      ),
    );
  }
}

void _prikaziObavestenje(BuildContext context, MojiNaloziObavestenje obavestenje) {
  final poruka = switch (obavestenje) {
    NalogNapravljen(:final nalog) => 'Uređaj je prijavljen, broj naloga ${nalog.id.value}.',
    OdgovorSacuvan(:final nalog) => nalog.stanje is UPopravci ? 'Ponuda je prihvaćena.' : 'Ponuda je odbijena.',
    AkcijaOdbijena(:final greska) => greska.poruka,
    AkcijaNijeUspela() => 'Zahtev nije uspeo. Pokušajte ponovo.',
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(poruka)));
  context.read<MojiNaloziBloc>().add(const ObavestenjePrikazano());
}

class _KarticaNaloga extends StatelessWidget {
  const _KarticaNaloga({required this.nalog, required this.cekaOdgovor, required this.onOtvori});

  final RadniNalog nalog;
  final bool cekaOdgovor;
  final VoidCallback onOtvori;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOtvori,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(nalog.uredjaj.naziv, style: tema.textTheme.titleMedium)),
                  OznakaStanja(stanje: nalog.stanje),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${nalog.id.value} · ${nazivVrste(nalog.uredjaj.vrsta)} · ${datumIVreme(nalog.primljenU)}',
                style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(nalog.opisKvara.tekst, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (cekaOdgovor) ...[
                const SizedBox(height: 8),
                Text(
                  'Čeka se vaš odgovor na ponudu',
                  style: tema.textTheme.labelLarge?.copyWith(color: tema.colorScheme.secondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Meni za demonstraciju stanja ekrana; postoji samo uz lažnu implementaciju porta.
class _MeniZaDemo extends StatelessWidget {
  const _MeniZaDemo();

  @override
  Widget build(BuildContext context) {
    final lazni = context.read<Zavisnosti>().lazniNalozi;
    final bloc = context.read<MojiNaloziBloc>();
    void javi(String tekst) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tekst)));
    return PopupMenuButton<String>(
      tooltip: 'Više',
      onSelected: (izbor) {
        switch (izbor) {
          case 'osvezi':
            bloc.add(const MojiNaloziZatrazeni());
          case 'greska':
            lazni?.neuspesniZahtevi = 1;
            javi('Sledeći zahtev neće uspeti.');
          case 'prazno':
            lazni?.prazniOdgovori = 1;
            bloc.add(const MojiNaloziZatrazeni());
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'osvezi', child: Text('Osveži')),
        if (lazni != null) ...[
          const PopupMenuItem(value: 'greska', child: Text('Simuliraj grešku sledećeg zahteva')),
          const PopupMenuItem(value: 'prazno', child: Text('Prikaži prazan odgovor')),
        ],
      ],
    );
  }
}
