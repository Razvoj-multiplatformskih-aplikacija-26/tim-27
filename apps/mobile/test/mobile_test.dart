import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
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
}
