import 'package:flutter_test/flutter_test.dart';

import 'package:monster_tap_game/main.dart';

void main() {
  testWidgets('shows start overlay', (WidgetTester tester) async {
    await tester.pumpWidget(const GameApp());

    expect(find.text('Monster Munch'), findsOneWidget);
    expect(find.text('Start The Game'), findsOneWidget);
  });
}
