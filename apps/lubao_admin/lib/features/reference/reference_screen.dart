import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ReferenceScreen extends ConsumerStatefulWidget {
  const ReferenceScreen({super.key});

  @override
  ConsumerState<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends ConsumerState<ReferenceScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, String>?> _showNameDialog(
    BuildContext context, {
    required String title,
    bool withCode = true,
    String? initialRu,
  }) {
    final t = context.l10n;
    final codeController = TextEditingController();
    final kkController = TextEditingController();
    final ruController = TextEditingController(text: initialRu ?? '');
    final zhController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (withCode) ...[
                AppTextField(label: t.adminCode, controller: codeController),
                const SizedBox(height: 8),
              ],
              AppTextField(label: t.adminNameKk, controller: kkController),
              const SizedBox(height: 8),
              AppTextField(label: t.adminNameRu, controller: ruController),
              const SizedBox(height: 8),
              AppTextField(label: t.adminNameZh, controller: zhController),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'code': codeController.text.trim(),
              'kk': kkController.text.trim(),
              'ru': ruController.text.trim(),
              'zh': zhController.text.trim(),
            }),
            child: Text(t.commonSave),
          ),
        ],
      ),
    );
  }

  Future<void> _addBodyType() async {
    final t = context.l10n;
    final result = await _showNameDialog(context, title: t.adminAddBodyType);
    if (result == null) return;
    await ref.read(adminRepositoryProvider).createBodyType(
          result['code']!,
          I18nText(kk: result['kk']!, ru: result['ru']!, zh: result['zh']!),
        );
    ref.invalidate(referenceDataProvider);
  }

  Future<void> _addPermit() async {
    final t = context.l10n;
    final result = await _showNameDialog(context, title: t.adminAddPermit);
    if (result == null) return;
    await ref.read(adminRepositoryProvider).createPermit(
          result['code']!,
          I18nText(kk: result['kk']!, ru: result['ru']!, zh: result['zh']!),
        );
    ref.invalidate(referenceDataProvider);
  }

  Future<void> _addPoint(List<City> cities) async {
    final t = context.l10n;
    String? cityId = cities.isNotEmpty ? cities.first.id : null;
    final kkController = TextEditingController();
    final ruController = TextEditingController();
    final zhController = TextEditingController();
    final locale = Localizations.localeOf(context).languageCode;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t.adminAddPoint),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: cityId,
                  decoration: InputDecoration(labelText: t.adminPointCity, border: const OutlineInputBorder()),
                  items: cities
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.forLanguageCode(locale))))
                      .toList(),
                  onChanged: (value) => setDialogState(() => cityId = value),
                ),
                const SizedBox(height: 8),
                AppTextField(label: t.adminNameKk, controller: kkController),
                const SizedBox(height: 8),
                AppTextField(label: t.adminNameRu, controller: ruController),
                const SizedBox(height: 8),
                AppTextField(label: t.adminNameZh, controller: zhController),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.commonSave)),
          ],
        ),
      ),
    );

    if (confirmed != true || cityId == null) return;
    await ref.read(adminRepositoryProvider).createPoint(
          cityId!,
          I18nText(kk: kkController.text.trim(), ru: ruController.text.trim(), zh: zhController.text.trim()),
        );
    ref.invalidate(referenceDataProvider);
  }

  Future<void> _togglePoint(String id, bool isActive) async {
    await ref.read(adminRepositoryProvider).setPointActive(id, isActive);
    ref.invalidate(referenceDataProvider);
  }

  /// Подтвердить город, предложенный пользователем (задача 021): диалог
  /// переводов предзаполнен его `ru`-названием как отправная точка.
  Future<void> _approvePendingCity(AdminPendingCity pending) async {
    final t = context.l10n;
    final result = await _showNameDialog(context, title: t.adminApprove, withCode: false, initialRu: pending.name);
    if (result == null) return;
    await ref.read(adminRepositoryProvider).approveCity(
          pending.id,
          I18nText(kk: result['kk']!, ru: result['ru']!, zh: result['zh']!),
        );
    ref.invalidate(pendingCitiesProvider);
    ref.invalidate(referenceDataProvider);
  }

  Future<void> _mergePendingCity(AdminPendingCity pending, List<City> cities, String locale) async {
    final t = context.l10n;
    String? targetId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t.adminMergeCity),
          content: DropdownButtonFormField<String>(
            initialValue: targetId,
            decoration: InputDecoration(labelText: t.adminMergeCityTarget, border: const OutlineInputBorder()),
            items: cities
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.forLanguageCode(locale))))
                .toList(),
            onChanged: (value) => setDialogState(() => targetId = value),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.adminMergeCity)),
          ],
        ),
      ),
    );
    if (confirmed != true || targetId == null) return;
    await ref.read(adminRepositoryProvider).mergeCity(pending.id, targetId!);
    ref.invalidate(pendingCitiesProvider);
    ref.invalidate(referenceDataProvider);
  }

  Future<void> _rejectPendingCity(AdminPendingCity pending) async {
    final t = context.l10n;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.adminReject),
        content: AppTextField(label: t.adminRejectReasonLabel, controller: controller, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(t.commonDone)),
        ],
      ),
    );
    if (reason == null) return;
    await ref.read(adminRepositoryProvider).rejectCity(pending.id, rejectReason: reason.trim());
    ref.invalidate(pendingCitiesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final referenceData = ref.watch(referenceDataProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.adminReferenceTitle),
        bottom: TabBar(controller: _tabController, tabs: [
          Tab(text: t.driverSetupVehicleBodyType),
          Tab(text: t.driverSetupPermits),
          Tab(text: t.navFeed),
          Tab(text: t.adminPendingCitiesTab),
        ]),
      ),
      body: referenceData.when(
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(referenceDataProvider)),
        data: (refData) => TabBarView(
          controller: _tabController,
          children: [
            _SimpleList(
              items: refData.bodyTypes.map((b) => (b.code, b.name.forLanguageCode(locale))).toList(),
              onAdd: _addBodyType,
              addLabel: t.adminAddBodyType,
            ),
            _SimpleList(
              items: refData.permits.map((p) => (p.code, p.name.forLanguageCode(locale))).toList(),
              onAdd: _addPermit,
              addLabel: t.adminAddPermit,
            ),
            _PointsList(
              points: refData.points,
              locale: locale,
              onAdd: () => _addPoint(refData.cities),
              onToggle: _togglePoint,
              addLabel: t.adminAddPoint,
            ),
            _PendingCitiesList(
              onApprove: _approvePendingCity,
              onMerge: (pending) => _mergePendingCity(pending, refData.cities, locale),
              onReject: _rejectPendingCity,
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingCitiesList extends ConsumerWidget {
  const _PendingCitiesList({required this.onApprove, required this.onMerge, required this.onReject});

  final void Function(AdminPendingCity) onApprove;
  final void Function(AdminPendingCity) onMerge;
  final void Function(AdminPendingCity) onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final pending = ref.watch(pendingCitiesProvider);

    return pending.when(
      loading: () => const LoadingView(),
      error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(pendingCitiesProvider)),
      data: (list) {
        if (list.isEmpty) return EmptyState(message: t.adminPendingCitiesEmpty, icon: LucideIcons.mapPin);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingCitiesProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final city = list[index];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(city.name, style: Theme.of(context).textTheme.titleMedium),
                    if (city.regionName != null) Text('${t.adminCityRegion}: ${city.regionName}'),
                    if (city.submittedByLabel != null) Text('${t.adminCitySubmittedBy}: ${city.submittedByLabel}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(onPressed: () => onApprove(city), child: Text(t.adminApprove)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(onPressed: () => onMerge(city), child: Text(t.adminMergeCity)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(onPressed: () => onReject(city), child: Text(t.adminReject)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SimpleList extends StatelessWidget {
  const _SimpleList({required this.items, required this.onAdd, required this.addLabel});

  final List<(String, String)> items;
  final VoidCallback onAdd;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final (code, name) = items[index];
            return ListTile(title: Text(name), subtitle: Text(code));
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(onPressed: onAdd, icon: const Icon(LucideIcons.plus), label: Text(addLabel)),
        ),
      ],
    );
  }
}

class _PointsList extends StatelessWidget {
  const _PointsList({required this.points, required this.locale, required this.onAdd, required this.onToggle, required this.addLabel});

  final List<LoadingPoint> points;
  final String locale;
  final VoidCallback onAdd;
  final void Function(String id, bool isActive) onToggle;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: points.length,
          itemBuilder: (context, index) {
            final point = points[index];
            return ListTile(
              title: Text(point.name.forLanguageCode(locale)),
              subtitle: Text(point.isActive ? t.adminActive : t.adminInactive),
              trailing: Switch(value: point.isActive, onChanged: (value) => onToggle(point.id, value)),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(onPressed: onAdd, icon: const Icon(LucideIcons.plus), label: Text(addLabel)),
        ),
      ],
    );
  }
}
