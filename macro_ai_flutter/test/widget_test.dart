import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:macro_ai/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MacroAiApp());
    expect(find.byType(Scaffold), findsWidgets);
  });
}
