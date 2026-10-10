import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import '../shared/admin_dialogs.dart';

/// Настройки (задача 028, п.22): точка по умолчанию, радиус «Близко к
/// дому», каналы кода входа (042 п.3). Каждое изменение — в audit_log.
/// Срок архива груза не настраивается: 3 дня после даты готовности
/// (CLAUDE.md), бэкенд такой настройки не читает (042 п.4).
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  Future<void> _saveDefaultCity(BuildContext context, WidgetRef ref, String cityId) async {
    final t = context.l10n;
    final reason = await showReasonDialog(context, title: t.adminSettingDefaultCity, confirmLabel: t.commonSave);
    if (reason == null) return;
    await ref.read(adminRepositoryProvider).setSetting('defaultPointCityId', cityId, reason: reason);
    ref.invalidate(adminSettingsProvider);
  }

  Future<void> _saveNumberSetting(BuildContext context, WidgetRef ref, {required String key, required String title, required String currentValue}) async {
    final t = context.l10n;
    final controller = TextEditingController(text: currentValue);
    final reasonController = TextEditingController();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final canConfirm = controller.text.trim().isNotEmpty && reasonController.text.trim().isNotEmpty;
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(label: title, controller: controller, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
                const SizedBox(height: 12),
                AppTextField(label: t.adminReasonLabel, controller: reasonController, maxLines: 2, onChanged: (_) => setState(() {})),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.commonCancel)),
              FilledButton(
                onPressed: canConfirm ? () => Navigator.pop(dialogContext, (controller.text.trim(), reasonController.text.trim())) : null,
                child: Text(t.commonSave),
              ),
            ],
          );
        },
      ),
    );
    if (result == null) return;
    await ref.read(adminRepositoryProvider).setSetting(key, result.$1, reason: result.$2);
    ref.invalidate(adminSettingsProvider);
  }

  Future<void> _pickDefaultCity(BuildContext context, WidgetRef ref, List<City> cities, String locale, String? currentCityId) async {
    final t = context.l10n;
    String? selection = currentCityId;
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(t.adminSettingDefaultCity),
          content: DropdownButtonFormField<String>(
            initialValue: selection,
            items: cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.forLanguageCode(locale)))).toList(),
            onChanged: (v) => setState(() => selection = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, selection), child: Text(t.commonSave)),
          ],
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    await _saveDefaultCity(context, ref, selected);
  }

  /// Переключатель «Перевод выкл.» (задача 010, п.8) — переиспользует
  /// общий AppSetting-механизм, отдельного эндпоинта нет.
  Future<void> _toggleTranslation(WidgetRef ref, bool enabled) async {
    await ref.read(adminRepositoryProvider).setSetting('translationEnabled', enabled ? 'true' : 'false');
    ref.invalidate(adminTranslationStatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final settings = ref.watch(adminSettingsProvider);
    final translationStats = ref.watch(adminTranslationStatsProvider);
    final refDataAsync = ref.watch(referenceDataProvider);
    final cities = refDataAsync.valueOrNull?.cities ?? const <City>[];
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(t.adminNavSettings)),
      body: settings.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('AdminSettingsScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminSettingsProvider));
        },
        data: (values) {
          final defaultCityId = values['defaultPointCityId'];
          final homeRadiusKm = values['homeRadiusKm'] ?? '200';
          final defaultCity = cities.where((c) => c.id == defaultCityId).firstOrNull;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.adminSettingDefaultCity, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Text(defaultCity?.name.forLanguageCode(locale) ?? t.adminSettingNotSet),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Тема задаёт FilledButton minimumSize на всю ширину
                    // (Size.fromHeight) — голый такой виджет рядом с
                    // Expanded в одном Row падает с «BoxConstraints forces
                    // an infinite width» (задачи 030/031, тот же баг, что в
                    // complaints_screen.dart/driver_detail_screen.dart).
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, AppSizes.buttonHeight)),
                      onPressed: cities.isEmpty ? null : () => _pickDefaultCity(context, ref, cities, locale, defaultCityId),
                      child: Text(t.adminEdit),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _NumberSettingCard(
                title: t.adminSettingHomeRadius,
                value: '$homeRadiusKm ${t.adminUnitKm}',
                onEdit: () => _saveNumberSetting(context, ref, key: 'homeRadiusKm', title: t.adminSettingHomeRadius, currentValue: homeRadiusKm),
              ),
              const SizedBox(height: 12),
              // 049 п.1: догруз за флагом, по умолчанию выключен (decisions.md 2026-10-08).
              AppCard(
                child: SwitchListTile(
                  key: const Key('settingPartialLoads'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.adminSettingPartialLoads, style: Theme.of(context).textTheme.titleSmall),
                  subtitle: Text(t.adminSettingPartialLoadsHint),
                  value: values['partialLoadsEnabled'] == 'true',
                  onChanged: (v) async {
                    await ref.read(adminRepositoryProvider).setSetting('partialLoadsEnabled', v ? 'true' : 'false');
                    ref.invalidate(adminSettingsProvider);
                    ref.invalidate(referenceDataProvider);
                  },
                ),
              ),
              const SizedBox(height: 12),
              const _LoginCodeChannelsCard(),
              const SizedBox(height: 12),
              _RatesCard(rates: refDataAsync.valueOrNull?.exchangeRates ?? const []),
              const SizedBox(height: 12),
              translationStats.when(
                loading: () => const AppCard(child: LoadingView()),
                error: (e, st) {
                  debugPrint('AdminSettingsScreen (translation): $e');
                  return const SizedBox.shrink();
                },
                data: (stats) => AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(t.adminTranslationSettingsTitle, style: Theme.of(context).textTheme.titleSmall)),
                          Switch(value: stats.enabled, onChanged: (v) => _toggleTranslation(ref, v)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${t.adminTranslationProviderLabel}: ${stats.provider}${stats.model != null ? ' (${stats.model})' : ''}'),
                      Text('${t.adminTranslationRequests7dLabel}: ${stats.requests7d} (${stats.successRequests7d} OK)'),
                      Text('${t.adminTranslationTokens7dLabel}: ${stats.tokensUsed7d}'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NumberSettingCard extends StatelessWidget {
  const _NumberSettingCard({required this.title, required this.value, required this.onEdit});

  final String title;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(value),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, AppSizes.buttonHeight)),
            onPressed: onEdit,
            child: Text(t.adminEdit),
          ),
        ],
      ),
    );
  }
}

