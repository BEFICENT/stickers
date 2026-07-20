import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stickers/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches and creates a static sticker pack', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byKey(const Key('create-pack-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('create-pack-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pack-title-field')),
      'Integration Pack',
    );
    await tester.enterText(
      find.byKey(const Key('pack-author-field')),
      'Integration Test',
    );
    await tester.tap(find.byKey(const Key('create-pack-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Integration Pack'), findsOneWidget);
  });
}
