import 'package:flutter_test/flutter_test.dart';
import 'package:farmpulse/main.dart';

void main() {
  testWidgets('FarmPulse app launches successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FarmPulseApp());

    expect(find.text('FarmPulse'), findsWidgets);
  });
}
