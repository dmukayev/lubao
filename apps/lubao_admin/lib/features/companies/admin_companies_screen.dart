import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';

class AdminCompaniesScreen extends ConsumerWidget {
  const AdminCompaniesScreen({super.key});

  Future<void> _toggle(WidgetRef ref, String id, bool value) async {
    await ref.read(adminRepositoryProvider).setCompanyVerified(id, value);
    ref.invalidate(adminCompaniesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final companies = ref.watch(adminCompaniesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.adminCompaniesTitle)),
      body: companies.when(
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminCompaniesProvider)),
        data: (list) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminCompaniesProvider),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final company = list[index];
              return ListTile(
                title: Text(company.name),
                subtitle: Text('${company.city ?? ''} · ★ ${company.ratingAvg.toStringAsFixed(1)} (${company.ratingCount})'),
                trailing: Switch(
                  value: company.isVerified,
                  onChanged: (value) => _toggle(ref, company.id, value),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
