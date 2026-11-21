import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../dependencies.dart';
import '../precice.dart';
import '../tekst.dart';
import '../widgets/detalj_panel.dart';
import '../widgets/dijalozi.dart';
import '../widgets/prikazi_stanja.dart';
import '../widgets/tabela_naloga.dart';

/// Ispod ove širine tabela postaje lista, a bočni panel ide ispod liste.
const granicaSirine = 900.0;

/// Glavni ekran osoblja: tabela svih naloga, detalj u bočnom panelu, rad tastaturom.
class TablaScreen extends StatefulWidget {
  const TablaScreen({super.key});

  @override
  State<TablaScreen> createState() => _TablaScreenState();
}

class _TablaScreenState extends State<TablaScreen> {
  final _fokus = FocusNode(debugLabel: 'tabela naloga');

  TablaNalogaBloc get _bloc => context.read<TablaNalogaBloc>();

  @override
  void dispose() {
    _fokus.dispose();
    super.dispose();
  }

  /// Akcija nad izabranim nalogom: prvo dijalog gde treba, pa događaj Blocu.
  Future<void> _izvrsi(AkcijaOsoblja akcija) async {
    final stanje = _bloc.state;
    if (stanje is! TablaUcitana || !stanje.izabraniDozvoljava(akcija)) return;
    final nalog = stanje.izabrani!;
    switch (akcija) {
      case AkcijaOsoblja.posaljiPonudu:
        final ponuda = await prikaziDijalogPonude(context, nalog);
        if (ponuda != null) _bloc.add(AkcijaZatrazena(nalog.id, akcija, ponuda: ponuda));
      case AkcijaOsoblja.izdaj || AkcijaOsoblja.otkazi:
        final razlog = await prikaziPotvrdu(context, nalog, akcija);
        if (razlog != null) _bloc.add(AkcijaZatrazena(nalog.id, akcija, razlog: razlog));
      case AkcijaOsoblja.preuzmi || AkcijaOsoblja.oznaciSpreman:
        _bloc.add(AkcijaZatrazena(nalog.id, akcija));
    }
    _fokus.requestFocus();
  }

