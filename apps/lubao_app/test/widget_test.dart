import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lubao_app/app.dart';

void main() {
  testWidgets('shows the role selection screen on first launch', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LubaoApp()));
    await tester.pump();

    expect(find.text('Водитель'), findsOneWidget);
    expect(find.text('Логистическая компания'), findsOneWidget);
  });
}
