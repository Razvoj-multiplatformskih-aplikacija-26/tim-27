import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/data/lazne_sesije.dart';
import 'package:mobile/dependencies.dart';

void main() {
  const kasnjenje = Duration(milliseconds: 10);

  testWidgets('lista prikazuje učitavanje pa naloge, a detalj ima ponudu', (tester) async {
    await tester.pumpWidget(RebootApp(zavisnosti: Zavisnosti.lazne(kasnjenje: kasnjenje)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Lenovo ThinkPad T14'), findsOneWidget);

    await tester.tap(find.text('Apple MacBook Air M1'));
    await tester.pumpAndSettle();
    expect(find.text('Nalog RN-1003'), findsOneWidget);
    expect(find.text('14.500 RSD'), findsOneWidget);

    await tester.tap(find.text('Prihvati ponudu'));
    await tester.pumpAndSettle();
    expect(find.text('Prihvatiti ponudu?'), findsOneWidget);
    await tester.tap(find.text('Prihvati'));
    await tester.pumpAndSettle();
    expect(find.text('U popravci'), findsOneWidget);
  });

  testWidgets('greška sledećeg zahteva pa „Pokušaj ponovo"', (tester) async {
    final zavisnosti = Zavisnosti.lazne(kasnjenje: kasnjenje);
    zavisnosti.lazniNalozi!.neuspesniZahtevi = 1;
    await tester.pumpWidget(RebootApp(zavisnosti: zavisnosti));
    await tester.pumpAndSettle();
    expect(find.text('Pokušaj ponovo'), findsOneWidget);
    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pumpAndSettle();
    expect(find.text('Lenovo ThinkPad T14'), findsOneWidget);
  });

  testWidgets('prazan prikaz', (tester) async {
    final zavisnosti = Zavisnosti.lazne(kasnjenje: kasnjenje);
    zavisnosti.lazniNalozi!.prazniOdgovori = 1;
    await tester.pumpWidget(RebootApp(zavisnosti: zavisnosti));
    await tester.pumpAndSettle();
    expect(find.text('Još nemate radnih naloga.'), findsOneWidget);
  });

  testWidgets('forma proverava opis kvara pravilom iz domena', (tester) async {
    await tester.pumpWidget(RebootApp(zavisnosti: Zavisnosti.lazne(kasnjenje: kasnjenje)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prijavi uređaj'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Marka i model'), 'HP EliteBook 840');
    await tester.enterText(find.widgetWithText(TextFormField, 'Opis kvara'), 'Ne radi');
    await tester.pump();
    expect(find.text('Opis kvara mora imati bar 10 znakova (sada 7).'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Opis kvara'), 'Ne pali se ni na punjaču.');
    await tester.tap(find.widgetWithText(FilledButton, 'Prijavi uređaj'));
    await tester.pumpAndSettle();
    expect(find.text('HP EliteBook 840'), findsOneWidget);
    expect(find.text('Moji nalozi'), findsOneWidget);
  });

  testWidgets('prijava: pogrešna lozinka, pa ulaz, pa odjava', (tester) async {
    await tester.pumpWidget(RebootApp(zavisnosti: Zavisnosti.lazne(kasnjenje: kasnjenje, prijavljen: false)));
    await tester.pumpAndSettle();
    expect(find.text('Prijavi se'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Korisničko ime'), 'ana');
    await tester.enterText(find.widgetWithText(TextField, 'Lozinka'), 'pogresna');
    await tester.tap(find.text('Prijavi se'));
    await tester.pumpAndSettle();
    expect(find.text('Pogrešno korisničko ime ili lozinka.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Lozinka'), 'reboot-demo');
    await tester.tap(find.text('Prijavi se'));
    await tester.pumpAndSettle();
    expect(find.text('Moji nalozi'), findsOneWidget);

    await tester.tap(find.byTooltip('Više'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Odjavi se'));
    await tester.pumpAndSettle();
    expect(find.text('Odjavili ste se.'), findsOneWidget);
  });

  testWidgets('istekla prijava vraća na prijavu i kaže zašto', (tester) async {
    final zavisnosti = Zavisnosti.lazne(kasnjenje: kasnjenje);
    await tester.pumpWidget(RebootApp(zavisnosti: zavisnosti));
    await tester.pumpAndSettle();
    (zavisnosti.sesije as LazneSesije).istekni();
    await tester.pumpAndSettle();
    expect(find.text('Prijava je istekla. Prijavite se ponovo.'), findsOneWidget);
  });
}
