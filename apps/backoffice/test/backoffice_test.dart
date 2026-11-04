import 'package:backoffice/app.dart';
import 'package:backoffice/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const kasnjenje = Duration(milliseconds: 10);

  Future<void> pokreni(WidgetTester tester, {Size velicina = const Size(1400, 900), Zavisnosti? zavisnosti}) async {
    tester.view.physicalSize = velicina;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(BackofficeApp(zavisnosti: zavisnosti ?? Zavisnosti.lazne(kasnjenje: kasnjenje)));
    await tester.pumpAndSettle();
  }

  testWidgets('tabela, kretanje strelicama i preuzimanje prečicom P', (tester) async {
    await pokreni(tester);
    expect(find.text('Broj'), findsOneWidget);
    expect(find.text('Marko Marković · aktivnih 4/5'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('Nalog RN-2005'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.pumpAndSettle();
    expect(find.text('Preuzeli ste nalog RN-2005.'), findsOneWidget);
    expect(find.text('Marko Marković · aktivnih 5/5'), findsOneWidget);
  });

  testWidgets('šesti aktivni nalog nije dozvoljen', (tester) async {
    await pokreni(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.textContaining('Preuzmi nalog'), findsNothing);
  });

  testWidgets('ponuda se šalje kroz dijalog sa pravilom iz domena', (tester) async {
    await pokreni(tester);
    await tester.tap(find.text('RN-2006'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
    await tester.pumpAndSettle();
    expect(find.text('Ponuda za RN-2006'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Pošalji ponudu'));
    await tester.pumpAndSettle();
    expect(find.text('Iznos ponude nije ispravan.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Iznos'), '9000');
    await tester.enterText(find.widgetWithText(TextFormField, 'Šta obuhvata popravka'), 'Čišćenje i nova pasta');
    await tester.tap(find.widgetWithText(FilledButton, 'Pošalji ponudu'));
    await tester.pumpAndSettle();
    expect(find.text('Ponuda za RN-2006 je poslata klijentu.'), findsOneWidget);
  });

  testWidgets('uzak prozor prikazuje listu i čuva izbor', (tester) async {
    await pokreni(tester);
    await tester.tap(find.text('RN-2006'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(700, 900);
    await tester.pumpAndSettle();
    expect(find.text('Broj'), findsNothing);
    expect(find.text('Nalog RN-2006'), findsOneWidget);
  });

  testWidgets('greška pa „Pokušaj ponovo"', (tester) async {
    final zavisnosti = Zavisnosti.lazne(kasnjenje: kasnjenje);
    zavisnosti.lazniNalozi!.neuspesniZahtevi = 1;
    await pokreni(tester, zavisnosti: zavisnosti);
    expect(find.text('Pokušaj ponovo'), findsOneWidget);
    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pumpAndSettle();
    expect(find.text('Broj'), findsOneWidget);
  });
}
