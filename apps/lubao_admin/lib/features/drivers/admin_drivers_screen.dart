import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';

class AdminDriversScreen extends ConsumerWidget {
  const AdminDriversScreen({super.key});

  Future<void> _toggle(WidgetRef ref, String id, bool value) async {
    await ref.read(adminRepositoryProvider).setDriverVerified(id, value);
    ref.invalidate(adminDriversProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final drivers = ref.watch(adminDriversProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.adminDriversTitle)),
      body: drivers.when(
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminDriversProvider)),
        data: (list) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminDriversProvider),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final driver = list[index];
              return ListTile(
                title: Text(driver.fullName),
                subtitle: Text('★ ${driver.ratingAvg.toStringAsFixed(1)} (${driver.ratingCount})'),
                trailing: Switch(
                  value: driver.isVerified,
                  onChanged: (value) => _toggle(ref, driver.id, value),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
