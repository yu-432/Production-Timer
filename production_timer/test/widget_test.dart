// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:production_timer/main.dart';

void main() {
  testWidgets('タイマーUIの開始/停止ボタンが切り替わる', (tester) async {
    await tester.pumpWidget(const ProductionTimerApp());

    expect(find.text('開始'), findsOneWidget);
    await tester.tap(find.text('開始'));
    await tester.pump();
    expect(find.text('停止'), findsOneWidget);

    await tester.tap(find.text('停止'));
    await tester.pump();
    expect(find.text('開始'), findsOneWidget);
  });
}
