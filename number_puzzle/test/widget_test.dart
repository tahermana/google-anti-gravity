import 'package:flutter_test/flutter_test.dart';
import 'package:number_puzzle/main.dart';

void main() {
  testWidgets('NumberPuzzleApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NumberPuzzleApp());
    expect(find.text('PUZZLE'), findsOneWidget);
  });
}
