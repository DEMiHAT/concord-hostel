import 'package:flutter_test/flutter_test.dart';
import 'package:concord/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ConcordApp());
    expect(find.text('C.O.N.C.O.R.D.'), findsOneWidget);
  });
}
