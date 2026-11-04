import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../precice.dart';
import '../tekst.dart';

/// Forma ponude; iznos i opis proverava Ponuda.proveri iz domena.
Future<Ponuda?> prikaziDijalogPonude(BuildContext context, RadniNalog nalog) => showDialog<Ponuda>(
  context: context,
  builder: (_) => _DijalogPonude(nalog: nalog),
);

class _DijalogPonude extends StatefulWidget {
  const _DijalogPonude({required this.nalog});

  final RadniNalog nalog;

  @override
  State<_DijalogPonude> createState() => _DijalogPonudeState();
}

class _DijalogPonudeState extends State<_DijalogPonude> {
  final _forma = GlobalKey<FormState>();
  final _iznos = TextEditingController();
  final _opis = TextEditingController();

  @override
  void dispose() {
    _iznos.dispose();
    _opis.dispose();
    super.dispose();
  }

  Rezultat<Ponuda> _proveri() =>
      Ponuda.proveri(iznos: int.tryParse(_iznos.text) ?? 0, opis: _opis.text, poslataU: DateTime.now());

  void _posalji() {
    if (!_forma.currentState!.validate()) return;
    Navigator.pop(context, _proveri().vrednostIliNull);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ponuda za ${widget.nalog.id.value}'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _forma,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _iznos,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Iznos', suffixText: 'RSD'),
                validator: (_) => switch (_proveri().greskaIliNull) {
                  final NeispravanIznos greska => greska.poruka,
                  _ => null,
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _opis,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Šta obuhvata popravka'),
                validator: (_) => switch (_proveri().greskaIliNull) {
                  final OpisPonudeObavezan greska => greska.poruka,
                  _ => null,
                },
                onFieldSubmitted: (_) => _posalji(),
              ),
              const SizedBox(height: 8),
              Text('Klijent ima 48 sati da odgovori na ponudu.', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Odustani')),
        FilledButton(onPressed: _posalji, child: const Text('Pošalji ponudu')),
      ],
    );
  }
}

/// Potvrda za nepovratne akcije; za otkazivanje traži i razlog. Vraća razlog ili null ako je odustao.
Future<String?> prikaziPotvrdu(BuildContext context, RadniNalog nalog, AkcijaOsoblja akcija) {
  final razlog = TextEditingController();
  final otkazivanje = akcija == AkcijaOsoblja.otkazi;
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${nazivAkcije(akcija)} ${nalog.id.value}?'),
      content: SizedBox(
        width: 420,
        child: otkazivanje
            ? TextField(
                controller: razlog,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Razlog otkazivanja'),
                onSubmitted: (_) => Navigator.pop(context, razlog.text),
              )
            : Text('${nalog.uredjaj.naziv} · ${nazivStanja(nalog.stanje)}. Ova promena se ne može vratiti.'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Odustani')),
        FilledButton(onPressed: () => Navigator.pop(context, razlog.text), child: Text(nazivAkcije(akcija))),
      ],
    ),
  );
}

Future<void> prikaziPrecice(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Prečice na tastaturi'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (taster, opis) in opisPrecica)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(taster, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: Text(opis)),
                ],
              ),
            ),
        ],
      ),
    ),
    actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Zatvori'))],
  ),
);
