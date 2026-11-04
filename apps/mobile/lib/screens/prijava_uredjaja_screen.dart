import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../tekst.dart';

/// Forma za prijavu uređaja. Unos proveravaju pravila iz domena, a tekst greške bira aplikacija.
class PrijavaUredjajaScreen extends StatefulWidget {
  const PrijavaUredjajaScreen({super.key});

  @override
  State<PrijavaUredjajaScreen> createState() => _PrijavaUredjajaScreenState();
}

class _PrijavaUredjajaScreenState extends State<PrijavaUredjajaScreen> {
  final _forma = GlobalKey<FormState>();
  final _naziv = TextEditingController();
  final _opis = TextEditingController();
  VrstaUredjaja _vrsta = VrstaUredjaja.laptop;
  bool _salje = false;

  @override
  void dispose() {
    _naziv.dispose();
    _opis.dispose();
    super.dispose();
  }

  void _posalji() {
    if (!_forma.currentState!.validate()) return;
    final uredjaj = Uredjaj.proveri(vrsta: _vrsta, naziv: _naziv.text).vrednostIliNull!;
    final opis = OpisKvara.proveri(_opis.text).vrednostIliNull!;
    setState(() => _salje = true);
    context.read<MojiNaloziBloc>().add(UredjajPrijavljen(uredjaj: uredjaj, opisKvara: opis));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MojiNaloziBloc, MojiNaloziState>(
      listenWhen: (pre, sada) => _salje,
      listener: (context, state) {
        if (state is MojiNaloziUcitani && state.obavestenje is NalogNapravljen) {
          context.go('/nalozi');
        } else if (state is MojiNaloziGreska || (state is MojiNaloziUcitani && state.obavestenje != null)) {
          setState(() => _salje = false);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Prijava uređaja')),
        body: Form(
          key: _forma,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<VrstaUredjaja>(
                initialValue: _vrsta,
                decoration: const InputDecoration(labelText: 'Vrsta uređaja'),
                items: [
                  for (final vrsta in VrstaUredjaja.values)
                    DropdownMenuItem(value: vrsta, child: Text(nazivVrste(vrsta))),
                ],
                onChanged: _salje ? null : (vrsta) => setState(() => _vrsta = vrsta ?? _vrsta),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _naziv,
                enabled: !_salje,
                decoration: const InputDecoration(labelText: 'Marka i model', hintText: 'npr. Lenovo ThinkPad T14'),
                validator: (unos) => Uredjaj.proveri(vrsta: _vrsta, naziv: unos ?? '').greskaIliNull?.poruka,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _opis,
                enabled: !_salje,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Opis kvara',
                  helperText: 'Od ${OpisKvara.minDuzina} do ${OpisKvara.maksDuzina} znakova.',
                  alignLabelWithHint: true,
                ),
                validator: (unos) => OpisKvara.proveri(unos ?? '').greskaIliNull?.poruka,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _salje ? null : _posalji,
                icon: _salje
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_salje ? 'Šalje se…' : 'Prijavi uređaj'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
