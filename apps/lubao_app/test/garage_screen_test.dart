import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_app/features/driver/profile/garage_screen.dart';
import 'package:lubao_app/providers/data_providers.dart';
import 'package:lubao_app/providers/locale_provider.dart';

GarageVehicle _vehicle({
  required String id,
  required VehicleKind kind,
  String? brand,
  String? plateNumber,
  double? capacityTons,
  bool isVerified = false,
}) =>
    GarageVehicle(
      id: id,
      kind: kind,
      plateNumber: plateNumber,
      brand: brand,
      capacityTons: capacityTons,
      isOwner: true,
      isVerified: isVerified,
      isArchived: false,
      createdAt: DateTime(2026, 10, 1),
    );

Future<void> _pump(WidgetTester tester, List<GarageVehicle> vehicles) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [garageVehiclesProvider.overrideWith((ref) async => vehicles)],
    child: MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: supportedLocales,
      localizationsDelegates: LubaoLocalizations.localizationsDelegates,
      home: const GarageScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows tractors and trailers in their own sections with the right status badge', (tester) async {
    await _pump(tester, [
      _vehicle(id: 't1', kind: VehicleKind.tractor, brand: 'MAN TGX', plateNumber: '777 ABP 05', isVerified: true),
      _vehicle(id: 't2', kind: VehicleKind.tractor, brand: 'Volvo FH', plateNumber: '123 ABC 02', isVerified: false),
      _vehicle(id: 'r1', kind: VehicleKind.trailer, plateNumber: '45 ABC 05', capacityTons: 20, isVerified: true),
    ]);

    expect(find.text('ТЯГАЧИ'), findsOneWidget);
    expect(find.text('ПРИЦЕПЫ'), findsOneWidget);
    expect(find.textContaining('MAN TGX'), findsOneWidget);
    expect(find.textContaining('Volvo FH'), findsOneWidget);
    expect(find.text('проверена'), findsNWidgets(2));
    expect(find.text('на проверке'), findsOneWidget);
  });

  testWidgets('shows the empty-state hint for a section with no vehicles', (tester) async {
    await _pump(tester, []);

    expect(find.text('Нет тягачей'), findsOneWidget);
    expect(find.text('Нет прицепов'), findsOneWidget);
    expect(find.text('Добавить машину'), findsOneWidget);
  });
}