/// «Каналы кода входа» (042 п.3, решение 2026-10-07): вкл/выкл и порядок
/// без релиза. Канал без ключей на сервере — серый, включить его нельзя.
class _LoginCodeChannelsCard extends ConsumerWidget {
  const _LoginCodeChannelsCard();

  String _label(LubaoLocalizations t, String id) => switch (id) {
        'telegram_bot' => t.loginChannelTelegramBot,
        'whatsapp' => t.loginChannelWhatsapp,
        'telegram' => t.loginChannelTelegram,
        _ => t.loginChannelSms,
      };

  Future<void> _save(BuildContext context, WidgetRef ref, List<AdminLoginCodeChannel> next) async {
    final t = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminRepositoryProvider).setLoginCodeChannels(next);
      messenger.showSnackBar(SnackBar(content: Text(t.adminLoginChannelsSaved)));
    } catch (e) {
      debugPrint('LoginCodeChannelsCard: $e');
      messenger.showSnackBar(SnackBar(content: Text(t.commonError)));
    }
    ref.invalidate(adminLoginCodeChannelsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final channels = ref.watch(adminLoginCodeChannelsProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.adminLoginChannelsTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(t.adminLoginChannelsHint, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          channels.when(
            loading: () => const LoadingView(),
            error: (e, st) {
              debugPrint('LoginCodeChannelsCard: $e');
              return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminLoginCodeChannelsProvider));
            },
            data: (list) => Column(
              children: [
                for (var i = 0; i < list.length; i++)
                  Opacity(
                    opacity: list[i].configured ? 1 : 0.45,
                    child: Row(
                      key: Key('adminLoginChannel-${list[i].id}'),
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_label(t, list[i].id)),
                              if (!list[i].configured) Text(t.adminLoginChannelsNoKeys, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: t.adminMoveUp,
                          icon: const Icon(LucideIcons.arrowUp, size: 18),
                          onPressed: i == 0 ? null : () => _save(context, ref, [...list]..insert(i - 1, list[i])..removeAt(i + 1)),
                        ),
                        IconButton(
                          tooltip: t.adminMoveDown,
                          icon: const Icon(LucideIcons.arrowDown, size: 18),
                          onPressed: i == list.length - 1 ? null : () => _save(context, ref, [...list]..insert(i + 2, list[i])..removeAt(i)),
                        ),
                        Switch(
                          key: Key('adminLoginChannelSwitch-${list[i].id}'),
                          value: list[i].enabled && list[i].configured,
                          onChanged: list[i].configured
                              ? (v) => _save(context, ref, [for (final c in list) c.id == list[i].id ? c.copyWith(enabled: v) : c])
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Курсы НБ РК (042 п.4): видно текущие, правка — с причиной (audit_log).
class _RatesCard extends ConsumerWidget {
  const _RatesCard({required this.rates});

  final List<ExchangeRate> rates;

  Future<void> _edit(BuildContext context, WidgetRef ref, Currency currency, double? current) async {
    final t = context.l10n;
    final rateController = TextEditingController(text: current?.toStringAsFixed(2) ?? '');
    final reasonController = TextEditingController();
    final code = currency.name.toUpperCase();
    final result = await showDialog<(double, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final rate = double.tryParse(rateController.text.trim().replaceAll(',', '.'));
          final canSave = rate != null && rate > 0 && reasonController.text.trim().isNotEmpty;
          return AlertDialog(
            title: Text('${t.adminRateEdit}: $code → ₸'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(key: const Key('adminRateValue'), label: '$code → ₸', controller: rateController, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {})),
                const SizedBox(height: 12),
                AppTextField(key: const Key('adminRateReason'), label: t.adminReasonLabel, controller: reasonController, maxLines: 2, onChanged: (_) => setState(() {})),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.commonCancel)),
              FilledButton(
                onPressed: canSave ? () => Navigator.pop(dialogContext, (rate, reasonController.text.trim())) : null,
                child: Text(t.commonSave),
              ),
            ],
          );
        },
      ),
    );
    if (result == null) return;
    await ref.read(adminRepositoryProvider).setExchangeRate(code, result.$1, reason: result.$2);
    ref.invalidate(referenceDataProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.adminRatesTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(t.adminRatesHint, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          // 058 п.4: + RUB, UZS (курс сума — до 4 знаков: 1 сум ≈ 0,04 ₸).
          for (final currency in const [Currency.usd, Currency.cny, Currency.rub, Currency.uzs])
            Builder(builder: (context) {
              final rate = rates.where((r) => r.currency == currency).firstOrNull?.rateToKzt;
              return Row(
                children: [
                  Expanded(child: Text('1 ${currency.name.toUpperCase()} = ${rate?.toStringAsFixed(rate < 1 ? 4 : 2) ?? '—'} ₸')),
                  IconButton(
                    key: Key('adminRateEdit-${currency.name}'),
                    tooltip: t.adminRateEdit,
                    icon: const Icon(LucideIcons.pencil, size: 18),
                    onPressed: () => _edit(context, ref, currency, rate),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}
