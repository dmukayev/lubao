import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lubao_admin/app.dart';

void main() {
  testWidgets('shows the admin login screen on first launch', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LubaoAdminApp()));
    await tester.pump();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Пароль'), findsOneWidget);
  });
}
