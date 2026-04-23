import 'package:flutter_test/flutter_test.dart';
import 'package:concord/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const HailmaryApp());
    expect(find.text('H.A.I.L.M.A.R.Y.'), findsOneWidget);
  });
}
