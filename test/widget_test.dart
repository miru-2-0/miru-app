import 'package:flutter_test/flutter_test.dart';
import 'package:miru/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MiruApp());
    expect(find.byType(MiruApp), findsOneWidget);
  });
}
