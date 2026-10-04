import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';

/// Настройки — базовый редактор ключ/значение сейчас (этап A: раздел
/// должен существовать и работать); конкретные поля (точка по умолчанию
/// через выбор города, радиус «Близко к дому», срок архива) — этап D.
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  Future<void> _save(BuildContext context, WidgetRef ref, String key, String value) async {
    final t = context.l10n;
    await ref.read(adminRepositoryProvider).setSetting(key, value);
    ref.invalidate(adminSettingsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.commonSave)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final settings = ref.watch(adminSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.adminNavSettings)),
      body: settings.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('AdminSettingsScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminSettingsProvider));
        },
        data: (values) {
          if (values.isEmpty) return EmptyState(message: t.adminSettingsEmpty);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final entry in values.entries) _SettingRow(settingKey: entry.key, value: entry.value, onSave: (v) => _save(context, ref, entry.key, v)),
            ],
          );
        },
      ),
    );
  }
}

class _SettingRow extends StatefulWidget {
  const _SettingRow({required this.settingKey, required this.value, required this.onSave});

  final String settingKey;
  final String value;
  final ValueChanged<String> onSave;

  @override
  State<_SettingRow> createState() => _SettingRowState();
}

class _SettingRowState extends State<_SettingRow> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.settingKey, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  AppTextField(label: widget.settingKey, controller: _controller),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(onPressed: () => widget.onSave(_controller.text), child: Text(t.commonSave)),
          ],
        ),
      ),
    );
  }
}