  void _prikaziObavestenje(TablaObavestenje obavestenje) {
    final poruka = switch (obavestenje) {
      AkcijaTableUspela(:final akcija, :final nalog) => switch (akcija) {
        AkcijaOsoblja.preuzmi => 'Preuzeli ste nalog ${nalog.id.value}.',
        AkcijaOsoblja.posaljiPonudu => 'Ponuda za ${nalog.id.value} je poslata klijentu.',
        AkcijaOsoblja.oznaciSpreman => 'Nalog ${nalog.id.value} je spreman za preuzimanje.',
        AkcijaOsoblja.izdaj => 'Uređaj iz naloga ${nalog.id.value} je izdat klijentu.',
        AkcijaOsoblja.otkazi => 'Nalog ${nalog.id.value} je otkazan.',
      },
      AkcijaTableOdbijena(:final greska) => greska.poruka,
      AkcijaTableNijeUspela(:final uzrok) => porukaNeuspeha(uzrok),
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(poruka)));
    _bloc.add(const ObavestenjeTablePrikazano());
  }

  void _simulirajGresku() {
    context.read<Zavisnosti>().lazniNalozi?.neuspesniZahtevi = 1;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sledeći zahtev neće uspeti.')));
  }

  void _prazanOdgovor() {
    context.read<Zavisnosti>().lazniNalozi?.prazniOdgovori = 1;
    _bloc.add(const TablaZatrazena());
  }

  @override
  Widget build(BuildContext context) {
    final lazni = context.read<Zavisnosti>().lazniNalozi;
    final serviser = _bloc.serviser;
    return Shortcuts(
      shortcuts: precice,
      child: Actions(
        actions: {
          PomeriIzborIntent: CallbackAction<PomeriIzborIntent>(onInvoke: (i) => _bloc.add(IzborPomeren(i.korak))),
          PonistiIzborIntent: CallbackAction<PonistiIzborIntent>(onInvoke: (_) => _bloc.add(const NalogIzabran(null))),
          AkcijaIntent: CallbackAction<AkcijaIntent>(onInvoke: (i) => _izvrsi(i.akcija)),
          OsveziIntent: CallbackAction<OsveziIntent>(onInvoke: (_) => _bloc.add(const TablaZatrazena())),
          PrikaziPreciceIntent: CallbackAction<PrikaziPreciceIntent>(onInvoke: (_) => prikaziPrecice(context)),
        },
        child: Focus(
          focusNode: _fokus,
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Reboot · radni nalozi'),
              actions: [
                BlocBuilder<TablaNalogaBloc, TablaNalogaState>(
                  builder: (context, state) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: Text(
                        state is TablaUcitana
                            ? '${serviser.ime} · aktivnih ${state.aktivnihPrijavljenog}/$maksAktivnihNaloga'
                            : serviser.ime,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Osveži (R)',
                  onPressed: () => _bloc.add(const TablaZatrazena()),
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Prečice (?)',
                  onPressed: () => prikaziPrecice(context),
                  icon: const Icon(Icons.keyboard_outlined),
                ),
                IconButton(
                  tooltip: 'Odjavi se',
                  onPressed: () => context.read<SesijaBloc>().add(const OdjavaZatrazena()),
                  icon: const Icon(Icons.logout),
                ),
                if (lazni != null)
                  PopupMenuButton<String>(
                    tooltip: 'Demo',
                    onSelected: (izbor) => izbor == 'greska' ? _simulirajGresku() : _prazanOdgovor(),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'greska', child: Text('Simuliraj grešku sledećeg zahteva')),
                      PopupMenuItem(value: 'prazno', child: Text('Prikaži prazan odgovor')),
                    ],
                  ),
                const SizedBox(width: 8),
              ],
            ),
            body: BlocConsumer<TablaNalogaBloc, TablaNalogaState>(
              listenWhen: (pre, sada) => sada is TablaUcitana && sada.obavestenje != null,
              listener: (context, state) => _prikaziObavestenje((state as TablaUcitana).obavestenje!),
              builder: (context, state) => switch (state) {
                TablaUcitavanje() => const PrikazUcitavanja(),
                TablaGreska(:final uzrok) => PrikazGreske(
                  uzrok: uzrok,
                  onPonovo: () => _bloc.add(const TablaZatrazena()),
                ),
                TablaPrazna() => PrazanPrikaz(
                  naslov: 'U servisu trenutno nema radnih naloga.',
                  akcija: FilledButton.tonal(
                    onPressed: () => _bloc.add(const TablaZatrazena()),
                    child: const Text('Osveži'),
                  ),
                ),
                TablaUcitana() => _Raspored(
                  stanje: state,
                  fokus: _fokus,
                  onIzaberi: (nalog) {
                    _bloc.add(NalogIzabran(nalog.id));
                    _fokus.requestFocus();
                  },
                  onAkcija: _izvrsi,
                  onZatvori: () => _bloc.add(const NalogIzabran(null)),
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Širok ekran: tabela levo, panel desno. Uzak: lista gore, panel ispod. Izbor je u Blocu, pa se ne gubi.
class _Raspored extends StatelessWidget {
  const _Raspored({
    required this.stanje,
    required this.fokus,
    required this.onIzaberi,
    required this.onAkcija,
    required this.onZatvori,
  });

  final TablaUcitana stanje;
  final FocusNode fokus;
  final ValueChanged<RadniNalog> onIzaberi;
  final ValueChanged<AkcijaOsoblja> onAkcija;
  final VoidCallback onZatvori;

  @override
  Widget build(BuildContext context) {
    final izabrani = stanje.izabrani;
    return LayoutBuilder(
      builder: (context, ogranicenja) {
        final siroko = ogranicenja.maxWidth >= granicaSirine;
        final tabela = ListenableBuilder(
          listenable: fokus,
          builder: (context, _) =>
              TabelaNaloga(stanje: stanje, imaFokus: fokus.hasPrimaryFocus, onIzaberi: onIzaberi, uska: !siroko),
        );
        final panel = izabrani == null
            ? null
            : DetaljPanel(nalog: izabrani, stanje: stanje, onAkcija: onAkcija, onZatvori: onZatvori);
        if (siroko) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tabela),
                if (panel != null) ...[
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 380,
                    child: ClipRRect(borderRadius: BorderRadius.circular(12), child: panel),
                  ),
                ],
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tabela),
              if (panel != null) ...[
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(borderRadius: BorderRadius.circular(12), child: panel),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
