import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../tekst.dart';
import '../tema.dart';

class OznakaStanja extends StatelessWidget {
  const OznakaStanja({super.key, required this.stanje});

  final StanjeNaloga stanje;

  @override
  Widget build(BuildContext context) {
    final boja = bojaStanja(stanje);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: boja.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: boja.withValues(alpha: 0.5)),
      ),
      child: Text(
        nazivStanja(stanje),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: boja, fontWeight: FontWeight.w600),
      ),
    );
  }
}
